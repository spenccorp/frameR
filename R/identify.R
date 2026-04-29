# frameR/R/identify.R
# Topic sentence identification

#' Identify topic-relevant sentences in a corpus
#'
#' Identifies sentences relevant to a topic of interest using
#' keyword matching, semantic similarity thresholding, or both.
#' The recommended default is "both", which takes the union of
#' keyword and similarity matches balancing precision and recall.
#'
#' @param sentences A character vector of all sentences in the corpus.
#' @param embeddings A matrix of sentence embeddings returned by
#'   \code{\link{embed_corpus}}.
#' @param anchor_words A character vector of keywords defining the
#'   topic of interest. For immigration these might be
#'   \code{c("immigration", "immigrant", "migration", "asylum")}.
#' @param model A model object returned by \code{\link{load_model}}.
#' @param threshold Numeric. Cosine similarity threshold for semantic
#'   matching. Sentences with similarity to the mean anchor embedding
#'   above this value are flagged as topic-relevant. Only used when
#'   \code{method} is \code{"similarity"} or \code{"both"}.
#'   Default 0.5. We recommend checking robustness across values
#'   of 0.3, 0.5, and 0.7.
#' @param method Character. One of \code{"keyword"},
#'   \code{"similarity"}, or \code{"both"} (recommended default).
#'
#' @return A logical vector of length equal to \code{sentences}.
#'   \code{TRUE} indicates a topic-relevant sentence.
#'
#' @details
#' The three identification methods involve different precision-recall
#' tradeoffs:
#' \itemize{
#'   \item \code{"keyword"}: High precision, potentially limited recall.
#'     Misses sentences that discuss the topic without anchor vocabulary.
#'   \item \code{"similarity"}: Higher recall at some cost to precision.
#'     Threshold choice affects this tradeoff directly.
#'   \item \code{"both"}: Recommended. Takes the union of keyword and
#'     similarity matches. Robust to varied vocabulary while maintaining
#'     reasonable precision.
#' }
#'
#' Results should be checked for robustness by running the full
#' analysis pipeline under alternative threshold values and confirming
#' that substantive findings are stable.
#'
#' @seealso \code{\link{embed_corpus}}, \code{\link{measure_frames}}
#'
#' @examples
#' \dontrun{
#' model <- load_model()
#' sentences <- my_corpus$text
#' embeddings <- embed_corpus(sentences, model)
#'
#' topic_mask <- identify_topic_sentences(
#'   sentences    = sentences,
#'   embeddings   = embeddings,
#'   anchor_words = c("immigration", "immigrant", "migration"),
#'   model        = model,
#'   threshold    = 0.5,
#'   method       = "both"
#' )
#'
#' sum(topic_mask) # number of topic-relevant sentences
#' topic_sentences <- sentences[topic_mask]
#' }
#'
#' @export
identify_topic_sentences <- function(sentences,
                                     embeddings,
                                     anchor_words,
                                     model,
                                     threshold = 0.5,
                                     method = "both") {

  check_python_env()
  check_model(model)

  if (!is.character(sentences)) {
    stop("sentences must be a character vector.", call. = FALSE)
  }

  if (!is.matrix(embeddings)) {
    stop("embeddings must be a matrix. Use embed_corpus() first.",
         call. = FALSE)
  }

  if (nrow(embeddings) != length(sentences)) {
    stop(
      "embeddings must have one row per sentence. ",
      "nrow(embeddings): ", nrow(embeddings),
      " length(sentences): ", length(sentences),
      call. = FALSE
    )
  }

  if (!is.character(anchor_words) || length(anchor_words) == 0) {
    stop("anchor_words must be a non-empty character vector.",
         call. = FALSE)
  }

  method <- match.arg(method, c("both", "keyword", "similarity"))

  mask <- pkg_env$identify_topic_sentences(
    sentences    = sentences,
    embeddings   = embeddings,
    anchor_words = anchor_words,
    model        = model,
    threshold    = threshold,
    method       = method
  )

  mask <- as.logical(mask)

  n_identified <- sum(mask)
  pct <- round(100 * n_identified / length(sentences), 1)

  message(
    "Identified ", n_identified, " topic-relevant sentences ",
    "(", pct, "% of corpus)."
  )

  if (n_identified < 10) {
    warning(
      "Fewer than 10 topic-relevant sentences identified. ",
      "Consider lowering the threshold or expanding anchor_words.",
      call. = FALSE
    )
  }

  return(mask)
}

# frameR/R/embed.R
# Corpus embedding functions

#' Embed a corpus of sentences
#'
#' Embeds all sentences in a corpus using the loaded sentence
#' embedding model. Embeddings should be computed once and
#' passed to downstream functions rather than recomputed
#' repeatedly.
#'
#' @param sentences A character vector of sentences to embed.
#' @param model A model object returned by \code{\link{load_model}}.
#' @param batch_size Integer. Number of sentences to embed per
#'   batch. Reduce if you encounter memory errors. Default 8.
#'
#' @return A numeric matrix with one row per sentence and one
#'   column per embedding dimension (768 for all-mpnet-base-v2).
#'   Row order matches the input \code{sentences} vector.
#'
#' @seealso \code{\link{load_model}}, \code{\link{identify_topic_sentences}}
#'
#' @examples
#' \dontrun{
#' model <- load_model()
#'
#' sentences <- c(
#'   "Immigration policy affects the labor market.",
#'   "Border security is a national priority.",
#'   "Cultural integration takes time."
#' )
#'
#' embeddings <- embed_corpus(sentences, model)
#' dim(embeddings) # n_sentences x 768
#' }
#'
#' @export
embed_corpus <- function(sentences, model, batch_size = 8L) {

  check_python_env()
  check_model(model)

  if (!is.character(sentences)) {
    stop("sentences must be a character vector.", call. = FALSE)
  }

  if (length(sentences) == 0) {
    stop("sentences must not be empty.", call. = FALSE)
  }

  message("Embedding ", length(sentences), " sentences...")

  embeddings <- pkg_env$embed_corpus(
    sentences = sentences,
    model = model,
    batch_size = as.integer(batch_size)
  )

  embeddings <- as.matrix(embeddings)

  message("Done. Embedding matrix: ",
          nrow(embeddings), " x ", ncol(embeddings))

  return(embeddings)
}

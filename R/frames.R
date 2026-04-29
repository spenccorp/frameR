# frameR/R/frames.R
# Frame category specification and keyword embedding

#' Embed frame category keywords
#'
#' Embeds the keywords representing each theoretically specified
#' frame category. The resulting keyword embeddings are used in
#' \code{\link{measure_frames}} to compute cosine similarity with
#' topic-relevant discourse.
#'
#' @param frame_categories A named list of character vectors.
#'   Each name is a frame category label and each character vector
#'   contains the keywords representing that category.
#'   Keywords should be specified in the language of the target
#'   corpus. For cross-lingual applications, translate and validate
#'   keywords independently for each language rather than translating
#'   mechanically.
#'   Example:
#'   \code{list(
#'     Economic = c("economy", "jobs", "welfare", "employment"),
#'     Cultural = c("culture", "values", "identity", "tradition"),
#'     Security = c("crime", "border", "terrorism", "security")
#'   )}
#' @param model A model object returned by \code{\link{load_model}}.
#'
#' @return A named list of numeric matrices, one per frame category.
#'   Each matrix has one row per keyword and one column per embedding
#'   dimension. Pass this object to \code{\link{measure_frames}}.
#'
#' @details
#' Frame categories should be derived from the substantive theoretical
#' and empirical literature on the issue and political context under
#' study, and specified prior to analysis. The validity of the
#' resulting frame measures depends on the theoretical grounding
#' of the keyword specification.
#'
#' We recommend assessing robustness to keyword specification by
#' running the full analysis under at minimum a baseline, broader,
#' and stricter keyword set for each category. See
#' \code{\link{measure_frames}} for details.
#'
#' @seealso \code{\link{load_model}}, \code{\link{measure_frames}}
#'
#' @examples
#' \dontrun{
#' model <- load_model()
#'
#' frame_categories <- list(
#'   Economic = c("economy", "jobs", "welfare", "employment", "wages"),
#'   Cultural = c("culture", "values", "identity", "tradition", "nation"),
#'   Security = c("crime", "border", "terrorism", "security", "illegal")
#' )
#'
#' keyword_embeddings <- embed_keywords(frame_categories, model)
#' names(keyword_embeddings) # "Economic" "Cultural" "Security"
#' }
#'
#' @export
embed_keywords <- function(frame_categories, model) {

  check_python_env()
  check_model(model)

  frame_categories <- frame_categories_to_python(frame_categories)

  # Check each category has at least one keyword
  empty <- sapply(frame_categories, function(x) length(x) == 0)
  if (any(empty)) {
    stop(
      "The following frame categories have no keywords: ",
      paste(names(frame_categories)[empty], collapse = ", "),
      call. = FALSE
    )
  }

  message("Embedding keywords for ", length(frame_categories),
          " frame categories...")

  keyword_embeddings <- pkg_env$embed_keywords(
    frame_categories = frame_categories,
    model            = model
  )

  for (cat in names(keyword_embeddings)) {
    keyword_embeddings[[cat]] <- as.matrix(keyword_embeddings[[cat]])
  }

  message("Done.")

  return(keyword_embeddings)
}

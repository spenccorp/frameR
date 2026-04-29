# frameR/R/model.R
# Model loading and management

#' Load a sentence embedding model
#'
#' Loads a sentence embedding model for use in frame analysis.
#' The default is the base all-mpnet-base-v2 model. When the
#' MARPOR-adapted model is available it will be the recommended
#' default for political text applications.
#'
#' @param model_name Character. One of:
#'   \itemize{
#'     \item \code{"base"} for the base all-mpnet-base-v2 model
#'       (default, works for any text)
#'     \item A Hugging Face model string such as
#'       \code{"sentence-transformers/all-mpnet-base-v2"}
#'     \item A local path to a fine-tuned model directory
#'   }
#'
#' @return A Python SentenceTransformer model object.
#'   Pass this object to \code{\link{embed_corpus}} and
#'   \code{\link{embed_keywords}}.
#'
#' @examples
#' \dontrun{
#' # Load the base model
#' model <- load_model()
#'
#' # Load a specific model by Hugging Face string
#' model <- load_model("sentence-transformers/all-mpnet-base-v2")
#'
#' # Load a locally fine-tuned model
#' model <- load_model("path/to/my/model")
#' }
#'
#' @export
load_model <- function(model_name = "base") {

  check_python_env()

  message("Loading model: ", model_name)
  message("This may take a moment on first use while the model downloads...")

  model <- pkg_env$load_model(model_name = model_name)

  message("Model loaded successfully.")

  return(model)
}

# frameR/R/utils.R
# Internal utilities and package load behaviour
# Not exported - for internal use only

# ============================================================
# PACKAGE STATE
# Store Python module reference once loaded
# ============================================================

pkg_env <- new.env(parent = emptyenv())


# ============================================================
# ON LOAD
# Runs automatically when user calls library(frameR)
# ============================================================

.onLoad <- function(libname, pkgname) {

  # Get stored environment path
  envpath <- get_stored_venv_path()

  # Activate environment if it exists
  if (!is.null(envpath) && reticulate::virtualenv_exists(envpath)) {
    reticulate::use_virtualenv(envpath, required = FALSE)
  }

  # Source the Python module
  python_file <- system.file(
    "python", "frameR.py",
    package = pkgname
  )

  if (file.exists(python_file)) {
    reticulate::source_python(python_file, envir = pkg_env)
  }
}


.onAttach <- function(libname, pkgname) {

  envpath <- get_stored_venv_path()

  if (is.null(envpath) || !reticulate::virtualenv_exists(envpath)) {
    packageStartupMessage(
      "frameR: Python environment not found.\n",
      "Run install_frameR() to set up the required dependencies.\n",
      "This only needs to be done once."
    )
  }
}
# ============================================================
# INTERNAL HELPERS
# ============================================================

#' Check that Python environment is ready
#' Throws an informative error if not
#' @noRd
check_python_env <- function() {
  if (!reticulate::virtualenv_exists("frameR")) {
    stop(
      "frameR Python environment not found. ",
      "Please run install_frameR() and restart R.",
      call. = FALSE
    )
  }
}


#' Check that a model object is valid
#' @noRd
check_model <- function(model) {
  if (is.null(model)) {
    stop(
      "No model provided. Load a model first using load_model().",
      call. = FALSE
    )
  }
}


#' Convert a named R list of character vectors to Python dict
#' Handles the reticulate translation explicitly
#' @noRd
frame_categories_to_python <- function(frame_categories) {
  if (!is.list(frame_categories)) {
    stop(
      "frame_categories must be a named list of character vectors.",
      call. = FALSE
    )
  }
  if (is.null(names(frame_categories))) {
    stop(
      "frame_categories must be a named list.",
      call. = FALSE
    )
  }
  return(frame_categories)
}


#' Convert bootstrap summary list from Python to R data frame
#' @noRd
summary_to_dataframe <- function(summary_list) {
  do.call(rbind, lapply(summary_list, as.data.frame))
}


#' Add significance stars to a p-value vector
#' @noRd
significance_stars <- function(p_values) {
  dplyr::case_when(
    p_values < 0.001 ~ "***",
    p_values < 0.01  ~ "**",
    p_values < 0.05  ~ "*",
    TRUE             ~ "ns"
  )
}

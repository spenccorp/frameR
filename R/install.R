# frameR/R/install.R
# Python environment setup
# Users run install_frameR() once after installing the package

#' Install Python dependencies for frameR
#'
#' Creates a dedicated Python virtual environment named "frameR"
#' and installs all required Python dependencies. This function
#' only needs to be run once after installing the frameR package.
#' After running it, restart R and load frameR as normal.
#'
#' @param envname Character. Name of the virtual environment to
#'   create. Defaults to "frameR". Only change this if you have
#'   a specific reason to use a different name.
#' @param restart Logical. Whether to prompt a restart of R after
#'   installation. Defaults to TRUE.
#'
#' @return Called for its side effects. Creates a Python virtual
#'   environment and installs dependencies.
#'
#' @examples
#' \dontrun{
#' # Run once after installing frameR
#' install_frameR()
#' # Then restart R and load the package normally
#' library(frameR)
#' }
#'
#' @export
install_frameR <- function(envname = "frameR", restart = TRUE) {

  # Check reticulate is available
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop(
      "The reticulate package is required. ",
      "Install it with: install.packages('reticulate')",
      call. = FALSE
    )
  }

  message("Creating Python virtual environment '", envname, "'...")

  # Create virtual environment
  reticulate::virtualenv_create(envname)

  message("Installing Python dependencies...")
  message("This may take a few minutes on first install.")

  # Install required packages
  reticulate::virtualenv_install(
    envname = envname,
    packages = c(
      "torch",
      "sentence-transformers",
      "scikit-learn",
      "numpy",
      "pandas"
    ),
    ignore_installed = FALSE
  )

  message("\nframeR Python environment installed successfully.")

  if (restart) {
    message("Please restart R and then load frameR with library(frameR).")
    if (rstudioapi::isAvailable()) {
      answer <- readline("Restart R now? (yes/no): ")
      if (tolower(answer) == "yes") {
        rstudioapi::restartSession()
      }
    }
  }
}


#' Check the status of the frameR Python environment
#'
#' Reports whether the frameR Python environment exists and
#' which Python packages are installed within it.
#'
#' @return Called for its side effects. Prints status information.
#'
#' @examples
#' \dontrun{
#' frameR_status()
#' }
#'
#' @export
frameR_status <- function() {

  if (!reticulate::virtualenv_exists("frameR")) {
    message("frameR Python environment not found.")
    message("Run install_frameR() to set it up.")
    return(invisible(FALSE))
  }

  message("frameR Python environment found.")
  message("\nInstalled packages:")

  pkgs <- reticulate::py_list_packages(envname = "frameR")
  relevant <- pkgs[pkgs$package %in% c(
    "torch", "sentence-transformers",
    "scikit-learn", "numpy", "pandas"
  ), ]

  print(relevant[, c("package", "version")])

  return(invisible(TRUE))
}

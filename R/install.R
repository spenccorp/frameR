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
#' @param envpath Character. Path where the virtual environment
#'   will be created. Defaults to a platform-appropriate location
#'   outside of cloud-synced folders. Change this if you want
#'   the environment in a specific location.
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
install_frameR <- function(envname = "frameR",
                           envpath = NULL,
                           restart = TRUE) {

  # Check reticulate is available
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop(
      "The reticulate package is required. ",
      "Install it with: install.packages('reticulate')",
      call. = FALSE
    )
  }

  # Determine safe environment path
  if (is.null(envpath)) {
    envpath <- get_safe_venv_path(envname)
  } else {
    envpath <- file.path(envpath, envname)
  }

  message("Creating Python virtual environment at:\n  ", envpath)

  # Create virtual environment at explicit path
  reticulate::virtualenv_create(envname = envpath)

  message("Installing Python dependencies...")
  message("This may take a few minutes on first install.")

  # Install required packages
  reticulate::virtualenv_install(
    envname  = envpath,
    packages = c(
      "torch",
      "sentence-transformers",
      "scikit-learn",
      "numpy",
      "pandas"
    ),
    ignore_installed = FALSE
  )

  # Store the path so .onLoad can find it
  store_venv_path(envpath)

  message("\nframeR Python environment installed successfully.")
  message("Environment location: ", envpath)

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

  envpath <- get_stored_venv_path()

  if (is.null(envpath) || !reticulate::virtualenv_exists(envpath)) {
    message("frameR Python environment not found.")
    message("Run install_frameR() to set it up.")
    return(invisible(FALSE))
  }

  message("frameR Python environment found at:\n  ", envpath)
  message("\nInstalled packages:")

  pkgs <- reticulate::py_list_packages(envname = envpath)
  relevant <- pkgs[pkgs$package %in% c(
    "torch", "sentence-transformers",
    "scikit-learn", "numpy", "pandas"
  ), ]

  print(relevant[, c("package", "version")])

  return(invisible(TRUE))
}


# ============================================================
# INTERNAL HELPERS FOR PATH MANAGEMENT
# ============================================================

#' Get a safe virtual environment path outside cloud sync folders
#' @noRd
get_safe_venv_path <- function(envname) {

  if (.Platform$OS.type == "windows") {
    # Use local app data on Windows - never synced by OneDrive
    base <- Sys.getenv("LOCALAPPDATA")
    if (nchar(base) == 0) {
      base <- file.path(Sys.getenv("USERPROFILE"), "AppData", "Local")
    }
    path <- file.path(base, "frameR", "venvs", envname)
  } else if (Sys.info()["sysname"] == "Darwin") {
    # Mac: use Application Support
    path <- file.path(
      path.expand("~"), "Library", "Application Support",
      "frameR", "venvs", envname
    )
  } else {
    # Linux: use ~/.local/share
    path <- file.path(
      path.expand("~"), ".local", "share",
      "frameR", "venvs", envname
    )
  }

  # Create parent directories if needed
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  return(path)
}


#' Store virtual environment path in user config
#' @noRd
store_venv_path <- function(envpath) {
  config_dir  <- tools::R_user_dir("frameR", which = "config")
  dir.create(config_dir, recursive = TRUE, showWarnings = FALSE)
  config_file <- file.path(config_dir, "config.rds")
  config      <- list(venv_path = envpath)
  saveRDS(config, config_file)
}


#' Retrieve stored virtual environment path
#' @noRd
get_stored_venv_path <- function() {
  config_file <- file.path(
    tools::R_user_dir("frameR", which = "config"),
    "config.rds"
  )
  if (!file.exists(config_file)) return(NULL)
  config <- readRDS(config_file)
  return(config$venv_path)
}

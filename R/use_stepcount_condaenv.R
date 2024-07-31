#' Use Conda Environment for `stepcount`
#'
#' @param ... additional arguments to pass to [reticulate::use_condaenv()]
#' other than `condaenv`.
#'
#' @return Nothing
#' @export
#' @rdname use_stepcount_condaenv
use_stepcount_condaenv = function(envname =  "stepcount", ...) {
  reticulate_python = Sys.getenv("RETICULATE_PYTHON", unset = NA)
  if (!is.na(reticulate_python)) {
    warning(
      paste0(
        "[stepcount] RETICULATE_PYTHON environment variable is set, ",
        "may not work. ",
        'Restart R, run Sys.unsetenv("RETICULATE_PYTHON") before running,',
        "or run stepcount::unset_reticulate_python()")
    )
  }
  # if (!have_stepcount_condaenv()) {
  #   warning("stepcount conda environment does not seem to exist!")
  # }
  reticulate::use_condaenv(condaenv = envname, ...)
}

#' @export
#' @rdname use_stepcount_condaenv
#' @param python_version version of Python to use for environment
#' @param envname environment name for the conda environment
conda_create_stepcount = function(
    envname = "stepcount",
    ...,
    python_version = "3.9"
) {
  reticulate::conda_create(
    envname = envname,
    packages = c("openjdk", "pip"),
    python_version = python_version)
  reticulate::py_install(
    packages = "stepcount",
    envname = envname,
    python_version = python_version,
    pip = TRUE,
    ...)

}


#' @export
#' @rdname use_stepcount_condaenv
unset_reticulate_python = function() {
  Sys.unsetenv("RETICULATE_PYTHON")
}

#' @export
#' @rdname use_stepcount_condaenv
have_stepcount_condaenv = function() {
  reticulate::condaenv_exists("stepcount")
}

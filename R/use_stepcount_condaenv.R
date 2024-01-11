#' Use Conda Environment for `stepcount`
#'
#' @param ... additional arguments to pass to [reticulate::use_condaenv()]
#' other than `condaenv`.
#'
#' @return Nothing
#' @export
#' @rdname use_stepcount_condaenv
use_stepcount_condaenv = function(...) {
  reticulate_python = Sys.getenv("RETICULATE_PYTHON", unset = NA)
  if (!is.na(reticulate_python)) {
    warning(
      paste0(
        "RETICULATE_PYTHON environment variable is set, may not work.",
        'Restart R, run Sys.unsetenv("RETICULATE_PYTHON") before running,',
        "or run stepcount::unset_reticulate_python()")
    )
  }
  if (!have_stepcount_condaenv()) {
    warning("stepcount conda environment does not seem to exist!")
  }
  reticulate::use_condaenv(condaenv = "stepcount", ...)
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

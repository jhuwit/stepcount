#' Command for `py_require` for `stepcount`
#'
#' @param ... arguments to pass to [reticulate::py_require()]
#'
#' @returns A logical value indicating whether the package is available.
#' @export
py_require_stepcount = function(...) {
  reticulate::py_require("stepcount==3.11.0", python_version = "3.10",
                         ...)
}

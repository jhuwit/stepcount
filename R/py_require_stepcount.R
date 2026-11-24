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

# Declare the Python requirement the first time a stepcount function needs
# Python, rather than in .onLoad. Loading the namespace (e.g. by R CMD check
# of a package that Suggests stepcount) then never changes the Python
# requirements of the session. py_require() can only be applied before Python
# is initialized, so skip it afterwards and use whatever Python is running.
ensure_stepcount_requirement = function() {
  if (!reticulate::py_available(initialize = FALSE)) {
    py_require_stepcount()
  }
  invisible(NULL)
}

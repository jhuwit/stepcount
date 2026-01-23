#' Check the `stepcount` Python Module
#'
#'
#' @return A logical value indicating whether the `stepcount` Python module is available.
#' @export
#' @rdname stepcount_setup
#' @examples
#' if (have_stepcount()) {
#'    stepcount_version()
#' }
have_stepcount = function() {
  reticulate::py_module_available("stepcount")
}

#' @export
#' @rdname stepcount_setup
stepcount_check = function() {
  step_version = try({
    stepcount_version()
  }, silent = TRUE)
  have_stepcount() && !inherits(step_version, "try-error") &&
    length(step_version) > 0 && package_version(step_version) >= package_version("3.11.0")
}


module_version = function(module = "numpy") {
  assertthat::is.scalar(module)
  if (!reticulate::py_module_available(module)) {
    stop(paste0(module, " is not installed!"))
  }
  df = reticulate::py_list_packages()
  df$version[df$package == module]
}


#' @export
#' @rdname stepcount_setup
stepcount_version = function() {
  module_version("stepcount")
}

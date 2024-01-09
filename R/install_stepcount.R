#' Install the `stepcount` Python Module
#'
#' @param packages packages to install
#' @param ... Additional arguments to pass to [reticulate::py_install()],
#' other than `pip` (`pip = TRUE` enforced)
#' @param envname environment name passed to  [reticulate::py_install()]
#'
#' @return Output of [reticulate::py_install]
#' @export
#' @rdname stepcount_setup
#' @examples
#' if (have_stepcount()) {
#'    stepcount_version()
#' }
#'
install_stepcount = function(packages = "stepcount",
                             ...,
                             envname = "stepcount") {
  packages = unique(c(packages, "stepcount"))
  reticulate::py_install(
    envname = envname,
    packages = packages,
    pip = TRUE, ...)
}

#' @export
#' @rdname stepcount_setup
have_stepcount = function() {
  reticulate::py_module_available("stepcount")
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


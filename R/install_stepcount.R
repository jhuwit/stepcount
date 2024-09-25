#' Install the `stepcount` Python Module
#'
#' @param packages packages to install.
#' If `stepcount` is not included, it will be added.  This package is
#' known to work with `stepcount==3.2.4`
#' @param ... Additional arguments to pass to [reticulate::py_install()],
#' other than `pip` (`pip = TRUE` enforced)
#'
#' @return Output of [reticulate::py_install]
#' @export
#' @rdname stepcount_setup
#' @examples
#' if (have_stepcount()) {
#'    stepcount_version()
#' }
install_stepcount = function(packages = "stepcount",
                             ...) {
  if (!any(grepl("^stepcount", trimws(tolower(packages))))) {
    packages = unique(c(packages, "stepcount"))
  }
  reticulate::py_install(
    packages = packages,
    pip = TRUE, ...)
}

#' @export
#' @rdname stepcount_setup
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
    length(step_version) > 0
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


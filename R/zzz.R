.onLoad <- function(libname, pkgname) {
  reticulate::py_require("stepcount", python_version = "3.10")
}

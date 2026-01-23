.onLoad <- function(libname, pkgname) {
  reticulate::py_require("stepcount>=3.11.0", python_version = "3.10")
}

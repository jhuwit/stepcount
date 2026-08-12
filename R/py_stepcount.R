#' Perform step count calculation in a separate Python environment
#'
#' @param ... arguments passed to [stepcount()]
#' @param pyenv_function function that loads the `stepcount` Python package.
#' By default, it uses [stepcount::py_require_stepcount].
#' If this function has an `args` argument, the output
#' of `pyenv_function` will be re-assigned to `args`.
#' @param show Logical, whether to show the standard output on the
#' screen while the child process is running, passed to [callr::r()]
#'
#' @returns The output from [stepcount()].
#' A tibble with minute-level `time`, `steps`, and `walking` columns.
#' @export
#'
#' @examples
#' \donttest{
#'   file = system.file("extdata/P30_wrist100.csv.gz", package = "stepcount")
#'   if (stepcount_check()) {
#'     df = readr::read_csv(file)
#'     out = try({py_stepcount(df, sample_rate = 100)})
#'   }
#' }
py_stepcount = function(
    ...,
    pyenv_function = function() {
      stepcount::py_require_stepcount()
    },
    show = TRUE) {
  rlang::check_installed("callr")
  steps <- callr::r(
    show = show,
    func = function(..., pyenv_function) {
      args = list(...)
      if ("args" %in% methods::formalArgs(pyenv_function)) {
        args = pyenv_function(args)
      } else {
        pyenv_function()
      }
      res = do.call(stepcount::stepcount, args = args)
    },
    args = list(...,
                pyenv_function = pyenv_function)
  ) # Safely injects data into the process
}

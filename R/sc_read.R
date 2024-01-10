#' Title
#'
#' @param file path to the file for reading
#' @param resample_hz Target frequency (Hz) to resample the signal. If
#' "uniform", use the implied frequency (use this option to fix any device
#' sampling errors). Pass `NULL` to disable. Defaults to "uniform".
#' @param verbose print diagnostic messages
#' @param keep_pandas do not convert the data to a `data.frame` and keep
#' as a `pandas` `data.frame`
#'
#' @return A list of the data and information about the data
#' @export
#'
#' @examples
#' file = system.file("extdata/P30_wrist100.csv.gz", package = "stepcount")
#' if (stepcount_check()) {
#'   out = sc_read(file)
#' }
sc_read = function(
    file,
    resample_hz = "uniform",
    verbose = TRUE,
    keep_pandas = FALSE
) {

  if (keep_pandas) {
    sc = stepcount_base_noconvert()
  } else {
    sc = stepcount_base()
  }
  verbose = as.logical(verbose)
  assertthat::assert_that(
    assertthat::is.readable(file),
    assertthat::is.count(resample_hz) || (
      assertthat::is.string(resample_hz) && resample_hz == "uniform")
  )
  out = sc$read(filepath = file,
                resample_hz = resample_hz,
                verbose = verbose)
  if (keep_pandas) {
    tmp = reticulate::py_to_r(out)
    out = list(
      data = out[[0]],
      info = reticulate::py_to_r(out)[[2]]
    )
  }
  names(out) = c("data", "info")
  out
}

#' Read a Data Set for `stepcount`
#'
#' @param file path to the file for reading
#' @param resample_hz Target frequency (Hz) to resample the signal. If
#' "uniform", use the implied frequency (use this option to fix any device
#' sampling errors). Pass `NULL` to disable. Defaults to "uniform".
#' @param verbose print diagnostic messages
#' @param sample_rate the sample rate of the data.  Set to `NULL`
#' for `stepcount` to try to guess this
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
#'   out = sc_read(file, sample_rate = 100L)
#' }
sc_read = function(
    file,
    sample_rate = NULL,
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
    is.null(sample_rate) || assertthat::is.count(sample_rate),
    is.null(resample_hz) ||
      assertthat::is.count(resample_hz) ||
      (assertthat::is.string(resample_hz) && resample_hz == "uniform")
  )
  file = normalizePath(path.expand(file))
  out = sc$read(filepath = file,
                resample_hz = resample_hz,
                sample_rate = sample_rate,
                verbose = verbose)
  if (keep_pandas) {
    out = list(
      data = out[[0]],
      info = reticulate::py_to_r(out[1])
    )
  }
  names(out) = c("data", "info")
  out
}

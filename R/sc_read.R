#' Title
#'
#' @param file path to the file for reading
#' @param resample_hz Target frequency (Hz) to resample the signal. If
#' "uniform", use the implied frequency (use this option to fix any device
#' sampling errors). Pass `NULL` to disable. Defaults to "uniform".
#' @param verbose print diagnostic messages
#'
#' @return A list of the data and information about the data
#' @export
#'
#' @examples
#' file = system.file("extdata/P30_wrist100.csv.gz", package = "stepcount")
#' if (have_stepcount()) {
#'   out = sc_read(file)
#' }
sc_read = function(
    file,
    resample_hz = "uniform",
    verbose = TRUE) {

  sc = stepcount_base()
  verbose = as.logical(verbose)
  assertthat::assert_that(
    assertthat::is.readable(file),
    assertthat::is.count(resample_hz) || (
      assertthat::is.string(resample_hz) && resample_hz == "uniform")
  )
  out = sc$read(filepath = file,
          resample_hz = resample_hz,
          verbose = verbose)
  names(out) = c("data", "info")
  out
}

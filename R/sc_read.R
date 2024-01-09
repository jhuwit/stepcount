#' Title
#'
#' @param file path to the file for reading
#' @param resample_hz Target frequency (Hz) to resample the signal. If
#' "uniform", use the implied frequency (use this option to fix any device
#' sampling errors). Pass `NULL` to disable. Defaults to "uniform".
#' @param verbose print diagnostic messages
#'
#' @return
#' @export
#'
#' @examples
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
  sc$read(filepath = file,
          resample_hz = resample_hz,
          verbose = verbose)
}

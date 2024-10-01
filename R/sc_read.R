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
#' @note The data `P30_wrist100` is from
#' \url{https://ora.ox.ac.uk/objects/uuid:19d3cb34-e2b3-4177-91b6-1bad0e0163e7},
#' where we took the first 180,000 rows, the first 30 minutes of data
#' from that participant as an example.
#'
#' @examples
#'
#' file = system.file("extdata/P30_wrist100.csv.gz", package = "stepcount")
#' if (stepcount_check()) {
#'   out = sc_read(file)
#' }
#' \dontrun{
#'   file = system.file("extdata/P30_wrist100.csv.gz", package = "stepcount")
#'   if (stepcount_check()) {
#'     out = sc_read(file, sample_rate = 100L)
#'   }
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
  if ("read" %in% names(sc)) {
    func = sc$read
  } else if ("utils" %in% names(sc) && "read" %in% names(sc$utils)) {
    func = sc$utils$read
  } else {
    warning("No function for reading found, using stepcount.read as default")
    func = sc$read
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
  out = func(filepath = file,
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

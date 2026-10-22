#' Rename data for Stepcount
#'
#' @param data a `data.frame` of raw accelerometry
#'
#' @return A `data.frame` of renamed columns
#' @export
sc_rename_data = function(data) {
  HEADER_TIMESTAMP = TIME = HEADER_TIME_STAMP = X = Y = Z = NULL
  rm(list = c("HEADER_TIMESTAMP", "HEADER_TIME_STAMP", "X", "Y", "Z",
              "TIME"))
  assertthat::assert_that(
    is.data.frame(data)
  )
  # uppercase
  colnames(data) = toupper(colnames(data))
  cn = colnames(data)
  if ("TIME" %in% cn && !"HEADER_TIMESTAMP" %in% cn) {
    data = renamer(data, old = "TIME", new = "HEADER_TIMESTAMP")
  }
  if ("HEADER_TIME_STAMP" %in% cn && !"HEADER_TIMESTAMP" %in% cn) {
    data = renamer(data, old = "HEADER_TIME_STAMP", new = "HEADER_TIMESTAMP")
  }
  stopifnot(all(c("X", "Y", "Z", "HEADER_TIMESTAMP") %in% colnames(data)))
  data = renamer(data, old = "HEADER_TIMESTAMP", new = "time")
  colnames(data) = tolower(colnames(data))
  data
}

#' @export
#' @param path path to the CSV output file
#' @param chunk_size number of rows formatted and written at a time, which
#' bounds the memory used for long recordings. The file is the same for any
#' `chunk_size`.
#' @rdname sc_rename_data
sc_write_csv = function(data, path = tempfile(fileext = ".csv"),
                        chunk_size = 1e6) {
  data = sc_rename_data(data = data)
  opts = options()
  on.exit(options(opts), add = TRUE)
  options(digits.secs = 3)
  n = nrow(data)
  if (n == 0) {
    data$time = format(data$time, "%Y-%m-%d %H:%M:%OS3")
    readr::write_csv(x = data, file = path, progress = FALSE)
    return(path)
  }
  for (start in seq(1, n, by = chunk_size)) {
    rows = seq.int(start, min(n, start + chunk_size - 1))
    chunk = data[rows, , drop = FALSE]
    # identical to format(chunk$time, "%Y-%m-%d %H:%M:%OS3")
    chunk$time = format_time_fast(chunk$time, digits = 3L)
    readr::write_csv(x = chunk, file = path, progress = FALSE,
                     append = start > 1)
  }
  return(path)
}


renamer = function(data, old, new) {
  stopifnot(length(old) == length(new))
  cn = colnames(data)
  cn[cn %in% old] = new
  colnames(data) = cn
  data
}

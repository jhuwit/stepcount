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
#' @rdname sc_rename_data
sc_write_csv = function(data, path = tempfile(fileext = ".csv")) {
  data = sc_rename_data(data = data)
  opts = options()
  on.exit(options(opts), add = TRUE)
  options(digits.secs = 3)
  data$time = format(data$time, "%Y-%m-%d %H:%M:%OS3")
  readr::write_csv(x = data, file = path, progress = FALSE)
  return(path)
}


renamer = function(data, old, new) {
  stopifnot(length(old) == length(new))
  cn = colnames(data)
  cn[cn %in% old] = new
  colnames(data) = cn
  data
}

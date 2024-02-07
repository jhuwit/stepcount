sc_model_version = function(model_type) {
  switch(
    model_type,
    "rf" = "20230713",
    "ssl" = "ssl-20230208"
  )
}
sc_model_md5 = function(model_type) {
  switch(
    model_type,
    "rf" = "9a6ef63ca4d651c937c18b25d5af4e72",
    "ssl" = "eea6179f079b554d5e2c8c98ccea8423"
  )
}

#' Load Stepcount Model
#'
#' @param model_type type of the model: either random forest (rf) or
#' Self-Supervised Learning model (ssl)
#' @param check_md5 Do a MD5 checksum on the file
#' @param force_download force a download of the model, even if the file
#' exists
#' @param model_path the file path to the model.  If on disk, this can be
#' re-used and not re-downloaded.  If `NULL`, will download to the
#' temporary directory
#' @param as_python Keep model object as a python object
#'
#' @return A model from Python.  `sc_download_model` returns a model file path.
#' @export
sc_load_model = function(
    model_type = c("ssl", "rf"),
    model_path = NULL,
    check_md5 = TRUE,
    force_download = FALSE,
    as_python = TRUE
) {

  model_type = match.arg(model_type, choices = c("ssl", "rf"))
  model_version = sc_model_version(model_type)
  model_md5 = sc_model_md5(model_type)
  if (as_python) {
    sc = stepcount_base_noconvert()
  } else {
    sc = stepcount_base()
  }
  if (is.null(model_path)) {
    model_path = file.path(
      tempdir(),
      paste0(model_version, "_", model_type, ".joblib.lzma")
    )
  } else {
    model_path = path.expand(model_path)
  }
  model = sc$load_model(
    model_path = model_path,
    model_type = model_type,
    check_md5 = check_md5,
    force_download = force_download)
  model
}

#' @export
#' @rdname sc_load_model
sc_model_filename = function(
    model_type = c("ssl", "rf")
) {
  model_type = match.arg(model_type, choices = c("ssl", "rf"))
  model_version = sc_model_version(model_type)
  paste0(model_version, ".joblib.lzma")
}

#' @export
#' @rdname sc_load_model
#' @param ... for `sc_download_model`, additional arguments to pass to
#' [curl::curl_download()]
sc_download_model = function(
    model_path,
    model_type = c("ssl", "rf"),
    check_md5 = TRUE,
    ...
) {
  model_type = match.arg(model_type, choices = c("ssl", "rf"))
  model_filename = sc_model_filename(model_type = model_type)
  model_md5 = sc_model_md5(model_type)
  base_url = "https://wearables-files.ndph.ox.ac.uk/files/models/stepcount/"
  url = paste0(base_url, model_filename)
  curl::curl_download(url = url, destfile = model_path)
  if (check_md5) {
    file_md5 = tools::md5sum(model_path)
    stopifnot(file_md5 == model_md5)
  }
  return(model_path)
}

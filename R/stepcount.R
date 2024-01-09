
#' Run Stepcount Model on Data
#'
#' @param file
#' @param model_type
#' @param model_path
#' @param pytorch_device
#' @param verbose
#'
#' @return
#' @export
#'
#' @examples
#' file = system.file("extdata/P30_wrist100.csv.gz", package = "stepcount")
#' if (have_stepcount() && have_stepcount_condaenv()) {
#'   out = stepcount(file = file)
#' }
stepcount = function(
    file,
    model_type = c("ssl", "rf"),
    model_path = NULL,
    pytorch_device = c("cpu", "cuda:0"),
    verbose = TRUE
) {

  model_type = match.arg(model_type, choices = c("ssl", "rf"))
  pytorch_device = match.arg(pytorch_device, choices = c("cpu", "cuda:0"))

  resample_hz = switch(model_type,
                       ssl = 30L,
                       rf = NULL,
                       NULL)
  out = sc_read(file = file,
                resample_hz = resample_hz,
                verbose = verbose,
                keep_pandas = TRUE)
  data = out$data
  info = out$info

  model = sc_load_model(
    model_path = model_path,
    model_type = model_type,
    check_md5 = TRUE,
    force_download = FALSE,
    as_python = TRUE)

  # Run model
  if (verbose) {
    message("Loading model...")
  }
  # TODO: implement reset_sample_rate()
  model$sample_rate = info[['ResampleRate']]
  model$window_len = as.integer(
    ceiling(info[['ResampleRate']] * reticulate::py_to_r(model$window_sec))
  )
  model$wd$sample_rate = info[['ResampleRate']]
  model$verbose = verbose
  model$wd$verbose = verbose

  model$wd$device = pytorch_device

  if (verbose) {
    message("Running step counter...")
  }
  result = model$predict_from_frame(data = data)
  sc = stepcount_base()
  summary = sc$summarize(out, reticulate::py_to_r(model$steptol))
  result = reticulate::py_to_r(result)
  result = data.frame(
    time = names(result),
    steps = unname(c(result))
  )
  result$time = lubridate::ymd_hms(result$time)
  result$time = lubridate::floor_date(result$time, unit = "1 second")
  return(result)
}


#' Run Stepcount Model on Data
#'
#' @param file accelerometry file to process, including CSV,
#' CWA, GT3X, and `GENEActiv` bin files
#' @param pytorch_device device to use for prediction for PyTorch.
#' @param verbose print diagnostic messages
#' @param sample_rate the sample rate of the data.  Set to `NULL`
#' for `stepcount` to try to guess this
#'
#' @return A list of the results (`data.frame`),
#' summary of the results, adjusted summary of the results, and
#' information about the data.
#' @export
#'
#' @inheritParams sc_load_model
#' @examples
#' file = system.file("extdata/P30_wrist100.csv.gz", package = "stepcount")
#' df = readr::read_csv(file)
#' if (stepcount_check()) {
#'   out = stepcount(file = file)
#'   out_df = stepcount(file = df)
#' }
stepcount = function(
    file,
    sample_rate = NULL,
    model_type = c("ssl", "rf"),
    model_path = NULL,
    pytorch_device = c("cpu", "cuda:0"),
    verbose = TRUE
) {

  if (!stepcount_check()) {
    warning(
      paste0(
        "stepcount_check() indicates the stepcount functions may not be ",
        " available, may need to run stepcount::use_stepcount_condaenv()")
    )
  }
  model_type = match.arg(model_type, choices = c("ssl", "rf"))
  pytorch_device = match.arg(pytorch_device, choices = c("cpu", "cuda:0"))

  if (is.data.frame(file)) {
    file = sc_rename_data(file)
    tfile = tempfile(fileext = ".csv")
    opts = options()
    on.exit(options(opts), add = TRUE)
    options(digits.secs = 3)
    file$time = format(file$time, "%Y-%m-%d %H:%M:%OS3")
    readr::write_csv(x = file, file = tfile, progress = FALSE)
    on.exit({
      file.remove(tfile)
    }, add = TRUE)
    file = tfile
  }
  resample_hz = switch(model_type,
                       ssl = 30L,
                       rf = NULL,
                       NULL)
  out = sc_read(file = file,
                resample_hz = resample_hz,
                sample_rate = sample_rate,
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
  names(result) = c("Y", "W", "T_steps")
  W = reticulate::py_to_r(result$W)
  T_steps = reticulate::py_to_r(result$T_steps)
  result = result$Y

  sc = stepcount_base()
  summary = sc$summarize(result, reticulate::py_to_r(model$steptol),
                         adjust_estimates = FALSE)
  summary_adj = sc$summarize(result, reticulate::py_to_r(model$steptol),
                             adjust_estimates = TRUE)
  result = reticulate::py_to_r(result)
  result = data.frame(
    time = names(result),
    steps = unname(c(result))
  )
  result$time = lubridate::ymd_hms(result$time)
  result$time = lubridate::floor_date(result$time, unit = "1 second")
  out = list(
    steps = result,
    walking = W,
    step_times = T_steps,
    summary = summary,
    summary_adjusted = summary_adj,
    info = info
  )
  return(out)
}

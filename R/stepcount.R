
convert_to_df = function(x, colname = "steps") {
  x = data.frame(
    time = names(x),
    steps = unname(c(x))
  )
  if (is.character(x$time)) {
    na_x = is.na(x$time) | x$time %in% ""
    new_x = lubridate::ymd_hms(x$time)
    na_new_x = is.na(new_x)
    if (any(na_new_x & !na_x)) {
      warning("Coercion of time to POSIXct induced NAs, keeping character")
    } else {
      x$time = new_x
    }
    rm(list = c("na_x", "new_x", "na_new_x"))
  }
  colnames(x)[2] = colname
  x
}


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
#'   st = out$step_times
#'   if (requireNamespace("ggplot2", quietly = TRUE) &&
#'       requireNamespace("tidyr", quietly = TRUE) &&
#'       requireNamespace("dplyr", quietly = TRUE)) {
#'     dat = df[10000:12000,] %>%
#'       dplyr::select(-annotation) %>%
#'       tidyr::gather(axis, value, -time)
#'     st = st %>%
#'       dplyr::mutate(time = lubridate::as_datetime(time)) %>%
#'       dplyr::as_tibble()
#'     st = st %>%
#'       dplyr::filter(time >= min(dat$time) & time <= max(dat$time))
#'     dat %>%
#'       ggplot2::ggplot(ggplot2::aes(x = time, y = value, colour = axis)) +
#'       ggplot2::geom_line() +
#'       ggplot2::geom_vline(data = st, ggplot2::aes(xintercept = time))
#'   }
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
    tfile = tempfile(fileext = ".csv")
    file = sc_write_csv(data = file, path = tfile)
    on.exit({
      file.remove(tfile)
    }, add = TRUE)
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
  W = convert_to_df(reticulate::py_to_r(result[[1]]), colname = "walking")
  if (length(result) > 2) {
    T_steps = try({
      reticulate::py_to_r(result[[2]])
    })
    if (!inherits(T_steps, "try-error")) {
      T_steps = unname(c(T_steps))
      T_steps = format(T_steps, format = "%Y-%m-%d %H:%M:%OS4")
      T_steps = data.frame(time = T_steps)
    } else {
      T_steps = NULL
    }
  } else {
    T_steps = NULL
  }

  result = result[[0]]

  sc = stepcount_base()
  summary = sc$summarize(result, reticulate::py_to_r(model$steptol),
                         adjust_estimates = FALSE)
  summary_adj = sc$summarize(result, reticulate::py_to_r(model$steptol),
                             adjust_estimates = TRUE)
  result = reticulate::py_to_r(result)
  result = convert_to_df(result)

  # result$time = lubridate::ymd_hms(result$time)
  result$time = lubridate::floor_date(result$time, unit = "1 second")
  out = list(
    steps = result,
    walking = W,
    processed_data = data,
    step_times = T_steps,
    summary = summary,
    summary_adjusted = summary_adj,
    info = info
  )
  return(out)
}

stepcount_base = function() {
  sc = reticulate::import("stepcount")
  stepcount = try({sc$stepcount})
  if (inherits(stepcount, "try-error")) {
    rlang::inform(
      paste(capture.output(print(reticulate::py_last_error())), collapse = "\n"),
      .frequency = "once",
      .frequency_id = "stepcount_base_import_error"
    )
    stepcount = reticulate::import("stepcount.stepcount")
  }
  stepcount
}


stepcount_base_noconvert = function() {
  sc = reticulate::import("stepcount", convert = FALSE)
  stepcount = try({sc$stepcount})
  if (inherits(stepcount, "try-error")) {
    rlang::inform(
      paste(capture.output(print(reticulate::py_last_error())), collapse = "\n"),
      .frequency = "once",
      .frequency_id = "stepcount_base_noconvert_import_error"
    )
    stepcount = reticulate::import("stepcount.stepcount", convert = FALSE)
  }
  stepcount
}

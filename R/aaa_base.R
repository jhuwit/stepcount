stepcount_base = function() {
  sc = reticulate::import("stepcount")
  stepcount = try({sc$stepcount})
  if (inherits(stepcount, "try-error")) {
    stepcount = reticulate::import("stepcount.stepcount")
  }
  stepcount
}


stepcount_base_noconvert = function() {
  sc = reticulate::import("stepcount", convert = FALSE)
  stepcount = try({sc$stepcount})
  if (inherits(stepcount, "try-error")) {
    stepcount = reticulate::import("stepcount.stepcount", convert = FALSE)
  }
  stepcount
}

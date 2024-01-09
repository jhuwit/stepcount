stepcount_base = function() {
  sc = reticulate::import("stepcount")
  stepcount = sc$stepcount
  stepcount
}


stepcount_base_noconvert = function() {
  sc = reticulate::import("stepcount", convert = FALSE)
  stepcount = sc$stepcount
  stepcount
}

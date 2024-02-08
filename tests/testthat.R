# This file is part of the standard setup for testthat.
# It is recommended that you do not modify it.
#
# Where should you do additional test configuration?
# Learn more about the roles of various files in:
# * https://r-pkgs.org/testing-design.html#sec-tests-files-overview
# * https://testthat.r-lib.org/articles/special-files.html


library(testthat)
library(stepcount)

if (stepcount::have_stepcount_condaenv()) {
  stepcount::unset_reticulate_python()
  stepcount::use_stepcount_condaenv()
}

testthat::test_check("stepcount")

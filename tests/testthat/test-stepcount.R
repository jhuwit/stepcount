remove_file_info = function(result) {
  result$info$Filename = result$info$`Filesize(MB)` = NULL
  result
}
testthat::test_that("stepcount ssl works", {
  file = system.file("extdata/P30_wrist100.csv.gz", package = "stepcount")
  testthat::skip_if_not(stepcount_check())
  if (stepcount_check()) {
    model_type = "ssl"
    model_path = sc_model_filename(model_type = model_type)
    model_path = file.path(tempdir(), model_path)
    stepcount::sc_download_model(model_path = model_path, model_type = model_type)
    res = stepcount(file = file, model_type = model_type, model_path = model_path)
    res = remove_file_info(res)
    testthat::expect_true(is.list(res))
    testthat::expect_true(all(c("steps", "walking") %in% names(res)))
    testthat::expect_named(res$steps, c("time", "steps"))
    testthat::expect_named(res$walking, c("time", "walking"))

    model = sc_load_model(model_type = model_type, model_path = model_path,
                          as_python = TRUE)
    res_model = stepcount_with_model(file = file, model_type = model_type,
                                     model = model)
    res_model = remove_file_info(res_model)
    # need to do this way because of pointers
    testthat::expect_true(isTRUE(all.equal(res, res_model)))

    df = readr::read_csv(file)
    res_model_df = stepcount_with_model(file = df, model_type = model_type,
                                        model = model)
    res_model_df = remove_file_info(res_model_df)

    # need to do this way because of pointers
    testthat::expect_true(isTRUE(all.equal(res_model_df, res_model)))

  }
})


testthat::test_that("stepcount rf works", {
  file = system.file("extdata/P30_wrist100.csv.gz", package = "stepcount")
  testthat::skip_if_not(stepcount_check())
  if (stepcount_check()) {
    model_type = "rf"
    model_path = sc_model_filename(model_type = model_type)
    model_path = file.path(tempdir(), model_path)
    stepcount::sc_download_model(model_path = model_path, model_type = model_type)
    res = stepcount(file = file, model_type = model_type, model_path = model_path)
    res = remove_file_info(res)

    testthat::expect_true(is.list(res))
    testthat::expect_true(all(c("steps", "walking") %in% names(res)))
    testthat::expect_named(res$steps, c("time", "steps"))
    testthat::expect_named(res$walking, c("time", "walking"))

    model = sc_load_model(model_type = model_type, model_path = model_path,
                          as_python = TRUE)
    res_model = stepcount_with_model(file = file, model_type = model_type,
                                     model = model)
    res_model = remove_file_info(res_model)

    # need to do this way because of pointers
    testthat::expect_true(isTRUE(all.equal(res, res_model)))

    df = readr::read_csv(file)
    res_model_df = stepcount_with_model(file = df, model_type = model_type,
                                        model = model)
    res_model_df = remove_file_info(res_model_df)
    # need to do this way because of pointers
    testthat::expect_true(isTRUE(all.equal(res_model_df, res_model)))
  }
})

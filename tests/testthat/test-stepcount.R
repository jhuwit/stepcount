remove_file_info = function(result) {
  result$info$Filename = result$info$`Filesize(MB)` = NULL
  result
}

testthat::test_that("model helpers map model types and paths", {
  testthat::expect_equal(stepcount:::sc_model_version("ssl"), "ssl-20230208")
  testthat::expect_equal(stepcount:::sc_model_version("rf"), "20230713")
  testthat::expect_equal(stepcount::sc_model_filename("ssl"),
                         "ssl-20230208.joblib.lzma")
  testthat::expect_equal(stepcount::sc_model_filename("rf"),
                         "20230713.joblib.lzma")
  testthat::expect_equal(
    stepcount::sc_model_params("rf", "cpu"),
    list(model_type = "rf", resample_hz = NULL, pytorch_device = "cpu")
  )
  testthat::expect_equal(
    stepcount::sc_model_params("ssl", "cuda:0"),
    list(model_type = "ssl", resample_hz = 30L, pytorch_device = "cuda:0")
  )
  testthat::expect_error(stepcount::sc_model_params("bad", "cpu"))
})

testthat::test_that("python availability checks can be exercised without python", {
  testthat::local_mocked_bindings(
    py_module_available = function(module) {
      identical(module, "stepcount")
    },
    py_list_packages = function() {
      data.frame(package = "stepcount", version = "3.11.2")
    },
    .package = "reticulate"
  )
  testthat::expect_true(have_stepcount())
  testthat::expect_true(stepcount_check())
  testthat::expect_equal(stepcount_version(), "3.11.2")
})

testthat::test_that("stepcount_check is false when the installed version is too old", {
  testthat::local_mocked_bindings(
    py_module_available = function(module) {
      identical(module, "stepcount")
    },
    py_list_packages = function() {
      data.frame(package = "stepcount", version = "3.10.9")
    },
    .package = "reticulate"
  )
  testthat::expect_false(stepcount_check())
})

testthat::test_that("sc_rename_data and sc_write_csv normalise headers and timestamps", {
  data = data.frame(
    TIME = as.POSIXct(c("2020-01-01 00:00:00", "2020-01-01 00:00:01"),
                      tz = "UTC"),
    X = 1:2,
    Y = 3:4,
    Z = 5:6
  )
  out = sc_rename_data(data)
  testthat::expect_equal(names(out), c("time", "x", "y", "z"))
  testthat::expect_true(inherits(out$time, "POSIXct"))

  data2 = data
  names(data2)[1] = "HEADER_TIME_STAMP"
  out2 = sc_rename_data(data2)
  testthat::expect_equal(names(out2), c("time", "x", "y", "z"))

  path = tempfile(fileext = ".csv")
  returned = sc_write_csv(data = data, path = path)
  testthat::expect_equal(returned, path)
  lines = readLines(path, warn = FALSE)
  testthat::expect_match(lines[2], "^2020-01-01 00:00:00\\.000,1,3,5$")
})

testthat::test_that("convert_to_df handles coercion and warning paths", {
  good = c("2020-01-01 00:00:00" = 1, "2020-01-01 00:00:01" = 2)
  out = stepcount:::convert_to_df(good, colname = "walking", tz = "UTC")
  testthat::expect_equal(names(out), c("time", "walking"))
  testthat::expect_true(inherits(out$time, "POSIXct"))

  bad = c("2020-01-01 00:00:00" = 1, "not-a-time" = 0)
  testthat::local_mocked_bindings(
    ymd_hms = function(x, tz) {
      as.POSIXct(c("2020-01-01 00:00:00", NA), tz = tz)
    },
    .package = "lubridate"
  )
  testthat::expect_warning(
    out_bad <- stepcount:::convert_to_df(bad, colname = "walking", tz = "UTC"),
    "Coercion of time to POSIXct induced NAs"
  )
  testthat::expect_type(out_bad$time, "character")
})

testthat::test_that("transform_data_to_files handles file lists", {
  f1 = tempfile(fileext = ".csv")
  f2 = tempfile(fileext = ".csv")
  writeLines("a,b", f1)
  writeLines("a,b", f2)

  files = stepcount:::transform_data_to_files(list(f1, f2), verbose = FALSE)
  testthat::expect_length(files, 2)
  testthat::expect_true(all(file.exists(unlist(files))))
})

testthat::test_that("sc_download_model can be tested without network access", {
  path = tempfile(fileext = ".joblib.lzma")
  testthat::local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      writeLines("payload", destfile)
      invisible(destfile)
    },
    .package = "curl"
  )
  testthat::local_mocked_bindings(
    md5sum = function(files) {
      stats::setNames(rep("abc123", length(files)), files)
    },
    .package = "tools"
  )
  testthat::local_mocked_bindings(
    sc_model_md5 = function(model_type) {
      "abc123"
    },
    .package = "stepcount"
  )

  out = sc_download_model(model_path = path, model_type = "rf", check_md5 = TRUE)
  testthat::expect_equal(out, path)
  testthat::expect_true(file.exists(path))
})

testthat::test_that("sc_read works with mocked stepcount readers", {
  file = tempfile(fileext = ".csv")
  writeLines("x", file)

  testthat::local_mocked_bindings(
    stepcount_base = function() {
      list(read = function(filepath, resample_hz, sample_rate, verbose) {
        list(
          data = data.frame(time = 1:2, x = 3:4),
          info = list(ResampleRate = 100L, Filename = filepath, `Filesize(MB)` = 1)
        )
      })
    },
    .package = "stepcount"
  )

  out = sc_read(file = file, verbose = FALSE)
  testthat::expect_equal(names(out), c("data", "info"))
  testthat::expect_s3_class(out$data, "data.frame")
  testthat::expect_equal(out$info$ResampleRate, 100L)
})

testthat::test_that("sc_read falls back to utils$read when needed", {
  file = tempfile(fileext = ".csv")
  writeLines("x", file)

  testthat::local_mocked_bindings(
    stepcount_base = function() {
      list(utils = list(read = function(filepath, resample_hz, sample_rate, verbose) {
        list(
          data = data.frame(time = 1:1, x = 2),
          info = list(ResampleRate = 25L, Filename = filepath, `Filesize(MB)` = 1)
        )
      }))
    },
    .package = "stepcount"
  )

  out = sc_read(file = file, verbose = FALSE)
  testthat::expect_equal(out$info$ResampleRate, 25L)
})

testthat::test_that("sc_load_model selects the appropriate python bridge", {
  fake_model = list(load_model = function(model_path, model_type, check_md5,
                                         force_download) {
    list(
      model_path = model_path,
      model_type = model_type,
      check_md5 = check_md5,
      force_download = force_download
    )
  })

  testthat::local_mocked_bindings(
    stepcount_base = function() fake_model,
    stepcount_base_noconvert = function() fake_model,
    .package = "stepcount"
  )

  path = tempfile(fileext = ".joblib.lzma")
  out = sc_load_model(
    model_type = "ssl",
    model_path = path,
    check_md5 = FALSE,
    force_download = TRUE,
    as_python = FALSE
  )
  testthat::expect_equal(out$model_path, path)
  testthat::expect_equal(out$model_type, "ssl")
  testthat::expect_false(out$check_md5)
  testthat::expect_true(out$force_download)

  out2 = sc_load_model(
    model_type = "rf",
    model_path = path,
    check_md5 = TRUE,
    force_download = FALSE,
    as_python = TRUE
  )
  testthat::expect_equal(out2$model_type, "rf")
  testthat::expect_true(out2$check_md5)
  testthat::expect_false(out2$force_download)
})

testthat::test_that("stepcount_with_model processes mocked results quickly", {
  file = data.frame(
    TIME = as.POSIXct(c("2020-01-01 00:00:00", "2020-01-01 00:00:01"),
                      tz = "UTC"),
    X = 1:2,
    Y = 3:4,
    Z = 5:6
  )
  fake_result = new_fake_py_tuple(list(
    list("2020-01-01 00:00:00" = 1, "2020-01-01 00:00:01" = 0),
    list("2020-01-01 00:00:00" = 1, "2020-01-01 00:00:01" = 0),
    as.POSIXct(c("2020-01-01 00:00:00", "2020-01-01 00:00:01"), tz = "UTC")
  ))
  fake_model = list(
    window_sec = 1.5,
    wd = list(verbose = NULL, device = NULL, sample_rate = NULL),
    predict_from_frame = function(data) {
      fake_result
    }
  )

  testthat::local_mocked_bindings(
    stepcount_check = function() TRUE,
    sc_read = function(file, resample_hz, sample_rate, verbose, keep_pandas) {
      testthat::expect_true(keep_pandas)
      list(
        data = data.frame(time = 1:2, x = 3:4),
        info = list(ResampleRate = 100L, Filename = "fake", `Filesize(MB)` = 1)
      )
    },
    stepcount_base = function() {
      list(read = function(...) NULL)
    },
    process_stepcount_result = function(result, model, tz = "UTC") {
      list(
        steps = data.frame(time = as.POSIXct(c("2020-01-01 00:00:00",
                                              "2020-01-01 00:00:01"), tz = tz),
                           steps = c(1, 0)),
        walking = data.frame(time = as.POSIXct(c("2020-01-01 00:00:00",
                                                 "2020-01-01 00:00:01"), tz = tz),
                             walking = c(1, 0)),
        step_times = NULL
      )
    },
    .package = "stepcount"
  )

  out = stepcount_with_model(
    file = file,
    model_type = "ssl",
    model = fake_model,
    verbose = FALSE,
    keep_data = TRUE
  )

  testthat::expect_equal(names(out), c("steps", "walking", "step_times", "info", "processed_data"))
  testthat::expect_true(inherits(out$steps$time, "POSIXct"))
  testthat::expect_true(inherits(out$walking$time, "POSIXct"))
  testthat::expect_true("processed_data" %in% names(out))
})

testthat::test_that("stepcount warns when the Python module is unavailable", {
  fake_out = list(steps = data.frame(), walking = data.frame())
  testthat::local_mocked_bindings(
    stepcount_check = function() FALSE,
    sc_load_model = function(model_path, model_type, check_md5, force_download, as_python) {
      list(wd = list(), window_sec = 1, predict_from_frame = function(...) NULL)
    },
    stepcount_with_model = function(...) fake_out,
    .package = "stepcount"
  )

  file = tempfile(fileext = ".csv")
  writeLines("x", file)
  testthat::expect_warning(
    out <- stepcount(file = file, model_type = "ssl", verbose = FALSE),
    "stepcount_check\\(\\)"
  )
  testthat::expect_equal(out, fake_out)
})

fmt = function(x, digits) format(x, paste0("%Y-%m-%d %H:%M:%OS", digits))
zones = c("UTC", "Europe/London", "America/New_York", "Australia/Lord_Howe",
          "Asia/Kathmandu", "Asia/Kolkata", "America/St_Johns",
          "Pacific/Chatham", "Africa/Abidjan", "")

# neighbouring doubles: one unit in the last place above and below
nextafter_up = function(x) x + pmax(abs(x), 1) * .Machine$double.eps
nextafter_down = function(x) x - pmax(abs(x), 1) * .Machine$double.eps

expect_same_format = function(x, digits = 0:6) {
  for (d in digits) {
    testthat::expect_identical(format_time_fast(x, digits = d), fmt(x, d),
                               info = paste("digits =", d))
  }
}

testthat::test_that("format_time_fast matches format for random times", {
  set.seed(20261022)
  # 1900 to 2100, with fractions at full double precision
  secs = runif(20000, -2208988800, 4102444800)
  for (tz in zones) {
    expect_same_format(.POSIXct(secs, tz = tz))
  }
})

testthat::test_that("format_time_fast matches format at fraction boundaries", {
  base = c(0, 1511172000, 1700000000, -86400 * 365.25 * 30)
  steps = c(0:9, 10^(1:6) - 1) / 1e6
  fractions = unique(c(steps, 1 - 1e-12, 1 - 1e-15, 0.5, 1 / 3, 2 / 3))
  values = as.vector(outer(base, fractions, "+"))
  # a few ULPs either side of each value
  values = unique(c(values, values * (1 + 1e-16), values * (1 - 1e-16),
                    nextafter_down(values), nextafter_up(values)))
  for (tz in c("UTC", "Europe/London", "Asia/Kathmandu")) {
    expect_same_format(.POSIXct(values, tz = tz))
  }
})

testthat::test_that("format_time_fast matches format for device sampling rates", {
  for (rate in c(30, 85.7, 100, 25, 1 / 3)) {
    t0 = 1511172000 + 0.5
    x = .POSIXct(t0 + (0:20000) / rate, tz = "Europe/London")
    expect_same_format(x, digits = c(3, 6))
  }
})

testthat::test_that("format_time_fast matches format across daylight saving", {
  transitions = list(
    "Europe/London" = c("2023-03-26 00:30:00", "2023-10-29 00:30:00"),
    "America/New_York" = c("2023-03-12 06:30:00", "2023-11-05 05:30:00"),
    "Australia/Lord_Howe" = c("2023-04-01 14:30:00", "2023-09-30 15:00:00")
  )
  for (tz in names(transitions)) {
    for (start in transitions[[tz]]) {
      t0 = as.numeric(as.POSIXct(start, tz = "UTC"))
      x = .POSIXct(t0 + seq(0, 2 * 3600, by = 0.37), tz = tz)
      expect_same_format(x, digits = c(0, 3, 6))
    }
  }
})

testthat::test_that("format_time_fast handles missing and special values", {
  x = .POSIXct(c(1511172000.123, NA, NaN, Inf, -Inf, 0.0005), tz = "UTC")
  expect_same_format(x)
  expect_same_format(.POSIXct(numeric(0), tz = "UTC"))
  expect_same_format(.POSIXct(NA_real_, tz = "UTC"))
  expect_same_format(.POSIXct(1511172000.999999, tz = "UTC"))
  # unsorted and duplicated times
  x = .POSIXct(c(5.5, 1.25, 5.5, 3, 1.25, 1e9 + 0.1), tz = "America/New_York")
  expect_same_format(x)
  # times before 1970
  expect_same_format(.POSIXct(c(-0.5, -1 / 30, -0.0001, -1e9 - 0.3), tz = "UTC"))
})

testthat::test_that("format_time_fast keeps the tzone attribute behaviour", {
  x = .POSIXct(1511172000 + (0:100) / 30)
  attr(x, "tzone") = NULL
  expect_same_format(x, digits = 3)
  attr(x, "tzone") = ""
  expect_same_format(x, digits = 3)
  old_tz = Sys.getenv("TZ", unset = NA)
  Sys.setenv(TZ = "Asia/Kolkata")
  on.exit(if (is.na(old_tz)) Sys.unsetenv("TZ") else Sys.setenv(TZ = old_tz),
          add = TRUE)
  expect_same_format(x, digits = 3)
})

testthat::test_that("format_time_fast falls back to format for other input", {
  testthat::expect_identical(format_time_fast(as.Date("2020-01-01"), 3),
                             fmt(as.Date("2020-01-01"), 3))
  lt = as.POSIXlt(.POSIXct(1511172000.123, tz = "UTC"))
  testthat::expect_identical(format_time_fast(lt, 3), fmt(lt, 3))
  x = .POSIXct(1511172000.12345678, tz = "UTC")
  # more than 6 digits is printed as 6 by format()
  testthat::expect_identical(format_time_fast(x, 9), fmt(x, 9))
})

# the previous implementation of sc_write_csv()
sc_write_csv_reference = function(data, path) {
  data = sc_rename_data(data = data)
  opts = options()
  on.exit(options(opts), add = TRUE)
  options(digits.secs = 3)
  data$time = format(data$time, "%Y-%m-%d %H:%M:%OS3")
  readr::write_csv(x = data, file = path, progress = FALSE)
  path
}

testthat::test_that("sc_write_csv writes the same file in any number of chunks", {
  set.seed(1)
  n = 2503
  data = data.frame(
    HEADER_TIMESTAMP = .POSIXct(1511172000 + (0:(n - 1)) / 30, tz = "Europe/London"),
    X = rnorm(n), Y = round(rnorm(n), 3), Z = c(NA, rnorm(n - 1)),
    temperature = 20
  )
  expected = sc_write_csv_reference(data, tempfile(fileext = ".csv"))
  for (chunk_size in c(1, 7, 1000, 2503, 1e6)) {
    out = sc_write_csv(data, path = tempfile(fileext = ".csv"),
                       chunk_size = chunk_size)
    testthat::expect_identical(unname(tools::md5sum(out)),
                               unname(tools::md5sum(expected)),
                               info = paste("chunk_size =", chunk_size))
  }
  for (rows in list(integer(0), 1L, 1:2)) {
    small = data[rows, , drop = FALSE]
    expected = sc_write_csv_reference(small, tempfile(fileext = ".csv"))
    out = sc_write_csv(small, path = tempfile(fileext = ".csv"), chunk_size = 1)
    testthat::expect_identical(readLines(out), readLines(expected))
  }
})

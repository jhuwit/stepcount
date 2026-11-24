# Format POSIXct times as format(x, "%Y-%m-%d %H:%M:%OS<digits>") does, but
# faster and with much less memory for long, densely sampled recordings.
#
# format() converts every time to POSIXlt (11 components per element) before
# formatting it.  Here only the unique whole seconds are formatted with
# format(), which handles the time zone and daylight saving time, and the
# seconds and fraction of each time are built from lookup tables.  The
# fraction follows R's own rules (src/main/datetime.c):
#   * as.POSIXlt() stores sec = tm_sec + (d - floor(d))
#   * format() with %OSn truncates, s = (int)(sec * 10^n) / 10^n, and prints
#     it with "%0*.*f" (width n + 3, n decimals); %OS0 prints %S
# so the result is identical to format(), including when the addition rounds
# sec up to the next whole second (printed as 60 within the same minute).
format_time_fast = function(x, digits = 3L) {
  if (!inherits(x, "POSIXct") || !is.numeric(digits) || length(digits) != 1L ||
      is.na(digits) || digits < 0 || digits != floor(digits)) {
    return(format(x, paste0("%Y-%m-%d %H:%M:%OS", digits)))
  }
  digits = min(as.integer(digits), 6L)
  out = rep(NA_character_, length(x))
  d = as.numeric(x)
  ok = which(is.finite(d))
  # NaN and infinite times are printed by format() as "NaN", "Inf", "-Inf"
  other = which(!is.finite(d) & !is.na(d) | is.nan(d))
  if (length(other)) {
    out[other] = format(x[other], paste0("%Y-%m-%d %H:%M:%OS", digits))
  }
  if (!length(ok)) {
    return(out)
  }
  d = d[ok]
  whole = floor(d)
  unique_whole = unique(whole)
  index = match(whole, unique_whole)
  times = .POSIXct(unique_whole, tz = attr(x, "tzone"))
  prefix = format(times, "%Y-%m-%d %H:%M:")
  tm_sec = as.POSIXlt(times)$sec
  rm(times, unique_whole)
  # the seconds field of as.POSIXlt(x)
  sec = tm_sec[index] + (d - whole)
  rm(d, whole)
  scale = 10^digits
  if (digits > 0L) {
    # (int) (sec * 10^digits), as in format.POSIXlt()
    k = trunc(sec * scale)
  } else {
    k = floor(sec)
  }
  rm(sec)
  seconds = k %/% scale
  seconds_table = sprintf("%02d", 0:61)
  if (digits > 0L) {
    fraction = k - seconds * scale
    fraction_table = paste0(".", formatC(seq_len(scale) - 1L, width = digits,
                                         flag = "0", format = "d"))
    out[ok] = paste0(prefix[index], seconds_table[seconds + 1L],
                     fraction_table[fraction + 1L])
  } else {
    out[ok] = paste0(prefix[index], seconds_table[seconds + 1L])
  }
  out
}

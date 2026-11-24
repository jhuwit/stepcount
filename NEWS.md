# stepcount 0.7.1

* Loading the package no longer calls `py_require_stepcount()` in
  `.onLoad`. The `stepcount` Python requirement is now declared the first
  time a function needs Python (`have_stepcount()`, `stepcount()`,
  `sc_read()`, `sc_load_model()`, ...), as long as Python has not been
  initialized yet. Loading the namespace, e.g. during `R CMD check` of a
  package that Suggests 'stepcount', no longer changes the Python
  requirements of the R session. If you start Python yourself before
  calling 'stepcount', call `py_require_stepcount()` first.

# stepcount 0.7.0

* `sc_write_csv()` formats times about five times faster with much less
  memory, and writes the CSV in chunks (`chunk_size`, default 1e6 rows), so
  writing a data frame for `stepcount()` no longer needs a full character
  copy of every time. The file written is identical to before.

# stepcount 0.6.0

* Added additional check for `have_stepcount`.
* Added `epoch` argument to `stepcount`, so you can do 30-seconds.

# stepcount 0.5.0

* Added in `rlang` for printing out errors.
* CRAN submission.

# stepcount 0.4.1

* Fixing README and more `gc()` functions to try to reduce memory usage.


# stepcount 0.3.2

* Initial CRAN submission.
* Updated to work with newer version of `stepcount`. 

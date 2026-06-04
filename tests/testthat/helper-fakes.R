new_fake_py_tuple = function(items) {
  structure(list(items = items), class = "fake_py_tuple")
}

length.fake_py_tuple = function(x) {
  length(x$items)
}

`[[.fake_py_tuple` = function(x, i, ...) {
  x$items[[i + 1L]]
}

`[.fake_py_tuple` = function(x, i, ...) {
  x$items[[i + 1L]]
}

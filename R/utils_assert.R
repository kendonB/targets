assert_callr_function <- function(callr_function) {
  if (!is.null(callr_function)) {
    assert_function(
      callr_function,
      "callr_function must be a function or NULL."
    )
  }
}

assert_chr <- function(x, msg = NULL) {
  if (!is.character(x)) {
    throw_validate(msg %||% "x must be a character.")
  }
}

assert_chr_no_delim <- function(x, msg = NULL) {
  assert_chr(x)
  if (any(grepl("|", x, fixed = TRUE) | grepl("*", x, fixed = TRUE))) {
    throw_validate(msg %||% "x must not contain | or *")
  }
}

assert_dbl <- function(x, msg = NULL) {
  if (!is.numeric(x)) {
    throw_validate(msg %||% "x must be numeric.")
  }
}

assert_df <- function(x, msg = NULL) {
  if (!is.data.frame(x)) {
    throw_validate(msg %||% "x must be a data frame.")
  }
}

assert_envir <- function(x, msg = NULL) {
  if (!is.environment(x)) {
    throw_validate(msg %||% "x must be an environment")
  }
}

assert_expr <- function(x, msg = NULL) {
  if (!is.expression(x)) {
    throw_validate(msg %||% "x must be an expression.")
  }
}

assert_correct_fields <- function(object, constructor) {
  assert_identical_chr(sort(names(object)), sort(names(formals(constructor))))
}

assert_function <- function(x, msg = NULL) {
  if (!is.function(x)) {
    throw_validate(msg %||% "x must be a function.")
  }
}

assert_ge <- function(x, threshold, msg = NULL) {
  if (any(x < threshold)) {
    throw_validate(msg %||% paste("x is less than", threshold))
  }
}

assert_identical <- function(x, y, msg = NULL) {
  if (!identical(x, y)) {
    throw_validate(msg %||% "x and y are not identical.")
  }
}

assert_identical_chr <- function(x, y, msg = NULL) {
  if (!identical(x, y)) {
    msg_x <- paste0(deparse(x), collapse = "")
    msg_y <- paste0(deparse(y), collapse = "")
    throw_validate(msg %||% paste(msg_x, " and ", msg_y, " not identical."))
  }
}

assert_in <- function(x, choices, msg = NULL) {
  if (!all(x %in% choices)) {
    throw_validate(msg %||% paste(deparse(x), " is not in ", deparse(choices)))
  }
}

assert_int <- function(x, msg = NULL) {
  if (!is.integer(x)) {
    throw_validate(msg %||% "x must be an integer vector.")
  }
}

assert_le <- function(x, threshold, msg = NULL) {
  if (any(x > threshold)) {
    throw_validate(msg %||% paste("x is greater than", threshold))
  }
}

assert_list <- function(x, msg = NULL) {
  if (!is.list(x)) {
    throw_validate(msg %||% "x must be a list.")
  }
}

assert_lgl <- function(x, msg = NULL) {
  if (!is.logical(x)) {
    throw_validate(msg %||% "x must be logical.")
  }
}

assert_name <- function(name) {
  assert_chr(name)
  assert_scalar(name)
  if (!nzchar(name)) {
    throw_validate("name must be a nonempty string.")
  }
  if (name != make.names(name)) {
    throw_validate(name, " is not a valid symbol name.")
  }
  if (grepl("\\.$", name)) {
    throw_validate(name, " ends with a dot.")
  }
}

assert_nonempty <- function(x, msg = NULL) {
  if (!length(x)) {
    throw_validate(msg %||% "x must not be empty")
  }
}

assert_nonmissing <- function(x, msg = NULL) {
  if (anyNA(x)) {
    throw_validate(msg %||% "x must have no missing values (NA's)")
  }
}

assert_package <- function(package, msg = NULL) {
  if (!requireNamespace(package, quietly = TRUE)) {
    throw_validate(msg %||% paste("package ", package, " not installed"))
  }
}

assert_path <- function(path, msg = NULL) {
  missing <- !file.exists(path)
  if (any(missing)) {
    throw_validate(
      msg %||% paste(
        "missing files: ",
        paste(path[missing], collapse = ", ")
      )
    )
  }
}

assert_match <- function(x, pattern, msg = NULL) {
  if (!grepl(pattern = pattern, x = x)) {
    throw_validate(msg %||% paste(x, " does not match pattern ", pattern))
  }
}

assert_positive <- function(x, msg = NULL) {
  if (any(x <= 0)) {
    throw_validate(msg %||% paste(x, " is not all positive."))
  }
}

assert_scalar <- function(x, msg = NULL) {
  if (length(x) != 1) {
    throw_validate(msg %||% "x must have length 1.")
  }
}

assert_store <- function() {
  assert_path(
    "_targets",
    paste(
      "utility functions like tar_delete() require a _targets/",
      "data store produced by tar_make() or similar in the",
      "current working directory."
    )
  )
}

assert_target_script <- function() {
  assert_path(
    "_targets.R",
    paste(
      "main functions like tar_make() require a special _targets.R script",
      "in the current working directory to define the pipeline.",
      "The tar_script() function is a convenient way to produce one."
    )
  )
}

assert_true <- function(condition, msg = NULL) {
  if (!condition) {
    throw_validate(msg %||% "condition does not evaluate not TRUE")
  }
}

assert_unique <- function(x, msg = NULL) {
  if (anyDuplicated(x)) {
    dups <- paste(unique(x[duplicated(x)]), collapse = ", ")
    throw_validate(paste(msg %||% "duplicated entries:", dups))
  }
}

assert_unique_targets <- function(x) {
  assert_unique(x, "duplicated target names:")
}

warn_output <- function(name, path) {
  missing <- !file.exists(path)
  if (any(missing)) {
    warn_validate(
      "could not find files expected from target ",
      name,
      ": ",
      paste(path[missing], collapse = ", ")
    )
  }
}

warn_template <- function(template) {
  if (!is.null(template)) {
    warn_validate(
      "Functions tar_options(), tar_target(), and tar_target_raw() ",
      "currently ignore the template argument. It will only be supported if ",
      "clustermq ever supports heterogeneous workers with varying resource ",
      "configurations. In the meantime, use the template argument of ",
      "tar_make_clustermq()."
    )
  }
}

tar_test("fst_tbl format", {
  skip_if_not_installed("fst")
  skip_if_not_installed("tibble")
  envir <- new.env(parent = baseenv())
  envir$f <- function() {
    tibble::tibble(x = 1, y = 2)
  }
  x <- target_init(
    name = "abc",
    expr = quote(f()),
    format = "fst_tbl",
    envir = envir
  )
  builder_update_build(x)
  builder_update_path(x)
  builder_update_object(x)
  exp <- envir$f()
  out <- tibble::as_tibble(fst::read_fst(x$store$file$path))
  expect_equal(out, exp)
  expect_equal(target_read_value(x)$object, exp)
  expect_silent(target_validate(x))
})

tar_test("fst_tbl coercion", {
  skip_if_not_installed("fst")
  skip_if_not_installed("tibble")
  envir <- new.env(parent = baseenv())
  envir$f <- function() {
    data.frame(x = 1, y = 2)
  }
  x <- target_init(
    name = "abc",
    expr = quote(f()),
    format = "fst_tbl",
    envir = envir
  )
  builder_update_build(x)
  expect_true(inherits(x$value$object, "tbl_df"))
  builder_update_path(x)
  builder_update_object(x)
  expect_true(inherits(target_read_value(x)$object, "tbl_df"))
})

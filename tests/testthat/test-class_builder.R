tar_test("builder$store", {
  x <- target_init(name = "abc", expr = quote(a), format = "rds")
  expect_silent(store_validate(x$store))
})

tar_test("builder$metrics", {
  x <- target_init(name = "abc", expr = quote(1L))
  expect_null(x$metrics)
  builder_update_build(x)
  expect_silent(metrics_validate(x$metrics))
})

tar_test("target_run() on a good builder", {
  x <- target_init(name = "abc", expr = quote(a))
  cache_set_object(x$cache, "a", "x")
  target_run(x)
  expect_silent(metrics_validate(x$metrics))
  expect_silent(value_validate(x$value))
  expect_equal(x$value$object, "x")
  builder_update_object(x)
  expect_true(file.exists(x$store$file$path))
})

tar_test("target_run() on a errored builder", {
  algorithm_init("local", pipeline_init())$start_algorithm()
  x <- target_init(name = "abc", expr = quote(identity(identity(stop(123)))))
  target_run(x)
  meta <- meta_init()
  target_update_depend(x, meta)
  expect_error(
    target_conclude(x, pipeline_init(), scheduler_init(), meta),
    class = "condition_run"
  )
  expect_null(x$value$object)
  expect_true(metrics_has_error(x$metrics))
})

tar_test("target_run_remote()", {
  algorithm_init("local", pipeline_init())$start_algorithm()
  x <- target_init(name = "abc", expr = quote(identity(identity(stop(123)))))
  y <- target_run_remote(x, garbage_collection = TRUE)
  expect_true(inherits(y, "tar_builder"))
  expect_silent(target_validate(y))
})

tar_test("builders with different names use different seeds", {
  a <- target_init(
    name = "a",
    expr = quote(sample.int(1e9, 1L)),
    envir = baseenv()
  )
  b <- target_init(
    name = "b",
    expr = quote(sample.int(1e9, 1L)),
    envir = baseenv()
  )
  c <- target_init(
    name = "b",
    expr = quote(sample.int(1e9, 1L)),
    envir = baseenv()
  )
  builder_update_build(a)
  builder_update_build(b)
  builder_update_build(c)
  expect_false(a$value$object == b$value$object)
  expect_equal(b$value$object, c$value$object)
})

tar_test("read and write objects", {
  x <- target_init(name = "abc", expr = quote(a), format = "rds")
  tmp <- tempfile()
  file <- x$store$file
  file$path <- tmp
  cache_set_object(x$cache, "a", "123")
  builder_update_build(x)
  builder_update_object(x)
  expect_equal(readRDS(tmp), "123")
  expect_equal(target_read_value(x)$object, "123")
})

tar_test("error = \"stop\" means stop on error", {
  x <- target_init("x", expr = quote(stop(123)), error = "stop")
  y <- target_init("y", expr = quote(stop(456)), error = "stop")
  pipeline <- pipeline_init(list(x, y))
  expect_error(algorithm_init("local", pipeline)$run(), class = "condition_run")
  expect_equal(x$store$file$path, character(0))
  meta <- meta_init()$database$read_condensed_data()
  expect_true(all(nzchar(meta$error)))
  expect_equal(x$store$file$path, character(0))
  expect_equal(y$store$file$path, character(0))
})

tar_test("error = \"continue\" means continue on error", {
  x <- target_init("x", expr = quote(stop(123)), error = "continue")
  y <- target_init("y", expr = quote(stop(456)), error = "continue")
  pipeline <- pipeline_init(list(x, y))
  expect_silent(suppressMessages(algorithm_init("local", pipeline)$run()))
  expect_equal(x$store$file$path, character(0))
  expect_equal(y$store$file$path, character(0))
  meta <- meta_init()$database$read_condensed_data()
  expect_true(all(nzchar(meta$error)))
  expect_equal(x$store$file$path, character(0))
  expect_equal(y$store$file$path, character(0))
})

tar_test("errored targets are not up to date", {
  x <- target_init("x", expr = quote(123))
  pipeline <- pipeline_init(list(x))
  algorithm_init("local", pipeline)$run()
  for (index in seq_len(2L)) {
    x <- target_init("x", expr = quote(stop(123)))
    pipeline <- pipeline_init(list(x))
    expect_error(
      algorithm_init("local", pipeline)$run(),
      class = "condition_run"
    )
  }
})

tar_test("same if we continue on error", {
  x <- target_init("x", expr = quote(123))
  pipeline <- pipeline_init(list(x))
  algorithm_init("local", pipeline)$run()
  for (index in seq_len(2L)) {
    x <- target_init("x", expr = quote(stop(123)), error = "continue")
    pipeline <- pipeline_init(list(x))
    local <- algorithm_init("local", pipeline)
    local$run()
    counter <- local$scheduler$progress$skipped
    out <- counter_get_names(counter)
    expect_equal(out, character(0))
  }
})

tar_test("builder$write_from(\"local\")", {
  algorithm_init("local", pipeline_init())$start_algorithm()
  x <- target_init("abc", expr = quote(a), format = "rds", storage = "local")
  pipeline <- pipeline_init(list(x))
  scheduler <- pipeline_produce_scheduler(pipeline)
  cache_set_object(x$cache, "a", "123")
  target_run(x)
  expect_false(file.exists(x$store$file$path))
  expect_true(is.na(x$store$file$hash))
  meta <- meta_init()
  memory_set_object(meta$depends, "abc", NA_character_)
  target_conclude(x, pipeline, scheduler, meta)
  expect_true(file.exists(x$store$file$path))
  expect_false(is.na(x$store$file$hash))
  path <- file.path("_targets", "objects", "abc")
  expect_equal(readRDS(path), "123")
  expect_equal(target_read_value(x)$object, "123")
  target_conclude(x, pipeline, scheduler, meta)
})

tar_test("builder$write_from(\"remote\")", {
  algorithm_init("local", pipeline_init())$start_algorithm()
  x <- target_init(
    "abc",
    expr = quote(a),
    format = "rds",
    storage = "remote",
    retrieval = "local"
  )
  cache_set_object(x$cache, "a", "123")
  target_run(x)
  expect_true(file.exists(x$store$file$path))
  expect_false(is.na(x$store$file$hash))
  path <- file.path("_targets", "objects", "abc")
  expect_equal(readRDS(path), "123")
  expect_equal(target_read_value(x)$object, "123")
  pipeline <- pipeline_init(list(x))
  scheduler <- pipeline_produce_scheduler(pipeline)
  meta <- meta_init()
  memory_set_object(meta$depends, "abc", NA_character_)
  target_conclude(x, pipeline, scheduler, meta)
})

tar_test("dynamic file and builder$write_from(\"local\")", {
  algorithm_init("local", pipeline_init())$start_algorithm()
  envir <- new.env(parent = environment())
  x <- target_init(
    name = "abc",
    expr = quote(f()),
    format = "file",
    envir = envir,
    storage = "local"
  )
  envir$f <- function() {
    file <- tempfile()
    writeLines("lines", con = file)
    file
  }
  target_run(x)
  expect_true(file.exists(x$store$file$path))
  expect_false(is.na(x$store$file$hash))
  pipeline <- pipeline_init(list(x))
  scheduler <- pipeline_produce_scheduler(pipeline)
  meta <- meta_init()
  memory_set_object(meta$depends, "abc", NA_character_)
  target_conclude(x, pipeline, scheduler, meta)
})

tar_test("dynamic file has illegal path", {
  x <- target_init(
    name = "abc",
    expr = quote("a*b"),
    format = "file"
  )
  local <- algorithm_init("local", pipeline_init(list(x)))
  expect_error(local$run(), class = "condition_validate")
})

tar_test("dynamic file has empty path", {
  x <- target_init(
    name = "abc",
    expr = quote(NULL),
    format = "file"
  )
  local <- algorithm_init("local", pipeline_init(list(x)))
  expect_error(local$run(), class = "condition_validate")
})

tar_test("dynamic file has missing path value", {
  x <- target_init(
    name = "abc",
    expr = quote(NA_character_),
    format = "file"
  )
  local <- algorithm_init("local", pipeline_init(list(x)))
  expect_error(local$run(), class = "condition_validate")
})

tar_test("dynamic file is missing at path", {
  x <- target_init(
    name = "abc",
    expr = quote("nope"),
    format = "file"
  )
  local <- algorithm_init("local", pipeline_init(list(x)))
  expect_warning(local$run(), class = "condition_validate")
})

tar_test("dynamic file and builder$write_from(\"remote\")", {
  algorithm_init("local", pipeline_init())$start_algorithm()
  envir <- new.env(parent = environment())
  x <- target_init(
    name = "abc",
    expr = quote(f()),
    format = "file",
    envir = envir,
    storage = "remote",
    retrieval = "local"
  )
  envir$f <- function() {
    file <- tempfile()
    writeLines("lines", con = file)
    file
  }
  target_run(x)
  expect_true(file.exists(x$store$file$path))
  expect_false(is.na(x$store$file$hash))
  pipeline <- pipeline_init(list(x))
  scheduler <- pipeline_produce_scheduler(pipeline)
  meta <- meta_init()
  memory_set_object(meta$depends, "abc", NA_character_)
  target_conclude(x, pipeline, scheduler, meta)
})

tar_test("basic progress responses are correct", {
  local <- algorithm_init("local", pipeline_order())
  progress <- local$scheduler$progress
  pipeline <- local$pipeline
  expect_equal(
    sort(counter_get_names(progress$queued)),
    sort(pipeline_get_names(pipeline))
  )
  expect_equal(sort(counter_get_names(progress$running)), character(0))
  expect_equal(sort(counter_get_names(progress$built)), character(0))
  expect_equal(sort(counter_get_names(progress$skipped)), character(0))
  expect_equal(sort(counter_get_names(progress$cancelled)), character(0))
  expect_equal(sort(counter_get_names(progress$errored)), character(0))
  local$run()
  expect_equal(sort(counter_get_names(progress$queued)), character(0))
  expect_equal(sort(counter_get_names(progress$running)), character(0))
  expect_equal(
    sort(counter_get_names(progress$built)),
    sort(pipeline_get_names(pipeline))
  )
  expect_equal(sort(counter_get_names(progress$skipped)), character(0))
  expect_equal(sort(counter_get_names(progress$cancelled)), character(0))
  expect_equal(sort(counter_get_names(progress$errored)), character(0))
})

tar_test("builders load their packages", {
  envir <- new.env(parent = globalenv())
  x <- target_init(
    "x",
    quote(tibble(x = "x")),
    packages = "tibble",
    envir = envir
  )
  pipeline <- pipeline_init(list(x))
  out <- algorithm_init("local", pipeline)
  out$run()
  expect_equal(
    target_read_value(pipeline_get_target(pipeline, "x"))$object,
    tibble(x = "x")
  )
})

tar_test("validate with nonmissing file and value", {
  x <- target_init(name = "abc", expr = quote(1L + 1L))
  x$value <- value_init(123)
  file <- x$store$file
  file$path <- tempfile()
  expect_silent(tmp <- target_validate(x))
})

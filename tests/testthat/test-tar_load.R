tar_test("tar_load() works", {
  pipeline <- pipeline_init(
    list(
      target_init("y1", quote(1L)),
      target_init("y2", quote(2L)),
      target_init("z", quote(y1 + y2))
    )
  )
  algorithm_init("local", pipeline = pipeline)$run()
  envir <- new.env(parent = emptyenv())
  tar_load(starts_with("y"), envir = envir)
  expect_equal(sort(names(envir)), sort(c("y1", "y2")))
  expect_equal(envir$y1, 1L)
  expect_equal(envir$y2, 2L)
})

tar_test("tar_read() on patterns with vector iteration", {
  pipeline <- pipeline_init(
    list(
      target_init("x", quote(letters[seq_len(4L)])),
      target_init("y", quote(x), pattern = quote(map(x)), iteration = "vector")
    )
  )
  algorithm_init("local", pipeline = pipeline)$run()
  expect_equal(tar_read(y), letters[seq_len(4L)])
  envir <- new.env(parent = emptyenv())
  tar_load(y, branches = c(2L, 3L), envir = envir)
  out <- get("y", envir = envir)
  expect_equal(out, letters[c(2L, 3L)])
})

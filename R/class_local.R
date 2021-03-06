local_new <- function(
  pipeline = NULL,
  scheduler = NULL,
  meta = NULL,
  garbage_collection = NULL
) {
  local_class$new(
    pipeline = pipeline,
    scheduler = scheduler,
    meta = meta,
    garbage_collection = garbage_collection
  )
}

local_class <- R6::R6Class(
  classname = "tar_local",
  inherit = algorithm_class,
  class = FALSE,
  portable = FALSE,
  cloneable = FALSE,
  public = list(
    assert_deployment = function(target) {
    },
    run_target = function(name) {
      target <- pipeline_get_target(self$pipeline, name)
      self$assert_deployment(target)
      target_prepare(target, self$pipeline, self$scheduler)
      target_run(target)
      target_conclude(
        target,
        self$pipeline,
        self$scheduler,
        self$meta
      )
      pipeline_unload_transient(self$pipeline)
    },
    process_target = function(name) {
      target <- pipeline_get_target(self$pipeline, name)
      target_debug(target)
      target_update_depend(target, meta)
      trn(
        target_should_run(target, self$meta),
        self$run_target(name),
        target_skip(
          target,
          self$pipeline,
          self$scheduler,
          self$meta
        )
      )
    },
    process_next = function() {
      if (self$garbage_collection) {
        gc()
      }
      self$process_target(self$scheduler$queue$dequeue())
    },
    run = function() {
      self$start()
      queue <- self$scheduler$queue
      while (queue$should_dequeue()) {
        self$process_next()
      }
      self$end()
      invisible()
    }
  )
)

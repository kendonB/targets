#' @title Read a target's value from storage.
#' @export
#' @description Read a target's return value from its file in
#'   `_targets/objects/`. For dynamic files (i.e. `format = "file"`)
#'   the paths are returned.
#' @return The target's return value from its file in
#'   `_targets/objects/`, or the paths to the custom files and directories
#'   if `format = "file"` was set.
#' @param name Symbol, name of the target to read.
#' @param branches Integer of indices of the branches to load
#'   if the target is a pattern.
#' @param meta Data frame of metadata from [tar_meta()].
#'   `tar_read()` with the default arguments can be inefficient for large
#'   pipelines because all the metadata is stored in a single file.
#'   However, if you call [tar_meta()] beforehand and supply it to the `meta`
#'   argument, then successive calls to `tar_read()` may run much faster.
#' @examples
#' \dontrun{
#' tar_dir({
#' tar_script(tar_pipeline(tar_target(x, 1 + 1)))
#' tar_make()
#' tar_read(x)
#' })
#' }
tar_read <- function(name, branches = NULL, meta = tar_meta()) {
  assert_store()
  name <- deparse_language(substitute(name))
  assert_chr(name, "name arg of tar_read() must be a symbol.")
  tar_read_inner(name, branches, meta)
}

tar_read_inner <- function(name, branches, meta) {
  index <- meta$name == name
  if (!any(index)) {
    throw_validate("target ", name, " not found")
  }
  record <- do.call(record_init, lapply(meta[max(which(index)), ], unlist))
  trn(
    record$type %in% c("stem", "branch"),
    read_builder(record),
    read_pattern(name, record, meta, branches)
  )
}

read_builder <- function(record) {
  store <- store_init(format = record$format)
  store_update_path(store, record$name, record$path)
  store_read_object(store)
}

read_pattern <- function(name, record, meta, branches) {
  names <- record$children
  if (!is.null(branches)) {
    names <- names[branches]
  }
  if (length(diff <- setdiff(names, meta$name))) {
    diff <- trn(anyNA(diff), "branches out of range", diff)
    throw_validate("branches not in metadata: ", paste(diff, collapse = ", "))
  }
  meta <- meta[meta$name %in% names,, drop = FALSE] # nolint
  if (nrow(meta)) {
    meta <- meta[match(names, meta$name),, drop = FALSE] # nolint
  }
  records <- map_rows(meta, ~do.call(record_init, lapply(.x, unlist)))
  objects <- lapply(records, read_builder)
  value <- value_init(iteration = record$iteration)
  value_produce_aggregate(value, objects)
}

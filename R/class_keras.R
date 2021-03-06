keras_new <- function(file = NULL) {
  force(file)
  enclass(environment(), c("tar_keras", "tar_store"))
}

# nocov start (tests are interactive and depend on Python Keras)
#' @export
store_read_path.tar_keras <- function(store, path) {
  keras::load_model_hdf5(path)
}

#' @export
store_write_path.tar_keras <- function(store, object, path) {
  keras::save_model_hdf5(object = object, filepath = path)
}

#' @export
store_serialize_value.tar_keras <- function(store, value) {
  value$object <- keras::serialize_model(value$object)
}

#' @export
store_unserialize_value.tar_keras <- function(store, value) {
  value$object <- keras::unserialize_model(value$object)
}
# nocov end

#' @export
store_validate_packages.tar_keras <- function(store) {
  assert_package("keras")
}

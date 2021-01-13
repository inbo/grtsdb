#' Display a message
#' @param ... arguments passed to `base::message()`
#' @param verbose Display progress
#' @importFrom assertthat assert_that is.flag noNA
#' @noRd
show_message <- function(..., verbose = TRUE) {
  assert_that(is.flag(verbose), noNA(verbose))
  if (verbose) {
    message(...)
  }
}

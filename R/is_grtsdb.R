#' Check is an object is a grtsdb
#' @param grtsdb the grtsdb object
#' @export
#' @importFrom assertthat has_name
is_grtsdb <- function(grtsdb = getOption("grtsdb", "grts.sqlite")) {
  if (!inherits(grtsdb, "SQLiteConnection")) {
    return(FALSE)
  }
  return(TRUE)
}

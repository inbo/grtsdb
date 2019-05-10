#' Check is an object is a grtsdb
#' @param grtsdb the grtsdb object
#' @export
#' @importFrom assertthat has_name
is_grtsdb <- function(grtsdb) {
  if (!inherits(grtsdb, "grtsdb")) {
    return(FALSE)
  }
  if (!is.list(grtsdb)) {
    return(FALSE)
  }
  if (!has_name(grtsdb, c("conn", "levels"))) {
    return(FALSE)
  }
  if (!inherits(grtsdb$conn, "DBIConnection")) {
    return(FALSE)
  }
  return(TRUE)
}

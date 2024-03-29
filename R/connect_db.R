#' connect to or create an SQLite database
#' @param db the name or path of the database
#' @export
#' @importFrom assertthat assert_that is.string
#' @importFrom RSQLite dbConnect SQLite
#' @family base
connect_db <- function(db = getOption("grtsdb", "grts.sqlite")) {
  dbConnect(SQLite(), db)
}

#' @importFrom RSQLite dbDisconnect
#' @export
#' @family base
DBI::dbDisconnect

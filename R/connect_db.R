#' connect to a grtsdb database
#' @param db the name of the database
#' @export
#' @importFrom assertthat assert_that is.string noNA
#' @importFrom RSQLite dbConnect SQLite dbListTables
connect_db <- function(db = getOption("grtsdb", "grts.sqlite")) {
  assert_that(is.string(db), noNA(db))
  conn <- dbConnect(SQLite(), db)
  available <- dbListTables(conn)
  available <- available[grep("level%02i", available)]
  grtsdb <- list(
    conn = conn,
    levels = as.integer(gsub("level", "", available))
  )
  class(grtsdb) <- "grtsdb"
  return(grtsdb)
}

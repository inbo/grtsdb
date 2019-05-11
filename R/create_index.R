#' Add the index to the table
#' @inheritParams add_level
#' @export
#' @importFrom assertthat assert_that is.count
#' @importFrom RSQLite dbListTables dbListFields dbSendStatement dbClearResult
create_index <- function(level, grtsdb = connect_db()) {
  assert_that(is_grtsdb(grtsdb), is.count(level))
  if (!sprintf("level%02i", level) %in% dbListTables(grtsdb)) {
    stop(sprintf("level %i is not available. use add_level()", level))
  }
  fields <- dbListFields(grtsdb, sprintf("level%02i", level))
  fields <- fields[grep("^x[[:digit:]]*$", fields)]
  sql <- sprintf(
    "CREATE INDEX IF NOT EXISTS idx%02i ON level%1$02i (ranking, %s)", level,
    paste(fields, collapse = ", "))
  res <- dbSendStatement(grtsdb, sql)
  dbClearResult(res)
  return(NULL)
}

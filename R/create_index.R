#' Add the index to the table
#' @inheritParams add_level
#' @inheritDotParams add_level
#' @inheritParams has_index
#' @export
#' @importFrom assertthat assert_that is.count is.flag noNA
#' @importFrom RSQLite dbListTables dbListFields dbSendStatement dbClearResult
create_index <- function(level, grtsdb = connect_db(), legacy = FALSE, ...) {
  assert_that(is_grtsdb(grtsdb), is.count(level))
  assert_that(is.flag(legacy), noNA(legacy))
  type <- ifelse(legacy, "legacy", "level")
  if (!sprintf("%s%02i", type, level) %in% dbListTables(grtsdb)) {
    assert_that(
      !legacy,
      msg = "No legacy sites available for this level. Use add_legecy_site()."
    )
    add_level(grtsdb = grtsdb, level = level, ...)
  }
  fields <- dbListFields(grtsdb, sprintf("%s%02i", type, level))
  fields <- fields[grep("^x[[:digit:]]*$", fields)]
  sql <- sprintf(
    "CREATE INDEX IF NOT EXISTS %s%02i ON %s%02i (ranking, %s)",
    ifelse(legacy, "idx_legacy", "idx"), level,
    ifelse(legacy, "legacy", "level"), level, paste(fields, collapse = ", ")
  )
  dbClearResult(dbSendStatement(grtsdb, sql))
  return(NULL)
}

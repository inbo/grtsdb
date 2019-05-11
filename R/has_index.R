#' has a table the required index
#' @inheritParams add_level
#' @export
#' @importFrom assertthat assert_that is.count
#' @importFrom RSQLite dbListTables dbGetQuery
has_index <- function(grtsdb = getOption("grtsdb", "grts.sqlite"), level) {
  assert_that(is_grtsdb(grtsdb), is.count(level))
  if (!sprintf("level%02i", level) %in% dbListTables(grtsdb)) {
    stop(sprintf("level %i is not available. use add_level()", level))
  }
  sql <- sprintf("PRAGMA index_list(level%02i)", level)
  pragma <- dbGetQuery(grtsdb, sql)
  if (nrow(pragma) == 0) {
    return(FALSE)
  }
  return(sprintf("idx%02i", level) %in% pragma$name)
}

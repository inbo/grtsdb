#' has a table the required index
#' @inheritParams add_level
#' @param legacy Use legacy sites.
#' Defaults to `FALSE`.
#' @inheritDotParams add_level
#' @export
#' @importFrom assertthat assert_that is.count is.flag noNA
#' @importFrom RSQLite dbListTables dbGetQuery
has_index <- function(level, grtsdb = connect_db(), legacy = FALSE, ...) {
  assert_that(is_grtsdb(grtsdb), is.count(level))
  assert_that(is.flag(legacy), noNA(legacy))
  type <- ifelse(legacy, "legacy", "level")
  if (!sprintf("%s%02i", type, level) %in% dbListTables(grtsdb)) {
    return(FALSE)
  }
  sql <- sprintf("PRAGMA index_list(%s%02i)", type, level)
  pragma <- dbGetQuery(grtsdb, sql)
  if (nrow(pragma) == 0) {
    return(FALSE)
  }
  return(
    sprintf("%s%02i", ifelse(legacy, "idx_legacy", "idx"), level) %in%
      pragma$name
  )
}

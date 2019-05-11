#' Return a vector of level number which are available in the database
#' @inheritParams add_level
#' @export
#' @importFrom assertthat assert_that
#' @importFrom RSQLite dbListTables
which_level <- function(grtsdb = connect_db()) {
  assert_that(is_grtsdb(grtsdb))
  available <- dbListTables(grtsdb)
  available <- available[grep("level[[:digit:]]{2}", available)]
  as.integer(gsub("level", "", available))
}

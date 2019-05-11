#' Compact the database by removing the lower levels and all indices
#' @export
#' @inheritParams add_level
#' @importFrom RSQLite dbSendStatement dbClearResult
compact_db <- function(grtsdb) {
  assert_that(is_grtsdb(grtsdb))
  level <- dbListTables(grtsdb)
  level <- level[grep("level[[:digit:]]*", level)]
  level <- as.integer(gsub("level", "", level))
  sql <- sprintf("DROP INDEX IF EXISTS idx%02i", level)
  sapply(
    sql,
    function(x) {
      res <- dbSendStatement(grtsdb, x)
      dbClearResult(res)
    }
  )
  sql <- sprintf("DROP TABLE IF EXISTS level%02i", level[-which.max(level)])
  sapply(
    sql,
    function(x) {
      res <- dbSendStatement(grtsdb, x)
      dbClearResult(res)
    }
  )
  res <- dbSendStatement(grtsdb, "VACUUM")
  dbClearResult(res)
  return(NULL)
}

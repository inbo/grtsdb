#' Add legacy sites
#' @param legacy A matrix with coordinates of the legacy sites.
#' One column for every dimension.
#' @inheritParams add_level
#' @export
#' @importFrom assertthat assert_that
#' @importFrom RSQLite dbClearResult dbGetQuery dbListFields dbListTables
#' dbSendStatement
#' @importFrom utils head tail
#' @family legacy
add_legacy_sites <- function(legacy, bbox, cellsize, grtsdb = connect_db()) {
  level <- n_level(bbox = bbox, cellsize = cellsize)
  assert_that(
    !sprintf("legacy%02i", level) %in% dbListTables(grtsdb),
    msg = paste("legacy sites for level", level, "already set")
  )
  assert_that(
    inherits(legacy, "matrix"), is.numeric(legacy), ncol(legacy) == nrow(bbox)
  )
  assert_that(
    all(legacy >= t(bbox[, rep(1, nrow(legacy))])),
    all(legacy <= t(bbox[, rep(2, nrow(legacy))])),
    msg = "Legacy sites must be within bbox"
  )
  fields <- dbListFields(grtsdb, sprintf("level%02i", level))
  fields <- fields[grep("^x[[:digit:]]*$", fields)]
  base_4 <- sprintf(
    "(ranking %% %i) / %i AS l%02i", 4 ^ seq_len(level), # nolint
    4 ^ (seq_len(level) - 1), seq_len(level)
  )
  sql <- sprintf(
    "CREATE TABLE legacy%02i AS
    SELECT %s, ranking, %s, 0 AS legacy
    FROM level%02i",
    level,
    paste(fields, collapse = ", "),
    paste(base_4, collapse = ", "),
    level
  )
  dbClearResult(dbSendStatement(grtsdb, sql))
  center <- rowMeans(bbox)
  midpoint <- 2 ^ (level - 1) - 0.5
  apply(
    legacy, 1,
    function(l) {
      clegacy <- round((l - center) / cellsize + midpoint)
      where <- sprintf("%s == %i", fields, clegacy)
      where <- paste(where, collapse = " AND ")
      sql <- sprintf("UPDATE legacy%02i SET legacy = 1 WHERE %s", level, where)
      dbClearResult(dbSendStatement(grtsdb, sql))
    }
  )
  fields <- sprintf("l%02i", rev(seq_len(level)))
  sql_current <- sprintf(
    "SELECT %s FROM legacy%02i WHERE legacy = 1 ORDER BY %s",
    paste(fields, collapse = ", "), level,
    paste(rev(fields), collapse = ", ")
  )
  current <- dbGetQuery(grtsdb, sql_current)
  stopifnot(any(current[1, fields] > 0))
  i <- 1
  target <- rep(0, level)
  f <- head(which(current[i, fields] > target), 1)
  while (i <= nrow(current) && length(f) > 0) {
    where_stable <- sprintf(
      "%s = %s", tail(fields, -f), tail(unlist(current[i, fields]), -f)
    )
    extra <- paste(fields[f], current[i, fields[f]], sep = " = ")
    sql <- sprintf(
      "UPDATE legacy%02i SET %s = -1 WHERE %s",
      level, fields[f],
      paste(c(where_stable, extra), collapse = " AND ")
    )
    dbClearResult(dbSendStatement(grtsdb, sql))
    extra <- paste(fields[f], target[f], sep = " = ")
    sql <- sprintf(
      "UPDATE legacy%02i SET %s = %i WHERE %s",
      level, fields[f], current[i, fields[f]],
      paste(c(where_stable, extra), collapse = " AND ")
    )
    dbClearResult(dbSendStatement(grtsdb, sql))
    extra <- paste(fields[f], -1, sep = " = ")
    sql <- sprintf(
      "UPDATE legacy%02i SET %s = %i WHERE %s",
      level, fields[f], target[f],
      paste(c(where_stable, extra), collapse = " AND ")
    )
    dbClearResult(dbSendStatement(grtsdb, sql))
    current <- dbGetQuery(grtsdb, sql_current)
    f <- head(which(current[i, fields] > target), 1)
    if (length(f) == 1) {
      next
    }
    i <- i + 1
    if (i > nrow(current)) {
      break
    }
    z <- tail(which(current[i - 1, fields] != current[i, fields]), 1)
    target <- c(rep(0, z - 1), target[z] + 1, tail(target, -z))
    f <- head(which(current[i, fields] > target), 1)
  }
  ranking <- sprintf("l%02i * %i", seq_len(level), 4 ^ (seq_len(level) - 1))
  sql <- sprintf(
    "UPDATE legacy%02i SET ranking = %s", level, paste(ranking, collapse = "+")
  )
  dbClearResult(dbSendStatement(grtsdb, sql))
  return(invisible(NULL))
}

#' Drop the table with legacy sites for a given level
#' @inheritParams add_level
#' @export
#' @importFrom assertthat assert_that is.count
#' @importFrom RSQLite dbClearResult dbSendStatement
#' @family legacy
drop_legacy_sites <- function(level, grtsdb = connect_db()) {
  assert_that(is.count(level))
  sql <- sprintf("DROP TABLE IF EXISTS legacy%02i", level)
  dbClearResult(dbSendStatement(grtsdb, sql))
  return(invisible(NULL))
}

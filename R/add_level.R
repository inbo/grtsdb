#' Add a level to the grtsdb
#' @inheritParams n_level
#' @inheritParams is_grtsdb
#' @param level the required level
#' @param verbose Display progress
#' @export
#' @importFrom assertthat assert_that is.flag noNA is.count
#' @importFrom RSQLite dbSendStatement dbClearResult dbWriteTable
add_level <- function(
  grtsdb = connect_db(), bbox, cellsize, verbose = TRUE, level) {
  assert_that(is.flag(verbose), noNA(verbose))
  if (missing(level)) {
    level <- n_level(bbox = bbox, cellsize = cellsize)
    message("Required number of levels: ", level)
  } else {
    assert_that(is.count(level), inherits(bbox, "matrix"), nrow(bbox) >= 1)
  }
  assert_that(is_grtsdb(grtsdb))
  if (level %in% grtsdb$levels) {
    return(invisible(grtsdb))
  }
  if (length(grtsdb$levels) == 0) {
    if (level == 1) {
      if (verbose) {
        message("Adding level ", level, ": create table", appendLF = FALSE)
      }
      sql <- sprintf("x%i INTEGER", seq_len(nrow(bbox)))
      sql <- sprintf(
        "CREATE TABLE IF NOT EXISTS level%02i (%s, ranking INTEGER)",
        level, paste(sql, collapse = ", "))
      res <- dbSendStatement(grtsdb$conn, sql)
      dbClearResult(res)
      df <- expand.grid(rep(list(0:1), nrow(bbox)))
      colnames(df) <- sprintf("x%i", seq_len(nrow(bbox)))
      df <- df[sample(nrow(df)), ]
      df$ranking <- seq_len(nrow(df)) - 1
      if (verbose) {
        message(", add coordinates, calculate ranking")
      }
      dbWriteTable(conn = grtsdb$conn, name = sprintf("level%02i", level),
                   value = df, append = TRUE)
      grtsdb$levels <- sort(c(grtsdb$levels, as.integer(level)))
      return(invisible(grtsdb))
    } else {
      grtsdb <- add_level(grtsdb = grtsdb, level = level - 1, bbox = bbox,
                          cellsize = cellsize, verbose = verbose)
    }
  }
  if (max(grtsdb$levels) > level) {
    stop("higher level available")
  }
  if (max(grtsdb$levels) + 1 < level) {
    grtsdb <- add_level(grtsdb = grtsdb, level = level - 1, bbox = bbox,
                        cellsize = cellsize, verbose = verbose)
  }
  if (verbose) {
    message("Adding level ", level, ": create table", appendLF = FALSE)
  }
  sql <- sprintf("x%i INTEGER", seq_len(nrow(bbox)))
  sql <- sprintf(
"CREATE TABLE IF NOT EXISTS level%02i
    (%s, level%02i INTEGER, ranking INTEGER)",
    level, paste(sql, collapse = ", "), level - 1)
  res <- dbSendStatement(grtsdb$conn, sql)
  dbClearResult(res)
  if (verbose) {
    message(", add coordinates", appendLF = FALSE)
  }
  df <- expand.grid(rep(list(0:1), nrow(bbox)))
  colnames(df) <- sprintf("x%i", seq_len(nrow(bbox)))
  sql <- sapply(
    colnames(df),
    function(i) {
      sprintf("%1$s * 2 + %2$i AS %1$s", i, df[[i]])
    }
  )
  sql <- sprintf(
"SELECT %1$s, ranking, rowid AS level%2$02i, random() AS z FROM level%2$02i",
    apply(sql, 1, paste, collapse = ", "), level - 1)
  sql <- sprintf(
    "WITH cte_base AS (
%1$s
)

INSERT INTO level%2$02i
SELECT %3$s, level%4$02i, ranking FROM cte_base ORDER BY level%4$02i, z",
    paste(sql, collapse = "\nUNION ALL\n  "), level,
    paste(colnames(df), collapse = ", "), level - 1)
  res <- dbSendStatement(grtsdb$conn, sql)
  dbClearResult(res)
  if (verbose) {
    message(", calculate ranking")
  }
  sql <- sprintf(
    "UPDATE level%02i SET
  ranking = %i * (rowid - %i * (level%02i - 1) - 1) + ranking",
    level, (2 ^ nrow(bbox)) ^ (level - 1), 2 ^ nrow(bbox), level - 1)
  res <- dbSendStatement(grtsdb$conn, sql)
  dbClearResult(res)
  grtsdb$levels <- sort(c(grtsdb$levels, as.integer(level)))
  return(invisible(grtsdb))
}
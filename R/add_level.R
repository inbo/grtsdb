#' Add a level to the grtsdb
#' @inheritParams n_level
#' @inheritParams is_grtsdb
#' @param level the required level
#' @param verbose Display progress
#' @export
#' @importFrom assertthat assert_that is.count
#' @importFrom RSQLite dbSendStatement dbClearResult dbWriteTable
#' @family base
add_level <- function(bbox, cellsize, grtsdb = connect_db(), verbose = TRUE,
                      level) {
  if (missing(level)) {
    level <- n_level(bbox = bbox, cellsize = cellsize)
    show_message("Required number of levels: ", level, verbose = verbose)
  } else {
    assert_that(is.count(level), inherits(bbox, "matrix"), nrow(bbox) >= 1)
  }
  if (level %in% which_level(grtsdb)) {
    return(invisible(NULL))
  }
  if (length(which_level(grtsdb)) == 0) {
    if (level == 1) {
      show_message(
        "Adding level ", level, ": create table", appendLF = FALSE,
        verbose = verbose
      )
      sql <- sprintf("x%i INTEGER", seq_len(nrow(bbox)))
      sql <- sprintf(
        "CREATE TABLE IF NOT EXISTS level%02i (%s, ranking INTEGER)",
        level, paste(sql, collapse = ", "))
      res <- dbSendStatement(grtsdb, sql)
      dbClearResult(res)
      df <- expand.grid(rep(list(0:1), nrow(bbox)))
      colnames(df) <- sprintf("x%i", seq_len(nrow(bbox)))
      df <- df[sample(nrow(df)), , drop = FALSE]
      df$ranking <- seq_len(nrow(df)) - 1
      show_message(", add coordinates, calculate ranking", verbose = verbose)
      dbWriteTable(
        conn = grtsdb, name = sprintf("level%02i", level),
        value = df, append = TRUE
      )
      return(invisible(NULL))
    } else {
      add_level(
        grtsdb = grtsdb, level = level - 1, bbox = bbox, cellsize = cellsize,
        verbose = verbose
      )
    }
  }

  if (max(which_level(grtsdb)) > level) {
    if (level < max(which_level(grtsdb)) - 1) {
      add_level(
        grtsdb = grtsdb, level = level + 1, bbox = bbox,
        cellsize = cellsize, verbose = verbose
      )
    }
    show_message(
      "Adding level ", level, ": create table", appendLF = FALSE,
      verbose = verbose
    )
    sql <- sprintf("x%i INTEGER", seq_len(nrow(bbox)))
    sql <- sprintf("CREATE TABLE IF NOT EXISTS level%02i
  (%s, level%02i INTEGER, ranking INTEGER)",
      level, paste(sql, collapse = ", "), level - 1)
    res <- dbSendStatement(grtsdb, sql)
    dbClearResult(res)
    show_message(", add coordinates, calculate ranking", verbose = verbose)
    fields <- sprintf("min(x%1$i / 2) AS x%1$i", seq_len(nrow(bbox)))
    sql <- sprintf("INSERT INTO level%3$02i
SELECT
  %1$s,
  level%3$02i - %5$i * cast(level%3$02i / %5$i AS int) AS level%2$02i,
  level%3$02i AS ranking
FROM level%4$02i
GROUP BY level%3$02i",
            paste(fields, collapse = ",\n  "), level - 1, level, level + 1,
            2 ^ nrow(bbox))
    res <- dbSendStatement(grtsdb, sql)
    dbClearResult(res)
    return(invisible(NULL))
  }
  if (max(which_level(grtsdb)) + 1 < level) {
    add_level(grtsdb = grtsdb, level = level - 1, bbox = bbox,
              cellsize = cellsize, verbose = verbose)
  }
  show_message(
    "Adding level ", level, ": create table", appendLF = FALSE,
    verbose = verbose
  )
  sql <- sprintf("x%i INTEGER", seq_len(nrow(bbox)))
  sql <- sprintf(
"CREATE TABLE IF NOT EXISTS level%02i
    (%s, level%02i INTEGER, ranking INTEGER)",
    level, paste(sql, collapse = ", "), level - 1)
  res <- dbSendStatement(grtsdb, sql)
  dbClearResult(res)
  show_message(", add coordinates", appendLF = FALSE, verbose = verbose)
  df <- expand.grid(rep(list(0:1), nrow(bbox)))
  colnames(df) <- sprintf("x%i", seq_len(nrow(bbox)))
  sql <- sapply(
    colnames(df),
    function(i) {
      sprintf("%1$s * 2 + %2$i AS %1$s", i, df[[i]])
    }
  )
  sql <- sprintf("SELECT %1$s, ranking, rowid - 1 AS level%2$02i, random() AS z
FROM level%2$02i",
    apply(sql, 1, paste, collapse = ", "), level - 1)
  sql <- sprintf(
    "WITH cte_base AS (
%1$s
)

INSERT INTO level%2$02i
SELECT %3$s, level%4$02i, ranking FROM cte_base ORDER BY level%4$02i, z",
    paste(sql, collapse = "\nUNION ALL\n  "), level,
    paste(colnames(df), collapse = ", "), level - 1)
  res <- dbSendStatement(grtsdb, sql)
  dbClearResult(res)
  show_message(", calculate ranking", verbose = verbose)
  sql <- sprintf(
    "UPDATE level%02i SET
  ranking = %i * (rowid - %i * level%02i - 1) + ranking",
    level, (2 ^ nrow(bbox)) ^ (level - 1), 2 ^ nrow(bbox), level - 1)
  res <- dbSendStatement(grtsdb, sql)
  dbClearResult(res)
  return(invisible(NULL))
}

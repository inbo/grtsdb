#' Add a level to the grtsdb
#' @inheritParams n_level
#' @inheritParams is_grtsdb
#' @param level the required level
#' @param verbose Display progress
#' @export
#' @importFrom assertthat assert_that is.count
#' @importFrom RSQLite dbSendStatement dbClearResult dbWriteTable
#' @family base
add_level <- function(
  bbox, cellsize, grtsdb = connect_db(), verbose = TRUE, level
) {
  if (missing(level)) {
    level <- n_level(bbox = bbox, cellsize = cellsize)
    show_message("Required number of levels: ", level, verbose = verbose)
  } else {
    assert_that(is.count(level), inherits(bbox, "matrix"), nrow(bbox) >= 1)
  }

  # nothing to do when the level already exists
  if (level %in% which_level(grtsdb)) {
    return(invisible(NULL))
  }

  # add the most coarse level
  if (level == 1) {
    add_level_start(grtsdb = grtsdb, bbox = bbox, verbose = verbose)
    return(invisible(NULL))
  }

  # create the previous level when no levels exist
  if (length(which_level(grtsdb)) == 0) {
    add_level(
      grtsdb = grtsdb, level = level - 1, bbox = bbox, cellsize = cellsize,
      verbose = verbose
    )
  }

  # restore coarse levels in a compacted database
  if (max(which_level(grtsdb)) > level) {
    restore_level(
      grtsdb = grtsdb, bbox = bbox, level = level, verbose = verbose
    )
    return(invisible(NULL))
  }

  # create the previous level when it is missing
  if (max(which_level(grtsdb)) + 1 < level) {
    add_level(
      grtsdb = grtsdb, level = level - 1, bbox = bbox, cellsize = cellsize,
      verbose = verbose
    )
  }

  # add the current level based on the previous level
  show_message(
    "Adding level ", level, ": create table", appendLF = FALSE,
    verbose = verbose
  )

  # create the table
  sql <- sprintf("x%i INTEGER", seq_len(nrow(bbox)))
  sql <- sprintf(
"CREATE TABLE IF NOT EXISTS level%02i
    (%s, level%02i INTEGER, ranking INTEGER)",
    level, paste(sql, collapse = ", "), level - 1)
  res <- dbSendStatement(grtsdb, sql)
  dbClearResult(res)

  # add the coordinates
  # randomise the current level within each block of the previous level
  show_message(", add coordinates", appendLF = FALSE, verbose = verbose)
  df <- expand.grid(rep(list(0:1), nrow(bbox)))
  colnames(df) <- sprintf("x%i", seq_len(nrow(bbox)))
  sql <- sapply(
    colnames(df),
    function(i) {
      sprintf("%1$s * 2 + %2$i AS %1$s", i, df[[i]])
    }
  )
  sql <- sprintf("SELECT %1$s, ranking, ranking AS level%2$02i, random() AS z
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

  # calculate the ranking based on the previous level and the row order
  # the previous step randomised the order of the rows
  show_message(", calculate ranking", verbose = verbose)
  sql <- sprintf(
    "UPDATE level%02i SET
  ranking = ((rowid - 1) %% %i) * %i + ranking",
    level, 2 ^ nrow(bbox), (2 ^ nrow(bbox)) ^ (level - 1))
  res <- dbSendStatement(grtsdb, sql)
  dbClearResult(res)

  return(invisible(NULL))
}

add_level_start <- function(grtsdb, bbox, verbose) {
  level <- 1
  show_message(
    "Adding level ", level, ": create table", appendLF = FALSE,
    verbose = verbose
  )

  # create the table
  sql <- sprintf("x%i INTEGER", seq_len(nrow(bbox)))
  sql <- sprintf(
    "CREATE TABLE IF NOT EXISTS level%02i (%s, ranking INTEGER)",
    level, paste(sql, collapse = ", "))
  res <- dbSendStatement(grtsdb, sql)
  dbClearResult(res)

  # randomise the coordinates
  df <- expand.grid(rep(list(0:1), nrow(bbox)))
  colnames(df) <- sprintf("x%i", seq_len(nrow(bbox)))
  df <- df[sample(nrow(df)), , drop = FALSE]
  df$ranking <- seq_len(nrow(df)) - 1

  show_message(", add coordinates, calculate ranking", verbose = verbose)
  # store the randomised coordinates
  dbWriteTable(
    conn = grtsdb, name = sprintf("level%02i", level),
    value = df, append = TRUE
  )
  return(invisible(NULL))
}

restore_level <- function(grtsdb, bbox, level, verbose) {
  # restore the next level when it doesn't exist
  if (level < max(which_level(grtsdb)) - 1) {
    restore_level(
      grtsdb = grtsdb, level = level + 1, bbox = bbox, verbose = verbose
    )
  }

  # restore the current level based on the next level
  show_message(
    "Adding level ", level, ": create table", appendLF = FALSE,
    verbose = verbose
  )

  # create the table
  sql <- sprintf("x%i INTEGER", seq_len(nrow(bbox)))
  sql <- sprintf("CREATE TABLE IF NOT EXISTS level%02i
  (%s, level%02i INTEGER, ranking INTEGER)",
  level, paste(sql, collapse = ", "), level - 1)
  res <- dbSendStatement(grtsdb, sql)
  dbClearResult(res)

  # fill the table
  show_message(", add coordinates, calculate ranking", verbose = verbose)
  fields <- sprintf("min(x%1$i / 2) AS x%1$i", seq_len(nrow(bbox))) #nolint: nonportable_path_linter
  sql <- sprintf("INSERT INTO level%1$02i
  SELECT
    %4$s,
  level%1$02i %% %5$i AS level%2$02i,
  level%1$02i AS ranking
  FROM level%3$02i
  GROUP BY level%1$02i",
    level, level - 1, level + 1, paste(fields, collapse = ",\n  "),
    (2 ^ nrow(bbox)) ^ (level - 1)
  )
  res <- dbSendStatement(grtsdb, sql)
  dbClearResult(res)
  return(invisible(NULL))
}

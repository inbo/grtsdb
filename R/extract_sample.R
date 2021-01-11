#' extract the grts sample
#' @inheritParams add_level
#' @param samplesize the required sample size
#' @param offset An optional number of samples to skip.
#' This is useful in cases where you need extra samples.
#' @export
#' @importFrom assertthat assert_that is.count
#' @importFrom RSQLite dbListTables dbListFields dbGetQuery
#' @family base
extract_sample <- function(
  grtsdb = connect_db(), samplesize, bbox, cellsize, verbose = TRUE, offset
) {
  assert_that(is.count(samplesize))
  assert_that(missing(offset) || is.count(offset))
  level <- n_level(bbox = bbox, cellsize = cellsize)
  if (!has_index(
    grtsdb = grtsdb, level = level, legacy = FALSE, bbox = bbox,
    cellsize = cellsize, verbose = verbose
  )) {
    show_message(
      "Creating index for level ", level, ". May take some time...",
      appendLF = FALSE, verbose = verbose
    )
    create_index(
      grtsdb = grtsdb, level = level, bbox = bbox, cellsize = cellsize,
      verbose = verbose
    )
    show_message(" Done.", verbose = verbose)
  }
  fields <- dbListFields(grtsdb, sprintf("level%02i", level))
  fields <- fields[grep("^x[[:digit:]]*$", fields)]
  center <- rowMeans(bbox)
  midpoint <- 2 ^ (level - 1) - 0.5
  where <- sprintf("%s %s %f", rep(fields, 2),
                   rep(c(">=", "<="), each = length(center)),
                   (as.vector(bbox) - center) / cellsize + midpoint)
  where <- paste(where, collapse = " AND ")
  fields <- sprintf("(%1$s - %2$f) * %3$f + %4$f AS %1$sc",
                    fields, midpoint, cellsize, center)
  sql <- sprintf(
    "SELECT %s, ranking FROM level%02i WHERE %s ORDER BY ranking LIMIT %i%s",
    paste(fields, collapse = ", "), level, where, samplesize,
    ifelse(missing(offset), "", paste(" OFFSET", offset))
  )
  dbGetQuery(grtsdb, sql)
}

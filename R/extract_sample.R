#' extract the grts sample
#' @inheritParams add_level
#' @param samplesize the required sample size
#' @export
#' @importFrom assertthat assert_that is.count
#' @importFrom RSQLite dbListTables dbListFields dbGetQuery
extract_sample <- function(grtsdb = connect_db(), samplesize, bbox, cellsize) {
  assert_that(is.count(samplesize))
  level <- n_level(bbox = bbox, cellsize = cellsize)
  if (!has_index(grtsdb = grtsdb, level = level)) {
    message("Creating index for level ", level, ". May take some time...",
            appendLF = FALSE)
    create_index(grtsdb = grtsdb, level = level)
    message(" Done.")
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
    "SELECT %s, ranking FROM level%02i WHERE %s ORDER BY ranking LIMIT %i",
    paste(fields, collapse = ", "), level, where, samplesize)
  dbGetQuery(grtsdb, sql)
}

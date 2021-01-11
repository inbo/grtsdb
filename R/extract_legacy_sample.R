#' Extract the GRTS sample with legancy sites
#' @inheritParams add_level
#' @inheritParams extract_sample
#' @export
#' @importFrom assertthat assert_that is.count
#' @importFrom RSQLite dbListTables dbListFields dbGetQuery
extract_legacy_sample <- function(
  grtsdb = connect_db(), samplesize, bbox, cellsize, verbose = TRUE, offset
) {
  assert_that(is.count(samplesize))
  assert_that(missing(offset) || is.count(offset))
  level <- n_level(bbox = bbox, cellsize = cellsize)
  if (!has_index(grtsdb = grtsdb, level = level, legacy = TRUE)) {
    show_message(
      "Creating index for legacy level ", level, ". May take some time...",
      appendLF = FALSE, verbose = verbose
    )
    create_index(
      grtsdb = grtsdb, level = level, bbox = bbox, cellsize = cellsize,
      verbose = verbose, legacy = TRUE
    )
    show_message(" Done.", verbose = verbose)
  }
  fields <- dbListFields(grtsdb, sprintf("legacy%02i", level))
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
    "SELECT %s, ranking FROM legacy%02i WHERE %s ORDER BY ranking LIMIT %i%s",
    paste(fields, collapse = ", "), level, where, samplesize,
    ifelse(missing(offset), "", paste(" OFFSET", offset))
  )
  dbGetQuery(grtsdb, sql)
}

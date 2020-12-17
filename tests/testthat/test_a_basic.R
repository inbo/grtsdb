context("minimal checks")
expect_is(conn <- connect_db(":memory:"), "SQLiteConnection")
bbox <- rbind(c(0, 7), c(0,7))
cellsize <- 1
expect_message(
  add_level(grtsdb = conn, bbox = bbox, cellsize = cellsize),
  "Required number of levels"
)
expect_null(compact_db(grtsdb = conn))
expect_error(has_index(grtsdb = conn, level = 1), "level 1 is not available")
expect_message(
  create_index(grtsdb = conn, level = 1, bbox = bbox, cellsize = cellsize),
  "Adding level 1"
)
expect_is(
  extract_sample(grtsdb = conn, samplesize = 10, bbox = bbox,
                 cellsize = cellsize),
  "data.frame"
)
expect_true(has_index(grtsdb = conn, level = 3))
expect_false(is_grtsdb(NULL))
expect_null(add_level(grtsdb = conn, bbox = bbox, cellsize = cellsize))
expect_message(
  add_level(grtsdb = conn, bbox = bbox, cellsize = cellsize, level = 5),
  "Adding level 5"
)

test_that("basic functionality", {
  expect_is(conn <- connect_db(":memory:"), "SQLiteConnection")
  bbox <- rbind(c(0, 7), c(0, 7))
  cellsize <- 1
  expect_message(
    add_level(grtsdb = conn, bbox = bbox, cellsize = cellsize),
    "Required number of levels"
  )
  expect_null(compact_db(grtsdb = conn))
  expect_false(has_index(grtsdb = conn, level = 1))
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
  expect_is(
    extract_sample(grtsdb = conn, samplesize = 10, bbox = bbox,
                   cellsize = cellsize, offset = 20),
    "data.frame"
  )
  RSQLite::dbDisconnect(conn)

  expect_error(
    n_level(matrix(0:1, nrow = 1), cellsize = 10),
    "the bounding box must contain at least 2 cells in each dimension"
  )
  expect_identical(
    n_level(matrix(0:1, nrow = 1), cellsize = 0.5),
    1
  )
})

test_that("add_level() doesn't mix dimensions", {
  conn <- connect_db(":memory:")
  bbox <- rbind(c(0, 7), c(0, 7))
  cellsize <- 1
  add_level(bbox = bbox, cellsize = cellsize, grtsdb = conn, verbose = FALSE)

  bbox <- rbind(c(0, 7))
  expect_error(
    add_level(bbox = bbox, cellsize = cellsize, grtsdb = conn, verbose = FALSE),
    "different dimensions"
  )

  bbox <- rbind(c(0, 15))
  expect_error(
    add_level(bbox = bbox, cellsize = cellsize, grtsdb = conn, verbose = FALSE),
    "different dimensions"
  )

  compact_db(grtsdb = conn)

  bbox <- rbind(c(0, 3))
  expect_error(
    add_level(bbox = bbox, cellsize = cellsize, grtsdb = conn, verbose = FALSE),
    "different dimensions"
  )
  dbDisconnect(conn)
})

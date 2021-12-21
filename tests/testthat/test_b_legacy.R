test_that("legacy sites are included", {
  expect_is(conn <- connect_db(":memory:"), "SQLiteConnection")
  bbox <- rbind(c(0, 1), c(0, 1))
  cellsize <- 0.01
  legacy <- matrix(runif(50), ncol = 2)
  expect_message(
    add_level(grtsdb = conn, bbox = bbox, cellsize = cellsize),
    "Required number of levels"
  )
  expect_invisible(
    add_legacy_sites(
      legacy = legacy, bbox = bbox, cellsize = cellsize, grtsdb = conn
    )
  )
  expect_false(
    has_index(grtsdb = conn, level = n_level(bbox, cellsize), legacy = TRUE)
  )
  expect_is(
    extract_legacy_sample(
      grtsdb = conn, samplesize = 10, bbox = bbox, cellsize = cellsize
    ),
    "data.frame"
  )
  expect_is(
    extract_legacy_sample(
      grtsdb = conn, samplesize = 10, bbox = bbox, cellsize = cellsize,
      offset = 20
    ),
    "data.frame"
  )
  expect_true(
    has_index(grtsdb = conn, level = n_level(bbox, cellsize), legacy = TRUE)
  )
  expect_invisible(
    drop_legacy_sites(level = n_level(bbox, cellsize), grtsdb = conn)
  )
  RSQLite::dbDisconnect(conn)
})

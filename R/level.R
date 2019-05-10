#' Calculate the required level based on a bounding box and a cellsize
#' @param bbox two-column matrix; the first column has the minimum, the second the maximum values; rows represent the spatial dimensions
#' @param cellsize the size of each cell. Either a single value or one value for each dimension.
#' @export
#' @importFrom assertthat assert_that noNA
#' @return the required level to cover the bbox using a grid with cellsize
level <- function(bbox, cellsize) {
  assert_that(inherits(bbox, "matrix"), is.numeric(bbox), noNA(bbox),
              ncol(bbox) == 2, nrow(bbox) >= 1,
              all(bbox[, 1] < bbox[, 2]), inherits(cellsize, "numeric"),
              noNA(cellsize), all(cellsize > 0),
              length(cellsize) == 1 | length(cellsize) == nrow(bbox))
  if (length(cellsize) < nrow(bbox)) {
    cellsize <- rep(cellsize, nrow(bbox))
  }
  max(ceiling(log2(apply(bbox, 1, diff) / cellsize)))
}

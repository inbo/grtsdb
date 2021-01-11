
<!-- README.md is generated from README.Rmd. Please edit that file -->

# grtsdb

<!-- badges: start -->

[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
![GitHub](https://img.shields.io/github/license/inbo/grtsdb) [![R build
status](https://github.com/inbo/grtsdb/workflows/R-CMD-check/badge.svg)](https://github.com/inbo/grtsdb/actions)
[![Codecov test
coverage](https://codecov.io/gh/inbo/grtsdb/branch/master/graph/badge.svg)](https://codecov.io/gh/inbo/grtsdb?branch=master)
![GitHub code size in
bytes](https://img.shields.io/github/languages/code-size/inbo/grtsdb.svg)
![GitHub repo
size](https://img.shields.io/github/repo-size/inbo/grtsdb.svg)
<!-- badges: end -->

The goal of `grtsdb` is to create as statially balanced sample based on
the ‘Generalised Random Tesselation Stratified’ strategy. We store the
base schema in an SQLite database. Store this database to make the
sampling reproducible. Sampling the same database with the same
parameters yields a stable sample.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("inbo/grtsdb")
```

## Example

This is a basic example.

``` r
library(grtsdb)
```

Connect to a database.

``` r
db <- connect_db(system.file("grts.sqlite", package = "grtsdb"))
```

To extract a sample, you’ll need to specify the bounding box in
projected coordinates and the size of the grid cells.

``` r
bbox <- rbind(
  c(0, 32),
  c(0, 32)
)
extract_sample(grtsdb = db, samplesize = 10, bbox = bbox, cellsize = 1)
#> Creating index for level 5. May take some time... Done.
#>     x1c  x2c ranking
#> 1  22.5 21.5       0
#> 2  26.5  1.5       1
#> 3   3.5 23.5       2
#> 4  10.5  8.5       3
#> 5  24.5 18.5       4
#> 6  16.5  2.5       5
#> 7  10.5 30.5       6
#> 8   9.5  5.5       7
#> 9  24.5 31.5       8
#> 10 27.5 12.5       9
```

Repeating the sample yields the same results.

``` r
extract_sample(grtsdb = db, samplesize = 10, bbox = bbox, cellsize = 1)
#>     x1c  x2c ranking
#> 1  22.5 21.5       0
#> 2  26.5  1.5       1
#> 3   3.5 23.5       2
#> 4  10.5  8.5       3
#> 5  24.5 18.5       4
#> 6  16.5  2.5       5
#> 7  10.5 30.5       6
#> 8   9.5  5.5       7
#> 9  24.5 31.5       8
#> 10 27.5 12.5       9
```

You can add legacy sites to the sampling scheme.

``` r
legacy <- rbind(
  c(4, 4),
  c(17, 6)
)
add_legacy_sites(legacy, bbox = bbox, cellsize = 1, grtsdb = db)
extract_legacy_sample(grtsdb = db, samplesize = 10, bbox = bbox, cellsize = 1)
#> Creating index for legacy level 5. May take some time... Done.
#>     x1c  x2c ranking
#> 1  16.5  6.5       0
#> 2   4.5  4.5       1
#> 3   3.5 23.5       2
#> 4  22.5 21.5       3
#> 5  26.5  1.5       4
#> 6   9.5  5.5       5
#> 7  10.5 30.5       6
#> 8  24.5 18.5       7
#> 9  27.5 12.5       8
#> 10  2.5 15.5       9
```

You can compact the database for storage.

``` r
compact_db(db)
```

Disconnect the database when done.

``` r
dbDisconnect(db)
```

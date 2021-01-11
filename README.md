
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

This is a basic example. For demonstration purposes, we store the
database in memory. In practice you should store the database on a hard
drive an archive it.

``` r
library(grtsdb)
# connect database
db <- connect_db(":memory:")
# bounding box of the target area
bbox <- rbind(
  c(0, 100),
  c(0, 100)
)
extract_sample(grtsdb = db, samplesize = 20, bbox = bbox, cellsize = 1)
#> Creating index for level 7. May take some time...Adding level 1: create table, add coordinates, calculate ranking
#> Adding level 2: create table, add coordinates, calculate ranking
#> Adding level 3: create table, add coordinates, calculate ranking
#> Adding level 4: create table, add coordinates, calculate ranking
#> Adding level 5: create table, add coordinates, calculate ranking
#> Adding level 6: create table, add coordinates, calculate ranking
#> Adding level 7: create table, add coordinates, calculate ranking
#>  Done.
#>     x1c  x2c ranking
#> 1  50.5 70.5       0
#> 2  41.5 65.5       2
#> 3  33.5 41.5       3
#> 4  81.5 95.5       4
#> 5  99.5 62.5       8
#> 6  66.5 37.5       9
#> 7  23.5  9.5      11
#> 8  77.5 54.5      16
#> 9  45.5 72.5      18
#> 10 38.5 49.5      19
#> 11 57.5  7.5      21
#> 12 30.5 85.5      22
#> 13 11.5 42.5      23
#> 14 91.5 62.5      24
#> 15 61.5 39.5      25
#> 16 37.5  3.5      27
#> 17 89.5 22.5      29
#> 18 17.5 14.5      31
#> 19 70.5 67.5      32
#> 20 97.5 10.5      33
```

Repeating the sample yields the same results

``` r
extract_sample(grtsdb = db, samplesize = 20, bbox = bbox, cellsize = 1)
#>     x1c  x2c ranking
#> 1  50.5 70.5       0
#> 2  41.5 65.5       2
#> 3  33.5 41.5       3
#> 4  81.5 95.5       4
#> 5  99.5 62.5       8
#> 6  66.5 37.5       9
#> 7  23.5  9.5      11
#> 8  77.5 54.5      16
#> 9  45.5 72.5      18
#> 10 38.5 49.5      19
#> 11 57.5  7.5      21
#> 12 30.5 85.5      22
#> 13 11.5 42.5      23
#> 14 91.5 62.5      24
#> 15 61.5 39.5      25
#> 16 37.5  3.5      27
#> 17 89.5 22.5      29
#> 18 17.5 14.5      31
#> 19 70.5 67.5      32
#> 20 97.5 10.5      33
```

You can add legacy sites to the sampling scheme.

``` r
legacy <- rbind(
  c(25, 25),
  c(51, 12)
)
add_legacy_sites(legacy, bbox = bbox, cellsize = 1, grtsdb = db)
extract_legacy_sample(grtsdb = db, samplesize = 20, bbox = bbox, cellsize = 1)
#> Creating index for legacy level 7. May take some time... Done.
#>     x1c  x2c ranking
#> 1  50.5 12.5       0
#> 2  24.5 24.5       1
#> 3  41.5 65.5       2
#> 4  50.5 70.5       3
#> 5  81.5 95.5       7
#> 6  66.5 37.5       8
#> 7  23.5  9.5       9
#> 8  99.5 62.5      11
#> 9  38.5 49.5      17
#> 10 45.5 72.5      18
#> 11 77.5 54.5      19
#> 12 11.5 42.5      21
#> 13 30.5 85.5      22
#> 14 61.5 39.5      24
#> 15 37.5  3.5      25
#> 16 91.5 62.5      27
#> 17 89.5 22.5      28
#> 18 17.5 14.5      29
#> 19 75.5 11.5      32
#> 20 47.5 24.5      33
```

Disconnect database when done.

``` r
dbDisconnect(db)
```

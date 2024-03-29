% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/extract_legacy_sample.R
\name{extract_legacy_sample}
\alias{extract_legacy_sample}
\title{Extract the GRTS sample with legacy sites}
\usage{
extract_legacy_sample(
  grtsdb = connect_db(),
  samplesize,
  bbox,
  cellsize,
  verbose = TRUE,
  offset
)
}
\arguments{
\item{grtsdb}{the grtsdb object}

\item{samplesize}{the required sample size}

\item{bbox}{A two-column matrix.
The first column has the minimum, the second the maximum values.
Rows represent the spatial dimensions.}

\item{cellsize}{The size of each cell.
Either a single value or one value for each dimension.}

\item{verbose}{Display progress}

\item{offset}{An optional number of samples to skip.
This is useful in cases where you need extra samples.}
}
\description{
Extract the GRTS sample with legacy sites
}
\seealso{
Other legacy: 
\code{\link{add_legacy_sites}()},
\code{\link{drop_legacy_sites}()}
}
\concept{legacy}

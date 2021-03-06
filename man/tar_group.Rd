% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tar_group.R
\name{tar_group}
\alias{tar_group}
\title{Group a data frame to iterate over subsets of rows.}
\usage{
tar_group(x)
}
\arguments{
\item{x}{Grouped data frame from \code{dplyr::group_by()}}
}
\value{
A data frame with a special \code{tar_group} column that
\code{targets} will use to find subsets of your data frame.
}
\description{
Like \code{dplyr::group_by()}, but for patterns.
\code{tar_group()} allows you to map or cross over subsets of data frames.
Requires \code{iteration = "group"} on the target. See the example.
}
\details{
The goal of \code{tar_group()} is to post-process the return value
of a data frame target to allow downstream targets to branch over
subsets of rows. It takes the groups defined by \code{dplyr::group_by()}
and translates that information into a special \code{tar_group} is a column.
\code{tar_group} is a vector of consecutive positive integers
from 1 to the number of groups. Rows with the same value of \code{tar_group}
belong to the same group.
}
\examples{
\dontrun{
# The tar_group() function simply creates
# a tar_group column to partition the rows
# of a data frame.
data.frame(
  x = seq_len(6),
  id = rep(letters[seq_len(3)], each = 2)
) \%>\%
  dplyr::group_by(id) \%>\%
  tar_group()
# We use tar_group() below to branch over
# subsets of a data frame defined with dplyr::group_by().
tar_dir({
tar_script({
library(dplyr)
tar_pipeline(
  tar_target(
    data,
    data.frame(
      x = seq_len(6),
      id = rep(letters[seq_len(3)], each = 2)
    ) \%>\%
      group_by(id) \%>\%
      tar_group(),
    iteration = "group"
  ),
  tar_target(
    sums,
    sum(data$x),
    pattern = map(data),
    iteration = "vector"
  )
)
})
tar_make()
tar_read(sums) # Should be c(3, 7, 11).
})
}
}

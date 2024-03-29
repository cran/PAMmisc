% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/straightPath.R
\name{straightPath}
\alias{straightPath}
\title{Mark Straight Path Segments in GPS Track}
\usage{
straightPath(gps, nSmall = 10, nLarge = 60, thresh = 10, plot = FALSE)
}
\arguments{
\item{gps}{gps data with columns Longitude, Latitude, and UTC (POSIX format).
Usually this has been read in from a Pamguard database, in which case columns
Heading and Speed will also be used.}

\item{nSmall}{number of points to average to get ship's current heading}

\item{nLarge}{number of points to average to get ship's longer trend heading}

\item{thresh}{the amount which \code{nSmall} and \code{nBig} should differ by to
call this a turn}

\item{plot}{logical flag to plot result, \code{gps} must also have columns
Latitude and Longitude}
}
\value{
the original dataframe \code{gps} with an added logical column
  \code{straight} indicating which portions are approximately straight
}
\description{
This function attempts to mark portions of a GPS track where a
  ship is traveling in a straight line by comparing the recent average
  heading with a longer term average heading. If these are different, then the
  ship should be turning. Note this currently does not take in to account time,
  only number of points
}
\examples{

gps <- data.frame(Latitude = c(32, 32.1, 32.2, 32.2, 32.2),
                  Longitude = c(-110, -110.1, -110.2, -110.3, -110.4),
                  UTC = as.POSIXct(c('2000-01-01 00:00:00', '2000-01-01 00:00:10',
                                     '2000-01-01 00:00:20', '2000-01-01 00:00:30',
                                     '2000-01-01 00:00:40')),
                  Heading = c(320, 320, 270, 270, 270),
                  Speed = c(.8, .8, .5, .5, .5))

straightPath(gps, nSmall=1, nLarge=2)

straightPath(gps, nSmall=1, nLarge=4)

}
\author{
Taiki Sakai \email{taiki.sakai@noaa.gov}
}

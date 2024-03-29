% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/addPgGps.R
\name{addPgGps}
\alias{addPgGps}
\title{Add GPS to a Pamguard Database}
\usage{
addPgGps(
  db,
  gps,
  source = c("csv", "SPOTcsv", "SPOTgpx"),
  format = c("\%m/\%d/\%Y \%H:\%M:\%S", "\%m-\%d-\%Y \%H:\%M:\%S",
    "\%Y/\%m/\%d \%H:\%M:\%S", "\%Y-\%m-\%d \%H:\%M:\%S"),
  tz = "UTC"
)
}
\arguments{
\item{db}{database file to add gps data to}

\item{gps}{data.frame of gps data or a character of the file name to be read. If a
data.frame or non-SPOT csv file, needs columns \code{UTC}, \code{Latitude}, and \code{Longitude}.
If multiple separate tracks are present in the same dataset, this should be marked with
a column labeled \code{Name}}

\item{source}{one of \code{SPOTcsv}, \code{SPOTgpx}, or \code{csv}. Describes the
source of the GPS data, not needed if \code{gps} is a data.frame}

\item{format}{date format for converting to POSIXct, only needed for \code{source='csv'}.
See \link{strptime}}

\item{tz}{timezone of gps source being added, will be converted to UTC}
}
\value{
Adds to the database \code{db}, invisibly returns the \code{Name} of the GPS track
  if successful (\code{NA} if not named)
}
\description{
Add GPS data to an existing Pamguard database
}
\examples{
\dontrun{
# not run because example files don't exist
myDb <- 'PamguardDatabase.sqlite3'
# adding from a .gpx file downloaded from SPOT
spotGpx <- 'SpotGPX.gpx'
addPgGps(myDb, spotGpx, source='SPOTgpx')
# adding from a csv file with a Y-M-D H:M date format
gpsCsv <- 'GPS.csv'
addPgGps(myDb, gpsCsv, source='csv', format='\%Y-\%m-\%d \%H:\%M')
}

}
\author{
Taiki Sakai \email{taiki.sakai@noaa.gov}
}

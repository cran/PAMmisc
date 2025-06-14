#' @title Format URL for Environmental Data Download
#'
#' @description This creates a properly formatted URL for downloading environmental
#'   data either from an ERDDAP or HYCOM server. This URL can be pasted into a browser
#'   or submitted to something like httr::GET to actually download the data. Also see
#'   \link{edinfoToURL}
#'
#' @param base the base URL to download from
#' @param dataset the specific datased ID to download
#' @param fileType the type of file to download, usually a netcdf
#' @param vars a vector of variables to download
#' @param ranges a list of three vectors specifying the range of data to download,
#'   must a list with named vectors \code{Longitude}, \code{Latitude}, and \code{UTC}
#'   where each vector is \code{c(min, max)} (Note: even if the time is something like
#'   "dayOfYear" this should still be called 'UTC' for the purpose of this list).
#'   (see \link{dataToRanges}).
#' @param stride the stride for all dimensions, a value of 1 gets every data point,
#'   2 gets every other, etc.
#' @param style either \code{'erddap'} or \code{'hycom'}
#'
#' @author Taiki Sakai \email{taiki.sakai@@noaa.gov}
#'
#' @return a properly formatted URL that can be used to download environmental data
#'
#' @examples
#'
#' formatURL(
#'     base = "https://upwell.pfeg.noaa.gov/erddap/griddap/",
#'     dataset = "jplMURSST41",
#'     fileType = "nc",
#'     vars = "analysed_sst",
#'     ranges = list(
#'                Latitude = c(30, 31),
#'                Longitude = c(-118, -117),
#'                UTC = as.POSIXct(c('2005-01-01 00:00:00', '2005-01-02 00:00:00'), tz='UTC')
#'              ),
#'     stride=1,
#'     style = 'erddap'
#' )
#'
#' @importFrom lubridate with_tz
#' @export
#'
formatURL <- function(base, dataset, fileType, vars, ranges, stride=1, style = c('erddap', 'hycom')) {
    # ranges are time, lat, long
    switch(style,
           'erddap' = fmtURL_erddap(base, dataset, fileType, vars, ranges, stride),
           'hycom' = fmtURL_hycom(base, dataset, fileType, vars, ranges, stride),
           stop('I dont know how to deal with style', style, '.')
    )
}

fmtURL_erddap <- function(base, dataset, fileType, vars, ranges, stride) {
    # erd naming convention is nc
    if(fileType == 'netcdf') {
        fileType <- 'nc'
    }
    if(grepl('tabledap', base)) {
        return(fmtURL_tabledap(base, dataset, fileType, vars, ranges))
    }
    allRanges <- fmtRange_erddap(ranges, stride, html=FALSE)
    # doing this in erddapToEdinfo now to acct for tabledaps
    # base <- gsub('/$', '', base)
    # base <- paste0(base, '/griddap/')
    paste0(base,
           dataset,
           '.', fileType, '?',
           paste0(vars, allRanges, collapse=',')
    )
}

fmtURL_tabledap <- function(base, dataset, fileType, vars, ranges) {
    # if(inherits(ranges, 'POSIXct')) {
    #     fmtPsx8601(ranges$UTC, html=TRUE)
    # }
    varPart <- paste0(c(names(ranges), vars), collapse='%2C')
    rangePart <- character(0)
    for(r in names(ranges)) {
        # only doing stationary so dont worry about coord subsetting
        # will unintentionally rule out times where our data is just to side
        # of stationary unit
        if(standardCoordNames(r) %in% c('Latitude', 'Longitude')) {
            next
        }
        if(inherits(ranges[[r]], 'POSIXct')) {
            ranges[[r]] <- fmtPsx8601(ranges[[r]], html=TRUE)
        }
        first <- paste0('&',
                        r,
                        '%3E=',
                        ranges[[r]][1]
        )
        second <- paste0('&',
                         r,
                         '%3C=',
                         ranges[[r]][2]
        )
        rangePart <- paste0(rangePart, first, second)
    }
    paste0(
        base,
        dataset,
        '.', fileType, '?',
        varPart,
        rangePart
    )
}

fmtURL_hycom <- function(base, dataset, fileType, vars, ranges, stride) {
    # hycom naming convention is netcdf
    if(fileType == 'nc') {
        fileType <- 'netcdf'
    }
    allRanges <- fmtRange_hycom(ranges, stride)
    paste0(base,
           dataset,
           '?', paste0('var=', vars, collapse = '&'),
           allRanges,
           '&accept=', fileType)
}

fmtRange_hycom <- function(ranges, stride=1, html=TRUE) {
    # hycom go do sad if them equals
    for(c in c('Latitude', 'Longitude')) {
        if(ranges[[c]][1] == ranges[[c]][2]) {
            ranges[[c]] <- ranges[[c]] + c(-.001, .001)
        }
    }
    if('Depth' %in% names(ranges)) {
        if(all(ranges[['Depth']] == 0)) {
            ranges[['Depth']] <- 1
        } else {
            ranges[['Depth']] <- NULL
        }
    }
    # time / lat[lo-hi] / long[left-right]
    paste0('&north=', ranges[['Latitude']][2],
           '&west=', ranges[['Longitude']][1],
           '&east=', ranges[['Longitude']][2],
           '&south=', ranges[['Latitude']][1],
           '&horizStride=', stride,
           '&time_start=', fmtPsx8601(ranges[['UTC']][1], html=html),
           '&time_end=', fmtPsx8601(ranges[['UTC']][2], html=html),
           '&timeStride=', stride,
           '&vertCoord=', ranges[['Depth']])
}

fmtRange_erddap <- function(ranges, stride=1, html=FALSE) {
    # Change times to proper format
    # expected time lat long
    rngOrder <- c('Latitude', 'Longitude')
    if('Depth' %in% names(ranges)) {
        rngOrder <- c('Depth', rngOrder)
        # ranges <- ranges[c('UTC', 'Depth', 'Latitude', 'Longitude')]
    }
    if('UTC' %in% names(ranges)) {
        rngOrder <- c('UTC', rngOrder)
        # ranges <- ranges[c('UTC', 'Latitude', 'Longitude')]
    }
    ranges <- ranges[rngOrder]
    paste0(sapply(ranges, function(x) {
        if('POSIXct' %in% class(x)) {
            x <- fmtPsx8601(x, html=html)
        }
        paste0('[(',
               x[1],
               '):', stride, ':(',
               x[2],
               ')]')
    }
    ), collapse = '')
}

fmtPsx8601 <- function(date, html = FALSE) {
    if(!('POSIXct' %in% class(date))) stop('Date must be POSIXct')
    result <- format(with_tz(date, 'UTC'), format = '%Y-%m-%dT%H:%M:%SZ')
    if(html) {
        gsub(':', '%3A', result)
    } else {
        result
    }
}

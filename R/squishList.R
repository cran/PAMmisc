#' @title Compress a List by Name
#'
#' @description Attempts to compress a list by combining elements with
#'   the same name, searching recursively if there are lists in your
#'   list
#'
#' @details items with the same name are assumed to have the same structure
#'   and will be combined. Dataframes will be combined with bind_rows, vectors
#'   just be collapsed into one vector, matrices will be combined with rbind,
#'   lists will be combined recursively with another call to \code{squishList}
#'
#' @param myList a list with named elements to be compressed
#' @param unique logical flag to try and reduce result to only unique values
#'
#' @return a list with one element for every unique name in the original list
#'
#' @author Taiki Sakai \email{taiki.sakai@@noaa.gov}
#'
#' @examples
#'
#' myList <- list(a=1:3, b=letters[1:4], a=5:6, b=letters[4:10])
#' squishList(myList)
#'
#' myList <- list(a=1:3, b=data.frame(x=1:3, y=4:6), b=data.frame(x=10:14, y=1:5))
#' squishList(myList)
#'
#' myList <- list(a=list(c=1:2, d=2), b=letters[1:3], a=list(c=4:5, d=6:9))
#' squishList(myList)
#'
#' @importFrom dplyr bind_rows distinct
#' @export
#'
squishList <- function(myList, unique=FALSE) {
    myNames <- unique(names(myList))
    if(is.null(myNames)) return(myList)
    result <- vector('list', length=length(myNames))
    names(result) <- myNames
    for(n in myNames) {
        whichThisName <- which(names(myList)==n)
        thisNameData <- myList[whichThisName]
        # thisClasses <- sapply(thisNameData, class)
        # This is a mess, but oh well.
        result[[n]] <- if(length(whichThisName)==1) {
            thisNameData[[1]]
        # } else if('list' %in% thisClasses) {
        } else if(all(sapply(thisNameData, function(x) inherits(x, 'list')))) {
            thisNameData <- unlist(thisNameData, recursive = FALSE)
            names(thisNameData) <- gsub(paste0(n, '\\.'), '', names(thisNameData))
            squishList(thisNameData, unique)
            # } else if(all(thisClasses=='data.frame')) {
        } else if(all(sapply(thisNameData, function(x) inherits(x, 'data.frame')))) {
            if(isTRUE(unique)) {
                distinct(bind_rows(thisNameData))
            } else {
                bind_rows(thisNameData)
            }
            # } else if(all(thisClasses=='NULL')) {
        } else if(all(sapply(thisNameData, function(x) inherits(x, 'NULL')))) {
            next
        } else if(all(sapply(thisNameData, function(x) inherits(x, 'matrix'))) &&
                  length(unique(sapply(thisNameData, ncol))) == 1) {
            do.call(rbind, thisNameData)
        } else {
            # thisNameData[[1]]
            if(isTRUE(unique)) {
                unique(unlist(thisNameData, use.names = FALSE))
            } else {
                unlist(thisNameData, use.names = FALSE)
            }
        }
    }
    result
}

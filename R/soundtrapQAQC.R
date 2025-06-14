#' @title Perform QA/QC on Soundtrap Files
#'
#' @description Gathers data from Soundtrap XML log files to perform QA/QC on
#'   a set of recordings.
#'
#' @param dir directory containing Soundtrap XML logs, wav files, and SUD files.
#'   Can either be a single directory containing folders with all files (will
#'   search recursively), or a vector of three directories containing the SUD files,
#'   wav files, and XML files (in that order - alphabetical S-W-X)
#' @param outDir if provided, output plots and data will be written to this folder
#' @param xlim date limit for plots
#' @param label label to be used for plots and names of exported files
#' @param voltSelect one of "internal" or "external" to select which battery voltage to use
#' @param plot logical flag to create output plots
#'
#' @return list of dataframes with summary data for \code{$xmlInfo}, \code{$sudInfo},
#'   and \code{$wavInfo}
#'
#' @author Taiki Sakai \email{taiki.sakai@@noaa.gov}
#'
#' @examples
#'
#' \dontrun{
#' # not run
#' stDir <- './Data/SoundtrapFiles/'
#' stData <- soundtrapQAQC(stDir, plot=TRUE)
#' # save data
#' stData <- soundtrapQAQC(stDir, outDir='./Data/SoundtrapFiles/QAQC', plot=TRUE)
#' # or provide separate folders of data
#' stDirs <- c('./Data/SoundtrapFiles/SUDFiles',
#'             './Data/SoundtrapFiles/WavFiles',
#'             './Data/SoundtrapFiles/XMLFiles')
#' stData <- soundtrapQAQC(stDirs, plot=TRUE)
#' }
#'
#' @importFrom xml2 read_xml xml_find_all xml_contents
#' @importFrom graphics axis.POSIXct mtext par
#' @importFrom grDevices dev.off png
#' @importFrom dplyr bind_rows
#'
#' @export
#'
soundtrapQAQC <- function(dir, outDir=NULL, xlim=NULL, label=NULL,
                          voltSelect = c('internal', 'external'), plot=TRUE) {
    if(!is.null(outDir) &&
       !dir.exists(outDir)) {
        dir.create(outDir)
    }
    if(length(dir) == 1) {
        allFiles <- list.files(dir, recursive=TRUE, full.names=TRUE, pattern='sud$|wav$|xml$')
        wavFiles <- allFiles[grepl('wav$', allFiles)]
        xmlFiles <- allFiles[grepl('xml$', allFiles)]
        sudFiles <- allFiles[grepl('sud$', allFiles)]
    } else if(length(dir) == 3) {
        sudFiles <- list.files(dir[1], recursive=TRUE, full.names=TRUE, pattern='sud$')
        wavFiles <- list.files(dir[2], recursive=TRUE, full.names=TRUE, pattern='wav$')
        xmlFiles <- list.files(dir[3], recursive=TRUE, full.names=TRUE, pattern='xml$')
    } else {
        stop('"dir" must be length 1 or 3.')
    }
    xmlInfo <- processSoundtrapLogs(xmlFiles, voltSelect)
    sudInfo <- data.frame(sudName=basename(sudFiles),
                          sudSize = sapply(sudFiles, file.size))
    wavInfo <- data.frame(wavName=basename(wavFiles),
                          wavSize = sapply(wavFiles, file.size))
    outs <- list(xmlInfo=xmlInfo, sudInfo=sudInfo, wavInfo=wavInfo)
    if(plot) {
        doQAQCPlot(outs, outDir=outDir, xlim=xlim, label=label, voltSelect = voltSelect)
    }
    if(!is.null(outDir)) {
        saveRDS(outs, file=file.path(outDir, paste0(label, '_Data.rds')))
    }
    outs
}

doQAQCPlot <- function(x, outDir=NULL, xlim=NULL, label=NULL, voltSelect=c('internal', 'external')) {
    # Can only plot these if num files is equal
    xmlInfo <- x$xmlInfo
    sudInfo <- x$sudInfo
    wavInfo <- x$wavInfo
    if(length(voltSelect) > 1) {
        voltSelect <- modelToVoltSelect(xmlInfo$model[1])
    }
    voltSelect <- match.arg(voltSelect)
    if(is.null(xlim)) {
        xlim <- range(xmlInfo$startUTC)
    }
    # Battery/ Temperature plot
    ## set up some fake test data
    ## add extra space to right margin of plot within frame
    if(!is.null(outDir)) {
        png(filename=file.path(outDir, paste0(label, '_TV.png')), width=6, height=4, units='in', res=300)
    }
    op <- par(mar=c(5, 4, 4, 6) + 0.1)
    on.exit(par(op))
    battLab <- switch(voltSelect,
                      'internal' = 'Internal Battery, V',
                      'external' = 'External Battery, V'
    )
    ## Plot first set of data and draw its axis
    plot(x=xmlInfo$startUTC, y=xmlInfo$batt,
         xaxt='n', yaxt='n', xlab="", ylab="", type="l",col="darkblue")
    mtext(battLab,side=2, col='darkblue', line=3)
    axis(2, ylim=xmlInfo$temp,las=1, col='darkblue', col.axis='darkblue')
    title(label)
    par(new=TRUE)

    plot(x=xmlInfo$startUTC, y=xmlInfo$temp,
         xlab="", ylab="", xaxt='n', yaxt='n', type='l', col='darkorange')

    mtext("Internal Temperature, C",side=4,line=3.5, col='darkorange')
    axis(4, ylim=xmlInfo$temp,las=1, col='darkorange', col.axis='darkorange')
    axis.POSIXct(1, x=xlim, format='%b-%d')

    par(op)
    on.exit()

    if(!is.null(outDir)) {
        dev.off()
        png(filename=file.path(outDir, paste0(label, '_GAPS.png')), width=6, height=4, res=300, units='in')
    }
    # Time gap plot
    fileGap <- xmlInfo$startUTC[2:nrow(xmlInfo)] - xmlInfo$endUTC[1:(nrow(xmlInfo)-1)]
    plot(x=xmlInfo$startUTC[1:(nrow(xmlInfo)-1)], y=fileGap/3600,
         ylab='Hours', xaxt='n', xlab='', col='darkblue')
    axis.POSIXct(1, x=xlim, format='%b-%d')
    title('Time gap between files')

    # Mulitpanel Plot
    doSud <- nrow(xmlInfo) == nrow(sudInfo)
    doWav <- nrow(xmlInfo) == nrow(wavInfo)
    nPlots <- 6 + doSud + doWav
    if(!is.null(outDir)) {
        dev.off()
        png(filename=file.path(outDir, paste0(label, '_QC.png')), width=12, height=3*(ceiling(nPlots/2)), res=300, units='in')
        on.exit(dev.off())
    }
    op <- par(mfrow=c(ceiling(nPlots/2), 2), mar=c(2.1, 4.1, 2.1, 2.1))
    on.exit(par(op))
    # 1 sud size plot
    if(doSud) {
        plot(x=xmlInfo$startUTC, y=sudInfo$sudSize/(1024^3),
             ylab='Gb', type='l', col='darkblue', xlim=xlim, xaxt='n', xlab='')
        title('Size of compressed files')
    }
    # 2 wav size plot
    if(doWav) {
        plot(x=xmlInfo$startUTC, y=wavInfo$wavSize/(1024^3),
             ylab='Gb', type='l', col='darkblue', xlim=xlim, xaxt='n', xlab='')
        title('Size of wav files')
    }
    # 3 period plot
    plot(x=xmlInfo$startUTC, y=xmlInfo$period,
         ylab='Hours', type='l', col='darkblue', xlim=xlim, xaxt='n', xlab='')
    title('Sampling Time Period')
    # 4 count/s plot
    plot(x=xmlInfo$startUTC, y=xmlInfo$sampleCount/(xmlInfo$period*1e-6),
         ylab='Samples/sec', type='l', col='darkblue', xlim=xlim, xaxt='n', xlab='')
    title('SampleCount / SampleTimePeriod')
    # 5 count plot
    plot(x=xmlInfo$startUTC, y=xmlInfo$sampleCount,
         ylab='Samples', type='l', col='darkblue', xlim=xlim, xaxt='n', xlab='')
    title('Number of samples per file')
    # 6 Time diff plot
    dt <- as.numeric(difftime(xmlInfo$endUTC, xmlInfo$startUTC, units='secs'))
    plot(x=xmlInfo$startUTC, y=xmlInfo$period*1e-6 - dt,
         ylab='Seconds', type='l', col='darkblue', xlim=xlim, xaxt='n', ylim=c(-1, 1), xlab='')
    title('SampTimePeriod - (DateStop - DateStart)')
    # 7 samp Gap plot
    par(mar=c(5.1, 4.1, 3.1, 2.1))
    if(all(is.na(xmlInfo$gap))) {
        xmlInfo$gap <- 0
        sampGapTitle <- 'Cumulative Sampling Gap (ALL WERE "NA")'
    } else {
        sampGapTitle <- 'Cumulative Sampling Gap'
    }
    plot(x=xmlInfo$startUTC, y=xmlInfo$gap*1e-6,
         ylab='Seconds', type='l', col='darkblue', xlim=xlim, xaxt='n', xlab='')
    axis.POSIXct(1, x=xlim, format='%b-%d')
    title(sampGapTitle)
    # 8 file gap plot

    plot(x=xmlInfo$startUTC[1:(nrow(xmlInfo)-1)], y=fileGap,
         ylab='Seconds', type='l', col='darkblue', xlim=xlim, xaxt='n', xlab='')
    axis.POSIXct(1, x=xlim, format='%b-%d')
    title('Gaps between files')
    if(!is.null(outDir)) {
        dev.off()
    }
}

modelToVoltSelect <- function(x) {
    if(x %in% c('ST4300')) {

    }
    if(x %in% c('ST640')) {

    }
    'internal'
}

#' @export
#' @rdname soundtrapQAQC
#'
processSoundtrapLogs <- function(dir, voltSelect=c('internal', 'external')) {
    if(is.character(dir)) {
        if(length(dir) == 1 && dir.exists(dir)) {
            dir <- list.files(dir, pattern='xml$', full.names=TRUE)
        }
        if(length(dir) > 1) {
            return(
                bind_rows(lapply(dir, processSoundtrapLogs, voltSelect=voltSelect))
            )
        }
        tryXml <- try(read_xml(dir))
        if(inherits(tryXml, 'try-error')) {
            warning('Unable to read file ', dir)
            return(NULL)
        }
        xml <- tryXml
    }
    if(!inherits(xml, 'xml_document')) {
        return(NULL)
    }
    result <- list()
    
    # try for auto-select based on HARDWARE_ID
    hardwareNode <- xml_find_all(xml, '//HARDWARE_ID')
    result$model <- as.character(gsub(' ', '', xml_contents(hardwareNode)))
    # decide based on model if appropriate
    if(length(voltSelect) > 1) {
        voltSelect <- modelToVoltSelect(result$model)
    }
    voltNode <- switch(match.arg(voltSelect),
                       'internal' = '//INT_BATT',
                       'external' = '//EX_BATT'
    )
    startNode <- xml_find_all(xml, '//@SamplingStartTimeUTC')
    if(length(startNode) > 0) {
        result$startUTC <- stToPosix(as.character(xml_contents(startNode)))
    } else {
        result$startUTC <- NA
    }
    endNode <- xml_find_all(xml, '//@SamplingStopTimeUTC')
    if(length(endNode) > 0) {
        result$endUTC <- stToPosix(as.character(xml_contents(endNode)))
    } else {
        result$endUTC <- NA
    }
    # voltSelect internal or external, change to //INT_BATT
    battNode <- xml_find_all(xml, voltNode)
    if(length(battNode) > 0) {
        result$batt <- as.numeric(gsub(' ', '', as.character(xml_contents(battNode)))) * .001
    } else {
        result$batt <- NA
    }
    # voltSelect internal or external, change to //INT_BATT
    intBattNode <- xml_find_all(xml, '//INT_BATT')
    if(length(intBattNode) > 0) {
        result$intBatt <- as.numeric(gsub(' ', '', as.character(xml_contents(intBattNode)))) * .001
    } else {
        result$intBatt <- NA
    }
    # voltSelect internal or external, change to //INT_BATT
    extBattNode <- xml_find_all(xml, '//EX_BATT')
    if(length(extBattNode) > 0) {
        result$extBatt <- as.numeric(gsub(' ', '', as.character(xml_contents(extBattNode)))) * .001
    } else {
        result$extBatt <- NA
    }
    tempNode <- xml_find_all(xml, '//TEMPERATURE')
    if(length(tempNode) > 0) {
        result$temp <- as.numeric(gsub(' ', '', as.character(xml_contents(tempNode)))) * .01
    } else {
        result$temp <- NA
    }
    gapNode <- xml_find_all(xml, '//@CumulativeSamplingGap')
    if(length(gapNode) > 0) {
        result$gap <- as.numeric(gsub('\\s*us$', '', as.character(xml_contents(gapNode))))
    } else {
        result$gap <- NA
    }
    periodNode <- xml_find_all(xml, '//@SamplingTimePeriod')
    if(length(periodNode) > 0) {
        result$period <- as.numeric(gsub('\\s*us$', '', as.character(xml_contents(periodNode))))
    } else {
        result$period <- NA
    }
    sampleNode <- xml_find_all(xml, '//@SampleCount')
    if(length(sampleNode) > 0) {
        result$sampleCount <- as.numeric(as.character(xml_contents(sampleNode)))
    } else {
        result$sampleCount <- NA
    }
    result$fileName <- basename(dir)
    result$fileTime <- stFileToPosix(dir)
    result
}

stToPosix <- function(x) {
    parse_date_time(x, orders=c('%Y-%m-%dT%H:%M:%S', '%m/%d/%Y %I:%M:%S %p'), tz='UTC', exact=TRUE)
}

stFileToPosix <- function(x) {
    x <- basename(x)
    format <- '%y%m%d%H%M%S'
    as.POSIXct(gsub('(.*\\.)([0-9]{12})\\..*$', '\\2', x), format=format, tz='UTC')
}

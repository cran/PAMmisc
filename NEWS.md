# PAMmisc 1.6.5

* Bug fixes for `updateUID`. Will check for "ClickNo" column first if that is more accurate,
and will not update a UID if it is matching based on time and there is more than one match

* Changed database testing to work on copied file in tmpdir for CRAN checks

# PAMmisc 1.6.4

* Added `updateUID` function to try and realign UID mismatches in Pamguard databases
between event detections and their corresponding binary files

# PAMmisc 1.6.3

* Changed `addPgGps` to use `parse_date_time` for date conversions to allow
for truncated date formats to be properly parsed because thanks Excel for
rounding those dates didn't need to know there were 0 seconds anyway

* `matchEnvData` not propagating `progress` argument properly

# PAMmisc 1.6.2

* Checks in database adding function to make sure file exists

* `writeAMWave` example resets par() settings to original

# PAMmisc 1.6.1

* Added a `NEWS.md` file to track changes to the package.

* Fixing `addPgGps` for spot CSVs

* Tons of documentation in prep of CRAN

* Added files in inst/extdata for testing

* Adding lots of unit testing

# PAMmisc 1.6.0 

* Whoa, environmental data functions might work fine for crossing the dateline now.

* `getFittedMap` also removed because `ggmap` package has been orphaned.

# PAMmisc 1.5.0 

*Added `addPgGps` to add GPS data to a Pamguard database

# PAMmisc 1.4.1 

* Internal changes to make `matchEnvData` a generic method so can write methods
for non-dataframe sources easier

# PAMmisc 1.4.0 

* Added functions for downloading environmental data and matching it to your
data. Replaced older verison of `formatURL` from v 1.3.0

* New exported functions are `edinfoToURL`, `downloadEnv`, `erddapToEdinfo`, `varSelect`, `getEdinfo`,
`ncToData`, `matchEnvData`, `browseEdinfo`. Updated tutorial to follow later.

# PAMmisc 1.3.1 

* bug fix where `straightPath` was not properly averaging angles. Changed to
polar coordinate style averaging, will now handle angles near the 0-360 border properly

# PAMmisc 1.3.0 

* added `formatURL` functions for making ERDDAP downloading URLs automatically

# PAMmisc 1.2.1 

* minor change in error handling for `peakTrough`

* `writeClickWave` can handle vectors for CPS and frequency

# PAMmisc 1.2.0 

* `writeAMWave` function added to create synthetic amplitude modulated waves

# PAMmisc 1.1.0 

* `addPgEvent` function added to add new events to an existing Pamguard database by
providing a vector of UIDs

# PAMmisc 1.0.4 

* fixed typo that broke `wignerTransform`

# PAMmisc 1.0.3 

* minor change to output of `wignerTransform`, resizes back to length of
original signal

# PAMmisc 1.0.2 

* bug fixed in `decimateWavFiles` when trying to write a folder of files

# PAMmisc 1.0.1 

* `wignerTransform` added

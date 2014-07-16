# RECEIV LON LAT ARGUMENTS AND RETURNS STATE/COUNTY, OR FALSE

suppressPackageStartupMessages(library(sp))
suppressPackageStartupMessages(library(maps))
suppressPackageStartupMessages(library(maptools))

# The single argument to this function, pointsDF, is a data.frame in which:
#   - column 1 contains the longitude in degrees (negative in the US)
#   - column 2 contains the latitude in degrees
lonlat2statecounty <- function(pointsDF) {
  # Prepare SpatialPolygons object with one SpatialPolygon
  # per state (plus DC, minus HI & AK)
  states_counties <- map('county', fill=TRUE, col="transparent", plot=FALSE)
  IDs <- sapply(strsplit(states_counties$names, ":"), function(x) x[1])
  states_counties_sp <- map2SpatialPolygons(states_counties, IDs=IDs,
                                            proj4string=CRS("+proj=longlat +datum=wgs84"))

  # Convert pointsDF to a SpatialPoints object
  pointsSP <- SpatialPoints(pointsDF,
                            proj4string=CRS("+proj=longlat +datum=wgs84"))

  # Use 'over' to get _indices_ of the Polygons object containing each point
  indices <- over(pointsSP, states_counties_sp)

  # Return the state names of the Polygons object containing each point
  states_counties_names <- sapply(states_counties_sp@polygons, function(x) x@ID)
  strsplit(states_counties_names[indices],",")[[1]]
}

ARGV <- commandArgs(trailingOnly = TRUE)

lon_lat <- data.frame(x = as.double(ARGV[1]), y = as.double(ARGV[2]))
state_county <- lonlat2statecounty(lon_lat)

state <- state_county[1]
county <- state_county[2]

# if state not found, returns false
if(is.na(state)) {
  cat('false')
} else {
  # replace D.C. by virginia (more counties withing metropolitan area)
  if(state == 'district of columbia') {
    state <- 'virginia'
  }
  # reply wiuth state/county separated by comma
  cat(paste(state, county, sep=','))
}

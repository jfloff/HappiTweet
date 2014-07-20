# RECEIVE FILE WITH TWEET AS ARGUMENT AND RETURNS A CSV WITH STATE/COUNTY, OR FALSE PER TWEET

suppressPackageStartupMessages(library(sp))
suppressPackageStartupMessages(library(maps))
suppressPackageStartupMessages(library(maptools))
suppressPackageStartupMessages(library(RJSONIO))

# The single argument to this function, pointsDF, is a data.frame in which:
#   - column 1 contains the longitude in degrees (negative in the US)
#   - column 2 contains the latitude in degrees
lonlat2statecounty <- function(pointsDF) {
  # Prepare SpatialPolygons object with one SpatialPolygon
  # per state (plus DC, minus HI & AK)
  states_counties <- map('county', fill=TRUE, col="transparent", plot=FALSE)
  IDs <- sapply(strsplit(states_counties$names, ":"), function(x) x[1])
  states_counties_sp <- map2SpatialPolygons(states_counties, IDs=IDs, proj4string=CRS("+proj=longlat +datum=wgs84"))

  # Convert pointsDF to a SpatialPoints object
  pointsSP <- SpatialPoints(pointsDF, proj4string=CRS("+proj=longlat +datum=wgs84"))

  # Use 'over' to get _indices_ of the Polygons object containing each point
  indices <- over(pointsSP, states_counties_sp)

  indices

  # Return the state names of the Polygons object containing each point
  states_counties_names <- sapply(states_counties_sp@polygons, function(x) x@ID)
  state_county <- states_counties_names[indices]
  # replace Washington D.C. by Virginia-Arlington (according to Gallup-Healthway is the closest to Washington DC community)
  state_county[state_county=='district of columbia,washington'] <- 'virginia,arlington'
  state_county
}

ARGV <- commandArgs(trailingOnly = TRUE)

con  <- file(ARGV[1], open = "r")
# store the data so after we build a data frame
lats <- c()
lons <- c()
# parse json file by line
while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0)
{
  tweet <- fromJSON(line)

  lats <- c(tweet[['coordinates']][['coordinates']][2], lats)
  lons <- c(tweet[['coordinates']][['coordinates']][1], lons)
}
close(con)

# build data frame and write to CSV
states_counties <- lonlat2statecounty(data.frame(x = lons, y = lats))
write(states_counties, file=ARGV[2])

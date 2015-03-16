#!/usr/bin/Rscript

# checks if the package is installed, and it install it if not
# http://stackoverflow.com/a/23286257/1700053
pkgTest <- function(x)
{
  if (!require(x,character.only = TRUE))
  {
    # uses rstudio default cran
    install.packages(x,dep=TRUE,repos="http://cran.rstudio.com/")
    if(!require(x,character.only = TRUE)) stop("Package not found")
  }
}

# Install yaml package so we read the other packages
pkgTest('yaml')

# gets config from config.yaml
config_yaml = yaml.load_file("config.yaml")

# gets working directory
wd = config_yaml$r$working_directory
# sets R environemnt variable with that string
Sys.setenv(R_HAPPITWEET = wd)

# Installs all needed packages
for(package in config_yaml$r$packages)
{
  pkgTest(package)
}

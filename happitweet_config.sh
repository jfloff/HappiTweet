#!/bin/bash

# R_CONFIG temporary filename
RCONFIG_FILENAME="r_config.temp.R"

# R_CONFIG data
cat > $RCONFIG_FILENAME <<EOF
  # checks if the package is installed, and it install it if not
  # http://stackoverflow.com/a/23286257/1700053
  pkgTest <- function(x)
  {
    if (!require(x,character.only = TRUE))
    {
      # uses rstudio default cran
      install.packages(x,dep=TRUE,repos='http://cran.rstudio.com/')
      if(!require(x,character.only = TRUE)) stop('Package not found')
    }
  }

  # Install yaml package so we read the other packages
  pkgTest('yaml')

  # gets config from config.yaml
  config_yaml = yaml.load_file('config.yaml')

  # Installs all needed packages
  for(package in config_yaml[['r']][['packages']])
  {
    pkgTest(package)
  }
EOF

# Run script to install packages 
# I think this is universal to all platforms
# Rscript $RCONFIG_FILENAME &>/dev/null

# change script to return working directory
cat > $RCONFIG_FILENAME <<EOF
  # supresses messages so it doens't return to stdout
  # and still returning the wd at the end
  suppressWarnings(suppressMessages(require('yaml')))

  # gets config from config.yaml
  config_yaml = yaml.load_file('config.yaml')

  # prints working_directory without "[1] " prefix
  cat(config_yaml[['r']][['working_directory']])
EOF

# Run script to get working directory
WD=$(Rscript $RCONFIG_FILENAME)

# OS specific commands
# Use `uname` to know your system details
if [ "$(uname)" == "Darwin" ]; then
  
  # MacOS
  if [ -z "$R_HAPPITWEET" ]; then
    echo 'export R_HAPPITWEET=$WD' >> ~/.bash_profile
    source ~/.bash_profile
  fi

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  
  # Linux
  if [ -z "$R_HAPPITWEET" ]; then
    echo 'export R_HAPPITWEET=$WD' >> ~/.bash_profile
    source ~/.bash_profile
  fi

elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
  # Windows
  cmd //c SETX R_HAPPITWEET "$WD" &>/dev/null
else
  echo "OS not supported. Please change this script to include its identifier."
fi



rm $RCONFIG_FILENAME
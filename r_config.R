#!/usr/bin/Rscript --vanilla

library(yaml)

# gets config from config.yaml
config_yaml = yaml.load_file("config.yaml")
wd = config_yaml$r$working_directory
# sets R environemnt variable with that string
Sys.setenv(R_HAPPITWEET = wd)

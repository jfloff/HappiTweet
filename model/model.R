setwd(Sys.getenv("R_HAPPITWEET"))

source('model/lib.R', echo=FALSE)

# files
gallup_file = "data/gallup_2012.csv"
state_features_file = "data/state_features.csv"
county_features_file = "data/county_features.csv"

############################################################################
############################## BY STATE ####################################
############################################################################

# train model
state_model = model(gallup_file, state_features_file, by_state=TRUE)

# print output
state_model$coefficients
state_model$predictions

# evaluate results
eval_predictions(state_model$predictions)

# compare with baseline
gallup_stats(state_model$predictions$gallup)


############################################################################
############################# BY COUNTY ####################################
############################################################################

# train model
county_model = model(gallup_file, state_features_file, by_state=FALSE, county_features_file=county_features_file)

# print output
county_model$coefficients
county_model$predictions

# evaluate results
eval_predictions(county_model$gallup, county_model$predictions)

# compare with baseline
gallup_stats(county_model$predictions$gallup)
setwd(Sys.getenv("R_HAPPITWEET"))

source('model/lib.R', echo=FALSE)

# files
gallup_file = "data/gallup_2012.csv"
state_features_file = "model-output/state_features.csv"
county_features_file = "model-output/county_features.csv"

# output
state_predictions_file = "model-output/state_predictions.csv"
state_coefficients_file = "model-output/state_coefficients.csv"
county_predictions_file = "model-output/county_predictions.csv"
county_coefficients_file = "model-output/county_coefficients.csv"

############################################################################
############################## BY STATE ####################################
############################################################################

# train model
state_model = model(gallup_file, state_features_file, by_state=TRUE)

# print output
state_model$coefficients
state_model$predictions

# write output files
write.csv(state_model$predictions, file=state_predictions_file, row.names=FALSE)
write.csv(tail(state_model$coefficients, n=-1), file=state_coefficients_file, row.names=FALSE)

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

# write output files
write.csv(county_model$predictions, file=county_predictions_file, row.names=FALSE)
write.csv(tail(county_model$coefficients, n=-1), file=county_coefficients_file, row.names=FALSE)

setwd(Sys.getenv("R_HAPPITWEET"))

source('model/lib.R', echo=FALSE)

############################################################################
############################## BY STATE ####################################
############################################################################

score_features_state = score_features(file="huge-data/scored.json", by_state=TRUE)

tweets_count_features_state = tweets_count_features(file="huge-data/scored.json", 
                                       all_file="huge-data/all_state_county.json", 
                                       by_state=TRUE)

mean_words_features_state = mean_words_features(file="huge-data/scored.json", by_state=TRUE)


state_features = merge_features(list(score_features_state, tweets_count_features_state, mean_words_features_state))

write.csv(file="huge-data/state_features.csv", x=state_features)

############################################################################
############################# BY COUNTY ####################################
############################################################################

score_features_county = score_features(file="huge-data/scored.json", by_state=FALSE)

tweets_count_features_county = tweets_count_features(file="huge-data/scored.json", 
                                       all_file="huge-data/all_state_county.json", 
                                       by_state=FALSE)

mean_words_features_county = mean_words_features(file="huge-data/scored.json", by_state=FALSE)

county_features = merge_features(list(score_features_county, tweets_count_features_county, mean_words_features_county))

write.csv(file="huge-data/county_features.csv", x=county_features)
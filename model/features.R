setwd(Sys.getenv("R_HAPPITWEET"))

source('lib/lib.R', echo=FALSE)

############################################################################
############################## BY STATE ####################################
############################################################################

score_features = score_features(file="huge-data/scored.json", by_state=TRUE)

count_features = tweets_count_features(file="huge-data/scored.json", 
                                       all_file="huge-data/all_state_county.json", 
                                       by_state=TRUE)

word_count_features <- mean_words_features(file="huge-data/scored.json", by_state=TRUE)


# state_features <- merge_features(features = list(features_1, features_10))


############################################################################
############################# BY COUNTY ####################################
############################################################################

score_features_county = score_features(file="huge-data/scored.json", by_state=FALSE)

count_features_county = tweets_count_features(file="huge-data/scored.json", 
                                       all_file="huge-data/all_state_county.json", 
                                       by_state=false)

word_count_features_county <- mean_words_features(file="huge-data/scored.json", by_state=FALSE)



#counties_features <- merge_features(features = list(features_1_county, features_10_county, features_7_county))


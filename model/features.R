setwd(Sys.getenv("R_HAPPITWEET"))

source('lib/lib.R', echo=FALSE)

############################################################################
############################## BY STATE ####################################
############################################################################

features_1 = to_state_county_score("huge-data/scored.json")
# features_1 <- score_features(file="data/scored.json", by_state=TRUE)

# ....
#features_7 <- tweets_count_features(file="data/us_tweets_with_score", all_file="data/us_tweets", by_state=TRUE)
# ....
# features_10 <- mean_words_features(file="~/non_neutral_data_test_subset", by_state=TRUE)
# ....

#state_features <- merge_features(features = list(features_1, features_10, features_7))
# state_features <- merge_features(features = list(features_1, features_10))


############################################################################
############################# BY COUNTY ####################################
############################################################################

#features_1_county <- score_features(file="data/us_tweets_with_score", by_state=FALSE)
# ....
#features_7_county <- tweets_count_features(file="data/us_tweets_with_score", all_file="data/us_tweets", by_state=FALSE)
# ....
#features_10_county <- mean_words_features(file="data/us_tweets_with_score", by_state=FALSE)
# ....

#counties_features <- merge_features(features = list(features_1_county, features_10_county, features_7_county))


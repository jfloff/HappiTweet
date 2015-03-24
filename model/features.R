setwd(Sys.getenv("R_HAPPITWEET"))

source('model/lib.R', echo=FALSE)

# input files
scored_tweets = "data/scored.csv"
all_tweets_state = "data/states.csv"
all_tweets_county = "data/counties.csv"
# output files
output_state = "huge-data/state_features.csv"
output_county = "huge-data/county_features.csv"

############################################################################
############################## BY STATE ####################################
############################################################################

score_features_state = score_features(file=scored_tweets, by_state=TRUE)

tweets_count_features_state = tweets_count_features(file=scored_tweets, 
                                       all_file=all_tweets_state, 
                                       by_state=TRUE)

mean_words_features_state = mean_words_features(file=scored_tweets, by_state=TRUE)


state_features = merge_features(list(score_features_state, tweets_count_features_state, mean_words_features_state))

write.csv(file=output_state, x=state_features, row.names=FALSE)

############################################################################
############################# BY COUNTY ####################################
############################################################################

score_features_county = score_features(file=scored_tweets, by_state=FALSE)

tweets_count_features_county = tweets_count_features(file=scored_tweets, 
                                       all_file=all_tweets_county, 
                                       by_state=FALSE)

mean_words_features_county = mean_words_features(file=scored_tweets, by_state=FALSE)

county_features = merge_features(list(score_features_county, tweets_count_features_county, mean_words_features_county))

write.csv(file=output_county, x=county_features, row.names=FALSE)
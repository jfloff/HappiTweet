setwd(Sys.getenv("R_HAPPITWEET"))

source('model/lib.R', echo=FALSE)

# input files
scored_tweets = "data/scored_noes.csv"
all_tweets_state = "data/states.csv"
all_tweets_county = "data/counties.csv"
# output files
output_state = "data/state_features.csv"
output_county = "data/county_features.csv"

############################################################################
############################## BY STATE ####################################
############################################################################

score_features_state = score_features(file=scored_tweets, by_state=TRUE)

num_tweets_features_state = num_tweets_features(file=scored_tweets,
                                                all_file=all_tweets_state, 
                                                by_state=TRUE)

word_count_features_state = word_count_features(file=scored_tweets, by_state=TRUE)


state_features = merge_features(list(score_features_state, num_tweets_features_state, word_count_features_state))

write.csv(file=output_state, x=state_features, row.names=FALSE)

############################################################################
############################# BY COUNTY ####################################
############################################################################

score_features_county = score_features(file=scored_tweets, by_state=FALSE)

num_tweets_features_county = num_tweets_features(file=scored_tweets,
                                                all_file=all_tweets_county, 
                                                by_state=FALSE)

word_count_features_county = word_count_features(file=scored_tweets, by_state=FALSE)


county_features = merge_features(list(score_features_county, num_tweets_features_county, word_count_features_county))

write.csv(file=output_county, x=county_features, row.names=FALSE)
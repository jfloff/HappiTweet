setwd(Sys.getenv("R_HAPPITWEET"))

library(plyr)
library(RJSONIO)

####
# Parses a file with tweets building a CSV with 3 columns for each tweet: state, county and score
# input_filename -> name of file with the tweets
#
to_state_county_score <- function(input_filename){
  # Open connection to file
  con  <- file(input_filename, open = "r")
  # store the data so after we build a data frame
  states <- c()
  counties <- c()
  scores <- c()
  # parse json file by line
  while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0)
  {
    tweet <- fromJSON(line)

    states <- c(tweet[['state']], states)
    counties <- c(tweet[['county']], counties)
#     scores <- c(as.double(tweet[['scores']]), scores)
    print(tweet[['scores']])
  }
  close(con)
  # build data frame
  data.frame(state = states, county = counties, score = scores)
}

####
# Count tweets in a CSV file by state or county
#   file      -> CSV file that has tweets with a columns: 'state', 'county'
#   by_state  -> flag that indicates if we wnt to count by state or county
#
count_tweets <- function(input_filename, by_state) {
  # Open connection to file
  con  <- file(input_filename, open = "r")
  # store the data so after we build a data frame
  states <- c()
  counties <- c()
  # parse json file by line
  while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0)
  {
    tweet <- fromJSON(line)

    states <- c(tweet[['state']], states)
    counties <- c(tweet[['county']], counties)
  }
  close(con)
  # build data frame and write to CSV
  state_county <- data.frame(state = states, county = counties)

  if(by_state){
    df <- count(state_county, c('state'))
  } else {
    # state_county concat to form unique "id"
    state_county$state_county = paste(state_county$state, state_county$county, sep=",")
    # count by state_county
    df <- count(state_county, c('state_county'))
  }
  names(df) <- c('entity', 'count')
  df
}

####
# Parses a file with tweets building a CSV with 3 columns for each tweet: state, county and word_count
# input_filename -> name of file with the tweets
#
to_state_county_word_count <- function(input_filename){
  # Open connection to file
  con  <- file(input_filename, open = "r")
  # store the data so after we build a data frame
  states <- c()
  counties <- c()
  word_counts <- c()
  # parse json file by line
  while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0)
  {
    tweet <- fromJSON(line)

    states <- c(tweet[['state']], states)
    counties <- c(tweet[['county']], counties)
    word_counts <- c(tweet[['word_count']], word_counts)
  }
  close(con)
  # build data frame and write to CSV
  data.frame(state = states, county = counties, word_count = word_counts)
}

####
# Mode of an array of scores
mode <- function(x) {
  if(length(x) < 2) {
    x
  }
  else {
    # limits and adjust should be changed to meet expectations
    d <- density(x, from=0, to=100 , adjust = 0.805)
    d$x[which.max(d$y)]
  }
}

####
# Returns features related to the score of a tweet file
# Current features are: max, min, mean, median, mode, sd
#
# file      -> file with tweets' score with state and county info
# by_state  -> flag that indicates if the features are by state (true) or county (false)
#
score_features <- function(file, by_state) {

  scores <- to_state_county_score(file)

  if(by_state) {
    split_by_entity <- split(scores, scores$state)
    features <- data.frame(entity = unique(scores$state))
  } else {
    scores$state_county <- paste(scores$state, scores$county, sep=",")
    split_by_entity <- split(scores, scores$state_county)
    features <- data.frame(entity = unique(scores$state_county))
  }


  features$max = sapply(split_by_entity, function(x) round(max(x$score), digits=2))[features$entity]
  features$min = sapply(split_by_entity, function(x) round(min(x$score), digits=2))[features$entity]
  features$mean = sapply(split_by_entity, function(x) round(mean(x$score), digits=2))[features$entity]
  features$median = sapply(split_by_entity, function(x) round(median(x$score), digits=2))[features$entity]
  features$mode = sapply(split_by_entity, function(x) round(mode(x$score), digits=2))[features$entity]
  features$sd = sapply(split_by_entity, function(x) round(sd(x$score), digits=2))[features$entity]

  features[with(features, order(entity)), ]
  features
}

####
# Returns features related to the number of tweets per entity
#
# file      -> file with tweets' score with state and county info
# by_state  -> flag that indicates if the features are by state (true) or county (false)
#
tweets_count_features <- function(file, all_file, by_state) {
  df <- count_tweets(file, by_state)
  # Open csv with all tweets with state and county
  all_tweets <- count_tweets(all_file, by_state)
  # merge data replacing NAs with 0
  tweets <- merge(df, all_tweets, by="entity", all = TRUE)
  tweets[is.na(tweets)] <- 0

  tweets$percentage <- round((tweets$count.x * 100)/tweets$count.y, digits=2)
  res <- data.frame(entity=tweets$entity, count=tweets$count.x, percentage=tweets$percentage)

  res[with(res, order(entity)), ]
  res
}

####
# Returns features related to the average words per tweet
#
# file      -> file with tweets' word_count with state and county info
# by_state  -> flag that indicates if the features are by state (true) or county (false)
#
mean_words_features <- function(file, by_state) {
  state_county_word_count <- to_state_county_word_count(file)

  if(by_state) {
    state_county_word_count <- subset(state_county_word_count, select=c('state','word_count'))
  } else {
    state_county_word_count$state_county = paste(state_county_word_count$state, state_county_word_count$county, sep=",")
    state_county_word_count <- subset(state_county_word_count, select=c('state_county','word_count'))
  }
  colnames(state_county_word_count)[1] <- 'entity'

  df <- aggregate(. ~ entity, data=state_county_word_count, FUN=sum)
  colnames(df)[2] <- 'total_words'

  df$total_tweets <- count(state_county_word_count, c('entity'))$freq
  res <- data.frame(entity = df$entity, mean_words = df$total_words / df$total_tweets)

  res[with(res, order(entity)), ]
  res
}

####
# Merges a list of features into a single data frame
#
# features -> list of features data frames to merge
#
merge_features <- function(features){
  # merge the first two elements
  merged <- merge(features[1], features[2], by="entity", all = TRUE)
  # remove those from the features
  features<-features[-c(1, 2)]
  # loops the remaining, merging them
  for (feature in features) {
    merged <- merge(merged, feature, by="entity", all = TRUE)
  }
  merged
}

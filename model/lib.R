setwd(Sys.getenv("R_HAPPITWEET"))

library(plyr)
library(RJSONIO)

####
# Parses a file with tweets building a CSV with 3 columns for each tweet: state, county and score
# input_filename -> name of file with the tweets
#
to_state_county_score = function(input_filename){
  # Open connection to file
  con  = file(input_filename, open = "r")
  
  # keeps a data frame per lexicon
  tweets_by_lexicon = list()
  # i = 0
  # parse json file by line
  while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0)
  {
    tweet = fromJSON(line)

    # for each lexicon in the tweet checks if its in the list
    # it not creates an empty dataframe
    for(score in tweet[['scores']])
    {
      # gets the name of the lexicon
      lexicon = names(score)
      
      # if lexicon was not initiated, creates a new entry and puts an empty dataframe in it
      if(is.null(tweets_by_lexicon[[lexicon]]))
      {
        df = data.frame(state=character(), county=character(), score=numeric(), stringsAsFactors=FALSE)
        tweets_by_lexicon[[lexicon]] = df
      }
      
      # new row values. Order = state,county,score
      newrow = c(tweet[['state']], tweet[['county']], as.numeric(score[[lexicon]]$score))
      
      # adds to end of the data frame
      tweets_by_lexicon[[lexicon]][nrow(tweets_by_lexicon[[lexicon]])+1,] = newrow
    }
    
    # i = i + 1
    # if (i == 100) break
  }
  
  # close file connection
  close(con)
  # returns built df
  return(tweets_by_lexicon)
}

####
# Mode of an array of scores
#
mode = function(x)
{
  if(length(x) < 2) 
  {
    return(x)
  }
  else
  {
    # limits and adjust should be changed to meet expectations
    d = density(x, from=0, to=100 , adjust = 0.805)
    return(d$x[which.max(d$y)])
  }
}

####
# Returns features related to the score of a tweet file
# Current features are: max, min, mean, median, mode, sd
#
# file      -> file with tweets' score with state and county info
# by_state  -> flag that indicates if the features are by state (true) or county (false)
#
score_features = function(file, by_state)
{
  scores_by_lexicon = to_state_county_score(file)
  
  # for each lexicon calculates its features
  features_by_lexicon = list()
  for(lexicon in names(scores_by_lexicon))
  {
    scores = scores_by_lexicon[[lexicon]]
    
    if(by_state)
    {
      split_by_entity = split(scores, scores$state)
      features = data.frame(entity = unique(scores$state))
    }
    else
    {
      scores$state_county = paste(scores$state, scores$county, sep=",")
      split_by_entity = split(scores, scores$state_county)
      features = data.frame(entity = unique(scores$state_county))
    }
    
    features$max = sapply(split_by_entity, function(x) round(max(as.numeric(x$score)), digits=2))[features$entity]
    features$min = sapply(split_by_entity, function(x) round(min(as.numeric(x$score)), digits=2))[features$entity]
    features$mean = sapply(split_by_entity, function(x) round(mean(as.numeric(x$score)), digits=2))[features$entity]
    features$median = sapply(split_by_entity, function(x) round(median(as.numeric(x$score)), digits=2))[features$entity]
    features$mode = sapply(split_by_entity, function(x) round(mode(as.numeric(x$score)), digits=2))[features$entity]
    features$sd = sapply(split_by_entity, function(x) round(sd(as.numeric(x$score)), digits=2))[features$entity]
    
    features[with(features, order(entity)), ]
    
    features_by_lexicon[[lexicon]] = features
  }
  
  features_by_lexicon
}


####
# Count tweets in a CSV file by state or county
#   file      -> CSV file that has tweets with a columns: 'state', 'county'
#   by_state  -> flag that indicates if we wnt to count by state or county
#
count_tweets_all = function(all_file, by_state) 
{
  data = read.csv(all_file, header = FALSE)
  names(data) = c('entity', 'count')
  return(data)
}

####
# Count tweets in a CSV file by state or county
#   file      -> CSV file that has tweets with a columns: 'state', 'county'
#   by_state  -> flag that indicates if we wnt to count by state or county
#
count_tweets_by_lexicon = function(input_filename, by_state)
{
  # Open connection to file
  con = file(input_filename, open = "r")
  
  # keeps a data frame per lexicon
  tweets_by_lexicon = list()
  i = 0
  # parse json file by line
  while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0)
  {
    tweet = fromJSON(line)
    
    # for each lexicon in the tweet checks if its in the list
    # it not creates an empty dataframe
    for(score in tweet[['scores']])
    {
      # gets the name of the lexicon
      lexicon = names(score)
      
      # if lexicon was not initiated, creates a new entry and puts an empty dataframe in it
      if(is.null(tweets_by_lexicon[[lexicon]]))
      {
        df = data.frame(state=character(), county=character(), state_county=character(), stringsAsFactors=FALSE)
        tweets_by_lexicon[[lexicon]] = df
      }
      
      # new row values. Order = state,county
      newrow = c(tweet[['state']], tweet[['county']], paste(tweet[['state']], tweet[['county']], sep=","))
      # adds to end of the data frame
      tweets_by_lexicon[[lexicon]][nrow(tweets_by_lexicon[[lexicon]])+1,] = newrow
    }
    
    print(i)
    i = i + 1
    # if (i == 10000) break
  }
  
  # close file connection
  close(con)
  
  # for each lexicon chooses its 'entity'
  for(lexicon in names(tweets_by_lexicon))
  {
    # filter is different for each entity
    filter = if(by_state) c('state') else c('state_county')
    # count tweets by filter
    df = count(tweets_by_lexicon[[lexicon]], filter)
    # change names
    names(df) = c('entity', 'count')
    # replace on list of tweets_by_lexicon
    tweets_by_lexicon[[lexicon]] = df
  }
  
  # returns built df
  return(tweets_by_lexicon)
}

####
# Returns features related to the number of tweets per entity
#
# file      -> file with tweets' score with state and county info
# all_file  -> file with state and county for all the tweets geolocated
# by_state  -> flag that indicates if the features are by state (true) or county (false)
#
tweets_count_features = function(file, all_file, by_state) {
  # counts tweets by each lexicon
  tweets_by_lexicon = count_tweets_by_lexicon(file, by_state)
  # counts all tweets with state and county
  all_tweets = count_tweets_all(all_file, by_state)
  
  # for each lexicon merges with the total and calculates percentage
  for(lexicon in names(tweets_by_lexicon))
  {
    df = tweets_by_lexicon[[lexicon]]
    
    # merge data replacing NAs with 0
    tweets = merge(df, all_tweets, by="entity", all = TRUE)
    tweets[is.na(tweets)] = 0
    # calculate percentage
    tweets$percentage = round((tweets$count.x * 100)/tweets$count.y, digits=2)
    res = data.frame(entity=tweets$entity, count=tweets$count.x, percentage=tweets$percentage)
    
    tweets_by_lexicon[[lexicon]] = res[with(res, order(entity)), ]
  }
  
  return(tweets_by_lexicon)
}

####
# Parses a file with tweets building a CSV with 3 columns for each tweet: state, county and word_count
# input_filename -> name of file with the tweets
#
to_state_county_word_count = function(input_filename, by_state){
  # Open connection to file
  con  = file(input_filename, open = "r")
  
  # keeps a data frame per lexicon
  tweets_by_lexicon = list()
  # i = 0
  # parse json file by line
  while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0)
  {
    tweet = fromJSON(line)
    
    # for each lexicon in the tweet checks if its in the list
    # it not creates an empty dataframe
    for(score in tweet[['scores']])
    {
      # gets the name of the lexicon
      lexicon = names(score)
      
      # if lexicon was not initiated, creates a new entry and puts an empty dataframe in it
      if(is.null(tweets_by_lexicon[[lexicon]]))
      {
        df = data.frame(entity=character(), word_count=numeric(), stringsAsFactors=FALSE)
        tweets_by_lexicon[[lexicon]] = df
      }
      
      # new row values according to entity
      # Order = state,word_count or state_county,word_count
      if(by_state) 
      {
        newrow = c(tweet[['state']], as.numeric(score[[lexicon]]$word_count))
      }
      else
      {
        newrow = c(paste(tweet[['state']], tweet[['county']], sep=","), as.numeric(score[[lexicon]]$word_count))
      }
      
      # adds to end of the data frame
      tweets_by_lexicon[[lexicon]][nrow(tweets_by_lexicon[[lexicon]])+1,] = newrow
    }
    
    # i = i + 1
    # if (i == 100) break
  }
  
  # close file connection
  close(con)
  # returns built df
  return(tweets_by_lexicon)
}

####
# Returns features related to the average words per tweet
#
# file      -> file with tweets' word_count with state and county info
# by_state  -> flag that indicates if the features are by state (true) or county (false)
#
mean_words_features = function(file, by_state) 
{
  # loads tweets by lexicon with entity separation (state/state_county)
  tweets_by_lexicon = to_state_county_word_count(file, by_state)
  
  # for each lexicon sums processes word_count
  for(lexicon in names(tweets_by_lexicon))
  {
    data = tweets_by_lexicon[[lexicon]]
    # due to bug that refers to word_count column as factor
    # we need to parse that column as numeric and assign it again
    data$word_count = as.numeric(as.character(data$word_count))
    
    # calculates total words by entity
    df = aggregate(. ~ entity, data=data, FUN=sum)
    colnames(df)[2] = 'total_words'
    # counts number of tweets
    df$total_tweets = count(data, c('entity'))$freq
    # does a mean average of words per tweet
    res = data.frame(entity = df$entity, mean_words = df$total_words / df$total_tweets)
    
    # sorts result by entity
    tweets_by_lexicon[[lexicon]] = res[with(res, order(entity)), ]
  }
  
  return(tweets_by_lexicon)
}

####
# Merges a list of features into a single data frame
#
# features -> list of features data frames to merge
#
merge_features = function(all_features)
{ 
  #will store for each lexicon its features
  merged_features = NULL
  for(features_by_type in all_features)
  {
    # iterates over the lexicons of each feature type
    for(lexicon in names(features_by_type))
    {
      # all features names expect entity
      features_names = names(features_by_type[[lexicon]])
      features_names = features_names[features_names != "entity"]
      # add lexicon to the feature
      features_names = paste(lexicon, features_names, sep="__")
      # add entity again
      features_names = c("entity", features_names)
      # replace with the new names
      names(features_by_type[[lexicon]]) = features_names
      
      # checks if its the first merged feature
      if (is.null(merged_features))
      {
        merged_features = features_by_type[[lexicon]]
      }
      else
      {
        merged_features = merge(merged_features, features_by_type[[lexicon]], by="entity", all = TRUE)
      }
    }
  }
  
  return(merged_features)
}

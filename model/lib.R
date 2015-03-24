setwd(Sys.getenv("R_HAPPITWEET"))

library(plyr)
library(RJSONIO)

####
# Returns column names with a specific given prefix
#
colnames_by_prefix = function(df, prefix)
{
  pattern = paste(c("^",prefix,"*"), collapse = '')
  names = names(df)[grepl(pattern, names(df)) == TRUE]
  return(names)
}

####
# Parses a CSV file with state, county columns and with pairs of <score__* / word_count__*>
# for each lexicon
#
to_entity_value = function(input_filename, by_state, prefix)
{
  data = read.csv(input_filename, header = TRUE)
  
  # gets column names from the score column
  value_column_names = colnames_by_prefix(data, prefix)
  filtered_names = c('entity', value_column_names)
  
  # if state rename state column, if county concatenates state and county
  if(by_state)
  {
    names(data)[names(data)=="state"] = 'entity'
  }
  else
  {
    data$entity = paste(data$state, data$county, sep=",")
  }
  
  # filter columns
  data = data[,filtered_names]
  # remove the score__ prefix
  names(data) = c('entity',substring(value_column_names,nchar(prefix)+1))
  
  return(data)
}

####
# Mode of an array of scores
#
mode = function(x, na.rm=FALSE)
{
  # checks if all vector is NA
  if(all(is.na(x)))
  {
    return(NA)
  }
  # returns non-NA value
  else if(sum(!is.na(x)) < 2) 
  {
    return(x[!is.na(x)])
  }
  # returns mode
  else
  {
    # limits and adjust should be changed to meet expectations
    d = density(x, from=0, to=100 , adjust = 0.805, na.rm = na.rm)
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
  scores = to_entity_value(file, by_state, 'score__')
  
  # lexicons
  lexicons = names(scores)[names(scores) != 'entity']
  # empty df for features
  features = data.frame(entity = unique(scores$entity))
  
  for(lexicon in lexicons)
  {
    # filter df with scores for that lexicon only
    score_by_lexicon = scores[c('entity',lexicon)]
    names(score_by_lexicon) = c('entity','score')
    
    # split results by entity
    split_by_entity = split(score_by_lexicon, score_by_lexicon$entity)

    # features
    max = sapply(split_by_entity, function(x) round(max(as.numeric(x$score), na.rm=TRUE), digits=2))[features$entity]
    features[[paste(lexicon, "max", sep = "__")]] = max
    min = sapply(split_by_entity, function(x) round(min(as.numeric(x$score), na.rm=TRUE), digits=2))[features$entity]
    features[[paste(lexicon, "min", sep = "__")]] = min
    mean = sapply(split_by_entity, function(x) round(mean(as.numeric(x$score), na.rm=TRUE), digits=2))[features$entity]
    features[[paste(lexicon, "mean", sep = "__")]] = mean
    median = sapply(split_by_entity, function(x) round(median(as.numeric(x$score), na.rm=TRUE), digits=2))[features$entity]
    features[[paste(lexicon, "median", sep = "__")]] = median
    mode = sapply(split_by_entity, function(x) round(mode(as.numeric(x$score), na.rm=TRUE), digits=2))[features$entity]
    features[[paste(lexicon, "mode", sep = "__")]] = mode
    sd = sapply(split_by_entity, function(x) round(sd(as.numeric(x$score), na.rm=TRUE), digits=2))[features$entity]
    features[[paste(lexicon, "sd", sep = "__")]] = sd
  }
  
  # replace Inf's and NaN's with NA
  is.na(features) <- do.call(cbind,lapply(features, is.infinite))
  is.na(features) <- do.call(cbind,lapply(features, is.nan))
  
  return(features)
}

####
# Count tweets in a CSV file by state or county
#   file      -> CSV file that has tweets with a columns: 'state', 'county'
#   by_state  -> flag that indicates if we wnt to count by state or county
#
count_tweets_all = function(all_file) 
{
  data = read.csv(all_file, header = FALSE)
  names(data) = c('entity', 'total_num_tweets')
  return(data)
}

####
# Count tweets in a CSV file by state or county
#   file      -> CSV file that has tweets with a columns: 'state', 'county'
#   by_state  -> flag that indicates if we wnt to count by state or county
#
num_tweets_by_lexicon = function(input_filename, by_state)
{
  word_counts = to_entity_value(input_filename, by_state, 'word_count__')
  
  # lexicons
  lexicons = names(word_counts)[names(word_counts) != 'entity']
  # num_tweets empty df
  num_tweets = data.frame(entity = unique(word_counts$entity))
  for(lexicon in lexicons)
  {
    # filter word_counts per lexicon
    word_counts_by_lexicon = word_counts[c('entity',lexicon)]
    names(word_counts_by_lexicon) = c('entity','word_count')
    # remove rows with 0 word_count, and filters out the word_count column
    tweets_entity = subset(word_counts_by_lexicon, word_count!=0)[c('entity')]
    
    # count by entity
    df = as.data.frame(table(tweets_entity))
    names(df) = c('entity', lexicon)
    # merge on entity
    num_tweets = merge(num_tweets,df,by="entity")
  }
  
  return(num_tweets)
}

####
# Returns features related to the number of tweets per entity
#
# file      -> file with tweets' score with state and county info
# all_file  -> file with state and county for all the tweets geolocated
# by_state  -> flag that indicates if the features are by state (true) or county (false)
#
num_tweets_features = function(file, all_file, by_state)
{
  # counts all tweets with state and county
  all_tweets = count_tweets_all(all_file)
  # counts tweets by each lexicon
  tweets_by_lexicon = num_tweets_by_lexicon(file, by_state)
  
  # lexicons
  lexicons = names(tweets_by_lexicon)[names(tweets_by_lexicon) != 'entity']
  
  # merge both dfs
  num_tweets = merge(all_tweets, tweets_by_lexicon, by="entity", all = TRUE)
  
  for(lexicon in lexicons)
  {
    # column with the percentage
    num_tweets[[paste(lexicon, 'num_tweets_percentage', sep='__')]] = round(
      (num_tweets[[lexicon]] * 100)/num_tweets[['total_num_tweets']], digits=2)
    
    # rename lexicon column
    names(num_tweets)[names(num_tweets)==lexicon] = paste(lexicon, 'num_tweets', sep='__')
  }
  
  return(num_tweets)
}

####
# Returns features related to the average words per tweet
#
# file      -> file with tweets' word_count with state and county info
# by_state  -> flag that indicates if the features are by state (true) or county (false)
#
word_count_features = function(file, by_state) 
{
  # loads word_counts by entity
  word_counts = to_entity_value(file, by_state, 'word_count__')
  
  # lexicons
  lexicons = names(word_counts)[names(word_counts) != 'entity']
  # num_tweets empty df
  word_counts_by_entity = data.frame(entity = unique(word_counts$entity))
  for(lexicon in lexicons)
  {
    # filter word_counts per lexicon
    word_counts_by_lexicon = word_counts[c('entity',lexicon)]
    names(word_counts_by_lexicon) = c('entity','word_count')
    
    # remove rows with 0 word_count, and filters out the word_count column
    tweets_entity = subset(word_counts_by_lexicon, word_count!=0)[c('entity')]
    
    # count by entity
    total_tweets = as.data.frame(table(tweets_entity))
    names(total_tweets) = c('entity', 'total_tweets')
    
    # count total words by entity
    total_word_count = aggregate(. ~ entity, data=word_counts_by_lexicon, FUN=sum)
    names(total_word_count) = c('entity', 'total_word_count')
    
    # merge both on entity
    mean_df = merge(total_tweets,total_word_count,by="entity")
    
    # add mean words per tweet
    mean_df$mean_word_count_per_tweet = round(mean_df$total_word_count / mean_df$total_tweets, digits=2)
    
    # select mean_word_count column and properly name it after the lexicon
    mean_df = mean_df[c('entity','mean_word_count_per_tweet')]
    names(mean_df) = c('entity', paste(lexicon, 'mean_word_count_per_tweet', sep='__'))
    
    # merge with  on entity
    word_counts_by_entity = merge(word_counts_by_entity,mean_df,by="entity")
  }
  
  # replace Inf's and NaN's with NA
  is.na(word_counts_by_entity) <- do.call(cbind,lapply(word_counts_by_entity, is.infinite))
  is.na(word_counts_by_entity) <- do.call(cbind,lapply(word_counts_by_entity, is.nan))
  
  return(word_counts_by_entity)
}

#######################################################################################################
####################################### CHANGE FROM HERE BELOW ########################################
#######################################################################################################








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

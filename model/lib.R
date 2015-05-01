setwd(Sys.getenv("R_HAPPITWEET"))

library(plyr)
library(dplyr)
library(RJSONIO)
library(glmnet)
library(Metrics)
library(caret)

set.seed(1)

# remove hawaii and alaska from states
STATE_NAMES = subset(
  data.frame(upper = state.name, lower = tolower(state.name), abbv = state.abb),
  abbv!='AK' & abbv!='HI')

##################################################################################################
######################################## GENERAL FEATURES ########################################
##################################################################################################

####
# Parses a CSV file with state, county columns and with pairs of <score__* / word_count__*>
# for each lexicon
#
to_entity_value = function(input_filename, by_state, prefix)
{
  data = read.csv(input_filename, header = TRUE, stringsAsFactors = FALSE, sep=";")
  
  # gets column names from the prefix column
  pattern = paste(c("^",prefix,"*"), collapse = '')
  value_column_names = names(data)[grepl(pattern, names(data)) == TRUE]
  
  # filter columns
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

##################################################################################################
######################################### SCORE FEATURES #########################################
##################################################################################################

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
  is.na(features) = do.call(cbind,lapply(features, is.infinite))
  is.na(features) = do.call(cbind,lapply(features, is.nan))
  
  return(features)
}

##################################################################################################
###################################### NUM TWEETS FEATURES #######################################
##################################################################################################

####
# Count tweets in a CSV file by state or county
#   file      -> CSV file that has tweets with a columns: 'state', 'county'
#   by_state  -> flag that indicates if we wnt to count by state or county
#
count_tweets_all = function(all_file) 
{
  data = read.csv(all_file, header = FALSE, stringsAsFactors = FALSE)
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
  
  # drop total_num_tweets column
  num_tweets$total_num_tweets = NULL
  
  return(num_tweets)
}

##################################################################################################
###################################### WORD COUNT FEATURES #######################################
##################################################################################################

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
  is.na(word_counts_by_entity) = do.call(cbind,lapply(word_counts_by_entity, is.infinite))
  is.na(word_counts_by_entity) = do.call(cbind,lapply(word_counts_by_entity, is.nan))
  
  return(word_counts_by_entity)
}

##################################################################################################
######################################### MERGE FEATURES #########################################
##################################################################################################

####
# Merges a list of features into a single data frame
#
# features -> list of features data frames to merge
#
merge_features = function(all_features)
{ 
  # function that merges 2 dataframes by entity
  merge.all = function(x, y) merge(x, y, all = TRUE, by="entity")
  # applies function to list dfs
  out = Reduce(merge.all, all_features)
  # reorder features alphabetically (entity stays)
  order = c('entity', sort(names(out)[names(out) != 'entity']))
  out = out[order]
  
  return(out)
}

##################################################################################################
############################################# MODEL ##############################################
##################################################################################################

####
# Receives a file with gallup score and returns a vector with
# only its scores
# 
# File format: 'state','gallup_score'
#
gallup_scores = function(file)
{ 
  # load gallup
  gallup = read.csv(file=file, header = TRUE, stringsAsFactors = FALSE)
  # make sure its sorted alphabetically
  gallup = gallup[order(gallup$state),]
  # convert scores into vector
  return(as.vector(gallup[,c('gallup_score')]))
}

####
# Receives a file with features and returns the entity associated
# 
# File format: 'entity','feature_1','feature_2',...
#
get_entities = function(features_file)
{
  # load features
  features_df = read.csv(file=features_file, header=TRUE, stringsAsFactors = FALSE)
  # make sure its sorted alphabetically
  return(sort(features_df$entity))
}

####
# Receives a file with features and returns a dataframe with
# only the features values. Removes rows with all NAs
# 
# File format: 'entity','feature_1','feature_2',...
#
load_features = function(file)
{
  # load features
  features_df = read.csv(file=file, header=TRUE, stringsAsFactors = FALSE)
  
  # make sure its sorted alphabetically
  features_df = features_df[order(features_df$entity),]
  # remove entity from columns
  features_df = select(features_df, -(entity))
  
  # first remove rows where is all NAs
  # features_df = features_df[rowSums(is.na(features_df)) != ncol(features_df), ]
  
  # remove columns where there is NA values
  # features_df = features_df[,colSums(is.na(features_df)) == 0]
  
  # remove columns where there is all NA values
  # features_df = features_df[,colSums(is.na(features_df)) == nrow(features_df)]
  
  # return features as matrix
  return(features_df)
}


####
# compare against baseline models that always predict the 
# mean or the median well-being index
#
gallup_stats = function(gallup)
{
  avg = rep(mean(gallup), length(gallup))
  med = rep(median(gallup), length(gallup))
  
  ret = list(
    rmse_mean = rmse(gallup, avg),
    mae_mean = mae(gallup, avg),
    rmse_median = rmse(gallup, med),
    mae_median = mae(gallup, med)
  )
  return(ret)
}


####
# Compare gallup with predictions
#
eval_predictions = function(predictions)
{
  # evaluate results
  ret = list(
    cor_pearson=cor(predictions$gallup, predictions$prediction, method = "pearson"),
    cor_kendall=cor(predictions$gallup, predictions$prediction, method = "kendall"),
    rmse=rmse(predictions$gallup, predictions$prediction),
    mae=mae(predictions$gallup, predictions$prediction)
  )
  return(ret)
}


####
# Filter features so they only have features that dont cause cv.glmnet 
# to throw erro
#
filter_features = function(features, gallup)
{
  # sort names by colSums of na features
  columns_by_na = names(sort(colSums(is.na(features)), decreasing=TRUE))
  
  # repeat calling model until it doesn't throw error
  repeat
  {
    out = tryCatch(
      { 
        # model with state characteristics
        model = cv.glmnet(x=as.matrix(features), y=gallup, alpha=0.5, nfolds=10)
        TRUE
      },
      error = function(e)
      {
        FALSE
      }
    )
      
    # break of out repreat if model didn't give error
    if(out)
    {
      break
    }
    else
    {
      # get the name of the column to remove
      col_to_remove = first(columns_by_na[1])
      
      # get column name index
      # I could only get remove to work by index
      col_to_remove = first(grep(col_to_remove, colnames(features)))
    
      # remove the column name from features
      features = features[, -c(col_to_remove)]
      
      # update available column names
      columns_by_na = tail(columns_by_na,-1)
    }
  }
  
  return(features)
}

####
# Compare gallup with predictions
#
model = function(gallup_file, state_features_file, by_state, county_features_file=NULL)
{
  # load gallup scores
  gallup = gallup_scores(gallup_file)
  
  # load state features
  state_features = load_features(state_features_file)
  # filter features so they don't throw error to cv.glmnet
  # state_features = filter_features(state_features, gallup)
  
  if(by_state)
  {
    # entities
    entities = get_entities(state_features_file)
    
    # convert features to matrix
    state_features = as.matrix(state_features)
    
    # train model and generate predictions, using the same data for training and testing
    # (cross-validation is only used to tune parameters)
    
    model = cv.glmnet(x=state_features, y=gallup, alpha=0.5, nfolds=10)
    
    coefficients = coef(model, s="lambda.min")
    predictions = predict(model, newx=state_features, s="lambda.min")
    
    # train and generate predictions with a leave-one-out cross validation methodology
    folds = createFolds(gallup, k=length(gallup), list=TRUE, returnTrain=TRUE)
    coefficients = rep(0.0, length(coefficients))
    for (f in folds) {
      model = cv.glmnet(x=state_features[f,] , y=gallup[f], alpha=0.5 , nfolds=length(gallup[f]))
      c = coef(model , s="lambda.min")
      coefficients = coefficients + coef(model, s="lambda.min")
      predictions[!f,] = predict(model, newx=state_features[!f,], s="lambda.min")
    }
    coefficients = coefficients / length(folds)
    
    # match upper state names with abbvs
    states_upper_lower = select(STATE_NAMES, c(upper,lower))
    names(states_upper_lower) = c('state_upper','state_lower')
    # merge by state upper
    state_merge = merge(data.frame(state_upper=entities),states_upper_lower,by="state_upper")
    
    # adds entity to predictions to improve readability
    predictions = data.frame(state=state_merge$state_lower,prediction=predictions[,1],gallup=gallup)
  }
  #County
  else
  {
    if(is.null(county_features_file)) 
      stop("In case of counties model you need to pass counties features file")
    
    # load county features
    county_features = load_features(county_features_file)
    
    # convert to matrix
    state_features = as.matrix(state_features)
    county_features = as.matrix(county_features)
    
    model = cv.glmnet(x=state_features[,], y=gallup, alpha=0.5, nfolds=length(gallup))
    
    coefficients = coef(model, s="lambda.min")
    predictions = predict(model, newx=county_features, s="lambda.min")
    
    # entities
    entities = get_entities(county_features_file)
    
    # adds entity to predictions to improve readability
    predictions = data.frame(county=entities,prediction=predictions[,1])
  }

  # turns sparse matrix into dataframe to improve readability
  coefficients = data.frame(
    feature=row.names(coefficients),
    coefficient=as.matrix(coefficients)[,1],
    stringsAsFactors=FALSE
  )
  rownames(coefficients) = NULL
  
  # replace 0's with NA's so its clear it comes from the sparse matrix
  coefficients[coefficients == 0] = NA
  
  return(list(coefficients=coefficients, predictions=predictions))
}

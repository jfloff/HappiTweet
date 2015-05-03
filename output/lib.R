setwd(Sys.getenv("R_HAPPITWEET"))

library(ggplot2)
library(RColorBrewer)
library(reshape)
library(scales)
library(sp)
library(maps)
library(maptools)
library(tools)
library(plyr)
library(dplyr)
library(xtable)

####
# CONSTANTS
#

# remove hawaii and alaska from states
STATE_NAMES = subset(
  data.frame(upper = state.name, lower = tolower(state.name), abbv = state.abb, stringsAsFactors=FALSE),
  abbv!='AK' & abbv!='HI')

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
# Parses a CSV file with state, county columns and select the respective  and with pairs of <score__* / word_count__*>
# for each lexicon
#
filter_state_score = function(input_filename, state_name, score_column)
{
  data = read.csv(input_filename, header = TRUE, stringsAsFactors = FALSE, sep=";")
  # filter score column  needed
  data = data[,c("state", score_column)]
  # filter the state name
  data = subset(data, state==state_name)
  # rename columns
  names(data) = c('state','score')

  rownames(data) = NULL

  return(data)
}

####
# Plots the tweet distribution from a state
# Current features are: max, min, mean, median, mode, sd
#
# csv           -> csv file with all the tweets and their scores
# state         -> state of the plot
# score_column  -> column with the tweet score for a certain lexicon
# title         -> title of the plot
# xlabel        -> Label of the xaxis = Lexicon score
#
plot_tweet_distribution = function(csv, state, score_column, title, xlabel)
{
  data = filter_state_score(csv, state, score_column)
  data_mean = mean(data$score)
  data_median = median(data$score)
  data_mode = mode(data$score)

  dens = density(data$score)
  max_dens = max(dens$y)
  
  plot = ggplot(data, aes(x=score), environment = environment()) +
    geom_histogram(
      aes(y=..density..),
      binwidth=.5,
      colour="black", fill="white"
    ) +
    scale_y_continuous(expand=c(0.001,0)) +
    expand_limits(y = max_dens*1.30) +
    scale_x_continuous(expand=c(0.001,0.001), breaks=pretty_breaks(n=10)) +
    geom_vline(aes(xintercept = data_mean), show_guide = TRUE, linetype = "longdash", size = 0.5, colour='red') +
    annotate("text", x = data_mean, y = max_dens * 1.10, label = "mean", size = 3.5, hjust = 1.2, colour = 'red') +
    geom_vline(aes(xintercept = data_median), show_guide = TRUE, linetype = "longdash", size = 0.5, colour='blue') +
    annotate("text", x = data_median, y = max_dens * 1.15, label = "median", size = 3.5, hjust = -.2, colour = 'blue') +
    geom_vline(aes(xintercept = data_mode), show_guide = TRUE, linetype = "longdash", size = 0.5, colour=muted('green')) +
    annotate("text", x = data_mode, y = max_dens * 1.05, label = "mode", size = 3.5, hjust = -.2, colour = muted('green')) +
    geom_density(from=1, to=9 , adjust = 0.805, size=1.2 ) +
    theme_bw() +
    ggtitle(title) +
    xlab(xlabel) +
    ylab("Density")

  output_filename = paste("output-files/tweet_distribution--",state,"--",score_column,".png",sep="")

  # save file to folder
  png(file=output_filename,width=320,height=260,res=96)
  print({plot})
  dev.off()

  # plots at the end also
  plot
}

####
# Plots the bump chart between predictions and Gallup
#
# gallup_filename     -> file with gallup values
# state_pred_filename -> file with state predictions
#
plot_bump_chart = function (gallup_filename, state_pred_filename)
{
  line_colors = terrain.colors(48, alpha = 1)

  gallup = read.csv(gallup_filename, header = TRUE, sep=",")
  # match lower state names with abbvs
  states_lower_abbv = select(STATE_NAMES, c(lower,abbv))
  names(states_lower_abbv) = c('state','state_abbv')
  # merge by state lower
  gallup = merge(gallup,states_lower_abbv,by="state")
  # ranking by score
  gallup$ranking = rank(-gallup$gallup_score, ties.method="first")
  #  set colors and group for plot
  gallup$color = line_colors
  gallup$group = "Gallup"
  gallup = subset(gallup, select=c(group,state_abbv,ranking,color))

  state_pred = read.csv(state_pred_filename, header = TRUE, sep=",")
  # match upper state names with abbvs
  states_lower_abbv = select(STATE_NAMES, c(lower,abbv))
  names(states_lower_abbv) = c('state','state_abbv')
  # merge by state upper
  state_pred = merge(state_pred,states_lower_abbv,by="state")
  # ranking by score
  state_pred$ranking = rank(-state_pred$prediction, ties.method="first")
  # set colors and group for plot
  state_pred$color = line_colors
  state_pred$group = "Prediction Model"
  state_pred = subset(state_pred, select=c(group,state_abbv,ranking,color))

  #bump chart
  bump = rbind(state_pred,gallup)
  plot = ggplot(bump, aes(x=group, y=ranking, color=color, group=state_abbv, label=state_abbv, colour=state_abbv)) +
    geom_line(stat='identity') +
    labs(x = '', y = '') +
    geom_text(data = subset(bump, group == "Prediction Model"), size=3.1, hjust=-.02) +
    geom_text(data = subset(bump, group == "Gallup"), size=3.1, hjust=1.02) +
    theme_bw() +
    scale_y_continuous(expand = c(0.03,0.03)) +
    scale_x_discrete(expand = c(0.2,0.2)) +
    theme(
      legend.position="none",
      axis.text=element_text(size=13,face='bold'),
      axis.line.y = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.background = element_blank()
    )

  # save file to folder
  png(file="output-files/bump_chart.png",width=600,height=650,res=96)
  print({plot})
  dev.off()

  # plot at the end anyway
  plot
}

####
# Returns the value of the asked quintiles
#
# quintiles   -> data to calculate quintiles on
# values      -> quintile values wanted
#
get_quintile = function(quintiles, values)
{
  if (quintiles[1] <= values & values <= quintiles[2])
  {
    return("5th Quintile")
  }
  else if (quintiles[2] <= values & values <= quintiles[3])
  {
    return("4th Quintile")
  }
  else if (quintiles[3] <= values & values <= quintiles[4])
  {
    return("3th Quintile")
  }
  else if (quintiles[4] <= values & values <= quintiles[5])
  {
    return("2nd Quintile")
  }
  else if (quintiles[5] <= values & values <= quintiles[6])
  {
    return("1st Quintile")
  }
}

####
# Plots a quintile choroplet given a csv file with score by state
# filename      -> csv file with state and score data
# state_column  -> state column name in file
# score_column  -> score column name in file
# title         -> title of the plot
#
plot_quintiles = function(filename, state_column, score_column, title)
{
  # turns file into scored vector
  df = read.csv(filename, header = TRUE, sep=",")
  data = as.vector(df[,c(score_column)])
  names(data) = df[,c(state_column)]

  # Gets data set with states already inside R
  states_polygons = map_data('state')
  states_polygons = subset(states_polygons, region != 'district of columbia')

  #Now link the vote data to the state shapes by matching names:
  states_polygons$score = data[states_polygons$region]

  quantiles = quantile(data, c(0, 0.2, 0.4, 0.6, 0.8, 1))
  states_polygons$quantiles = sapply(states_polygons$score, function(x) get_quintile(quantiles, x))

  #Finally, add a color layer to the map:
  # passes the map, and as fill column the scores
  map = ggplot(states_polygons, environment = environment()) +
    aes(long, lat, group=group) +
    geom_polygon() +
    aes(fill=quantiles) +
    labs(fill = "Quintiles") +
    theme_bw() +
    theme(legend.position = "bottom",
          axis.line=element_blank(),
          axis.text.x=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks=element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank()
    ) +
    # GALLUP 2013 HTML COLORS
    # GREEN = #4F993F
    # BLUE = #329FB2
    # YELLOW = #E4CC3C
    # ORANGE = #E76B19
    # RED = #C22D20

    # GALLUP 2012 HTML COLORS
    # GREEN = #689A27
    # BLUE = #4DA7C1
    # YELLOW = #E7CD44
  # ORANGE = #E87625
  # RED = #C53D27
  scale_fill_manual(values = c('#689A27','#4DA7C1','#E7CD44','#E87625','#C53D27')) +
    theme(
      plot.title=element_text(face="bold", size=20),
      legend.title = element_text(size = 16, face="bold"),
      legend.text = element_text(size = 16)
    ) +
    coord_map(project='globular') +
    ggtitle(title)

  output_filename=paste("output-files/quintiles_by_state--",file_path_sans_ext(basename(filename)),".png",sep="")
  png(file=output_filename,width=900,height=550,res=96)
  print({map})
  dev.off()

  # print
  print({map})
}

###
# Plots scatter correlation plots between feature and prediction values
#
# features_filename -> filename of features file
# predictions_filename -> filename of predictions file
# feature_name -> feature to plot scatter of
# ylabel -> label of the y axix
#
plot_scatter_features = function(features_filename, predictions_filename, feature_name, ylabel)
{
  features = read.csv(features_filename, header = TRUE, sep=",")
  features = features[, c("entity", feature_name)]
  names(features) = c('state_upper', feature_name)

  # match lower state names with abbvs
  states_upper_lower = select(STATE_NAMES, c(upper,lower))
  names(states_upper_lower) = c('state_upper','state')
  # merge by state lower
  features = merge(features,states_upper_lower,by="state_upper")

  # load predictions
  predictions = read.csv(predictions_filename, header = TRUE, sep=",")

  # merge features and predictions
  data = merge(features,predictions,by="state")
  data = select(data, -c(state_upper,gallup))

  plot = ggplot(data, aes_string(x="prediction", y=feature_name), environment=environment()) +
    geom_point(shape=1) + # Use hollow circles
    geom_smooth(method=lm) + # Add linear regression line
    labs(x = "Well-being index", y = ylabel) +
    theme_bw() +
    theme(
      axis.text=element_text(size=10),
      panel.grid = element_blank(),
      panel.background=element_blank(),
      axis.text.y=element_text(colour="black"),
      axis.text.x=element_text(colour="black"),
      plot.title=element_text(size=10.5, face='bold'),
      axis.title=element_text(size=10.5,face='bold')
    )

  output_filename = paste("output-files/scatter--",feature_name,".png",sep='')

  png(file=output_filename,width=320,height=260,res=96)
  print({plot})
  dev.off()

  plot
}

###
# Transforms various data in the table for the paper
#
# file_list -> list of files to include in the table
#     csv -> csv filename
#     state_cap -> capitalization of the csv in the file: upper, lower or abbv (see STATE_NAMES object)
#     colindex -> index columns
#     colorder -> order of the columns to merge in the final table
# state_cap -> Choose the correct capitalization of your state: upper, lower or abbv (see STATE_NAMES object)
# colnames  -> column names for the table
#
data_table = function(file_list, state_cap, colnames)
{
  # start with all the state names
  table = STATE_NAMES

  for(file_info in file_list)
  {
    # load csv -- ASSUMING all have headers and sep is a comma
    df = read.csv(file_info$csv, header=TRUE, sep=",")
    # filer csv by colindex
    df = df[,file_info$colindex]
    # set df names to merge with table (according to caps)
    colnames(df)[1] = file_info$state_cap
    # reorder columns
    df = df[,file_info$colorder]
    # merge with table on the correct state cap
    table = merge(table,df,by=file_info$state_cap)
  }

  # remove columns that are not the correct caps
  caps_to_remove = c('upper','lower','abbv')
  caps_to_remove = caps_to_remove[caps_to_remove != state_cap];
  table = table[, -which(names(table) %in% caps_to_remove)]

  # add min max avg rows at the end
  if(state_cap == 'upper')
  {
    max_rowname = 'Maximum'
    min_rowname = 'Minimum'
    avg_rowname = 'Average'
  }
  else if (state_cap == 'lower')
  {
    max_rowname = 'maximum'
    min_rowname = 'minimum'
    avg_rowname = 'average'
  }
  else
  {
    max_rowname = 'MAX'
    min_rowname = 'MIN'
    avg_rowname = 'AVG'
  }

  # add avg row
  avg_row = sapply(table, function(x) mean(as.numeric(as.character(x)), na.rm=TRUE))
  avg_row[1] = avg_rowname
  table = rbind(table,avg_row)
  # add min row
  min_row = sapply(table, function(x) min(as.character(x), na.rm=TRUE))
  min_row[1] = min_rowname
  table = rbind(table,min_row)
  # add max row
  max_row = sapply(table, function(x) max(as.character(x), na.rm=TRUE))
  max_row[1] = max_rowname
  table = rbind(table,max_row)

  # set column names
  colnames(table) = colnames

  # save table to folder
  print(xtable(table), type="latex", file="output-files/table.tex")

  return(table)
}

###
# Colors scales for state predictions
#
state_color_scales = function()
{
  # load predictions
  state_pred = read.csv(file="model-output/state_predictions.csv", header=TRUE, sep=",")
  predictions = as.vector(state_pred$prediction)
  
  # load key statistics
  mean = mean(predictions, na.rm=TRUE)
  sd = sd(predictions, na.rm=TRUE)
  min = min(predictions, na.rm = TRUE)
  max = max(predictions, na.rm = TRUE)
  
  # scale to 9 values spreading out the values near the mean
  scale = c(min, mean - (sd/8), mean - (sd/7), mean - (sd/6), 
            mean, 
            mean + (sd/6), mean + (sd/7), mean - (sd/8), max)
  
  return(scale)
}

###
# Colors scales for county predictions
#
county_color_scales = function()
{
  # load predictions
  county_pred = read.csv(file="model-output/county_predictions.csv", header=TRUE, sep=",")
  predictions = as.vector(county_pred$prediction)
  
  # load key statistics
  mean = mean(predictions, na.rm=TRUE)
  sd = sd(predictions, na.rm=TRUE)
  min = min(predictions, na.rm = TRUE)
  max = max(predictions, na.rm = TRUE)
  
  # scale to 9 values spreading out the values near the mean
  scale = c(min, mean - (sd/8), mean - (sd/6), mean - (sd/4), mean - (sd/3), 
            mean, 
            mean + (sd/3), mean + (sd/4), mean + (sd/6), mean + (sd/8), max)
  
  return(scale)
}

###
# State chloropleth for a state scores file
#
# state_scores_filename -> file with score data
# title -> title of the plot
#
state_choropleth = function(state_scores_filename, score_column, title)
{
  scores = read.csv(file=state_scores_filename, header=TRUE, sep=",")
  vec = as.vector(scores[,c(score_column)])
  names(vec) = scores$state
  
  # Gets data set with states already inside R
  states_polygons = map_data('state')
  
  #Now link the vote data to the state shapes by matching names:
  states_polygons$score = vec[states_polygons$region]
  
  # scales for states
  scale = state_color_scales()
  
  #Finally, add a color layer to the map:
  # passes the map, and as fill column the scores
  map = ggplot(states_polygons) +
    aes(long, lat, group=group) +
    geom_polygon() +
    aes(fill=score) +
    theme_bw() +
    theme(axis.line=element_blank(),
          axis.text.x=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks=element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank()
    ) + 
    scale_fill_gradientn(
      colours = brewer.pal(length(scale), "RdYlGn"),
      values = rescale(scale),
      name='score'
    ) + 
    theme(plot.title=element_text(face="bold")) +
    coord_map(project='globular') +
    ggtitle(title)
  
  # save to file
  output_filename = paste("output-files/state_choropleth--", score_column, ".png",sep='')
  png(file=output_filename,width=900,height=450,res=96)
    print({map})
  dev.off()
  
  # plot at the end anyway
  map
}


###
# County chloropleth for a county scores file
#
# county_scores_filename -> file with score data
# score_column -> score column name
# title -> title of the plot
#
county_choropleth = function(county_scores_filename, score_column, title)
{
  county_pred = read.csv("model-output/county_predictions.csv", header = TRUE)
  vec = as.vector(county_pred[,c(score_column)])
  names(vec) = tolower(county_pred$county)
  
  # Gets data set with counties already inside R
  states_polygons = map_data('county')
  states_polygons$state_county = paste(states_polygons$region, states_polygons$subregion, sep=",")
  
  #Now link the vote data to the state shapes by matching names:
  states_polygons$score = vec[states_polygons$state_county]
  
  # color scale for plot
  scale <- county_color_scales()
  
  #Finally, add a color layer to the map:
  # passes the map, and as fill column the scores
  map = ggplot(states_polygons) +
    aes(long, lat, group=group) +
    geom_polygon() +
    aes(fill=score) +
    theme_bw() +
    theme(axis.line=element_blank(),
          axis.text.x=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks=element_blank(),
          axis.title.x=element_blank(),
          axis.title.y=element_blank()
    ) + 
    scale_fill_gradientn(
      colours = brewer.pal(length(scale), "RdYlGn"),
      values = rescale(scale),
      name='score'
    ) + 
    theme(
      plot.title=element_text(face="bold", size=20),
      legend.title = element_text(size = 16, face="bold"),
      legend.text = element_text(size = 16)
    ) + 
    coord_map(project='globular') + 
    ggtitle (title)
  
  # save to file
  output_filename = paste("output-files/county_choropleth--", score_column, ".png",sep='')
  png(file=output_filename,width=900,height=450,res=96)
  print({map})
  # needs sleep since county plot is heavy and takes a bit longer to plot
  Sys.sleep(60)
  dev.off()
  
  # plot at the end anyway
  map
}
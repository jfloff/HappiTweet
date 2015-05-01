setwd(Sys.getenv("R_HAPPITWEET"))

library(ggplot2)
library(RColorBrewer)
library(scales)

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
plot_tweet_distribution <- function(csv, state, score_column, title, xlabel)
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
  
  output_filename = paste("output-charts/tweet_distribution--",state,"--",score_column,".png",sep="");
  
  # save file to folder  
  png(file=output_filename,width=320,height=260,res=96)  
  print({plot})
  dev.off()
  
  # plots at the end also
  plot
}

setwd(Sys.getenv("R_HAPPITWEET"))

source('lib.R', echo=FALSE)

library(ggplot2)
library(RColorBrewer)
library(scales)

plot_tweet_distribution <- function(data, state_name, title){
  state_df <- subset(data, state==state_name)
  state_mean <- mean(state_df$score)
  state_median <- median(state_df$score)
  state_mode <- mode(state_df$score)
  state_plot <- ggplot(state_df, aes(x=score)) +
    geom_histogram(
      aes(y=..density..),
      binwidth=.5,
      colour="black", fill="white"
    ) +
    scale_y_continuous(expand=c(0.001,0)) +
    expand_limits(y = 0.70) +
    scale_x_continuous(expand=c(0.001,0.001), breaks=pretty_breaks(n=10)) +
    geom_vline(aes(xintercept = state_mean), show_guide = TRUE, linetype = "longdash", size = 0.5, colour='red') +
    annotate("text", x = state_mean, y = 0.44, label = "mean", size = 3.5, hjust = 1.1, colour = 'red') +
    geom_vline(aes(xintercept = state_median), show_guide = TRUE, linetype = "longdash", size = 0.5, colour='blue') +
    annotate("text", x = state_median, y = 0.50, label = "median", size = 3.5, hjust = -.1, colour = 'blue') +
    geom_vline(aes(xintercept = state_mode), show_guide = TRUE, linetype = "longdash", size = 0.5, colour=muted('green')) +
    annotate("text", x = state_mode, y = 0.44, label = "mode", size = 3.5, hjust = -.1, colour = muted('green')) +
    geom_density(from=1, to=9 , adjust = 0.805, size=1.5 ) +
    theme_bw() +
    ggtitle(title) +
    xlab("ANEW valence score") +
    ylab("Density")

  state_plot
}

# png(file="paper/tweets_distribution_anew_state.png",width=320,height=260,res=96)
plot_tweet_distribution(data=to_state_county_score("data/us_tweets_with_score"), state_name="indiana", title="Colorado\n(first in ranking")
# dev.off()

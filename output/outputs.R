setwd(Sys.getenv("R_HAPPITWEET"))

source('output/lib.R', echo=FALSE)

# files
tweets_scored = "data/scored_noes.csv"
gallup_filename = "data/gallup_2012.csv"
state_predictions = "model-output/state_predictions.csv"

############################################################################
########################### TWEETS DISTRIBUTION ############################
############################################################################

plot_tweet_distribution(csv=tweets_scored,
  state="Indiana",
  score_column="score__en.hedo.happiness.no_filter",
  title="Indiana\n(first in ranking)",
  xlabel="Hedonometer (No Filter)")

############################################################################
################################ BUMP CHART ################################
############################################################################

plot_bump_chart(gallup_filename=gallup_filename, state_pred_filename=state_predictions)

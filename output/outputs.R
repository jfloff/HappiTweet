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
################################# SCATTER ##################################
############################################################################

plot_scatter_features(
  features_filename="model-output/state_features.csv",
  predictions_filename="model-output/state_predictions.csv",
  feature_name="en.hedo.happiness.delta_one_of_5__max",
  ylabel="Non-neutral hedonometer lexicon\nMax hapiness score")


############################################################################
################################ BUMP CHART ################################
############################################################################

plot_bump_chart(gallup_filename=gallup_filename, state_pred_filename=state_predictions)


############################################################################
################################ QUINTILES #################################
############################################################################

gallup_quintiles = plot_quintiles(
  filename="data/gallup_2012.csv",
  state_column="state",
  score_column="gallup_score",
  title="Quintiles for Gallup-Healthways well-being index")

prediction_quintiles = plot_quintiles(
  filename="model-output/state_predictions.csv",
  state_column="state",
  score_column="prediction",
  title="Quintiles for predicted well-being scores")


############################################################################
################################ CHOROPLETH ################################
############################################################################

state_choropleth(
  state_scores_filename='model-output/state_predictions.csv', 
  score_column='prediction', 
  title='Predicted well-being scores')

state_choropleth(
  state_scores_filename='model-output/state_predictions.csv', 
  score_column='gallup', 
  title='Gallup well-being scores')


############################################################################
################################## TABLE ###################################
############################################################################

table = data_table(
  file_list = list(
    list(csv = "model-output/state_predictions.csv", state_cap = "lower", colindex = c(1,2,3), colorder = c(1,3,2)),
    list(csv = "data/all_tweets_by_state.csv", state_cap = "upper", colindex = c(1,2), colorder = c(1,2)),
    list(csv = "model-output/state_features.csv", state_cap = "upper", colindex = c(1,21,26), colorder = c(1,3,2)) 
  ),
  state_cap = 'upper',
  colnames = c("State", "Gallup-Healthways", "Predicted Well-Being","Number of Tweets","Tweets with Hedonometer","Average Happiness")
)
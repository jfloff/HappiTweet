setwd(Sys.getenv("R_HAPPITWEET"))

# see http://web.stanford.edu/~hastie/glmnet/glmnet_alpha.html
library(glmnet)
library(Metrics)
library(caret)
library(dplyr)

set.seed(1)

# files
gallup_file = "data/gallup_2012.csv"
features_file = "data/state_features.csv"

# load gallup and convert into vector score
gallup = read.csv(file=gallup_file, header = TRUE )
gallup = as.vector(gallup[,c('gallup_score')])

# load features
features_df = read.csv(file=features_file, header=TRUE)
# remove entity from columns
features_df = select(features_df, -(entity))
# first remove rows where is all NAs
features_df = features_df[rowSums(is.na(features_df)) != ncol(features_df), ]
# remove columns where there is NA values
features_df = features_df[,colSums(is.na(features_df)) == 0]
# load features as matrix
features = as.matrix(features_df)

# train model and generate predictions, using the same data for training and testing (cross-validation is only used to tune parameters)
model <- cv.glmnet( x=features , y=gallup , alpha = 0.5 , nfolds=10 )
coefficients <- coef( model , s = "lambda.min" )
predictions <- predict( model , newx=features, s = "lambda.min")

# train and generate predictions with a leave-one-out cross validation methodology
folds <- createFolds( gallup , k = length(gallup) , list = TRUE, returnTrain = TRUE )
coefficients <- rep(0.0, length(coefficients))
for (f in folds) {
 model <- cv.glmnet( x=features[f,] , y=gallup[f] , alpha = 0.5 , nfolds=length(gallup[f]) )
 c <- coef( model , s = "lambda.min" )
 coefficients <- coefficients + coef( model , s = "lambda.min" )
 predictions[!f,] <- predict( model , newx=features[!f,], s = "lambda.min")
}
coefficients <- coefficients / length(folds)

# print results
coefficients
predictions

# evaluate results
cor( gallup, predictions, method = "pearson" )
cor( gallup, predictions, method = "kendall" )
rmse( gallup, predictions )
mae( gallup, predictions )

# compare against baseline models that always predict the mean or the median well-being index
avg <- rep( mean( gallup ) , length(gallup) )
med <- rep( median( gallup ) , length(gallup) )
rmse( gallup, avg )
mae( gallup, avg )
rmse( gallup, med )
mae( gallup, med )

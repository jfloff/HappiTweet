setwd(Sys.getenv("R_HAPPITWEET"))

source('model/features.R', echo=FALSE)

# see http://web.stanford.edu/~hastie/glmnet/glmnet_alpha.html
library(glmnet)
library(Metrics)
library(caret)

set.seed(1)

# load features and remove state column
features <- as.matrix(state_features[,2:ncol(state_features)])

# load gallup and keep data for 2012
gallup <- read.csv("data/gallup.csv", header = TRUE )
gallup <- as.vector(gallup[,2])
# train model and generate predictions, using the same data for training and testing (cross-validation is only used to tune parameters)
model1 <- cv.glmnet( x=features , y=gallup , alpha = 0.5 , nfolds=10 )
coefficients <- coef( model1 , s = "lambda.min" )
predictions <- predict( model1 , newx=features, s = "lambda.min")

# train and generate predictions with a leave-one-out cross validation methodology
folds <- createFolds( gallup , k = length(gallup) , list = TRUE, returnTrain = TRUE )
coefficients <- rep(0.0, length(coefficients))
for (f in folds) {
 model1 <- cv.glmnet( x=features[f,] , y=gallup[f] , alpha = 0.5 , nfolds=length(gallup[f]) )
 c <- coef( model1 , s = "lambda.min" )
 coefficients <- coefficients + coef( model1 , s = "lambda.min" )
 predictions[!f,] <- predict( model1 , newx=features[!f,], s = "lambda.min")
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

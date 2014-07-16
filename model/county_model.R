setwd("~/Code/sigspatial2014/") 

source('model/features.R', echo=FALSE)

# see http://web.stanford.edu/~hastie/glmnet/glmnet_alpha.html
library(glmnet)
library(Metrics)
library(caret)

# load features and remove state column
features <- as.matrix(state_features[,2:49])

# load features for counties
features_counties <- as.matrix(counties_features[,2:49])

# load gallup and keep data for 2012
gallup <- read.csv("data/gallup.csv", header = TRUE )
gallup <- as.vector(gallup[,2])

model <- cv.glmnet(x=features , y=gallup , alpha = 0.5 , nfolds=length(gallup) )
predictions <- predict( model , newx=features_counties, s = "lambda.min")

# print results
coefficients
predictions

# compare against baseline models that always predict the mean or the median well-being index
avg <- rep( mean( gallup ) , length(gallup) )
med <- rep( median( gallup ) , length(gallup) )
rmse( gallup, avg )
mae( gallup, avg )
rmse( gallup, med )
mae( gallup, med )
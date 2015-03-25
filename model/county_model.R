setwd(Sys.getenv("R_HAPPITWEET"))

# see http://web.stanford.edu/~hastie/glmnet/glmnet_alpha.html
library(glmnet)
library(Metrics)
library(caret)

# file
gallup_file = "data/gallup_2012.csv"
features_file = "data/county_features.csv"

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

# model
model = cv.glmnet(x=features, y=gallup, alpha=0.5 , nfolds=length(gallup))
coefficients = coef(model, s ="lambda.min")
predictions = predict(model, newx=features_counties, s="lambda.min")

# print results
coefficients
predictions

# compare against baseline models that always predict the mean or the median well-being index
avg <- rep(mean(gallup), length(gallup))
med <- rep(median(gallup), length(gallup))
rmse(gallup, avg)
mae(gallup, avg)
rmse(gallup, med)
mae(gallup, med)

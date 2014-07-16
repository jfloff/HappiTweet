setwd("~/Code/sigspatial2014")

source('lib.R', echo=FALSE)

library(sp)
library(ggplot2)
library(maps)
library(maptools)
library(RColorBrewer)
library(scales)

#### 
# Plots a quintile choroplet given a named vector with score by state
plot_quintiles <- function(vec, title){
  # Gets data set with states already inside R
  states_polygons = map_data('state')
  states_polygons = subset(states_polygons, region != 'district of columbia')
  
  #Now link the vote data to the state shapes by matching names:
  states_polygons$score = vec[states_polygons$region]
  
  quantiles <- quantile(vec, c(0, 0.2, 0.4, 0.6, 0.8, 1))
  states_polygons$quantiles <- sapply(states_polygons$score, function(x) get_quintile(quantiles, x))
  
  #Finally, add a color layer to the map:
  # passes the map, and as fill column the scores
  map = ggplot(states_polygons) +
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
    scale_fill_manual(values = c('#689A27','#4DA7C1','#E7CD44','#E87625','#C53D27'))
  
  # 2013
  # GREEN = #4F993F
  # BLUE = #329FB2
  # YELLOW = #E4CC3C
  # ORANGE = #E76B19
  # RED = #C22D20
  
  # 2012
  # GREEN = #689A27
  # BLUE = #4DA7C1
  # YELLOW = #E7CD44
  # ORANGE = #E87625
  # RED = #C53D27
  
  map = map + theme(
    plot.title=element_text(face="bold", size=20),
    legend.title = element_text(size = 16, face="bold"),
    legend.text = element_text(size = 16)
  )
  map = map + 
    coord_map(project='globular') +
    ggtitle(title)
  
  map
}

########################################################################################
################################ GALLUP QUINTILES ######################################
########################################################################################
gallup_data <- read.csv("data/gallup.csv", header = TRUE)
gallup <- as.vector(gallup_data$gallup_2012_score)
names(gallup) = gallup_data$state
gallup_quintiles <- plot_quintiles(vec=gallup, title="Quintiles for Gallup-Healthways well-being index")
png(file="paper/quintiles_state_gallup.png",width=900,height=550,res=96)
gallup_quintiles
dev.off()

########################################################################################
################################ MODEL QUINTILES #######################################
########################################################################################
source('model/state_model.R', echo=FALSE)
predictions <- as.vector(predictions)
names(predictions) = states

gallup_quintiles <- plot_quintiles(vec=predictions, title="Quintiles for predicted well-being scores")
png(file="paper/paper/quintiles_state_model.png",width=900,height=550,res=96)
gallup_quintiles
dev.off()

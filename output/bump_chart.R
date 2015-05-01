setwd(Sys.getenv("R_HAPPITWEET"))

source('lib.R', echo=FALSE)
source('model/state_model.R', echo=FALSE)

library(ggplot2)
library(reshape)
library(scales)

colors <- terrain.colors(48, alpha = 1)

#gallup data frame
gallup <- read.csv("data/gallup.csv", header = TRUE)
colnames(gallup)[2] <- "gallup_score"
gallup$ranking = rank(-gallup$gallup_score, ties.method= "first")
gallup$group = "Gallup"
gallup$state = states_abbrv
gallup$color = colors
gallup <- subset(gallup, select=c(group,state,ranking,color))

# Predictions with states named vector
labmt <- data.frame(state = states, score = as.vector(predictions))
labmt$ranking = rank(-labmt$score, ties.method= "first")
labmt$group = "Prediction Model"
labmt$color = colors
labmt <- subset(labmt, select=c(group,state,ranking,color))

#bump chart
bump <- rbind(labmt,gallup)
plot <- ggplot(bump, aes(x=group, y=ranking, color=color, group=state, label=state, colour=state)) +
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

plot

png(file="paper/bump_chart.png",width=600,height=650,res=96)
plot
dev.off()

setwd(Sys.getenv("R_HAPPITWEET"))

source('output/lib.R', echo=FALSE)

plot_bump_chart = function (gallup_filename, state_pred_filename)
{
  line_colors = terrain.colors(48, alpha = 1)
  
  gallup = read.csv(gallup_filename, header = TRUE, sep=",")
  # match lower state names with abbvs
  states_lower_abbv = select(STATE_NAMES, c(lower,abbv))
  names(states_lower_abbv) = c('state','state_abbv')
  # merge by state lower
  gallup = merge(gallup,states_lower_abbv,by="state")
  # ranking by score
  gallup$ranking = rank(-gallup$gallup_score, ties.method="first")
  #  set colors and group for plot
  gallup$color = line_colors
  gallup$group = "Gallup"
  gallup = subset(gallup, select=c(group,state_abbv,ranking,color))
  
  state_pred = read.csv(state_pred_filename, header = TRUE, sep=",")
  # match upper state names with abbvs
  states_upper_abbv = select(STATE_NAMES, c(upper,abbv))
  names(states_upper_abbv) = c('state','state_abbv')
  # merge by state upper
  state_pred = merge(state_pred,states_upper_abbv,by="state")
  # ranking by score
  state_pred$ranking = rank(-state_pred$prediction, ties.method="first")
  # set colors and group for plot
  state_pred$color = line_colors
  state_pred$group = "Prediction Model"
  state_pred = subset(state_pred, select=c(group,state_abbv,ranking,color))
  
  #bump chart
  bump = rbind(state_pred,gallup)
  plot = ggplot(bump, aes(x=group, y=ranking, color=color, group=state_abbv, label=state_abbv, colour=state_abbv)) +
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
  
  # save file to folder  
  png(file="output-charts/bump_chart.png",width=600,height=650,res=96)  
  print({plot})
  dev.off()
  
  plot
}



png(file="paper/bump_chart.png",width=600,height=650,res=96)
plot
dev.off()

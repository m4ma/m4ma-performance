# Profiling the Estimation of the Predictive Pedestrian Model

library(m4ma)

rm(list = ls())
source("RCore/PredictivePedestrian.R")

fun_names_see = c(
  'line.line.intersection',
  'seesGoal',
  'seesCurrentGoal',
  'seesMany',
  'seesGoalOK'
)

rm(list = c(fun_names_see))

# trace = readRDS("Experiments/Escience/Data/3-play/play_escience_m01s02p03r001.RDS")

# prepped_trace = prepSimTrace(trace)

# save(prepped_trace, file = '../bench/play_escience_m01s02p03r001.rda')

load('../bench/play_escience_m01s02p03r001.rda')

# Get subject parameters
p = attr(large_trace, 'pMat') 

profile = profvis::profvis(msumlogLike(
  p, large_trace, cores = 1, minLike = 1e-10, mult = -1
))

htmlwidgets::saveWidget(profile, "../profile/profile_predped_estimation.html")

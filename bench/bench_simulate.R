# Measure the Impact of m4ma Implementations on Simulation Performance

# This code loads the data from a simulation of the Predictive Pedestrian model
# with 50 pedestrians after 250 iterations. It runs the simulation for one more
# iteration from the last state while using different implementations from the
# m4ma package instead of predped. The speed of the simulation is measured and
# compared across different function combinations that are replaced.

# To run the simulation, the settings must be loaded. The code for loading the
# settings is adapted from the scripts `3-play_main.R`.

library(m4ma)
library(parallel)

# Load predped functions to run simulation
rm(list = ls())
source("../predped/RCore/pp_geometry.R")    # geometry functions
source("../predped/RCore/pp_plot.R")        # plotting functions
source("../predped/RCore/pp_see.R")         # line intersection and "sees" functions
source("../predped/RCore/pp_predict.R")     # prediction functions
source("../predped/RCore/pp_utility.R")     # utility functions
source("../predped/RCore/pp_parameter.R")   # parameter management functions
source("../predped/RCore/pp_dcm.R")         # DCM functions
source("../predped/RCore/pp_route.R")       # routing and tour functions
source("../predped/RCore/pp_goals.R")       # goal management functions
source("../predped/RCore/pp_block.R")       # object blocking functions
source("../predped/RCore/pp_collide.R")     # fix collisions functions
source("../predped/RCore/pp_simulate.R")    # iterate simulation functions
source("../predped/RCore/pp_flow.R")        # flow metrics functions
source("../predped/RCore/pp_estimation.R")  # estimation functions

# Get benchmark helper functions
source('bench_helpers.R')

# Load state of simulation after 250 iterations
trace = readRDS(
  "../predped/Experiments/Escience/Data/3-play/play_escience_m01s02p04r002.RDS"
)

## Settings for simulation
exp_id = "Escience"  # experiment id
m_id = "m01"         # m[make id]
s_id = "s02"         # s[stack id]
p_id = "p04"         # p[play id]
r_id = "r002"        # r[repetition id]

# Cores (only 1 possible on Windows)
cores = 1            # parallel process

# Output control
plotSim = FALSE       # Plot to RStudio plot window

# Console reporting
reportGoal = FALSE    # Report goal updates to console

# Nests
nests = list(Central = c(0, 6, 17, 28), 
               NonCentral = c(0:33)[-c(0 , 6, 17, 28)],
               acc = c(1:11), 
               const = 12:22,
               dec = c(0, 23:33))

# All alternatives a member of 2 nests so always alpha = .5
alpha_nests = setAlpha(nests)

play_settings = read.csv(paste("../predped/Experiments/", exp_id, 
                                 "/Config/play_settings.csv", sep = ""),
                           stringsAsFactors = FALSE)

# Settings of play p
play_p = play_settings[play_settings$play_id == p_id, ]

# Pedestrians
p_interactionTime = play_p$interactionTime  # cycles to stay at goals
p_pReroute = play_p$pReroute                # Probability of reroute,

# Directory names
dat_dir = paste("../predped/Experiments/", exp_id, "/Data", sep = "")
fig_dir = paste("../predped/Experiments/", exp_id, "/Figures", sep = "")
plot_dir =  ""

# File names 
nam = paste(tolower(exp_id), "_", sep = "")
make_nam = paste("1-make/make_", nam, m_id, sep = "") 
stack_nam = paste("2-stack/stack_", nam, m_id, s_id, sep = "")
play_nam = paste("3-play/play_", nam, m_id, s_id, p_id, r_id, sep = "")

N = length(trace) + 1

file_name = paste(plot_dir, "/", nam, m_id, s_id, p_id, r_id, "_N", N, sep = "")

# Load space objects
load(paste(dat_dir, "/", make_nam, ".RData", sep = ""))

# Load stacks
load(paste(dat_dir, "/", stack_nam, ".RData", sep = ""))

# Set m4ma wrappers to use C++ implementations
predped_env = environment()
predped_env$use = 'cpp'

# Create function that runs iteration while temporarily removing funs
# from global env
run_sim_wo_funs = function(fun_names) {
  # Save functions that will be removed
  tmp_funs = list()
  for (fun_name in fun_names) {
    tmp_funs[[fun_name]] = get(fun_name)
  }
  
  # Remove functions from globabl env
  rm(list = fun_names, pos = ".GlobalEnv")
  
  # Run simulation for an additional iteration and measure execution time
  t = system.time(moveAll(trace[[length(trace)]], objects, nests, alpha_nests,
                          cores = cores, plotSim = plotSim, fname = file_name, 
                          reportGoal = reportGoal, 
                          interactionTime = p_interactionTime,
                          pReroute = p_pReroute))
  
  # Restore removed functions
  for (fun_name in fun_names) {
    assign(fun_name, tmp_funs[[fun_name]], pos = ".GlobalEnv")
  }
  
  # Return only total elapsed time
  return(t[3])
}

fun_names_geometry = c(
  'dist',
  'dist1',
  'angle2s',
  'angle2',
  'aTOd',
  'Iangle',
  'minAngle',
  'Dn',
  'headingAngle',
  'c_vd',
  'scaleVel',
  'coneNum',
  'ringNum'
)

fun_names_see = c(
  'line.line.intersection',
  'seesGoal',
  'seesCurrentGoal',
  'seesMany',
  'seesGoalOK'
)

fun_names_util_extra = c(
  'destinationAngle',
  'predClose',
  'eObjects',
  'iCones',
  'iCones2Cells',
  'blockedAngle',
  'getLeaders',
  'getBuddy'
)

# Define list of functions to use from m4ma instead of predped
ablations = list(
  '[none]' = character(0),
  'line.line.intersection' = c('line.line.intersection'),
  'seesGoal' = c('seesGoal'),
  'dist1' = c('dist1'),
  'geometry' = fun_names_geometry,
  'see' = fun_names_see,
  'util_extra' = fun_names_util_extra,
  'geometry + see' = c(fun_names_geometry, fun_names_see),
  'see + util_extra' = c(fun_names_see, fun_names_util_extra),
  'geometry + util_extra' = c(fun_names_geometry, fun_names_util_extra),
  'geometry + see + util_extra' = c(
    fun_names_geometry, fun_names_see, fun_names_util_extra
  )
)

# Measure time for each ablation
elapsed_time = sapply(ablations, run_sim_wo_funs)

# Create df for plotting
plot_df = data.frame(
  labels = names(ablations),
  time = elapsed_time,
  ratio = round(sapply(elapsed_time, function(x) elapsed_time[1]/x), 2)
)

# Plot elapsed times for each ablation
ggplot(plot_df, aes(
    x = time,
    y = reorder(labels, time),
    label = reorder(ratio, time)
  )) + 
  geom_col(fill = 'steelblue') +
  geom_text() +
  labs(
    x = 'Total elapsed time (in s)',
    y = 'Functions used from m4ma instead of predped'
  ) + theme_classic()

write.csv(bench_df, file.path('data', 'bench_moveAll.csv'))

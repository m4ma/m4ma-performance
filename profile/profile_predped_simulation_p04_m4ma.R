library(m4ma)

rm(list = ls())
source("RCore/PredictivePedestrian.R")

m4ma_fun_names = lsf.str("package:m4ma")

exclude = c(
  "baUtility", "caUtility", "flUtility", "gaUtility", "idUtility", "like_state",
  "msumlogLike", "pCNL", "psUtility", "utility", "wbUtility"
)

m4ma_fun_names = m4ma_fun_names[!m4ma_fun_names %in% exclude]

rm(list = m4ma_fun_names)

# Load state of simulation after 250 iterations
trace <- readRDS("Experiments/Escience/Data/3-play/play_escience_m01s02p04r002.RDS")

## Settings for simulation
exp_id <- "Escience"  # experiment id
m_id <- "m01"         # m[make id]
s_id <- "s02"         # s[stack id]
p_id <- "p04"         # p[play id]
r_id <- "r002"        # r[repetition id]

# Cores (only 1 possible on Windows)
cores <- 1            # parallel process

# Output control
plotSim <- FALSE       # Plot to RStudio plot window

# Console reporting
reportGoal <- TRUE    # Report goal updates to console

# Nests
nests <- list(Central = c(0, 6, 17, 28), 
              NonCentral = c(0:33)[-c(0 , 6, 17, 28)],
              acc = c(1:11), 
              const = 12:22,
              dec = c(0, 23:33))

# All alternatives a member of 2 nests so always alpha = .5
alpha <- setAlpha(nests)

play_settings <- read.csv(paste("Experiments/", exp_id, 
                                "/Config/play_settings.csv", sep = ""),
                          stringsAsFactors = FALSE)

# Settings of play p
play_p <- play_settings[play_settings$play_id == p_id, ]

# Pedestrians
p_interactionTime <- play_p$interactionTime  # cycles to stay at goals
p_pReroute <- play_p$pReroute                # Probability of reroute,

# Directory names
dat_dir <- paste("Experiments/", exp_id, "/Data", sep = "")
fig_dir <- paste("Experiments/", exp_id, "/Figures", sep = "")
plot_dir <-  ""

# File names 
nam <- paste(tolower(exp_id), "_", sep = "")
make_nam <- paste("1-make/make_", nam, m_id, sep = "") 
stack_nam <- paste("2-stack/stack_", nam, m_id, s_id, sep = "")
play_nam <- paste("3-play/play_", nam, m_id, s_id, p_id, r_id, sep = "")

# Load space objects
load(paste(dat_dir, "/", make_nam, ".RData", sep = ""))

# Load stacks
load(paste(dat_dir, "/", stack_nam, ".RData", sep = ""))

N <- length(trace) + 1

file_name <- paste(plot_dir, "/", nam, m_id, s_id, p_id, r_id, "_N", N, sep = "")

# Run the simulation for an additional iteration and profile code
profile = profvis::profvis(moveAll(trace[[length(trace)]], objects, nests, alpha,
                                   cores = cores, plotSim = plotSim, fname = file_name, 
                                   reportGoal = reportGoal, 
                                   interactionTime = p_interactionTime,
                                   pReroute = p_pReroute))

# Save profile to html
htmlwidgets::saveWidget(profile, "../profile/profile_predped_simulation_p04_m4ma.html")

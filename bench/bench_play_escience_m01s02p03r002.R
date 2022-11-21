
rm(list = ls())

setwd('../predped')

source("RCore/PredictivePedestrian.R")

fun_names_see = c(
  'line.line.intersection',
  'seesGoal',
  'seesCurrentGoal',
  'seesMany',
  'seesGoalOK'
)

rm(list = fun_names_see)

# Load EScience package
library("m4ma")

predped_env <- new.env()
predped_env$use <- 'cpp' # or use = 'cpp'

cores = 50

exp_id <- "Escience"  # experiment id
m_id <- "m01"         # m[make id]
s_id <- "s02"         # s[stack id]
p_id <- "p03"         # p[play id]
r_id <- "r002"        # r[repetition id]

# Output control
plotSim <- FALSE       # Plot to RStudio plot window
plotScreen <- FALSE    # Save screenplot file
saveTrace <- FALSE     # Write and save trace

# Console reporting
reportGoal <- FALSE    # Report goal updates to console
addPedReport <- FALSE  # Report ped additions to console

# Netsts
nests <- list(Central = c(0, 6, 17, 28), 
              NonCentral = c(0:33)[-c(0 , 6, 17, 28)],
              acc = c(1:11), 
              const = 12:22,
              dec = c(0, 23:33))

# All alternatives a member of 2 nests so always alpha = .5
alpha <- setAlpha(nests)

# Nest association = 1/(1-mu), mu = within nest precision, >= 1
nA <- rep(0,5); names(nA) <- names(nests)


# Settings based on play id -----------------------------------------------

# Settings all play files
play_settings <- read.csv(paste("Experiments/", exp_id, 
                                "/Config/play_settings.csv", sep = ""),
                          stringsAsFactors = FALSE)

# Settings of play p
play_p <- play_settings[play_settings$play_id == p_id, ]

# Pedestrians
p_entryCycles <- play_p$entryCycles          # Try to add ped every entryCycles 
p_max_caps <- play_p$max_caps                # store capacity
p_n_iterations <- play_p$n_iterations        # maximum iterations
p_interactionTime <- play_p$interactionTime  # cycles to stay at goals
p_pReroute <- play_p$pReroute                # Probability of reroute,
# set 0 for estimation

# Parameters
p <- c(nA,
       c(rU = play_p$rU,                              # utility randomness, divides utility
         bS = play_p$bS,                              # don't move
         bCA = play_p$bCA, aCA = play_p$aCA,          # current angle
         bCAlr = play_p$bCAlr,                        # left <1 / right >1 pref        
         bGA = play_p$bGA, aGA = play_p$aGA,          # goal angle
         bBA = play_p$bBA, aBA = play_p$aBA,          # blocked angle
         bID = play_p$bID, aID = play_p$aID,          # interpersonal distance
         dID = play_p$dID,                            # extra for outGroup
         bPS = play_p$bPS, aPS = play_p$aPS,          # preferred speed
         sPref = play_p$sPref, sSlow = play_p$sSlow,  # ~3.5 km/h, distance from goal to begin slowing
         bWB = play_p$bWB, aWB = play_p$aWB,          # walk beside
         bFL = play_p$bFL, aFL = play_p$aFL,          # follow the leader
         dFL = play_p$dFL))                           # extra for inGroup

# Transform parameters to real scale
p_p <- toReal(p)

# Individual variability
p_pSD  <- rep(play_p$pSD, length(p_p))       # no variability
names(p_pSD) <- names(p_p)


# File and directory names ------------------------------------------------

# File names 
nam <- paste(tolower(exp_id), "_", sep = "")
make_nam <- paste("1-make/make_", nam, m_id, sep = "") 
stack_nam <- paste("2-stack/stack_", nam, m_id, s_id, sep = "")
play_nam <- paste("3-play/play_", nam, m_id, s_id, p_id, r_id, sep = "")

# Directory names
dat_dir <- paste("Experiments/", exp_id, "/Data", sep = "")
fig_dir <- paste("Experiments/", exp_id, "/Figures", sep = "")

# Input data --------------------------------------------------------------

# Load space objects
load(paste(dat_dir, "/", make_nam, ".RData", sep = ""))

# Load stacks
load(paste(dat_dir, "/", stack_nam, ".RData", sep = ""))


# Setup output ------------------------------------------------------------

# Trace
trace <- vector(mode = "list", length = p_n_iterations)

# Directory if figures of simulation need to be saved
if (!plotScreen) {
  plot_dir <-  ""
} else {
  # Create directory for figures
  plot_dir <- paste(fig_dir, "/", play_nam, sep = "")
  if(!dir.exists(plot_dir)) {
    dir.create(plot_dir)
  }
}

# Run simulation ----------------------------------------------------------

time_sim = system.time({

# Set up simulation: first ped
state <- makeState(stacks[[1]], p_p, p_pSD, group = 1)

# Show initial state, for first pedestrian (goals = 0, way points = +)
if (plotSim) {
  plotPed(state$p, getP(state), state$a, state$r, objects)
  draw_grid(state$p[1,], state$v, state$a, plotPoints = FALSE)
  points(pathPoints, pch = 3, lwd = 2, col = "#252525", cex = 1.4)
  points(state$P[[1]][substr(row.names(state$P[[1]]), 1, 1) == "G", ], 
         pch = 16, col = "#CA0020", cex = 2)
}

N <- 1
repeat {
  # Add current state to trace
  if (saveTrace) { 
    trace[[N]] <- state
    # # Remove attributes (getting rid of large "replan" attribute), 
    # # Might go to far, might need "i" and "stop" 
    # trace[[N]]$P <- lapply(state$P,function(x){x[,1:2]})
  }
  
  # Create new state
  if (plotScreen) {
    file_name <- paste(plot_dir, "/", nam, m_id, s_id, p_id, r_id, "_N", N, sep = "")
  }
  
  # Move states
  state <- moveAll(state, objects, nests, alpha, cores = cores,
                   plotSim = plotSim, fname = file_name, 
                   reportGoal = reportGoal, 
                   interactionTime = p_interactionTime, pReroute = p_pReroute) 
  
  # Add chosen cell to previous state
  trace[[N]]$cell <- state$cell
  
  # Remove pedestrians at exit state
  state <- exitPed(state) # if reached goal exit
  
  # Print iteration number and # pedestrians present
  cat(paste0(N, ":", nrow(state$p), "\n"))
  
  # Stop simulation if there are no pedestrians anymore
  if (dim(state$p)[1] == 0) {
    break 
  }
  
  # Add pedestrian to state unless store full or start position occupied
  if (!(nrow(state$p) >= p_max_caps) & (N %% p_entryCycles == 0)) { 
    # Randomly pick goal stack from available sets
    gstack = stacks[[sample(1:length(stacks), 1)]]
    state <- addPed(gstack, p = p_p, pSD = p_pSD, state = state, 
                    addPedReport = addPedReport) 
  }
  
  # New iteration
  N <- N + 1 
  
  # Stop if maximum iterations has been reached
  if (N > p_n_iterations) {
    break
  }
}

})

# Remove empty slots in trace in case sim is topped before n_iterations
trace <- trace[!unlist(lapply(trace, is.null))]


# Prepare trace -----------------------------------------------------------

# Add space attributes for replay
attr(trace, "space") <- list(objects = objects, goalLines = goalLines,
                             goalRectangles = goalRectangles, entry = entry, 
                             exitHigh = exitHigh, pathPoints = pathPoints, 
                             oneWay1 = oneWay1, oneWay2 = oneWay2)

# Add alpha and nests attributes
attr(trace, "alpha") <- alpha
attr(trace, "nests") <- nests

# Only using RDS for compatibility with old cog servers
if (saveTrace) {
  saveRDS(trace, file = paste(dat_dir, "/", play_nam, ".RDS", sep = ""))
}

time_df = data.frame(
  user = time_sim[1],
  system = time_sim[2],
  elapsed = time_sim[3]
)

write.csv(
  time_df,
  paste0('../bench/data/bench_play_escience_', m_id, s_id, p_id, r_id, '.csv'),
  row.names = FALSE
)

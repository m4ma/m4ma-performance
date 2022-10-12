# Profiling the Predictive Pedestrian Simulation

Malte Lüken and Eva Viviani

12-10-2022

## Goal
In order to optimize the speed of the simulation for the Predictive Pedestrian
model, we first profile the code to get an overview of how long different 
functions in the simulation take to run. With this knowledge, we can focus on
optimizing the functions that take the most time to run. Consequently, 
improvements in the speed of those functions should lead to improvements in the
speed of the simulation.

## Procedure
To profile the code, we use the R package `profvis` which relies on R's native
tool for profiling called `Rprof`.

The simulation of the Predictive Pedestrian model runs slower the more 
pedestrians are in the simulation and the more iterations it runs for. That is, 
many functions called during the simulation will also run slower under these 
conditions, too. Realistically, the model will be used for up to 50 
pedestrians. Since the simulation typically starts with 0 pedestrians, and
pedestrians enter the simulation one after each other, it takes
many iterations until all 50 participants are present.

In the file `predped/Experiments/Escience/Config/play_settings.csv`, we have 
different settings for running simulations of the Predictive Pedestrian model. 
For profiling, we choose the fourth setting `p04`, which runs a simulation for
250 iterations using default parameters for the pedestrians. Every 5 iterations,
a new pedestrian enters the simulation until a maximum of 50 is reached at the
end of the simulation. This setting should give us a simulation that resembles 
realistic use cases.

The chosen simulation can be run by executing the following R script: 
`predped/Experiments/Escience/R/3-play/play_escience_m01s02p04r002.R`. We 
choose the second file because it comes from a simulation only using R code 
(the script ending with `r001` uses C++ geometry functions). Note that, 
for the code to run properly, the working directory must be set to `predped/`. 
This can be achieved by opening the `predped/` folder as a project in RStudio 
or by `r setwd("predped")`.

The resulting data of the simulation with the chosen setting is located in the
directory `predped/Experiments/Escience/Data/3-play/` in the file 
`/play_escience_m01s02p04r002.RDS`.

For profiling, we run the simulation for one more iteration from its last state
with 50 participants to see how fast the R code is under these conditions. The
profiling results can be obtained by running the R script 
`profile/profile_predped_simulation_p04.R`. Note that the results might be 
slightly different every time the profiling is done because it is not 
deterministic. The conclusions, however, should remain the same. The script 
saves the profiling results as an interface in an HTML file.

## Results
In the profiling results, we focus on the data view in the HTML interface. The
most time for executing the iteration is spent on `mcapply`, which in our case
of a single core directly translates into `mapply`. This function applies the
same anonymous routine to all pedestrians in the simulation. The anonymous 
function spends the most time on `utility` as well as `bodyObjectOK` and
`okObject`.

The `utility` function calls several sub functions from the `pp_utility` module:
`predClose`, `getLeaders`, `getBuddy`, `blockedAngle`, and `destinationAngle`. 
These in turn call functions from the `pp_geometry` and `pp_see` modules.

The functions `bodyObjecjtOK` and `okObject` also call sub functions from the
`pp_geometry` and `pp_see` modules.

One function from the `pp_see` module that is called very frequently and takes
much time is `line.line.intersection`. Within this function, calculating the
determinant of a 2x2 matrix is especially costly.

## Conclusions
Based on the profiling results, we conclude that optimizing the functions in the
`pp_geometry` and `pp_see` modules will likely lead to improvements in the speed
of the simulation. Moreover, optimizing the functions in the `pp_utility` module
could lead to further improvements. Most importantly, we expect that optimizing
the function `line.line.intersection` in the `pp_see` module will lead to the
greatest speed improvements.



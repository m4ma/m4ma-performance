# Profiling the predped Code Base

Malte Lüken and Eva Viviani

12-10-2022

## Goal
In order to optimize the speed of the predped code base, we first profile the code to get an overview of how long different 
functions in the simulation and parameter estimation take to run. With this knowledge, we can focus on
optimizing the functions that take the most time to run. Improvements in the speed of those functions should lead to improvements in the
speed of the simulation.

## Procedure
To profile the code, we use the R package `profvis` which relies on R's native
tool for profiling called `Rprof`.

### Profiling the Simulation
The simulation of the Predictive Pedestrian model runs slower the more 
pedestrians are in the simulation. That is, 
many functions called during the simulation will also run slower under these 
conditions, too. Realistically, the model will be used for up to 50 
pedestrians. Since the simulation typically starts with 0 pedestrians, and
pedestrians enter the simulation one after each other, it takes
many iterations until all 50 participants are present.

In the file `../predped/Experiments/Escience/Config/play_settings.csv`, we have 
different settings for running simulations of the Predictive Pedestrian model. 
For profiling, we choose the fourth setting `p04`, which runs a simulation for
250 iterations using default parameters for the pedestrians. Every 5 iterations,
a new pedestrian enters the simulation until a maximum of 50 is reached at the
end of the simulation. This setting should give us a simulation that resembles 
realistic use cases.

The chosen simulation can be run by executing the following R script: 
`../predped/Experiments/Escience/R/3-play/play_escience_m01s02p04r002.R`. We 
choose the second file because it comes from a simulation only using R code 
(the script ending with `r001` uses C++ geometry functions). Note that, 
for the code to run properly, the working directory must be set to `../predped/`. 

The resulting data of the simulation with the chosen setting is located in the
directory `../predped/Experiments/Escience/Data/3-play/` in the file 
`/play_escience_m01s02p04r002.RDS`.

For profiling, we run the simulation for one more iteration from its last state
with 50 participants to see how fast the R code is under these conditions. The
profiling results can be obtained by running the R script 
`profile_predped_simulation_p04.R`. Note that the results might be 
slightly different every time the profiling is done because it is not 
deterministic. The conclusions, however, should remain the same. The script 
saves the profiling results as an interface in an HTML file.

### Profiling the Simulation with Improvements
Based on the first profiling, we optimized several functions that we identified as slow. We repeat the procedure for profiling the simulation in the previous section but substitute functions from 3 modules with optimized reimplementations ('geometry', 'see', 'utility_extra'). The profiling results can be reproduced by running the R script `profile_predped_simulation_p04_m4ma.R`. Again, the results might be slightly different every time the profiling is run.

### Profiling the Estimation
To profile the parameter estimation, we applied the function to a simulation result (setup: m01, s02) with max. 50 pedestrians and 600 iterations. This result is supposed to mimic a realistic use case of pedestrian behavior over 5 minute real time. It is stored in the file `../predped/Experiments/Escience/Data/3-play/play_escience_m01s02p03r001.RDS`. The profiling can be reproduced by executing the R script `profile_predped_estimation.R`,

## Results
In the profiling results, we focus on the data view in the HTML interface.

### Profiling the Simulation
The most time for executing the iteration is spent on `mcapply`. This function applies the
same anonymous routine to all pedestrians in the simulation. The anonymous 
function spends the most time on `utility` as well as `bodyObjectOK` and
`okObject`.

The `utility` function calls several sub functions from the `pp_utility` module:
`predClose`, `getLeaders`, `getBuddy`, `blockedAngle`, and `destinationAngle`. 
These in turn call functions from the `pp_geometry` and `pp_see` modules.

The functions `bodyObjectOK` and `okObject` also call sub functions from the
`pp_geometry` and `pp_see` modules.

One function from the `pp_see` module that is called very frequently and takes
much time is `line.line.intersection`. Within this function, calculating the
determinant of a 2x2 matrix is especially costly.

Based on the profiling results, we conclude that optimizing the functions in the following
modules will likely lead to improvements in the speed of the simulation:

- `pp_see`
- `pp_geometry`
- `pp_utility`

Most importantly, we expect that optimizing the function `line.line.intersection` in the `pp_see` module will lead to the greatest speed improvements.

### Profiling the Simulation with Improvements
With optimized functions from the `pp_geometry`, `pp_see`, and `pp_utility` modules, the profiling shows that the optimization and reimplementation substantially improved the speed of the simulation and the slow functions identified in the initial profiling. The function that remains costly, is `bodyObjectOK`. We therefore conclude that optimizing this function should even further improve the simulation speed.

### Profiling the Estimation
Again, most time for executing the likelihood estimation function is spent on `mclapply`, which applies an anonymous function to all iterations or pedestrians in the simulation result. The most expensive sub function is `like_state`, which computes the likelihood of a single iteration/subject. This function splits into two functions that consume a lot of time: `utility` and `pCNL`, which calculate the utility of probabilities movement decisions. Within the `utility` function, the function to compute the utility for the distance to other pedestrians called `idUtility` is the most expensive (it accounts for 2/3 of the execution time of `utility`).

Based on these insights, we conclude that optimizing the `utility` and `pCNL` functions including their sub functions will lead to the highest speed improvements for the parameter estimation function.


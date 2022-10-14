# Benchmark Performance Likelihood Functions

library(m4ma)

# Get benchmark helper functions
source('../bench/bench_helpers.R')

# Get predped functions for likelihood estimation
source("RCore/PredictivePedestrian.R")

# Load test case
obj_name = load('../bench/trace_i.rda')

# Get subject parameters
p = attr(get(obj_name), 'pMat')

# Define nests and alpha lists
nests = list(
  Central = c(0, 6, 17, 28),
  NonCentral = c(0:33)[-c(6, 17, 28)],
  acc = c(1:11),
  const = c(12:22),
  dec = c(0, 23:33)
)

alpha = list(
  Central = rep(1/3, 4),
  NonCentral = c(1/3, rep(0.5, 4), 1/3, rep(0.5, 9), 1/3, 
                 rep(0.5, 9), 1/3, rep(0.5, 5)),
  acc = c(rep(0.5, 4), 1, 1/3, rep(0.5, 5)),
  const = c(rep(0.5, 4), 1, 1/3, rep(0.5, 5)),
  dec = c(1/3, rep(0.5, 4), 1, 1/3, rep(0.5, 5))
)

# Get nest indices for cells
cell_nest = m4ma::get_cell_nest()

# Transform trace into format for C++ processing
trace_rcpp = m4ma::create_rcpp_trace(get(obj_name))

bench_df = microbenchmark(
  R = msumlogLike(p, get(obj_name), cores = 1),
  Rcpp = m4ma::msumlogLike(p, trace_rcpp, nests, alpha, cell_nest),
  times = 1000
) %>%
  mutate(fun_name = 'msumloglike')

# Calc ratio of execution times R/Rcpp
ratio_df = calc_exec_time_ratio(bench_df)

# Create plot of benchmark results
plot_benchmark(bench_df, ratio_df)

ggsave('../bench/figures/bench_utility.png', width = 8, height = 4)
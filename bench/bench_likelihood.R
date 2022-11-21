# Benchmark Performance Likelihood Functions

library(m4ma)
library(parallel)

# Get benchmark helper functions
source('bench_helpers.R')

# Get predped functions for likelihood estimation
source("../predped/RCore/pp_estimation.R")
source("../predped/RCore/pp_parameter.R")
source("../predped/RCore/pp_utility.R")

# Load small test case (max 3 subjects for 3 iterations)
load('play_escience_m01s02p02r001.rda')

# Get subject parameters
p_small = attr(trace_small, 'pMat')

# Load large test case (max 50 subjects for 600 iterations)
load('play_escience_m01s02p03r001.rda')

# Get subject parameters
p_large = attr(trace_large, 'pMat')

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
trace_rcpp_small = m4ma::create_rcpp_trace(trace_small)
trace_rcpp_large = m4ma::create_rcpp_trace(trace_large)

bench_df_small = microbenchmark(
  R = msumlogLike(p_small, trace_small, cores = 1),
  Rcpp = m4ma::msumlogLike(p_small, trace_rcpp_small, nests, alpha, cell_nest),
  times = 1000
) %>%
  mutate(fun_name = 'msumloglike-3_15')

bench_df_large = microbenchmark(
  R = msumlogLike(p_large, trace_large, cores = 1),
  Rcpp = m4ma::msumlogLike(p_large, trace_rcpp_large, nests, alpha, cell_nest),
  times = 10
) %>%
  mutate(fun_name = 'msumloglike-50_600')

write.csv(rbind(bench_df_small, bench_df_large), file.path('data', 'bench_likelihood.csv'))

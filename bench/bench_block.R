# Benchmark Performance Block Functions

library(m4ma)

# Get benchmark helper functions
source('bench_helpers.R')

# Create dummy objects
objects = list(
  list(x = c(0.15, 0.35), y = c(0.35, 0.55)),
  list(x = c(0.55, 0.35), y = c(0.75, 0.65))
)

set.seed(123)

centres = matrix(rnorm(66), 33, 2)

r = 0.5

ok = as.logical(rbinom(33, size = 1, prob = 0.5))

ok_centres = centres[ok, , drop = FALSE]

oL_r = object2lines_r(objects[[1]])
oL_rcpp = object2lines_rcpp(objects[[1]])

# Benchmark R vs Rcpp implementations
bench_df = rbind(
  bench_fun('object2lines', objects[[1]]),
  bench_fun_diff_args(
    'bodyObjectOverlap',
    r_args = list(oL_r, r, ok_centres),
    rcpp_args = list(oL_rcpp, r, ok_centres)),
  bench_fun('bodyObjectOK', r, centres, objects, ok)
)

write.csv(bench_df, file.path('data', 'bench_block.csv'))
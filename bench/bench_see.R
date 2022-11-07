# Benchmark Performance See Functions

library(m4ma)

# Get benchmark helper functions
source('bench_helpers.R')

# Create dummy objects
n = 1

P1 = c(0, 0); P2 = c(0, 1); P3 = c(1, 0); P4 = c(1, 1)

objects = list(
  list(x = c(0.25, 0.25), y = c(0.75, 0.75)),
  list(x = c(0.75, 0.75), y = c(0.25, 0.25))
)

state = list(
  p = matrix(P1, 1, 2),
  P = list(
    matrix(c(0.5, 0.5), 1, 2)
  )
)
attr(state$P[[1]], "i") = 1

ps = rbind(P2, P3, P4)

set.seed(123123)
centres = matrix(rnorm(66), 33, 2)

ok = as.logical(c(0, rep(1, 32)))

# Number of evaluations
n_eval = 1000

# Benchmark R vs Rcpp implementations
bench_df = rbind(
  bench_fun('line_line_intersection', P1, P2, P3, P4,
            extra_name = 'line_line_intersection-no_intersection'),
  bench_fun('line_line_intersection', P1, P4, P2, P3,
            extra_name = 'line_line_intersection-yes_intersection'),
  bench_fun('line_line_intersection', P1, P4, P2, P3, TRUE,
            extra_name = 'line_line_intersection-interior_only'),
  bench_fun('seesGoal', P1, P4, objects),
  bench_fun('seesCurrentGoal', n, state, objects),
  bench_fun('seesMany', P1, ps, objects),
  bench_fun('seesGoalOK', n, objects, state, centres, ok)
)

write.csv(bench_df, file.path('data', 'bench_see.csv'))

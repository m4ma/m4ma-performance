# Benchmark Performance Utility (Estimation) Functions

library(m4ma)

# Get benchmark helper functions
source('bench_helpers.R')

# Load test case
obj_name = load('trace_i.rda')

# Get subject parameters
p = attr(get(obj_name), 'pMat')[1, ]

# Create dummy precomputed utility variables 
set.seed(123123)
ba = runif(33, 0, 10)
names(ba) = 1:33

leaders = cbind(c(1, 85, 1), c(2, 135, 1), c(3, 45, 1))
rownames(leaders) = c('cell', 'angleDisagree', 'inGroup')

dists = matrix(rnorm(3 * 33), 3, 33)

fl = list( leaders = leaders, dists = dists)

ga = runif(11, 0, 10)

id = matrix(runif(2 * 33, 0, 10), 2, 33)
rownames(id) = 1:2

ok = matrix(as.logical(sample(c(0, 1), 33, replace = TRUE)), 11, 3)

group = c(1, 1, 1)
names(group) = 1:3

v = 0.5
d = 0.5

buddies = leaders[1:2, ]

wb = list(buddies = buddies, dists = dists)

# Benchmark R vs Rcpp implementations
bench_df = rbind(
  bench_fun_diff_args(
    'baUtility',
    r_args = list(p, ba),
    rcpp_args = list(p["aBA"], p["bBA"], ba, as.numeric(1:33)-1)
  ),
  bench_fun_diff_args(
    'caUtility',
    r_args = list(p),
    rcpp_args = list(p["aCA"], p["bCA"], p["bCAlr"])
  ),
  bench_fun_diff_args(
    'flUtility',
    r_args = list(p, fl),
    rcpp_args = list(p["aFL"], p["bFL"], p["dFL"], leaders, dists)
  ),
  bench_fun_diff_args(
    'gaUtility',
    r_args = list(p, ga),
    rcpp_args = list(p["bGA"], p["aGA"], ga)
  ),
  bench_fun_diff_args(
    'idUtility',
    r_args = list(p, 1, id, ok, group),
    rcpp_args = list(p["bID"], p["dID"], p["aID"], 0, ok, group, id)
  ),
  bench_fun_diff_args(
    'psUtility',
    r_args = list(p, v, d),
    rcpp_args = list(p["aPS"], p["bPS"], p["sPref"], p["sSlow"], v, d)
  ),
  bench_fun_diff_args(
    'wbUtility',
    r_args = list(p, wb),
    rcpp_args = list(p["aWB"], p["bWB"], buddies, dists)
  )
)

write.csv(bench_df, file.path('data', 'bench_utility.csv'))

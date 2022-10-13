# Benchmark Performance Geometry Functions

library(m4ma)

# Get benchmark helper functions
source('../bench/bench_helpers.R')

# Create dummy objects
nms = c('a1', 'a2', 'c1')

p1 = matrix(c(0, 0), 1, 2)
rownames(p1) = nms[1]

p1a = rbind(c(0, 0), c(0.75, 0.75), c(1.25, 1.25))

p2 = rbind(c(0, 0), c(0.5, 0.5), c(1, 1))
rownames(p2) = nms

a_double = 135
names(a_double) = nms[1]

a = c(90, 90, 90)
names(a) = nms

v = 0.5
names(v) = nms[1]

vels = matrix(rep(c(1.5, 1, .5), each = 11), ncol = 3)

angles = matrix(rep(c(72.5, 50, 32.5, 20, 10, 0, 350, 340, 
                      327.5, 310, 287.5), times = 3), ncol = 3)

# Benchmark R vs Rcpp implementations
bench_df = rbind(
  bench_fun('dist', p1a, p2),
  bench_fun('dist1', p1, p2),
  bench_fun('angle2', p1, p2),
  bench_fun('angle2', p1, p2),
  bench_fun('aTOd', a),
  bench_fun('Iangle', p1, a_double, p2),
  bench_fun('Dn', p1a, p2),
  bench_fun('minAngle', a_double, a),
  bench_fun('c_vd', 1:33, p1[1, ], v, a_double, vels, angles)
)

# Calc ratio of execution times R/Rcpp
ratio_df = calc_exec_time_ratio(bench_df)

# Create plot of benchmark results
plot_benchmark(bench_df, ratio_df)

ggsave('../bench/figures/bench_geometry.png', width = 8, height = 4)

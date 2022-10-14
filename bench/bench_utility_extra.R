# Benchmark Performance Utility Helper Functions

library(m4ma)

# Get benchmark helper functions
source('../bench/bench_helpers.R')

## Get dummy objects

# Pedestrian names
nms = c('a1', 'a2', 'c1')

# Current pedestrian
p1 = matrix(c(0, 0), 1, 2)
rownames(p1) = nms[1]

# All pedestrians
p2 = rbind(c(0, 0), c(0.5, 0.5), c(1, 1))
rownames(p2) = nms

# Pedestrian angle in front
a_front = 90
names(a_front) = nms[1]

# Pedestrian angles not in front
a_not_front = 135
names(a_not_front) = nms[1]

# Pedestrian angles vector
a = c(90, 90, 90)
names(a) = nms

# Pedestrian velocities
v = c(0.5, 0.5, 0.5)
names(v) = nms

# Goals
P1 = matrix(c(2, 2, -1, -1), 2, 2)
rownames(P1) = c('g1', 'g2')
attr(P1, 'i') = 1

# Pedestrian radius
r = c(0.5, 0.5, 0.5)
names(r) = nms

# Pedestrian group
group = c(2, 1, 2)
names(group) = nms

# Cell centres
set.seed(23123)
centres = matrix(rnorm(66), 33, 2)

# Predicted pedestrian positions
p_pred = rbind(c(0, 0), c(0.75, 0.75), c(1.25, 1.25))
rownames(p_pred) = nms

# Objects not occluding view between p1 and p2
objects = list(
  list(x = c(1, 0), y = c(0, 1)),
  list(x = c(0, 1), y = c(1, 0))
)

# Objects occluding view between p1 and p2
objects_occlude = list(
  list(x = c(0.15, 0.35), y = c(0.15, 0.35))
)

# State list
state = list(
  p = p2,
  a = c(45, 45, 45),
  v = v,
  r = r,
  P = list(
    P1, P1, P1
  ),
  group = group
)
names(state$a) = nms

# Pos of current pedestrian in p2
n = 1

# Dummy cones for iCones2Cells
set.seed(23123)
cones = c(rnorm(6))
names(cones) = as.character(1:6)

# Benchmark R vs Rcpp implementations
bench_df = rbind(
  bench_fun('destinationAngle', a_front, p1, P1),
  bench_fun('predClose', n, p1, a_front,
            p2, r, centres, p_pred, objects),
  bench_fun('eObjects', p1, p2, r),
  # bench_fun leads to stack overflow here
  microbenchmark(
    R = iCones_r(p1, a_front, p2[-n, , drop = FALSE], r, objects),
    Rcpp = iCones_rcpp(p1, a_front, p2[-n, , drop = FALSE], r, objects),
    times = 1000
  ) %>%
    mutate(fun_name = 'iCones'),
  bench_fun('iCones2Cells', cones, v[1]),
  bench_fun('blockedAngle', n, state, p_pred, objects),
  bench_fun('getLeaders', n, state_leaders, centres, objects)
)

# Calc ratio of execution times R/Rcpp
ratio_df = calc_exec_time_ratio(bench_df)

# Create plot of benchmark results
plot_benchmark(bench_df, ratio_df)

ggsave('../bench/figures/bench_utility_extra.png', width = 8, height = 4)
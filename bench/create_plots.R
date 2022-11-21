# Create plots for performance benchmarks

library(purrr)

source(file.path('..', 'bench', 'bench_helpers.R'))

# Load benchmark data

mod_names = c('geometry', 'likelihood', 'see', 'utility_extra', 'utility', 'block')

load_bench_df = function(name) {
  df = read.csv(file.path('..', 'bench', 'data', paste0('bench_', name, '.csv')))
  return(df)
}

bench_dfs = map(mod_names, load_bench_df)

# Calc ratio of execution times R/Rcpp
ratio_dfs = map(bench_dfs, calc_exec_time_ratio)

# Create plots of benchmark results
theme_set(theme_classic(base_size = 14))

plots = map2(bench_dfs, ratio_dfs, plot_benchmark)

# Save plots
save_plot = function(name, plot) {
  ggsave(file.path('..', 'bench', 'figures', paste0('bench_', name, '.png')), plot = plot,
         width = 8, height = 4)
  return(invisible(NULL))
}

map2(mod_names, plots, save_plot)

# Load benchmark data for moveAll
moveAll_df = read.csv(file.path('..', 'bench', 'data', 'bench_moveAll.csv'))

# Plot elapsed times for substitution in moveAll
ggplot(moveAll_df, aes(
  x = time,
  y = reorder(labels, time),
  label = reorder(ratio, time)
)) + 
  geom_col(fill = 'steelblue') +
  geom_text() +
  labs(
    x = 'Total elapsed time (in s)',
    y = '',
    subtitle = 'Modules/functions used from m4ma\ninstead of predped'
  )

ggsave(file.path('..', 'bench', 'figures', 'bench_moveAll.png'), width = 8, height = 4)

# Load simulation execution times
sim_time = sapply(1:5, function(i) read.csv(file.path('..', 'bench', 'data', paste0('bench_play_escience_m01s02p03r00', i, '.csv')))[,3])

# Create data frame
sim_time_df = data.frame(
  time = sim_time,
  labels = c('[None]', 'see', 'see + utility_extra', 'see + utility_extra + geometry', 'see + utility_extra + block'),
  ratio = round(sim_time[1] / sim_time, 2)
)

ggplot(sim_time_df, aes(x = time, y = reorder(labels, time), label = reorder(ratio, time))) + 
  geom_boxplot(color = 'steelblue') +
  geom_point() +
  geom_text(aes(x = 0)) +
  scale_x_continuous(limits = c(0, 2000), breaks = seq(0, 2000, 250)) +
  labs(
    x = 'Total elapsed time (in s)',
    y = '',
    subtitle = 'Modules used from m4ma\ninstead of predped'
  )

ggsave(file.path('..', 'bench', 'figures', 'bench_play_escience_m01s02p03.png'), width = 8, height = 4)

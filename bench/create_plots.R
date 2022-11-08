# Create plots for performance benchmarks

library(purrr)

source(file.path('..', 'bench', 'bench_helpers.R'))

# Load benchmark data

mod_names = c('geometry', 'likelihood', 'see', 'utility_extra', 'utility')

load_bench_df = function(name) {
  df = read.csv(file.path('..', 'bench', 'data', paste0('bench_', name, '.csv')))
  return(df)
}

bench_dfs = map(mod_names, load_bench_df)

# Calc ratio of execution times R/Rcpp
ratio_dfs = map(bench_dfs, calc_exec_time_ratio)

# Create plots of benchmark results
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
    y = 'Functions used from m4ma instead of predped'
  ) + theme_classic()

ggsave(file.path('..', 'bench', 'figures', 'bench_moveAll.png'), width = 8, height = 4)
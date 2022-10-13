# Helper Functions for Benchmarking

library(microbenchmark)
library(dplyr)
library(ggplot2)
library(tidyr)

# Benchmark factory function
bench_fun = function(fun_name, ..., extra_name = NULL, n_eval = 1000) {
  # Get R and Rcpp functions
  r = get(paste0(fun_name, '_r'))
  cpp = get(paste0(fun_name, '_rcpp'))
  
  # Benchmark
  df = microbenchmark(
    r(...),
    cpp(...),
    times = n_eval
  )
  
  levels(df$expr) = c('R', 'Rcpp')
  
  # Assign special name for different conditions if necessary
  df['fun_name'] = if (is.null(extra_name)) fun_name else extra_name
  
  return(df)
}

# Benchmark factory function when R and Rcpp need different args
bench_fun_diff_args = function(
    fun_name, r_args, rcpp_args, extra_name = NULL, n_eval = 1000
) {
  # Get R and Rcpp functions
  r = get(paste0(fun_name, '_r'))
  cpp = get(paste0(fun_name, '_rcpp'))
  
  # Benchmark
  df = microbenchmark(
    do.call(r, r_args),
    do.call(cpp, rcpp_args),
    times = n_eval
  )
  
  levels(df$expr) = c('R', 'Rcpp')
  
  # Assign special name for different conditions if necessary
  df['fun_name'] = if (is.null(extra_name)) fun_name else extra_name
  
  return(df)
}

# Compute median exec time ratio
calc_exec_time_ratio = function(df) {
  ratio_df = df %>%
    group_by(expr, fun_name) %>%
    summarise(med = median(time)) %>% # median exec time
    mutate(id = row_number()) %>%
    ungroup() %>%
    pivot_wider( # to wide format
      id_cols = c('fun_name'),
      names_from = c('expr'),
      values_from = 'med'
    ) %>%
    mutate(ratio = R / Rcpp) # calc ratio
  
  return(ratio_df)
}

# Create benchmark plot with exec time ratio
plot_benchmark = function(bench_df, ratio_df) {
  p = ggplot(bench_df, aes(
      x = log10(time*1e-6), # convert to ms
      y = fun_name, 
      color = expr
    )) +
    geom_boxplot() +
    geom_text( # add ratio
      data = ratio_df,
      aes(y = seq_len(nrow(ratio_df)), x = 0, label = round(ratio, 2)),
      inherit.aes = FALSE
    ) +
    labs(
      x = expression(log[10]~'(exec time) [in ms]'),
      y = 'Function name',
      color = ''
    ) +
    scale_color_manual(values = c('steelblue', 'indianred')) + 
    theme_classic()
  
  return(p)
}
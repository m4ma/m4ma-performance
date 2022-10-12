# Performance Optimization in the Minds for Mobile Agents Project

A repository for evaluating the performance optimization in the Minds for 
Mobile Agents project. It contains both code and files for profiling the
Predictive Pedestrian model in the `profile/` directory. The `bench/` directory
contains code and files for comparing the performance of the original R
functions against the optimized versions in the m4ma R package. The optimized
versions are usually written in C++ and imported using the Rcpp framework.

The `predped` sub module is a fork of the `predped` package which contains the
original R code for simulating and estimating the Predictive Pedestrian model.
Initiating the sub module requires access to the original repository which is
private until publication.

## Requirements
- R and RStudio
- R packages available on CRAN:
  - cppRouting
  - igraph
  - parallel
  - profvis
  - TSP
- The m4ma R package containing optimized code

The R packages on CRAN can be installed via:

```r

install.packages(c("cppRouting", "igraph", "parallel", "profvis", "TSP"))

```

The m4ma package can be install from GitHub via devtools:

```r

install.packages("devtools")

devtools::install_github("m4ma/m4ma")

```

## Getting Started
Clone this repository using the command line:

```console

git clone https://github.com/m4ma/m4ma-performance.git

cd ./m4ma-performance

```

With access to the `predped` repository, initiate and fetch the sub module:

```console

git submodule init

git submodule update

```

**Important**: To run the scripts in the `profile/` and `bench/` directories,
it is best to open the `predped/` sub directory as a project in RStudio or set
the working directory there with `setwd("predped")`.
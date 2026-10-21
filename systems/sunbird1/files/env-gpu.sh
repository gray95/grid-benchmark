#!/usr/bin/env bash

module load mpi/openmpi/4.1.6
module load compiler/gnu/11/3.0;
module load CUDA/11.7

# location of Grid dependencies
# these need to be installed beforehand
export GRID_DEP=$HOME/GridSupport

#!/usr/bin/env bash

module purge
module load mpi/openmpi/4.1.6
module load compiler/gnu/12/1.0;

# location of Grid dependencies
# these need to be installed beforehand
export GRID_DEP=$HOME/GridSupport

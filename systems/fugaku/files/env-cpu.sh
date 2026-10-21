#!/usr/bin/env bash

# Cross-compilation for the A64FX compute nodes from the x86 login nodes: the compiler
# wrappers (a64fx-clang, a64fx-clang++, mpiclang, mpiclang++) use the clang of the
# 'a64fx-toolchain' Pixi environment and the system Fujitsu MPI (mpifccpx, mpiFCCpx).
export PATH="${GRIDENVDIR}:${PATH}"
# binaries find the A64FX libraries through their rpath on the compute nodes
export A64FX_LDFLAGS="-Wl,-rpath,${CONDA_PREFIX}/lib"

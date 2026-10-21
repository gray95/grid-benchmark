#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2050,SC2170
# submit with: pjsub -g <group> run.cpu.4n.sh

#PJM -N benchmark-grid-4
#PJM -L "elapse=1:00:00"
#PJM -L "node=2x2x1:torus"
#PJM -L "rscgrp=small-torus"
# normal mode (2.0 GHz, both FP pipelines): faster than the default boost-eco mode,
# which runs at 2.2 GHz with one FP pipeline
#PJM -L "freq=2000,eco_state=0"
#PJM --mpi "max-proc-per-node=4"
#PJM --mpi "rank-map-bychip:XYZ"
#PJM -x PJM_LLIO_GFSCACHE=/vol0004:/vol0005
#PJM -o %n.%j.out
#PJM -e %n.%j.err
#PJM -S

set -euo pipefail

# load environment #############################################################
# the environment's x86 tools are not sourced on the compute nodes: the binaries
# find the A64FX libraries through their rpath
env_cfg="${HOME}/.config/grid-benchmark/grid-env"
if [ ! -f "${env_cfg}" ]; then
	echo "error: ${env_cfg} does not exists"
	exit 1
fi
env_dir="$(readlink -f "$(cat "${env_cfg}")")"
export OMP_NUM_THREADS=12
export PLE_MPI_STD_EMPTYFILE=off

# application and parameters ###################################################
app="${env_dir}/prefix/gridbench_cpu/bin/Benchmark_Grid"

# collect job information ######################################################
job_info_dir=job/${PJM_JOBNAME}.${PJM_JOBID}
mkdir -p "${job_info_dir}"

date                         > "${job_info_dir}/start-date"
echo "epoch $(date '+%s')" >> "${job_info_dir}/start-date"
set                          > "${job_info_dir}/env"
ldd "${app}"                 > "${job_info_dir}/ldd"
md5sum "${app}"              > "${job_info_dir}/app-hash"
readelf -a "${app}"          > "${job_info_dir}/elf"
mpiexec -n $(( 4 * PJM_NODE )) -stdout-proc "${job_info_dir}/nodes" hostname
cat "${job_info_dir}"/nodes.* | sort -u > "${job_info_dir}/nodes" && rm -f "${job_info_dir}"/nodes.*
cp "${BASH_SOURCE[0]}"       "${job_info_dir}/script"

# run! #########################################################################
# 4 ranks per node (one per CMG), 12 threads each; rank 0 output goes to 'log'
# (--comms-overlap: with feature/fugaku-optimisation, halo exchange overlapped with the interior
# computation through Fujitsu MPI persistent requests and MPI polling, no slower for any test here;
# --tofu: Grid lays its node grid onto the job's Tofu torus, which needs every node grid extent
# larger than 1 to be an extent of the torus shape requested above;
# --max-L 24: the domain-wall test at L = 32 does not fit in the node memory;
# --shm 2048: the largest halo buffers need about 1.2 GB per rank, pages are only used when touched;
# SU(3) only: the SU(4) and Sp(4) tests are disabled, Sp(4) two-index antisymmetric at L = 24 does not
# fit in the node memory)
mpiexec -n $(( 4 * PJM_NODE )) -stdout-proc "${job_info_dir}/log" \
	-stderr-proc "${job_info_dir}/err" \
	"${app}" \
	--json-out "${job_info_dir}/result.json" \
	--mpi 2.2.2.2 \
	--threads 12 \
	--dslash-asm \
	--comms-overlap \
	--tofu \
	--max-L 24 \
	--shm 2048 \
	--no-benchmark-su4 \
	--no-benchmark-flops-su4 \
	--no-benchmark-flops-sp4-f \
	--no-benchmark-flops-sp4-2as
mv "${job_info_dir}"/log.*.0 "${job_info_dir}/log" && rm -f "${job_info_dir}"/log.*
cat "${job_info_dir}"/err.* > "${job_info_dir}/err" 2> /dev/null || true
rm -f "${job_info_dir}"/err.*

# if we reach that point the application exited successfully ###################
touch "${job_info_dir}/success"
date > "${job_info_dir}/end-date"
echo "epoch $(date '+%s')" >> "${job_info_dir}/end-date"

################################################################################

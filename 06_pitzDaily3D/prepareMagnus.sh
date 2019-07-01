#!/bin/bash --login
#SBATCH --ntasks=1
#SBATCH --time=00:30:00
#SBATCH --partition=debugq
#SBATCH --job-name=prepare
#SBATCH --export=NONE

module swap PrgEnv-cray PrgEnv-gnu
module swap gcc gcc/5.3.0
module use /group/director782/espinosa/software/cle60up05/modulefiles
module load openfoam+/v1812

AEG_ranks="0 8 16 24 32 40 48 56 64 72 80 88 96 104 112 120 128 136 144 152 160 168 176 184"

srun --export=all -n 1 blockMesh -fileHandler collated -ioRanks "(${AEG_ranks})"
srun --export=all -n 1 renumberMesh -overwrite -fileHandler collated -ioRanks "(${AEG_ranks})"
srun --export=all -n 1 decomposePar -force -fileHandler collated -ioRanks "(${AEG_ranks})"

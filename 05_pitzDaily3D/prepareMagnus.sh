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

AEG_ranks="0 24 48 72 96 120 144 168"

srun --export=all -n 1 blockMesh -fileHandler collated -ioRanks "(${AEG_ranks})"
srun --export=all -n 1 renumberMesh -overwrite -fileHandler collated -ioRanks "(${AEG_ranks})"
srun --export=all -n 1 decomposePar -force -fileHandler collated -ioRanks "(${AEG_ranks})"

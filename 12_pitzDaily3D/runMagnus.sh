#!/bin/bash --login
#SBATCH --ntasks=192
#SBATCH --time=00:05:00
#SBATCH --partition=workq
#SBATCH --job-name=pitz3D_192Magnus
#SBATCH --export=NONE

module swap PrgEnv-cray PrgEnv-gnu
module swap gcc gcc/5.3.0
module use /group/director782/espinosa/software/cle60up05/modulefiles
module load openfoam+/v1812

#Preparing the case ..........
####srun --export=all -n 1 blockMesh -fileHandler uncollated
####srun --export=all -n 1 renumberMesh -overwrite -fileHandler uncollated
####srun --export=all -n 1 decomposePar -force -fileHandler uncollated

#Running the case ..........
#srun --export=all -n $SLURM_NTASKS --unbuffered pimpleFoam -parallel -fileHandler uncollated

#Running the case with Darshan ..........
module use /group/pawsey0001/software/cle60up05/modulefiles
module load darshan
srun --export=all -n $SLURM_NTASKS --unbuffered pimpleDarshanFoam -parallel -fileHandler uncollated

#Running the case with pat_run  ..........
###module load perftools-preload
###srun --export=all -n $SLURM_NTASKS --unbuffered pat_run -z pm="mpi" /group/director782/espinosa/software/cle60up05/apps/PrgEnv-gnu/6.0.4/gcc/5.3.0/haswell/openfoam+/v1812/OpenFOAM-v1812/platforms/linux64CrayDPInt32Opt/bin/pimpleFoam -parallel -fileHandler uncollated

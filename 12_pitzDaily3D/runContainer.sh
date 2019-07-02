#!/bin/bash --login
#SBATCH --ntasks=96
#SBATCH --time=00:10:00
#SBATCH --partition=debugq
#SBATCH --job-name=pitz3D_96
#SBATCH --export=NONE

OFVERSION=v1812

module swap sandybridge broadwell
module load shifter

srun -export=all -ntasks=$SLURM_NTASKS shifter run --mpi alexisespinosa/openfoam:$OFVERSION pimpleFoam -parallel

#!/bin/bash --login
#SBATCH --ntasks=192
#SBATCH --time=00:15:00
#SBATCH --partition=workq
#SBATCH --job-name=pitz3D_192Magnus
#SBATCH --export=NONE

echo "Raw module list"
module list
echo "----------------------------------------"

module swap PrgEnv-cray PrgEnv-gnu
module swap gcc gcc/5.3.0
module use /group/director782/espinosa/software/cle60up05/modulefiles
module load openfoam+/v1812
echo "Updated #1 module list"
module list
echo "----------------------------------------"

#Setting the iteration and resubmission
#-----------------------
##Setting the slurm-cycle variables
#job_iteration variable will be received through the --export=all call of the "previous job", otherwise it is default to 1
: ${job_iteration:="1"}
this_job_iteration=${job_iteration}
#It is always good to have a reasonable number here
job_iteration_max=10
echo "This jobscript is calling itself in cycles. This is iteration=${this_job_iteration}."
echo "And the slurm job id is: ${SLURM_JOB_ID}"

#-----------------------
##Defining the name of the dependent script (in this case this script)
thisScript=`squeue -h -j $SLURM_JOBID -o %o`
export dependentScript=${thisScript}

#-----------------------
##Security checks before proceeding
#Check 1: If the file named stopSlurmCycle exists in the submission directory, then stop execution.
#         Create a file with this name if you want to interrupt the submission cycle by using the following two commands:
#             touch stopSlurmCycle
#             scancel the-job-IDs-of-the-jobs-involved-in-the-cycle
#         Remember to scancel both, the queued waiting job and the running job.
if [[ -f stopSlurmCycle ]]; then
   echo "The file \"stopSlurmCycle\" exists, so the script \"${thisScript}\" will exit."
   echo "If you still want to use the script, you need to remove that file."
   exit 1
fi
#Check 2: If the number of output files is large ("slurm*" in this case), this could be a sign of the recursive loop executing to infinity
#         Check your output files regularly and remove the not needed old ones to avoid falling into this check with no reason.
maxSlurmies=25
slurmies=$(find . -maxdepth 1 -name "slurm*" | wc -l)
if [ $slurmies -gt $maxSlurmies ]; then
   echo "There are ${slurmies} slurm files in the directory and is greater that the maximum allowed=${maxSlurmies}"
   echo "This could be a sign of an infinite loop of slurm cycle calls."
   echo "So the script ${thisScript} will exit."
   exit 2
fi

#-----------------------
##Submitting the dependent job in an iterative cycle
#IMPORTANT: Never use cycles that could fall into infinite loops. Numbered cycles are the best option.
#The following variable needs to be "true" for the cycle to proceed
useDependentCycle=true
#The if clause also checks for the correct value of job_iteration in order to proceed
if [ "$useDependentCycle" = "true" ] && [ ${job_iteration} -lt ${job_iteration_max} ]; then
   #Update the counter of cycle iterations
   (( job_iteration ++ ))
   #IMPORTANT: The --export="list_of_exported_vars" guarantees that values are passed to the dependent job
   next_jobid=$(sbatch --export="job_iteration=${job_iteration}" --dependency=afterok:${SLURM_JOB_ID} ${dependentScript} | awk '{print $4}')
   echo "Dependent with slurm job id ${next_jobid} was submitted"
   echo "If you want to stop the submission chain it is recommended to use scancel on the dependent job first"
   echo "Or create a file named: \"stopSlurmCycle\""
   echo "And then you can scancel this job if needed too"
else
   echo "This is the last iteration of the cycle, no more dependent jobs will be submitted"
fi

#Preparing the case ..........
AEG_ranks="0 8 16 24 32 40 48 56 64 72 80 88 96 104 112 120 128 136 144 152 160 168 176 184"
####srun --export=all -n 1 blockMesh -fileHandler collated -ioRanks "(${AEG_ranks})"
####srun --export=all -n 1 renumberMesh -overwrite -fileHandler collated -ioRanks "(${AEG_ranks})"
####srun --export=all -n 1 decomposePar -force -fileHandler collated -ioRanks "(${AEG_ranks})"

#Removing any existing result file
find -P . -mindepth 2 -maxdepth 2 -type d -name "0.*" -print0 -o -name "*e-*" -print0 -o -name "*e+*" -print0 | xargs -0 -I{} find -P {} -type f -print0 -o -type l -print0 | xargs -0 munlink
find -P . -mindepth 2 -maxdepth 2 -type d -name "0.*" -print0 -o -name "*e-*" -print0 -o -name "*e+*" -print0 | xargs -0 -I{} find {} -type d -empty -delete

#Running the case ..........
#srun --export=all -n $SLURM_NTASKS --unbuffered pimpleFoam -parallel -fileHandler collated -ioRanks "(${AEG_ranks})"

#Running the case with Darshan ..........
module use /group/pawsey0001/software/cle60up05/modulefiles
module load darshan
echo "Updated #2 module list"
module list
echo "----------------------------------------"
srun --export=all -n $SLURM_NTASKS --unbuffered pimpleDarshanFoam -parallel -fileHandler collated -ioRanks "(${AEG_ranks})"

#Running the case with pat_run  ..........
###module load perftools-preload
###srun --export=all -n $SLURM_NTASKS --unbuffered pat_run -z pm="mpi" /group/director782/espinosa/software/cle60up05/apps/PrgEnv-gnu/6.0.4/gcc/5.3.0/haswell/openfoam+/v1812/OpenFOAM-v1812/platforms/linux64CrayDPInt32Opt/bin/pimpleFoam -parallel -fileHandler collated -ioRanks "(${AEG_ranks})"
###mv patran.txt patran-%SLURM_JOB_ID.txt

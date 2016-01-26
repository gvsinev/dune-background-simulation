#!/bin/bash
#==================================================
# A script to reconstruct a simulation with
# signals on DUNE photon detectors.
#
# Based on simulation.sh,
# which is in turn based on Alex Himmel's script 
# OpticalLibraryBuild_Grid_lbne.sh
# 
# Gleb Sinev, Duke, 2015, gleb.sinev@duke.edu
#==================================================

# This is how to run this script:
# ./reconstruction.sh $MRB_TOP $MRB_PROJECT $MRB_PROJECT_VERSION $MRB_QUALS $input $sim_cluster $sim_process

# Allow created files and directories to be accessed
# by everyone in the group
umask 0002 

# Define environment variables
group=dune
input=$5
if [ "$7" = "all" ]
then input_label=${6}_$(printf '%03d' $PROCESS)
else input_label=${6}_${7}
fi
label=${input_label}_${CLUSTER:-test}
log=${CONDOR_DIR_LOG:-$PWD}/efficiency_reconstruction_${label}.log
reco_fcl=${CONDOR_DIR_FCL:-$PWD}/efficiency_reco_rerun_${label}.fcl

# Create a log file
touch $log
echo "Writing log to $log" 1>> $log 2>&1
echo                       1>> $log 2>&1

# Rename FHiCL files
echo "Create this job's FHiCL files"               1>> $log 2>&1
mv -v ${CONDOR_DIR_INPUT:-$PWD}/reco.fcl $reco_fcl 1>> $log 2>&1
echo                                               1>> $log 2>&1

# Need to change the process_name, otherwise LArSoft complains
# that data products with the same name already exist
# (because it already contains reconstructed data products)
echo "Change process_name and number of events processed"                     1>> $log 2>&1
echo 'sed -i  "s/process_name: OpReco/process_name: OpRecoRerun/"  $reco_fcl' 1>> $log 2>&1
sed -i  "s/process_name: OpReco/process_name: OpRecoRerun/"  $reco_fcl        1>> $log 2>&1
# Process all simulated events
echo 'sed -i  "s/maxEvents:   1000/maxEvents:   -1  /"             $reco_fcl' 1>> $log 2>&1
sed -i  "s/maxEvents:   1000/maxEvents:   -1  /"             $reco_fcl        1>> $log 2>&1
echo                                                                          1>> $log 2>&1

# Change to the output directory
cd ${CONDOR_DIR_ROOT:-$PWD} 1>> $log 2>&1
echo "cd $OLDPWD -> $PWD"   1>> $log 2>&1
echo                        1>> $log 2>&1

# Output some environment variables
echo "Environment:"             1>> $log 2>&1
echo "HOSTNAME:     " $HOSTNAME 1>> $log 2>&1
echo "CLUSTER:      " $CLUSTER  1>> $log 2>&1
echo "PROCESS:      " $PROCESS  1>> $log 2>&1
echo "PWD:          " $PWD      1>> $log 2>&1
echo                            1>> $log 2>&1

# Give meaningful names to the script arguments
mrb_top=$1
mrb_project=$2
mrb_version=$3
mrb_quals=$(echo $4 | tr : _)

# Setup the environment
echo "Setup $group environment"                                                           1>> $log 2>&1
echo "> source /grid/fermiapp/products/$group/setup_$group.sh"                            1>> $log 2>&1
source /grid/fermiapp/products/$group/setup_$group.sh                                     1>> $log 2>&1
echo "> source ${mrb_top}/localProducts_${mrb_project}_${mrb_version}_${mrb_quals}/setup" 1>> $log 2>&1
source ${mrb_top}/localProducts_${mrb_project}_${mrb_version}_${mrb_quals}/setup          1>> $log 2>&1
echo "> mrbslp"                                                                           1>> $log 2>&1
mrbslp                                                                                    1>> $log 2>&1
echo                                                                                      1>> $log 2>&1

envlog=${CONDOR_DIR_LOG:-$PWD}/environment_reconstruction_${label}.log
touch $envlog
uname -a                1>> $envlog 2>&1
echo                    1>> $envlog 2>&1
cat /etc/redhat-release 1>> $envlog 2>&1
echo                    1>> $envlog 2>&1
env                     1>> $envlog 2>&1

# Copy the input Root file
echo "Copy the input file to the current directory"                1>> $log 2>&1
echo "> ifdh cp ${input}_${input_label}.root ./reco_${label}.root" 1>> $log 2>&1
ifdh cp ${input}_${input_label}.root ./reco_${label}.root          1>> $log 2>&1
echo                                                               1>> $log 2>&1

# Run the job
echo "***** Starting job"                                       1>> $log 2>&1
echo                                                            1>> $log 2>&1
lar -c $reco_fcl -s reco_${label}.root -T flashes_${label}.root 1>> $log 2>&1
echo                                                            1>> $log 2>&1
ret=$? # Record the return value of the last process
echo "***** Job completed ($ret)"                               1>> $log 2>&1
echo                                                            1>> $log 2>&1
# Remove all the root files except for {waveforms,anatree}_${label}.root
rm -v reco*.root                                                1>> $log 2>&1
echo                                                            1>> $log 2>&1
date                                                            1>> $log 2>&1

# Exit with the return/exit code from running LArSoft
exit $ret

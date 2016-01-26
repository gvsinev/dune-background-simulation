#!/bin/bash
#==================================================
# A script to generate photon detector simulation 
# for single electrons with several energy values
# and the vertex position uniformly distributed
# inside the 4APA detector.
# Then photon detector reconstruction is run
# on that simulation.
#
# Based on Alex Himmel's script 
# OpticalLibraryBuild_Grid_lbne.sh
# 
# Gleb Sinev, Duke, 2015, gleb.sinev@duke.edu
#==================================================

# This is how to run this script:
# ./simulation.sh $MRB_TOP $MRB_PROJECT $MRB_PROJECT_VERSION $MRB_QUALS $number_of_events

# Allow created files and directories to be accessed
# by everyone in the group
umask 0002 

# Define environment variables
group=dune
label=${CLUSTER:-test}_$(printf '%03d' $PROCESS)
log=${CONDOR_DIR_LOG:-$PWD}/efficiency_simulation_${label}.log
gen_fcl=${CONDOR_DIR_FCL:-$PWD}/efficiency_gen_${label}.fcl
g4_fcl=${CONDOR_DIR_FCL:-$PWD}/efficiency_g4_${label}.fcl
digi_fcl=${CONDOR_DIR_FCL:-$PWD}/efficiency_digi_${label}.fcl
reco_fcl=${CONDOR_DIR_FCL:-$PWD}/efficiency_reco_${label}.fcl

# Create a log file
touch $log
echo "Writing log to $log" 1>> $log 2>&1
echo                       1>> $log 2>&1

# Rename FHiCL files
echo "Create this job's FHiCL files"                1>> $log 2>&1
mv -v ${CONDOR_DIR_INPUT:-$PWD}/gen_*.fcl $gen_fcl  1>> $log 2>&1
mv -v ${CONDOR_DIR_INPUT:-$PWD}/g4.fcl    $g4_fcl   1>> $log 2>&1
mv -v ${CONDOR_DIR_INPUT:-$PWD}/digi.fcl  $digi_fcl 1>> $log 2>&1
mv -v ${CONDOR_DIR_INPUT:-$PWD}/reco.fcl  $reco_fcl 1>> $log 2>&1
echo                                                1>> $log 2>&1

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
number_of_events=$5

# Setup the environment
echo "Setup $group environment"                                                           1>> $log 2>&1
echo "> source /grid/fermiapp/products/$group/setup_$group.sh"                            1>> $log 2>&1
source /grid/fermiapp/products/$group/setup_$group.sh                                     1>> $log 2>&1
echo "> source ${mrb_top}/localProducts_${mrb_project}_${mrb_version}_${mrb_quals}/setup" 1>> $log 2>&1
source ${mrb_top}/localProducts_${mrb_project}_${mrb_version}_${mrb_quals}/setup          1>> $log 2>&1
echo "> mrbslp"                                                                           1>> $log 2>&1
mrbslp                                                                                    1>> $log 2>&1
echo                                                                                      1>> $log 2>&1

# Edit the search path to include Alex's photon libraries
#export FW_SEARCH_PATH="/lbne/data/users/ahimmel/Libraries/:$FW_SEARCH_PATH"

envlog=${CONDOR_DIR_LOG:-$PWD}/environment_simulation_${label}.log
touch $envlog
uname -a                1>> $envlog 2>&1
echo                    1>> $envlog 2>&1
cat /etc/redhat-release 1>> $envlog 2>&1
echo                    1>> $envlog 2>&1
env                     1>> $envlog 2>&1

# Run the job
echo "***** Starting job"                                                                         1>> $log 2>&1
echo                                                                                              1>> $log 2>&1
lar -c $gen_fcl               -o gen.root                                    -n $number_of_events 1>> $log 2>&1
echo                                                                                              1>> $log 2>&1
echo "***** Gen stage done, starting G4"                                                          1>> $log 2>&1
echo                                                                                              1>> $log 2>&1
lar -c $g4_fcl   -s gen.root  -o g4.root                                     -n $number_of_events 1>> $log 2>&1
echo                                                                                              1>> $log 2>&1
echo "***** G4 stage done, starting Digi"                                                         1>> $log 2>&1
echo                                                                                              1>> $log 2>&1
lar -c $digi_fcl -s g4.root   -o digi.root                                   -n $number_of_events 1>> $log 2>&1
echo                                                                                              1>> $log 2>&1
echo "***** Digi stage done, starting Reco"                                                       1>> $log 2>&1
echo                                                                                              1>> $log 2>&1
lar -c $reco_fcl -s digi.root -o reco_${label}.root -T flashes_${label}.root -n $number_of_events 1>> $log 2>&1
echo                                                                                              1>> $log 2>&1
ret=$? # Record the return value of the last process
echo "***** Job completed ($ret)"                                                                 1>> $log 2>&1
echo                                                                                              1>> $log 2>&1
# Remove all the root files except for {waveforms,anatree}_${label}.root
rm -v {gen,g4,digi}.root *hist*.root                                                              1>> $log 2>&1
echo                                                                                              1>> $log 2>&1
date                                                                                              1>> $log 2>&1

# Exit with the return/exit code from running LArSoft
exit $ret

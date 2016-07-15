#!/bin/bash
# Usage: ./SubmitPDReco.sh sim_cluster sim_process option

script=reconstruction.sh

sim_cluster=$1   # Label of the simulation files to process
sim_process="$2" # "all" (all files with the sim_cluster -- don't forget to quote the asterisk!) or XX (a digit or several) is expected
option=$3        # "nobg", "ar39", or "rn222"

clientargs="--group=dune --role=Analysis --resource-provides=usage_model=DEDICATED,OPPORTUNISTIC --OS=SL6 --expected-lifetime='long' --memory=2GB"

dir=/pnfs/dune/scratch/users/gvsinev/photon_detectors/efficiency/dune4apa_${option} # PNFS Scratch directory

reco_fcl=$PWD/reco.fcl
fileargs="-f $reco_fcl"

input=$dir/root/reco
if [ "$sim_process" = "all" ]
then njobs=$(ls -l ${input}_${sim_cluster}_*.root | wc -l)
else njobs=1
fi

outputargs="-dROOT $dir/root -dFCL $dir/fcl -dLOG $dir/log"

larsoft="$MRB_TOP $MRB_PROJECT $MRB_PROJECT_VERSION $MRB_QUALS"
scriptargs="$larsoft $input $sim_cluster $sim_process"
thisjob="-q -N $njobs file://$PWD/$script $scriptargs"

#echo "jobsub_submit $clientargs $fileargs $outputargs $thisjob"
jobsub_submit $clientargs $fileargs $outputargs $thisjob

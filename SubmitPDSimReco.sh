#!/bin/bash
# Usage: ./SubmitPDSimReco.sh njobs nevents option

script=simulation.sh

njobs=$1
nevents=$2
option=$3 # "nobg", "ar39", or "rn222"

clientargs="--group=dune --role=Analysis --resource-provides=usage_model=DEDICATED,OPPORTUNISTIC --OS=SL6 --expected-lifetime='long' --memory=2GB"

gen_fcl=$PWD/gen_${option}.fcl
g4_fcl=$PWD/g4.fcl
digi_fcl=$PWD/digi.fcl
reco_fcl=$PWD/reco.fcl
fileargs="-f $gen_fcl -f $g4_fcl -f $digi_fcl -f $reco_fcl"

outdir=/pnfs/dune/scratch/users/gvsinev/photon_detectors/efficiency/dune4apa_${option} # PNFS Scratch directory
outputargs="-dROOT $outdir/root -dFCL $outdir/fcl -dLOG $outdir/log"

larsoft="$MRB_TOP $MRB_PROJECT $MRB_PROJECT_VERSION $MRB_QUALS"
scriptargs="$larsoft $nevents"
thisjob="-q -N $njobs file://$PWD/$script $scriptargs"

#echo "jobsub_submit $clientargs $fileargs $outputargs $thisjob"
jobsub_submit $clientargs $fileargs $outputargs $thisjob

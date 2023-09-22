#!/bin/bash
echo "
#####################################################################
#   GLOW version 1.0                                                #
#   GLOW - GaMD, Deep Learning, Free Energy Profiling Workflow      #
#   Authors: Hung Do, Jinan Wang, Apurba Bhattarai, Yinglong Miao   #
#   Update in 10/2021                                            #
#===================================================================#
If you use any parts of GLOW, please cite:                          #
Do, H., Wang, J., Bhattarai, A., and Miao, Y. (2021). GLOW - a      #
   Workflow Integrating Gaussian accelerated Molecular Dynamics     #
   and Deep Learning for Free Energy Profiling.                     #
#####################################################################"
echo "
=====================================================================
IMPORTANT NOTES FOR USERS:
The input file must be named: GLOW.in
In GLOW.in, please keep the format of the variables as follows,
    in case you have more systems, i.e.
- workfolder_1, workfolder_2, workfolder_3, ...
- parm_sys_1, parm_sys_2, parm_sys_3, ...
- nb_prot_1, nb_prot_2, nb_prot_3, ...
- ...
Please use CTRL + A & CTRL + D to log off your terminal!
If you run into any issues, please contact miao@ku.edu
====================================================================="
parfolder=`pwd`
source $parfolder/GLOW.in

cd $parfolder
echo "Current Directory: $parfolder"

nb_systems=$nb_systems
echo "Number of systems: $nb_systems"

echo "
#####################################################################
#   (III) 2D Free Energy Profiling                                  #
#####################################################################"
source $AMBER/amber.sh

echo "Since the combination of reaction coordinates (RCs) for 2D free
    energy profiling requires experiences from the users and also
    CONVERSION OF RESIDUE INDECES FROM CONTACT MAPS BACK TO ORIGINAL
    SYSTEMS, this part still needs to be done manually!"
echo "After some RCs can be selected, their timecourse distances can be
    calculated using the generated 'dist-calc.in' script"
echo "XXX and YYY in 'dist-calc.in' can be replaced with the residue
    indeces of selected RCs in the original systems"

for i in `seq 1 $nb_systems`
do
    workfolder=workfolder_$i
    parm_protein=parm_prot_$i
    pdb_protein=pdb_prot_$i

    work_dir=${!workfolder}
    parm_prot=${!parm_protein}
    pdb_prot=${!pdb_protein}
    
    echo "parm $work_dir/$parm_prot
trajin $work_dir/md-2.nc
reference $work_dir/$pdb_prot
    
autoimage
rms reference mass out $work_dir/rmsd-CA.dat @CA

# Format: distance dist-R128-E256 :128@CA :256@CA out dist-R128-E256.dat
distance dist-XXX-YYY :XXX@CA :YYY@CA out dist-XXX-YYY.dat
distance dist-XXX-YYY :XXX@CA :YYY@CA out dist-XXX-YYY.dat
distance dist-XXX-YYY :XXX@CA :YYY@CA out dist-XXX-YYY.dat
distance dist-XXX-YYY :XXX@CA :YYY@CA out dist-XXX-YYY.dat
distance dist-XXX-YYY :XXX@CA :YYY@CA out dist-XXX-YYY.dat" >> $work_dir/dist-calc.in
done

echo "
For a guide on how to plot 2D free energy profiles, please refer to https://miaolab.ku.edu/PyReweighting/"
echo "GLOW is completed!"

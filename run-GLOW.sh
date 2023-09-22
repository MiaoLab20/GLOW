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
      and Deep Learning for Free Energy Profiling.                  #
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

rm $parfolder/*.log
if [ $run_GaMD == 1 ]
then
    for i in `seq 1 $nb_systems`
    do
        workfolder=workfolder_$i
        parm_sys=parm_sys_$i
        rst_sys=rst_sys_$i
        
        work_dir=${!workfolder}
        parm_full=${!parm_sys}
        rst_full=${!rst_sys}
        if [ ! -d ${AMBER} ] || [ ! -d ${work_dir} ] || [ ! -f ${work_dir}/${parm_full} ] || [ ! -f ${work_dir}/${rst_full} ]; then
            echo "One of the required input files for system $i is missing!"
            exit 0
        else
            echo "All the required input files for system $i are available!"
        fi
    done
    source $parfolder/run-GaMD.sh >> $parfolder/run-GaMD.log
else
    true
fi

if [ $run_GaMD_analysis == 1 ]
then
    source $parfolder/run-GaMD-analysis.sh >> $parfolder/run-GaMD-analysis.log
else
    true
fi

if [ $run_DL_prep == 1 ]
then
    for i in `seq 1 $nb_systems`
    do
        workfolder=workfolder_$i
        pdb_dl=pdb_cmap_$i
        traj_dl=traj_cmap_$i

        work_dir=${!workfolder}
        pdb_cmap=${!pdb_dl}
        traj_cmap=${!traj_dl}
        if [ ! -d ${work_dir} ] || [ ! -f ${work_dir}/${pdb_cmap} ] || [ ! -f ${work_dir}/${traj_cmap} ]; then
            echo "One of the input files for calculations of residue contact maps of system $i is missing!"
            exit 0
        else
            echo "All the input files for calculations of residue contact maps of system $i are available!"
        fi
    done
    source $parfolder/run-DL-prep.sh >> $parfolder/run-DL-prep.log
else
    true
fi

if [ $run_2D_CNN == 1 ]
then
    source $parfolder/run-2D-CNN.sh >> $parfolder/run-2D-CNN.log
else
    true
fi

if [ $run_DL_analysis == 1 ]
then
    if [ ! -d ${dl_dir}/../model ]; then
        echo "The model is not available! DL analysis was not run properly!"
        exit 0
    else
        echo "DL analysis was properly run!"
    fi
    source $parfolder/run-DL-analysis.sh >> $parfolder/run-DL-analysis.log
else
    true
fi

if [ $run_2D_FEPs == 1 ]
then
    source $parfolder/run-2D-FEPs.sh
else
    true
fi

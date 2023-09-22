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
#   (I) GaMD - Gaussian accelerated Molecular Dynamics!             #
#####################################################################"
echo "Set up your system with CHARMM-GUI and run the cMD beforehand!"

source $AMBER/amber.sh

echo "
=====================================================================
#   Part 1.2: Analysis of GaMD Trajectories!                        #
====================================================================="
for i in `seq 1 $nb_systems`
do
    workfolder=workfolder_$i
    parm_system=parm_sys_$i
    pdb_sys=pdb_sys_$i
    rst_sys=rst_sys_$i
    rst_full=${!rst_sys}
    pdb_full=${!pdb_sys}
    nb_protein=nb_prot_$i
    parm_protein=parm_prot_$i
    pdb_protein=pdb_prot_$i
    residues=res_idx_$i
    parm_contact_map=parm_cmap_$i
    pdb_contact_map=pdb_cmap_$i
    trajectory_cmap=traj_cmap_$i

    work_dir=${!workfolder}
    parm_sys=${!parm_system}
    nb_prot=${!nb_protein}
    parm_prot=${!parm_protein}
    pdb_prot=${!pdb_protein}
    res_idx=${!residues}
    parm_cmap=${!parm_contact_map}
    pdb_cmap=${!pdb_contact_map}
    traj_cmap=${!trajectory_cmap}
    
    echo "The directory for system $i is $work_dir"
    mkdir -p $work_dir 

    cat $work_dir/gamd-2.log >> $work_dir/gamd-all.log
    
    rm ${work_dir}/extract-pdb-sys.in
    echo "parm ${work_dir}/${parm_sys}
trajin ${work_dir}/${rst_full}
trajout ${work_dir}/$pdb_full"> ${work_dir}/extract-pdb-sys.in
    cpptraj -i ${work_dir}/extract-pdb-sys.in
    
    rm ${work_dir}/extract-pdb-protein.in
    echo "parm ${work_dir}/${parm_sys}
trajin ${work_dir}/${rst_full}
strip !@1-${nb_prot}
trajout ${work_dir}/${pdb_prot}"> ${work_dir}/extract-pdb-protein.in
    cpptraj -i ${work_dir}/extract-pdb-protein.in

    rm $work_dir/extract-parm-protein.in
    echo "parm $work_dir/$parm_sys
parmstrip !@1-$nb_prot
parmwrite out $work_dir/$parm_prot nochamber" >> $work_dir/extract-parm-protein.in
    cpptraj -i $work_dir/extract-parm-protein.in
    
    rm $work_dir/extract-parm-cmap.in
    echo "parm $work_dir/$parm_prot
parmstrip !:$res_idx
parmstrip @H*
parmwrite out $work_dir/$parm_cmap nochamber" >> $work_dir/extract-parm-cmap.in
    cpptraj -i $work_dir/extract-parm-cmap.in
       
    rm $work_dir/extract-traj-cmap.in
    echo "parm $work_dir/$parm_prot
trajin $work_dir/md-2.nc 1 last ${stride}
reference $work_dir/$pdb_prot
    
autoimage
rms reference mass out $work_dir/rmsd-CA.dat @CA
    
strip !:$res_idx
strip @H*
    
trajout $work_dir/$traj_cmap" >> $work_dir/extract-traj-cmap.in
    cpptraj -i $work_dir/extract-traj-cmap.in
    
    rm $work_dir/extract-pdb-cmap.in
    echo "parm $work_dir/$parm_cmap
trajin $work_dir/$traj_cmap 1 1
trajout $work_dir/$pdb_cmap" >> $work_dir/extract-pdb-cmap.in
    
    if [ $i -lt $nb_systems ]
    then
        cpptraj -i $work_dir/extract-pdb-cmap.in &
    else
        cpptraj -i $work_dir/extract-pdb-cmap.in
    fi
    
    if [ $? != 0 ]; then
        echo "Errors with the analysis of GaMD simulations!"
        exit 0
    fi
done

echo "The analysis of GaMD production trajectories are finished!"

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

source ${AMBER}/amber.sh

echo "
=====================================================================
#   Part 1.1: GaMD                                                  #
====================================================================="
echo "Your workstation must have $nb_systems GPUs"
echo "
Preparing GaMD Equilibration and Production Input Files"
for i in `seq 1 $nb_systems`
do
    workfolder=workfolder_$i
    parm_sys=parm_sys_$i
    nb_protein=nb_prot_$i
    rst_sys=rst_sys_$i
    rst_full=${!rst_sys}
    cuda_device=$(expr $i - 1)
    work_dir=${!workfolder}
    parm_full=${!parm_sys}
    nb_prot=${!nb_protein}
    natom_sys=`head -7 ${work_dir}/${parm_full} |tail -1 |awk '{print \$1}'`
    ntave=`echo $((4000*(natom_sys/1000+1)))`
    ntcmd=`echo $((ntave*5))`
    ntcmdprep=`echo $((ntave*2))`
    ntebprep=`echo $((ntave*2))`
    nteb=`echo $((ntave*25))`
    nstlim=`echo $((ntcmd+nteb))`
    # echo ${natom_sys},${ntave},${ntcmd},${ntcmdprep},${ntebprep},${nteb},${nstlim}

    echo "The directory for system $i is $work_dir"
    mkdir -p $work_dir
    
    rm $work_dir/md.in
    echo "GaMD equilibration
 &cntrl
    imin=0,       ! No minimization
    irest=0,   ! This IS a new MD simulation
    ntx=1,       ! read coordinates only

    ! Temperature control
    ntt=3,         ! Langevin dynamics
    gamma_ln=1.0,  ! Friction coefficient (ps^-1)
    tempi=310.0,   ! Initial temperature
    temp0=310.0,   ! Target temperature
    ig=-1,         ! random seed

    ! Potential energy control
    cut=9.0,       ! nonbonded cutoff, in Angstroms

    ! MD settings
    nstlim=${nstlim}, ! simulation length
    dt=0.002,      ! time step (ps)

    ! SHAKE
    ntc=2,         ! Constrain bonds containing hydrogen
    ntf=2,         ! Do not calculate forces of bonds containing hydrogen

    ! Control how often information is printed
    ntpr=500,      ! Print energies every 500 steps
    ntwx=500,      ! Print coordinates every 500 steps to the trajectory
    ntwr=10000,    ! Print a restart file every 10K steps (can be less frequent)
!   ntwv=-1,       ! Uncomment to also print velocities to trajectory
!   ntwf=-1,       ! Uncomment to also print forces to trajectory
    ntxo=2,        ! Write NetCDF format
    ioutfm=1,      ! Write NetCDF format (always do this!)

    ! Wrap coordinates when printing them to the same unit cell
    iwrap=1,
    ntwprt = $nb_prot,

    ! Constant pressure control. Note that ntp=3 requires barostat=1
    barostat=1,    ! Berendsen... change to 2 for MC barostat
    ntp=3,         ! 1=isotropic, 2=anisotropic, 3=semi-isotropic w/ surften
    pres0=1.0,     ! Target external pressure, in bar
    taup=0.5,      ! Berendsen coupling constant (ps)

    ! Constant surface tension (needed for semi-isotropic scaling). Uncomment
    ! for this feature. csurften must be nonzero if ntp=3 above
    csurften=3,    ! Interfaces in 1=yz plane, 2=xz plane, 3=xy plane
    gamma_ten=0.0, ! Surface tension (dyne/cm). 0 gives pure semi-iso scaling
    ninterface=2,  ! Number of interfaces (2 for bilayer)

    ! Set water atom/residue names for SETTLE recognition
    watnam='WAT', ! Water residues are named TIP3
    owtnm='O',   ! Water oxygens are named OH2

    ! GaMD parameters
    igamd = 3, iE = 1, irest_gamd = 0,
    ntcmd = ${ntcmd}, nteb = ${nteb}, ntave = ${ntave},
    ntcmdprep = ${ntcmdprep}, ntebprep = ${ntebprep},
    sigma0P = 6.0, sigma0D = 6.0,
 /" > $work_dir/md.in
    
    rm $work_dir/gamd-restart.in
    echo "GaMD simulation
 &cntrl
    imin=0,        ! No minimization
    irest=0,       ! This IS a new MD simulation
    ntx=1,         ! read coordinates only

    ! Temperature control
    ntt=3,         ! Langevin dynamics
    gamma_ln=1.0,  ! Friction coefficient (ps^-1)
    tempi=310.0,   ! Initial temperature
    temp0=310.0,   ! Target temperature
    ig=-1,         ! random seed

    ! Potential energy control
    cut=9.0,       ! nonbonded cutoff, in Angstroms

    ! MD settings
    nstlim=${total_prod_steps}, ! simulation length
    dt=0.002,      ! time step (ps)

    ! SHAKE
    ntc=2,         ! Constrain bonds containing hydrogen
    ntf=2,         ! Do not calculate forces of bonds containing hydrogen

    ! Control how often information is printed
    ntpr=500,      ! Print energies every 500 steps
    ntwx=500,      ! Print coordinates every 500 steps to the trajectory
    ntwr=10000,    ! Print a restart file every 10K steps (can be less frequent)
!   ntwv=-1,       ! Uncomment to also print velocities to trajectory
!   ntwf=-1,       ! Uncomment to also print forces to trajectory
    ntxo=2,        ! Write NetCDF format
    ioutfm=1,      ! Write NetCDF format (always do this!)

    ! Wrap coordinates when printing them to the same unit cell
    iwrap=1,
    ntwprt = $nb_prot,

    ! Constant pressure control. Note that ntp=3 requires barostat=1
    barostat=1,    ! Berendsen... change to 2 for MC barostat
    ntp=3,         ! 1=isotropic, 2=anisotropic, 3=semi-isotropic w/ surften
    pres0=1.0,     ! Target external pressure, in bar
    taup=0.5,      ! Berendsen coupling constant (ps)

    ! Constant surface tension (needed for semi-isotropic scaling). Uncomment
    ! for this feature. csurften must be nonzero if ntp=3 above
    csurften=3,    ! Interfaces in 1=yz plane, 2=xz plane, 3=xy plane
    gamma_ten=0.0, ! Surface tension (dyne/cm). 0 gives pure semi-iso scaling
    ninterface=2,  ! Number of interfaces (2 for bilayer)

    ! Set water atom/residue names for SETTLE recognition
    watnam='WAT', ! Water residues are named TIP3
    owtnm='O',   ! Water oxygens are named OH2

    ! GaMD parameters
    igamd = 3, iE = 1, irest_gamd = 1,
    ntcmd = 0, nteb = 0, ntave = ${ntave},
    ntcmdprep = 0, ntebprep = 0,
    sigma0P = 6.0, sigma0D = 6.0,
 /" > $work_dir/gamd-restart.in
   
    rm $work_dir/run-gamd.sh
    echo "export CUDA_VISIBLE_DEVICES=$cuda_device
cd $work_dir
pmemd.cuda -O -i md.in -p ${parm_full} -c ${rst_full} -o md-1.out -x md-1.nc -r md-1.rst -gamd gamd-1.log
pmemd.cuda -O -i gamd-restart.in -p $parm_full -c md-1.rst -o md-2.out -x md-2.nc -r gamd-2.rst -gamd gamd-2.log" > $work_dir/run-gamd.sh
 
    echo "GaMD-$i is about to be run!"
    if [ $i -lt $nb_systems ]
    then
        echo "GaMD-$i is running!"
        sh $work_dir/run-gamd.sh &
        if [ $? != 0 ]; then
            echo "Errors with GaMD-$i!"
            exit 0
        fi
    else
        echo "GaMD-$i is running!"
        sh $work_dir/run-gamd.sh
        if [ $? != 0 ]; then
            echo "Errors with GaMD-$i!"
            exit 0
        fi
    fi
done

echo "GaMD's are done running!"

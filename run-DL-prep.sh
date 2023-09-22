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
#   (II) Deep Learning of the Residue Contact Maps                  #
#####################################################################"
echo "Your residue contact maps will be deposited at $dl_dir"
echo "
=====================================================================
#   PART 2.1: Preparing the inputs for Deep Learning Analysis       #
====================================================================="
dl_dir=$dl_dir
mkdir -p $dl_dir
rm -r $dl_dir/Train $dl_dir/Valid
mkdir -p $dl_dir/Train
for i in `seq 1 $nb_systems`
do
    system_folder=sys_fold_$i
    sys_fold=${!system_folder}
    
    mkdir -p $dl_dir/Train/$sys_fold
done
scp -r $dl_dir/Train $dl_dir/Valid

rm $dl_dir/../cmap-gen.py
echo "#!/bin/python3
import os
import mdtraj as md
from contact_map import ContactFrequency
import numpy as np
from PIL import Image
import random

nb_systems = $nb_systems
pdb_systems = [" >> $dl_dir/../cmap-gen.py
for i in `seq 1 $nb_systems`
do
    workfolder=workfolder_$i
    pdb_dl=pdb_cmap_$i

    work_dir=${!workfolder}
    pdb_cmap=${!pdb_dl}
    if [ $i -lt $nb_systems ]
    then
        echo " '$work_dir/$pdb_cmap', " >> $dl_dir/../cmap-gen.py
    else
        echo " '$work_dir/$pdb_cmap' " >> $dl_dir/../cmap-gen.py
    fi
done
echo "]" >> $dl_dir/../cmap-gen.py
echo "traj_systems = [" >> $dl_dir/../cmap-gen.py
for i in `seq 1 $nb_systems`
do
    workfolder=workfolder_$i
    traj_dl=traj_cmap_$i
    
    work_dir=${!workfolder}
    traj_cmap=${!traj_dl}
    if [ $i -lt $nb_systems ]
    then
        echo " '$work_dir/$traj_cmap', " >> $dl_dir/../cmap-gen.py
    else
        echo " '$work_dir/$traj_cmap' " >> $dl_dir/../cmap-gen.py
    fi
done
echo "]" >> $dl_dir/../cmap-gen.py
echo "assert(nb_systems == len(pdb_systems))
assert(nb_systems == len(traj_systems))

sys_list = [" >> $dl_dir/../cmap-gen.py
for i in `seq 1 $nb_systems`
do
    system_folder=sys_fold_$i
    system_image=sys_img_$i
    
    sys_fold=${!system_folder}
    sys_img=${!system_image}
    if [ $i -lt $nb_systems ]
    then
        echo " '$sys_fold/$sys_img', " >> $dl_dir/../cmap-gen.py
    else
        echo " '$sys_fold/$sys_img' " >> $dl_dir/../cmap-gen.py
    fi
done
echo "]" >> $dl_dir/../cmap-gen.py
echo "train_dir = '$dl_dir/Train/'
train_outputs = [train_dir + sys for sys in sys_list]
assert(nb_systems == len(train_outputs))

valid_dir = '$dl_dir/Valid/'
valid_outputs = [valid_dir + sys for sys in sys_list]
assert(nb_systems == len(valid_outputs))

for idx in np.arange(0, nb_systems):
    system = md.load(traj_systems[idx], top=pdb_systems[idx])
    system_top = system.topology
    len_system = len(system)
    img_list = []
    for i in np.arange(0, len_system):
        system_freq = ContactFrequency(system[i])
        system_freq = system_freq.residue_contacts
        system_freq = system_freq.df
        system_freq = system_freq.to_numpy()
        system_cmap = np.nan_to_num(system_freq)
    
        indices_one = (system_cmap == 1)
        indices_zero = (system_cmap == 0)
        system_cmap[indices_one] = 0
        system_cmap[indices_zero] = 1

        system_cmap = system_cmap * 255
        system_cmap = system_cmap.astype(np.uint8)
    
        system_img = Image.fromarray(system_cmap, 'L')
        img_list.append(system_img)
    
    assert(len(img_list) == len_system)
    random.shuffle(img_list)
    
    for k in np.arange(0, len_system):
        if k < 0.8 * len_system:
            img_file = train_outputs[idx] + '-' + str(k) + '.jpg'
        else: # k >= 0.8 * len_system
            img_file = valid_outputs[idx] + '-' + str(k) + '.jpg'
            
        img_list[k].save(img_file)" >> $dl_dir/../cmap-gen.py

python $dl_dir/../cmap-gen.py
if [ $? != 0 ]; then
    echo "Errors with calculations and image-transformations of residue contact maps!"
    exit 0
fi
echo "The input preparation for Deep Learning is completed!"

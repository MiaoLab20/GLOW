#!/bin/bash
echo "
#####################################################################
#   GLOW version 1.0                                                #
#   GLOW - GaMD, Deep Learning, Free Energy Profiling Workflow      #
#   Authors: Hung Do, Jinan Wang, Apurba Bhattarai, Yinglong Miao   #
#   Update in 10/2021                                               #
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
#   Part 2.3: Analysis of the Deep Learning Results                 #
====================================================================="
rm $dl_dir/../metrics-vis.py
echo "#!/bin/python3
from matplotlib import pyplot
import pickle

metrics_file = open('$dl_dir/../metrics/metrics.pkl', 'rb')
history = pickle.load(metrics_file)
metrics_file.close()

pyplot.subplot(211)
pyplot.title('Loss')
pyplot.plot(history['loss'], label='Train')
pyplot.plot(history['val_loss'], label='Validation')
pyplot.xlabel('Epoch', fontsize=24, fontweight='bold')
pyplot.ylabel('Loss', fontsize=24, fontweight='bold')
pyplot.legend()

pyplot.subplot(212)
pyplot.title('Accuracy')
pyplot.plot(history['accuracy'], label='Train')
pyplot.plot(history['val_accuracy'], label='Validation')
pyplot.xlabel('Epoch', fontsize=24, fontweight='bold')
pyplot.ylabel('Accuracy', fontsize=24, fontweight='bold')
pyplot.legend()
pyplot.savefig('$dl_dir/../metrics.jpg')
" >> $dl_dir/../metrics-vis.py
python $dl_dir/../metrics-vis.py
if [ $? != 0 ]; then
    echo "Errors with the loading of DL metrics!"
    exit 0
fi

rm $dl_dir/../conf-matrix.py $dl_dir/../conf-matrix.dat
echo "#!/bin/python3
from tensorflow.keras.models import load_model
from tensorflow.keras.models import Model
from tensorflow.keras.preprocessing.image import ImageDataGenerator

import numpy as np
from sklearn.metrics import confusion_matrix
import pylab

model = load_model('$dl_dir/../model')

img_width, img_height = $nb_residues, $nb_residues
valid_data_dir = '$dl_dir/Valid/'

nb_valid_samples = 0.2 * ${nb_systems} * ${total_prod_steps} * 0.002 / ${stride}
batch_size = 64

valid_datagen = ImageDataGenerator(rescale=1. /255)
valid_generator = valid_datagen.flow_from_directory(valid_data_dir,
        shuffle=False, target_size=(img_width, img_height),
        batch_size=batch_size, color_mode='grayscale', class_mode='categorical')

valid_pred = model.predict(valid_generator, nb_valid_samples // batch_size + 1)
valid_pred = np.argmax(valid_pred, axis=1)

cf_matrix = confusion_matrix(valid_generator.classes, valid_pred)
print(cf_matrix)
cf_matrix = cf_matrix / cf_matrix.astype(np.float).sum(axis=1)
print(cf_matrix)

pylab.imshow(cf_matrix, vmin=0, vmax=1, cmap='Blues')
cbar = pylab.colorbar()
for l in cbar.ax.yaxis.get_ticklabels():
    l.set_weight('bold')
    l.set_fontsize(24)

pylab.tick_params(left=False, bottom=False, labelleft=False, labelbottom=False)
pylab.xlabel('Predicted Class', fontsize=24, fontweight='bold')
pylab.ylabel('True Class', fontsize=24, fontweight='bold')
pylab.savefig('$dl_dir/../conf-matrix.jpg')" >> $dl_dir/../conf-matrix.py
python $dl_dir/../conf-matrix.py >> $dl_dir/../conf-matrix.dat
if [ $? != 0 ]; then
    echo "Errors with the calculation of confusion matrix!"
    exit 0
fi

for i in `seq 1 $nb_systems`
do
    system_folder=sys_fold_$i
    system_image=sys_img_$i
    
    sys_fold=${!system_folder}
    sys_img=${!system_image}

    rm $dl_dir/../contact-deter-$i.py $dl_dir/../contacts-$i.dat
    echo "#!/bin/python3
import tensorflow as tf
from tensorflow.keras.models import load_model
from tensorflow.keras.models import Model
from tensorflow.keras.preprocessing.image import load_img
from tensorflow.keras.preprocessing.image import img_to_array
from tf_keras_vis.utils.scores import CategoricalScore
from tensorflow.keras import backend as K
from tf_keras_vis.saliency import Saliency
from tf_keras_vis.utils import normalize

import numpy as np
import pylab

model = load_model('$dl_dir/../model')

image_o = load_img('$dl_dir/Valid/$sys_fold/${sys_img}-${image_index}.jpg', color_mode='grayscale')
img_w, img_h = $nb_residues, $nb_residues

image = img_to_array(image_o)
image = np.expand_dims(image, axis=0)
image = image / 255
image_pred = tf.Variable(image, dtype=float)

with tf.GradientTape() as tape:
    pred = model(image_pred, training=False)
    print(pred[0])

def model_modifier(cloned_model):
    cloned_model.layers[-1].activation = tf.keras.activations.linear
    return cloned_model

score = CategoricalScore([0])

saliency = Saliency(model, model_modifier=model_modifier,
                    clone=False)
saliency_map = saliency(score, image)
saliency_map = saliency_map.reshape(img_w, img_h)

contacts = np.argwhere((saliency_map >= $gradient_cutoff))
contacts = contacts + [1, 1]
print('The characteristic residue contacts of system $i is: ')
print(*contacts)

pylab.imshow(saliency_map, vmin=0.15, vmax=0.45, cmap='jet')
cbar = pylab.colorbar()
for l in cbar.ax.yaxis.get_ticklabels():
    l.set_weight('bold')
    l.set_fontsize(24)

pylab.xlabel('Residue', fontsize=24, rotation=0, fontweight='bold')
pylab.ylabel('Residue', fontsize=24, rotation=90, fontweight='bold')
pylab.xticks(fontsize=24, fontweight='bold')
pylab.yticks(fontsize=24, fontweight='bold')
pylab.savefig('$dl_dir/../contact-deter-$i.jpg')" >> $dl_dir/../contact-deter-$i.py
    python $dl_dir/../contact-deter-$i.py >> $dl_dir/../contacts-$i.dat
    if [ $? != 0 ]; then
        echo "Errors with the RC determination of system $i!"
        exit 0
    fi
done

echo "The analysis of Deep Learning Results is done!"
echo "The important residue contacts can be found in contacts-*.dat files"

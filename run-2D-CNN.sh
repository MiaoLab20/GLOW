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
#   Part 2.2: 2D Convolutional Neural Network Model                 #
====================================================================="
export LD_LIBRARY_CONFIG=${cuDNN_lib}
mkdir -p $dl_dir/../metrics
rm $dl_dir/../conv-net.py $dl_dir/../model-summary.dat
echo "#!/bin/python3
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D
from tensorflow.keras.layers import BatchNormalization, Activation, Dropout, Flatten, Dense
from tensorflow.keras import optimizers
from tensorflow.keras import backend as K
from tensorflow.keras.callbacks import EarlyStopping
import pickle

train_data_dir = '$dl_dir/Train/'
valid_data_dir = '$dl_dir/Valid/'
img_width, img_height = $nb_residues, $nb_residues
nb_classes = $nb_systems
nb_epochs = 15
batch_size = 64
model_name = '$dl_dir/../model'
model_metrics = '$dl_dir/../metrics/' + 'metrics.pkl'

def conv_net(train_data_dir, valid_data_dir, img_width, img_height,
            nb_classes, nb_epochs, batch_size,
        model_name, model_metrics):
    color_mode = 'grayscale'

    if K.image_data_format() == 'channels_first':
        input_shape = (1, img_width, img_height)
    else:
        input_shape = (img_width, img_height, 1)

    class_mode='categorical'

    model = Sequential()
    model.add(Conv2D(32, (3, 3), padding='same', input_shape=input_shape,
        name='conv1'))
    model.add(Activation('relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))
    
    model.add(Conv2D(32, (3, 3), padding='same', name='conv2'))
    model.add(Activation('relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))

    model.add(Conv2D(64, (3, 3), padding='same', name='conv3'))
    model.add(Activation('relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))
    
    model.add(Conv2D(64, (3, 3), padding='same', name='conv4'))
    model.add(Activation('relu'))
    model.add(MaxPooling2D(pool_size=(2, 2)))
    
    model.add(Flatten())
    model.add(Dense(512, name='FC1'))
    model.add(Activation('relu'))
    model.add(Dropout(0.5))
   
    model.add(Dense(128, name='FC2'))
    model.add(Activation('relu'))
    model.add(Dropout(0.5))
    
    model.add(Dense(nb_classes, activation='softmax',
            name='output'))
       
    opt = optimizers.Adam(learning_rate=3e-4)
    model.compile(loss='categorical_crossentropy', optimizer=opt,
            metrics=['accuracy'])
    model.summary()

    train_datagen = ImageDataGenerator(rescale=1. /255, shear_range=0.3,
        zoom_range=0.3, width_shift_range=0.3, height_shift_range=0.3,
        rotation_range=30, horizontal_flip=True)
    train_generator = train_datagen.flow_from_directory(train_data_dir,
        shuffle=True, target_size=(img_width, img_height),
        batch_size = batch_size, color_mode=color_mode, class_mode=class_mode)
        
    valid_datagen = ImageDataGenerator(rescale=1. /255)
    valid_generator = valid_datagen.flow_from_directory(valid_data_dir,
        shuffle=True, target_size=(img_width, img_height),
        batch_size = batch_size, color_mode=color_mode, class_mode=class_mode)
    
    es = EarlyStopping(monitor='val_loss', mode='min', patience=5)
    history = model.fit(train_generator, epochs = nb_epochs,
                    batch_size = batch_size,
                    validation_data = valid_generator,
                    callbacks=[es])
    
    model.save(model_name)
    metrics = open(model_metrics, 'wb')
    pickle.dump(history.history, metrics)
    metrics.close()
    
if __name__ == '__main__':
    conv_net(train_data_dir, valid_data_dir, img_width, img_height,
            nb_classes, nb_epochs, batch_size,
        model_name, model_metrics)" >> $dl_dir/../conv-net.py

echo "The 2D Convolutional Neural Network Model is running!"
python $dl_dir/../conv-net.py >> $dl_dir/../model-summary.dat
if [ $? != 0 ]; then
    echo "Errors with DL of image-transformed residue contact maps!"
    exit 0
fi
echo "The 2D Convolutional Neural Network Model is done!"

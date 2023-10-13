# GLOW

GLOW integrates Gaussian accelerated molecular dynamics (GaMD) and Deep Learning (DL) for free energy profiling of biomolecules. First, all-atom GaMD enhanced sampling simulations are performed on biomolecules of interest. Structural contact maps are then calculated from GaMD simulation frames and transformed into images for building DL models using convolutional neural network (CNN). Important structural contacts can be determined from DL models of saliency (attention) maps of the residue contact gradients, which allow for the identification of system reaction coordinates . Finally, free energy profiles of these reaction coordinates are calculated through energetic reweighting of GaMD simulations.

# Downloads

<strong>1. Anaconda3 (version 2021.05 or later): <a href="https://www.anaconda.com/products/individual#linux">Anaconda3-2021.05-Linux-x86_64</a></strong>

<strong>2. Full GLOW package (with manual and a testing "EXAMPLE" folder): <span style="color: #ff0000;"><a href="https://www.med.unc.edu/pharm/miaolab/wp-content/uploads/sites/1385/2023/09/GLOW.zip">GLOW.zip</a></span></strong>

<strong>3. Energetic reweighting: <a href="https://www.med.unc.edu/pharm/miaolab/resources/pyreweighting/">PyReweighting</a> </strong>

# Tutorial

The GLOW package consists of eight bash scripts. The script <span style="color: #ff0000;"><strong><a href="https://github.com/MiaoLab20/GLOW/blob/main/run-GLOW.sh" rel="noopener">run-GLOW.sh</a></strong></span> is used to run GLOW in full or parts, while others will generate all the necessary files and scripts for running GLOW.

To run GLOW, type the following command in the terminal: <strong>nohup ./run-GLOW.sh &amp;</strong> and <strong>always use CTRL A + CTRL D </strong> to log off the terminal and not disrupt the running process.

All the flags and variables to run GLOW are defined in the <span style="color: #ff0000;"><strong><a href="https://github.com/MiaoLab20/GLOW/blob/main/GLOW.in" rel="noopener">GLOW.in</a></strong></span> input file. The following parameters are used to define which parts of GLOW to be run:

<strong>run_GaMD:</strong> <strong>1</strong> to run GaMD simulations or <strong>0</strong> to skip. Related to the bash script <span style="color: #ff0000;"><strong><a href="https://github.com/MiaoLab20/GLOW/blob/main/run-GLOW.sh" rel="noopener">run-GLOW.sh</a></strong></span>

<strong>run_GaMD_analysis:</strong> <strong>1</strong> to perform GaMD simulation analysis or <strong>0</strong> to skip. Related to the bash script <span style="color: #ff0000;"><strong><a href="https://github.com/MiaoLab20/GLOW/blob/main/run-GaMD-analysis.sh" rel="noopener">run-GaMD-analysis.sh</a></strong></span>

<strong>run_DL_prep:</strong> <strong>1</strong> to calculate residue contact maps of GaMD simulation frames and transform them into images or <strong>0</strong> to skip. Related to the bash script <span style="color: #ff0000;"><strong><a href="https://github.com/MiaoLab20/GLOW/blob/main/run-DL-prep.sh" rel="noopener">run-DL-prep.sh</a></strong></span>

<strong>run_2D_CNN:</strong> <strong>1</strong> to perform DL analysis of image-transformed residue contact maps or <strong>0</strong> to skip. Related to the bash script <span style="color: #ff0000;"><strong><a href="https://github.com/MiaoLab20/GLOW/blob/main/run-2D-CNN.sh" rel="noopener">run-2D-CNN.sh</a></strong></span>

<strong>run_DL_analysis:</strong> <strong>1</strong> to plot DL metrics, confusion matrix and calculate important residue contacts from residue contact maps or <strong>0</strong> to skip. Related to the bash script<span style="color: #ff0000;"> <strong><a href="https://github.com/MiaoLab20/GLOW/blob/main/run-DL-analysis.sh" rel="noopener">run-DL-analysis.sh</a></strong></span>

<strong>run_2D_FEPs:</strong> <strong>1</strong> to print out instructions on how to plot 2D free energy landscapes or <strong>0</strong> to skip. Related to the bash script <span style="color: #ff0000;"><strong><a href="https://github.com/MiaoLab20/GLOW/blob/main/run-2D-FEPs.sh" rel="noopener">run-2D-FEPs.sh</a></strong></span>

Each part of GLOW (GaMD, DL and free energy profiling) requires the specifications of a number of variables to run properly. Detailed explanations of these variables can be found in the manual. The "EXAMPLE" folder of GLOW includes only two systems for demonstration. In case users have more than two systems, the new variables must be in identical formats to the existing ones (<strong>same_text_$i</strong>, with <strong>$i = 1, 2, 3 ...</strong>)

The script <strong><a href="https://github.com/MiaoLab20/GLOW/blob/main/install-PyPackages.sh" rel="noopener">install-PyPackages.sh</a></strong> will install the necessary Python packages for DL. Run <strong>./install-PyPackages.sh</strong> for installation. It is recommended to install them into an Anaconda3 environment of Python3.7+. Detailed instructions on how to set up an Anaconda3 environment can be found in the manual.

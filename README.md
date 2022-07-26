# skullstripper

### Skull stripping with 3D Densenet trained on NFBS data ###
Build on Matlab R2021a and c3d
Works only with nifti files ('.nii', or '.nii.gz')
Matlab function loop over image and label folder, perform skull stripping and write out calculated dice score to csv file

### Supporting Files ###
dicePixelClassification3dLayer.m
trainedDensenet3d_NFBS.mat

### Inputs for skullstripper function ###
ImagePath  = '/skullstripper/image/IBSR_01_ana.nii.gz';
LabelPath  = '/skullstripper/label/mask.nii.gz';
outputPath = '/skullstripper';
processor = 'gpu';

### Outputs ###
Segmented labels will be saved in 'outputPath/outputLabels'
Imageid and dicescore will be saved in 'outputPath/dice.csv'

### Instructions to run skullstrip function in Matlab ###
skullstrip('/skullstripper/image/IBSR_01_ana.nii.gz','/skullstripper/label/mask.nii.gz','/skullstripper', 'gpu')

### Instructions to run "skullstripper" in XNAT ###

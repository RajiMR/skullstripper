%Brain Segmentation with Densenet3D

function skullstrip(ImagePath,LabelPath,outputPath,processor)

disp( ['ImagePath  = ''',ImagePath ,''';']);
disp( ['LabelPath  = ''',LabelPath ,''';']);
disp( ['outputPath = ''',outputPath ,''';']);
disp( ['processor = ''',processor ,''';']);

imgDir = dir(fullfile(ImagePath));
imgFile = {imgDir.name}';
imgFolder = {imgDir.folder}';

lblDir = dir(fullfile(LabelPath));
lblFile = {lblDir.name}';
lblFolder = {lblDir.folder}';

for id = 1:length(imgFile)
    
    imgLoc = char(fullfile(imgFolder(id),imgFile(id)));
    imginfo = niftiinfo(imgLoc);
    imgvol = niftiread(imginfo);

    lblLoc = char(fullfile(lblFolder(id),lblFile(id)));
    
    %Preprocess image
    outV = single(imgvol);
    chn_Mean = mean(outV,[1 2 3]);
    chn_Std = std(outV,0,[1 2 3]);
    scale = 1./chn_Std;

    %Get the original resolution
    a = num2str(size(imgvol,1));
    b = num2str(size(imgvol,2));
    c = num2str(size(imgvol,3));
    originalSize = [a 'x' b 'x' c];
    
    %Get the Image name
    fparts = strsplit(char(imgFile(id)), '.');
    name = fparts{1};
    filename = cellstr(name);
    
    imgNormalized = ['imgNormalized_' name '.nii'];
    imgReorient = ['imgReorient_' name '.nii'];
    imgResized = ['imgResized_' name '.nii'];

    system(sprintf('c3d %s -shift %f -scale %f -clip -5 5 -type float -o %s', imgLoc, -chn_Mean, scale, imgNormalized));  
    system(sprintf('c3d %s -orient RAI -o %s', imgNormalized, imgReorient));
    system(sprintf('c3d %s -int 0 -resample 192x192x192 -o %s', imgReorient, imgResized));

    %Preprocess lbl
    lblReorient = ['lblReorient_' name '.nii'];
    system(sprintf('c3d %s -orient RAI -o %s', lblLoc, lblReorient));

    %Segmentation
    info = niftiinfo(imgResized);
    vol = niftiread(info);

    trainedNetwork = load('trainedDensenet3d_NFBS.mat');
    segmentedLabel = semanticseg(vol,trainedNetwork.net,'ExecutionEnvironment',processor);        
    segmentation = ['segmentedLabel_' name '.nii'];
    niftiwrite(single(segmentedLabel),segmentation,info);

    %Postprocessing - change the intesity from [1 2] to [0 1] 
    intShift =  ['intShift_' name '.nii'];
    system(sprintf('c3d %s -shift -1 -o %s', segmentation, intShift));

    %Resample predicted label to original size
    predictedLabel =  ['predLabel_' name '.nii'];
    system(sprintf('c3d %s -int 0 -resample %s -o %s', intShift, originalSize, predictedLabel));	

    %Calculate Dice score
    [~, out] = system(sprintf('c3d -verbose %s %s -overlap 1', lblReorient, predictedLabel));
    s = extractAfter(out, 'Dice similarity coefficient:    ');
    t = strsplit(s);
    dice = cellstr(t{2});
    tbl = [filename, dice];
    
    mkdir(fullfile(outputPath,'outputLabels'));
    outFile = fullfile(outputPath,'dice.csv');
    writecell(tbl, outFile, 'WriteMode', 'append'); 

    movefile(predictedLabel,fullfile(outputPath,'outputLabels'))

    delete imgNormalized* imgReorient* imgResized* segmentedLabel* intShift* lblReorient*;

end

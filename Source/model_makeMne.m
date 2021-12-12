%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make         %
%=========================================================================%
% MODEL SCRIPT     =======================================================%
%                  This script generates a single model from a dataset    %
%                  and exports to either R Build folder or MATLAB build.  %
%                  Generally, R datasets are optimized for size & import  %
%                  whereas the MATLAB Build folder is for temporary and   %
%                  larger files.                                          %
%                  Notes:                                                 %
%                        matlab_00_common.m - common include file         %
%                        repmanClass - required class for helper methods  %
%                           included in htp_minimum distribution          %
%                        target_file - primary output tracked by Make     %
%=========================================================================%

%=========================================================================%
% CONFIGURATION    =======================================================%
%                  Define inputs and outputs. Filenames in RepMake stay    %
%                  consistent between the script name & any output files. %
%                  The prefix specifies type of output (i.e., figure_).   %
%                  This code automatically switches between a specific    %
%                  command line output file and if the script is run from %
%                  Matlab. Note: Cap sensitive and no spaces.             %
%=========================================================================%

%=========================================================================%
% Step 1: Load common packages, data, and functions.                      %
% ========================================================================%

matlab_00_common

eeglab nogui;
brainstorm nogui;

debug = 1;
if debug == 1
%=========================================================================%
% Step 2: Customize basename and target file for script                   %
%=========================================================================%

basename    = 'makeMne'; % Edit
prefix      = ['model_' basename];

output_file_extension = 'MAT'; % CSV, DOCX, MAT

if IsBatchMode, target_file = target_file; else
    target_file = r.outFile(prefix, syspath.MatlabBuild, output_file_extension);
end

%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = 'model_loadDataset.mat'; % any MAT/Parquet inputs (or NA)

if ~ismissing(data_file)
    load(fullfile(syspath.MatlabBuild, data_file))
end

%=========================================================================%
%                            CONSTRUCT MODEL                              %
%=========================================================================%

[~,project_name,~] = fileparts(syspath.htpdata);
            
%=========================================================================%
%                             CREATE PROTOCOL                             %
%=========================================================================%
% option: "Yes, use protocols default anatomy."
% option: "Yes, use only one global channel file."
try
p.bst_deleteActiveProtocol;
catch
end
gui_brainstorm('CreateProtocol', project_name, 1, 2);

%=========================================================================%
%                            DEFINE NET                                   %
%=========================================================================%
chanInfoStruct.headModel    = 'ICBM152';
chanInfoStruct.brand        = 'GSN';
chanInfoStruct.chanNumber   = '128';
chanInfoStruct.chanLabelFormat = 'E1';

[netIndex, allNetOptions] = p.bst_locateChannels(chanInfoStruct);

%=========================================================================%
%                       ADD SUBJECTS TO PROTOCOL                          %
%=========================================================================%

for i = 1 : numel(p.sub)
    s = p.sub(i);
    fprintf("Loaded Subject %s\n", s.subj_basename);

    % Convert to continous data for Brainstorm Import
    s.loadDataset('postcomps');
    s.epoch2cont;
    s.storeDataset( s.EEG, s.pathdb.source, s.subj_subfolder, s.filename.('postcomps'));

    % Reread file to load into Brainstorm
    rawFile = fullfile(s.pathdb.source, s.subj_subfolder, s.filename.postcomps);
    subjectName = s.subj_basename;
    filetype = 'EEG-EEGLAB';

    bst_process('CallProcess', ...
        'process_import_data_raw', [], [], ...
        'subjectname', subjectName, ...
        'datafile', {rawFile, filetype}, ...
        'channelreplace', netIndex, ...
        'channelalign', 1, ...
        'evtmode', 'value');
end

arrayfun(@(x) x.unloadDataset, p.sub);

sFiles = bst_process('CallProcess', 'process_select_files_data', [], []);

sFiles = bst_process('CallProcess', 'process_import_channel', ...
    sFiles, [], ...
    'usedefault', netIndex, ...% ICBM152: GSN HydroCel 128 E1
    'channelalign', 1, ...
    'fixunits', 1, ...
    'vox2ras', 1);

% Process: Compute head model
sFiles = bst_process('CallProcess', 'process_headmodel', sFiles, [], ...
    'Comment', '', ...
    'sourcespace', 1, ...% Cortex surface
    'volumegrid', struct(...
    'Method', 'isotropic', ...
    'nLayers', 17, ...
    'Reduction', 3, ...
    'nVerticesInit', 4000, ...
    'Resolution', 0.005, ...
    'FileName', ''), ...
    'meg', 3, ...% Overlapping spheres
    'eeg', 3, ...% OpenMEEG BEM
    'ecog', 2, ...% OpenMEEG BEM
    'seeg', 2, ...% OpenMEEG BEM
    'openmeeg', struct(...
    'BemSelect', [1, 1, 1], ...
    'BemCond', [1, 0.0125, 1], ...
    'BemNames', {{'Scalp', 'Skull', 'Brain'}}, ...
    'BemFiles', {{}}, ...
    'isAdjoint', 0, ...
    'isAdaptative', 1, ...
    'isSplit', 0, ...
    'SplitLength', 4000));


sFiles = bst_process('CallProcess', 'process_noisecov', sFiles, [], ...
    'baseline', [-500, -0.001], ...
    'datatimewindow', [0, 500], ...
    'sensortypes', 'MEG, EEG, SEEG, ECOG', ...
    'target', 1, ...% Noise covariance     (covariance over baseline time window)
    'dcoffset', 1, ...% Block by block, to avoid effects of slow shifts in data
    'identity', 1, ...
    'copycond', 0, ...
    'copysubj', 0, ...
    'copymatch', 0, ...
    'replacefile', 1); % Replace

sFiles = bst_process('CallProcess', 'process_inverse_2018', sFiles, [], ...
    'output', 1, ...% Kernel only: shared
    'inverse', struct(...
    'Comment', 'MN: EEG', ...
    'InverseMethod', 'minnorm', ...
    'InverseMeasure', 'amplitude', ...
    'SourceOrient', {{'fixed'}}, ...
    'Loose', 0.2, ...
    'UseDepth', 1, ...
    'WeightExp', 0.5, ...
    'WeightLimit', 10, ...
    'NoiseMethod', 'none', ...
    'NoiseReg', 0.1, ...
    'SnrMethod', 'fixed', ...
    'SnrRms', 1e-06, ...
    'SnrFixed', 3, ...
    'ComputeKernel', 1, ...
    'DataTypes', {{'EEG'}}));

db_reload_database('current');

% manual confirmation of electrode placement
% via plot of scalp with electrodes
cfg.plot = [{'EEG'}    {'scalp'}    {[1]}];
cfg.map  = {'@default_study/channel.mat'};
[hFig, ~, ~] = view_channels_3d(cfg.map, cfg.plot{:});
saveas(hFig, fullfile(syspath.MatlabBuild, ...
    'figure_makeMne_confirmElectrodeLocations.png'));
bst_memory('UnloadAll', 'Forced');
bst_progress('stop');

%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try    
    save(target_file, 'p', 'syspath', 'keyfiles')
    fprintf("Success: Saved %s", target_file);
catch ME
    disp(ME.message);
    fprintf("Error: Save Target File");
end

end
%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%

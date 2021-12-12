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
%                  Define inputs and outputs. Filenames in RepMake stay   %
%                  consistent between the script name & any output files. %
%                  The prefix specifies type of output (i.e., figure_).   %
%                  This code automatically switches between a specific    %
%                  command line output file and if the script is run from %
%                  Matlab. Note: Cap sensitive and no spaces.             %
%=========================================================================%

%=========================================================================%
% Step 1: Load common packages, data, and functions.                      %
% ========================================================================%

matlab_00_common;

eeglab nogui;

%=========================================================================%
% Step 2: Customize basename for script                                   %
%=========================================================================%

basename    = 'bstElecAbsPow'; % Edit
prefix      = ['model_' basename];

%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = 'model_contDataset.mat'; % any MAT/Parquet inputs (or NA)

if ~ismissing(data_file)
    load(fullfile(syspath.MatlabBuild, data_file))
end
    
%=========================================================================%
% Step 4: Specify target for interactive Matlab (no modification needed)  %
%=========================================================================%

output_file_extension = 'MAT'; % CSV, DOCX, MAT

if IsBatchMode, target_file = target_file; else
    target_file = r.outFile(prefix, syspath.RBuild, output_file_extension);
end

%=========================================================================%
%                            CONSTRUCT MODEL                              %
%=========================================================================%

%=========================================================================%
% BRAINSTORM       =======================================================%
% HELPER           Activate Brainstorm in no display (nogui) mode. Checks %
%                  and activates ProtocolName. Retrieves several key BST  %
%                  variables:                                             %
%                  protocol_name  protocol name                           %
%                  sStudy       study structure                           %
%                  sProtocol    protocol structure                        %
%                  sSubjects    subject structure                         %
%                  sStudyList   all assets in study                       %
%                  atlas        cortical atlas structure                  %
%                  sCortex      cortical structure                        %
%                  GlobalData   global brainstorm structure               %
%                                                                         %
ProtocolName          = project_name; % set protocol name                    %
brainstorm_01_common  % brainstorm include                                %
%                     script will end if wrong protocol                   %
%=========================================================================%

cfg.predefinedBands = {...
    'delta', '2.5, 4', 'mean'; ...
    'theta', '4.5, 7.5', 'mean';....
    'alpha1', '8, 12', 'mean'; ...
    'alpha2', '10, 12.5', 'mean'; ...
    'beta', '15, 29', 'mean'; ...
    'gamma1', '30, 55', 'mean'; ...
    'gamma2', '65, 90', 'mean'};
cfg.timewindow = [0 80];
cfg.win_length = 2;
cfg.win_overlap = 50;

%=========================================================================%
%  Specify Power Type    Spectral power is calculated via BST Welsch      
%                        function. Code for analysis is carried through    
%                        analysis making it easier to search for.
%  Available Codes:      scalpAbsPow755   Absolute Power
%                        scalpRelPow765   Relative Power
%                        scalpAbsFFT775   Absolute Power continuous
%                        scalpRelFFT785   Relative Power continuous
%=========================================================================%

powerType = 'scalpAbsPow755';

% check if analysis already complete
sFilesTF = bst_process('CallProcess', 'process_select_files_timefreq', [], [], ...
    'subjectname',   'All', ...
    'condition',     '', ...
    'tag',           powerType, ...
    'includebad',    0, ...
    'includeintra',  0, ...
    'includecommon', 0);

if isempty(sFilesTF)
    powAnalysisComplete = false;
else
    if numel(sFilesTF) == numel(p.sub)
        fprintf('## NOTE ## %s already performed.\n', powerType);
        powAnalysisComplete = true;
        sPow.(powerType) = sFilesTF;
    else
        powAnalysisComplete = false;
    end
end

% Compute if only not already present
if ~powAnalysisComplete
    sFilesRecordings = p.bst_getAllRecordings();
    sPow.(powerType) = fx_BstElecPow(sFilesRecordings, cfg, powerType);
    % Process: Set name: Not defined
    sPow.(powerType) = bst_process('CallProcess', ...
        'process_set_comment', sPow.(powerType), [], ...
        'tag',           powerType, ...
        'isindex',       1);
end

% get subject Ids
[subnames, groupids] = fx_customGetSubNames(sPow.(powerType),p,"default");

% get group-level table
sValues = bst_process('CallProcess', 'process_extract_values', sPow.(powerType), [], ...
    'timewindow',  [], ...
    'sensortypes', [], ...
    'isabs',       0, ...
    'avgtime',     0, ...
    'avgrow',      0, ...
    'dim',         2, ...  % Concatenate time (dimension 2)
    'Comment',     '');

% Process: Set name: Not defined
sValues = bst_process('CallProcess', 'process_set_comment', sValues, [], ...
    'tag',           ['group_' powerType], ...
    'isindex',       1);

[sMatrix, matName] = in_bst(sValues.FileName);

timefreq = sMatrix.TF;
channels = sMatrix.RowNames;
freqbands = sMatrix.Freqs(:,1)';

%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    save(target_file, 'subnames', 'freqbands','timefreq', 'channels','-v6')
    fprintf("Success: Saved %s", target_file);
catch ME
    disp(ME.message);
    fprintf("Error: Save Target File");
end
%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%

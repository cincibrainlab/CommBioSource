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

matlab_00_common

eeglab nogui;

%=========================================================================%
% Step 2: Customize basename for script                                   %
%=========================================================================%

basename    = 'bstSourcePow'; % Edit
prefix      = ['model_' basename];

[~,project_name,~] = fileparts(syspath.htpdata);


%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = missing; % any MAT/Parquet inputs (or NA)

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

% Gather source models
sFilesMne = bst_process('CallProcess', 'process_select_files_results', [], []);

% Calculate Power per Vertex
% Dataset B1: Source Absolute Band Power
sPow.mneAbspowTmp = fx_BstElecPow(sFilesMne, cfg, 'source_abspow');
sPow.mneAbspow = fx_BstElecPow(sPow.mneAbspowTmp, cfg, 'source_smooth');
sPow.mneAbspow = fx_bstAddTag(sPow.mneAbspow, 'MNE_ABSPOW');



%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    assert(strcmp(status, 'bstSourcePow: Success.'), status); 
    save(target_file, 'p', 'syspath', 'keyfiles')
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

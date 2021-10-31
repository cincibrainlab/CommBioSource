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

basename    = 'bstElecRelPowStats'; % Edit
prefix      = ['model_' basename];

%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = 'model_bstElecRelPow.mat'; % any MAT/Parquet inputs (or NA)

if ~ismissing(data_file)
    load(fullfile(syspath.RBuild, data_file))
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
ProtocolName          = 'FXSREST'; % set protocol name                    %
brainstorm_01_common  % brainstorm include                                %
%                     script will end if wrong protocol                   %
%=========================================================================%

%=========================================================================%
%  Specify Power Type    Spectral power is calculated via BST Welsch      
%                        function. Code for analysis is carried through    
%                        analysis making it easier to search for.
%  Available Codes:      scalpAbsPow755   Absolute Power
%                        scalpRelPow765   Relative Power
%                        scalpAbsFFT775   Absolute Power continuous
%                        scalpRelFFT785   Relative Power continuous
%=========================================================================%

powerType = 'scalpRelPow765';

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
    if numel(sFilesTF) == numel(subnames)
        fprintf('## NOTE ## %s already performed.\n', powerType);
        powAnalysisComplete = true;
        sPow.(powerType) = sFilesTF;
    else
        powAnalysisComplete = false;
    end
end

% Compute if only not already present
if powAnalysisComplete
   
% get subject Ids
[subnames, groupids] = fx_customGetSubNames(sPow.(powerType)); 

groupLabels = categories(categorical(groupids));

% only valid for two groups
assert(numel(groupLabels) == 2, 'model_bstElectRelPowStats: Too many groups');

groupIndex1 = find(strcmp(groupids, groupLabels(1)));
groupIndex2 = find(strcmp(groupids, groupLabels(2)));

% Process: Perm t-test equal [0.000s,80.000s 2.5-90Hz]          H0:(A=B), H1:(A<>B)
sStats = bst_process('CallProcess', 'process_test_permutation2', sPow.(powerType)(groupIndex1), sPow.(powerType)(groupIndex2), ...
    'timewindow',     [0, 80], ...
    'freqrange',      [2.5, 90], ...
    'rows',           '', ...
    'isabs',          0, ...
    'avgtime',        1, ...
    'avgrow',         0, ...
    'avgfreq',        0, ...
    'matchrows',      0, ...
    'iszerobad',      1, ...
    'Comment',        sprintf('permutation2_stats_%s', powerType), ...
    'test_type',      'ttest_equal', ...  % Student's t-test   (equal variance) t = (mean(A)-mean(B)) / (Sx * sqrt(1/nA + 1/nB))Sx = sqrt(((nA-1)*var(A) + (nB-1)*var(B)) / (nA+nB-2))
    'randomizations', 1000, ...
    'tail',           'two');  % Two-tailed

else

    error(sprintf('Error: Too many groups'));

end

%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    save(target_file, 'sStats', '-v6')
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

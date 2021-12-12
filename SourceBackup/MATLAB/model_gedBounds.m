%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %
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
% brainstorm server;

%=========================================================================%
% Step 2: Customize basename for script                                   %
%=========================================================================%

basename    = 'gedbounds_01_compute'; % Edit
prefix      = ['model_' basename];

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
% Step 4: Specify target for interactive Matlab (no modification needed)  %
%=========================================================================%

output_file_extenstion = 'MAT'; % CSV, DOCX, MAT

if IsBatchMode, target_file = target_file; else
    target_file = r.outFile(prefix, syspath.MatlabBuild, output_file_extenstion);
end

%=========================================================================%
%                            CONSTRUCT MODEL                              %
%=========================================================================%

%=========================================================================%
% GEBOUNDS           Power is calculated using MATLAB pWelch function.    %
%                    Key parameter is window length with longer windows   %
%                    providing increased frequency resolution. Overlap    %
%                    is set at default at 50%. A hanning window is also   %
%                    implemented.                                         %
%   sapienlabs.org/factors-that-impact-power-spectrum-density-estimation/ %
%=========================================================================%

%=========================================================================%
% ANALYSIS PARAMETERS                                                     %
%=========================================================================%

sublist = p.sub;

gedHandler = mvarHandler; % methods for GED analysis
    minTrials = 60; % minimum valid trials to include (60 x 2 s = 120 s)

lowerBoundGED = 2; %Hz
upperBoundGED = 80; %Hz
freqStepsGED = 500;

findSubject = @(findString) find(strcmp(findString, {sublist.subj_basename}));

findSubject('D01_113_rest')

gedArray = cell(length(sublist),1); % result Array for parFor efficiency

parfor si = 1 : length(sublist)
    
    % data import
    s = sublist(si);
    ged = mvarClass;  % subject-level methods object
    ged.setMinTrials(minTrials);
    ged.setPermutationDirectory( syspath.MatlabBuild  );
    ged.setPathDb(syspath);
    ged.setGedParameters(lowerBoundGED, upperBoundGED, freqStepsGED);
    ged.loadSubject(s, 'postcomps'); % pre-cleaned resting state data
    
    ged = func_gedBoundsCompute(ged);

    fprintf('Subj. %d: %s Complete\n', si, ged.s.subj_basename);

    %     ged.loadSubject(s, 'postcomps'); % pre-cleaned resting state data
    %     % check # of trials
    %     if ged.areRequiredTrialsPresent(minTrials), validTrials = true; ...
    %             ged.selectConsecutiveTrials(minTrials);
    %     else, validTrials = false;
    %     end
    %     ged.loadSensorInfo('egi128');
    %     atlas = ged.getAtlas; % load sensor information
    %     ged.setPermutationDirectory( syspath.perms  );
    %     ged.gedBounds([lowerBoundGED upperBoundGED], freqStepsGED);
    %     ged.clearLastEEG; % unloads dataset, but retains subject details.
    %     fprintf('Subj. %d: %s Complete\n', si, ged.s.subj_basename);
    
    gedArray{si} = ged; % results array
end

gedHandler.loadGedArray(gedArray); % group-level methods object
gedHandler.setPathDb( syspath ); % assign system paths

%save(fullfile(gedPermDir, 'gedArray_128_filtfilt.mat'),'gedHandler','-mat')

fprintf("Calculated gedBounds Loop complete.");

% end Results: Computation (GED)



%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%

save(target_file, 'gedHandler', 'p');

%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%

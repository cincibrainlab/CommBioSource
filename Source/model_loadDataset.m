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

%=========================================================================%
% Step 2: Customize basename for script                                   %
%=========================================================================%

basename    = 'loadDataset'; % Edit
prefix      = ['model_' basename];

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

output_file_extenstion = 'MAT'; % CSV, DOCX, MAT

if IsBatchMode, target_file = target_file; else
    target_file = r.outFile(prefix, syspath.MatlabBuild, output_file_extenstion);
end

%=========================================================================%
%                            CONSTRUCT MODEL                              %
%=========================================================================%

p = htpPortableClass;   % MATLAB object / methods / properties
p.importDataObjects( keyfiles.datacsv, keyfiles.datamat, syspath.htpdata );
p.updateBasePaths( syspath.htpdata );

for i = 1 : numel(p.sub)
    fprintf("Loaded Subject %s\n", p.sub(i).subj_basename);
    if i == numel(p.sub)
        fprintf("%d Subjects Loaded\n", numel(p.sub))
    end
end
p.htpcfg.logger = ...
    log4m.getLogger();


%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%

save(target_file, 'p', 'syspath', 'keyfiles')
disp(['Data File Save Complete: ' target_file]);

%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%

%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %
%=========================================================================%
% TABLE SCRIPT     =======================================================%
%                  This script generates a single table from a dataset    %
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

basename    = 'electrodePowerContinuous'; % Edit
prefix      = ['table_' basename];

%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = 'model_electrodePower.mat'; % any MAT/Parquet inputs (or NA)

if ~ismissing(data_file)
    load(fullfile(syspath.MatlabBuild, data_file))
end
    
%=========================================================================%
% Step 4: Target (output) specification (no modification needed)          %
%=========================================================================%

output_file_extenstion = 'PARQUET'; % CSV, DOCX, MAT

if IsBatchMode, target_file = target_file; else
    target_file = r.outFile(prefix, syspath.RBuild, output_file_extenstion);
end

%=========================================================================%
%                            CONSTRUCT TABLE                              %
%=========================================================================%
global_count = 1;
for i = 1 : length(power_results)
    
    for col_i = 2 : 4
        
        res = power_results{i,col_i};
        
        for row_i = 1 : length(res)
            powtable(global_count, :)= [power_results{i,1} ...
                power_col_labels{col_i} {freq_col_labels(row_i)} num2cell(res(row_i,:)) ];
            global_count = global_count + 1;
        end
    end
end

prepTable = cell2table(powtable,'VariableNames', [{'eegid'},{'measure'}, ...
    {'freq'}, chan_col_labels]);
%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%

% writetable(prepTable, target_file); 
parquetwrite(target_file, ...
    prepTable );
%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%

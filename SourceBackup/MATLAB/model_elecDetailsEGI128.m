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

basename    = 'elecDetailsEGI128'; % Edit
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

output_file_extension = 'CSV'; % CSV, DOCX, MAT

if IsBatchMode, target_file = target_file; else
    target_file = r.outFile(prefix, syspath.MatlabBuild, output_file_extension);
end

%=========================================================================%
%                            CONSTRUCT MODEL                              %
%=========================================================================%

p.sub(1).loadDataset('postcomps');

channels = {p.sub(1).EEG.chanlocs.labels};

% Create electrode detail CSV including scalp and/or regions
net_regions = p.htpcfg.chanNow.net_regions;
regions = fieldnames(net_regions);
regchan = struct2cell(net_regions)';

scalpElectrodes = channels( [1:16, 18:37, 39:42, 45:47, 50:55, ...
                57:72, 74:80, 82:87, 89:106, 108:112, 115:118, 122:124] );

            % create Region Lookup Table
count = 1;
regionlookup={};
for ri = 1:length(regions)
    
    curchan = regchan{ri};
    for r2i = 1 : length(curchan)
       regionlookup{count,2} = regions{ri};
       regionlookup{count,1} = sprintf('E%d',curchan(r2i));
       count = count + 1;
    end
    
end

% create final table
count = 1;
res= {};
for chani = 1 : length(channels)
    res{count, 1} = channels{chani};
    if any(strcmp(scalpElectrodes, res{count,1}))
        res{count,2} = 'SCALP';
    else
        res{count,2} = 'OTHER';
    end
    regionIdx = find(strcmp(regionlookup(:,1), res{count, 1}));
    if isempty(regionIdx)
        res{count,3} = 'NA';
    else
        res{count,3} = regionlookup{regionIdx,2};
    end
    count = count+1;
end

resTable = cell2table(res, 'VariableNames', {'chan','position','region'});


%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    resTable = cell2table(res, 'VariableNames', {'chan','position','region'});
    writetable(resTable, target_file)
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

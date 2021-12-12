%=========================================================================%
% MATLAB COMMON   ========================================================%
%                 RepMake: GNU Make for Matlab: Reproducible Manuscripts   %
%                 Critical file for MATLAB standalone scripts defining    %
%                 constants, paths, and data files.                       %
%                 Datafiles are stored as htpPortableClass objects which  %
%                 contain eegDataClass objects. Objects contain paths to  %
%                 datafiles and analysis methods.                         %
%=========================================================================%

%=========================================================================%
%                     CREATE REPRODUCIBLE ENVIRONMENT                     %
%=========================================================================%


IsBatchMode = batchStartupOptionUsed;

if IsBatchMode
    restoredefaultpath();
end

%=========================================================================%
%                           TOOLBOX CONFIGURATION                         %
% eeglab: https://sccn.ucsd.edu/eeglab/download.php                       %
% high throughput pipline: github.com/cincibrainlab/htp_minimum.git       %
% fieldtrip: https://www.fieldtriptoolbox.org/download/                   %
% brainstorm: https://www.fieldtriptoolbox.org/download/                  %
%=========================================================================%

EEGLAB_PATH             = '/srv/cbl/Toolkits/eeglab2021';
HTP_PATH                = '/srv/cbl/Toolkits/htp_minimum';
BRAINSTORM_PATH         = '/srv/cbl/Toolkits/brainstorm3';
FIELDTRIP_PATH          = '/srv/cbl/Toolkits/fieldtrip-master';
OPENMEEG_PATH           = '/srv/cbl/Toolkits/OpenMEEG-2.4.1-Linux';

% Add paths to toolboxes
cellfun(@(x) addpath(x), {EEGLAB_PATH, BRAINSTORM_PATH, ...
    FIELDTRIP_PATH}, 'uni',0)
cellfun(@(x) addpath(genpath(x)), {HTP_PATH, OPENMEEG_PATH}, 'uni',0)

%=========================================================================%
%                        DIRECTORY CONFIGURATION                          %
%=========================================================================%

% syspath.MatlabBuild  = '/media/ext/srv/MatlabBuild/';
% syspath.RBuild       = '/srv/cbl/CommBioEEGRev/Build/';

 syspath.MatlabBuild  = '/srv/build/CommBioEEGRev/';
 syspath.RBuild       = '/srv/cbl/CommBioEEGRev/Build/';

% adding both build folders to MATLAB path
cellfun(@(x) addpath(x), {syspath.MatlabBuild, syspath.RBuild}, 'uni',0)

%=========================================================================%
%                          DATA CONFIGURATION                             %
%=========================================================================%

syspath.htpdata          = '/srv/rawdata/P1_70FXS_71_TDC';
keyfiles.datacsv = fullfile(syspath.htpdata, 'A00_ANALYSIS/A1911071145_subjTable_P1Stage4.csv');
keyfiles.datamat = fullfile(syspath.htpdata, 'A00_ANALYSIS/A1911071145_subjTable_P1Stage4.mat');

%=========================================================================%
%                          CUSTOM FUNCTIONS                               %
%=========================================================================%

r = repMakeClass;

%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%

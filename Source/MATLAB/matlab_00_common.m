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

%clear all;
restoredefaultpath();
IsBatchMode = batchStartupOptionUsed;

%=========================================================================%
%                           TOOLBOX CONFIGURATION                         %
% eeglab: https://sccn.ucsd.edu/eeglab/download.php                       %
% high throughput pipline: github.com/cincibrainlab/htp_minimum.git       %
% fieldtrip: https://www.fieldtriptoolbox.org/download/                   %
% brainstorm: https://www.fieldtriptoolbox.org/download/                  %
%=========================================================================%

EEGLAB_PATH             = missing; % e.g. 'E:/Research Software/eeglab2021';
HTP_PATH                = missing; % e.g. 'C:/Users/ernie/Dropbox/htp_minimum';
BRAINSTORM_PATH         = missing; % e.g. 'E:/Research Software/brainstorm3';
FIELDTRIP_PATH          = missing; % e.g. 'E:/Research Software/fieldtrip-master';

% Add paths to toolboxes
cellfun(@(x) addpath(x), {EEGLAB_PATH, BRAINSTORM_PATH, ...
    FIELDTRIP_PATH}, 'uni',0)
cellfun(@(x) addpath(genpath(x)), {HTP_PATH}, 'uni',0)

%=========================================================================%
%                        DIRECTORY CONFIGURATION                          %
%=========================================================================%

syspath.MatlabBuild  = missing; % e.g. 'E:/data/gedtemp/Build/';
syspath.RBuild       = missing; % e.g. 'C:/Users/ernie/Dropbox/cbl/GEDBOUNDS/Build/';

% adding both build folders to MATLAB path
cellfun(@(x) addpath(x), {syspath.MatlabBuild, syspath.RBuild}, 'uni',0)

%=========================================================================%
%                          DATA CONFIGURATION                             %
%=========================================================================%

syspath.htpdata          = missing; % e.g. 'E:/data/gedtemp/dataset';
keyfiles.datacsv = missing; % e.g. fullfile(syspath.htpdata, 'A00_ANALYSIS/A1911071145_subjTable_P1Stage4.csv');
keyfiles.datamat = missing; % e.g. fullfile(syspath.htpdata, 'A00_ANALYSIS/A1911071145_subjTable_P1Stage4.mat');

%=========================================================================%
%                          CUSTOM FUNCTIONS                               %
%=========================================================================%

r = repmanClass;

%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%

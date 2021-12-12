% Project name    FXSREST (test)
% Analysis Group: Spectral Power
% Component:      MATLAB model
% Description:    Revision of source analysis EEG paper for Nature Communications Biology
% Author:         EP
% Date Created:   6/29/2021

% Data Models Contained in this File
% 1. Electrode Spectral Power
% 2. Source Model EEG data
% 3. Spectral power (relative, normalized, and absolute) in CSV

%% Dataset:     Electrode Spectral Power
% Type:         CSV
% Location:     R
% Description:  Scalp spectral power by electrode
% Input:        BST Protocol

%% Required Parameters
cfg.bst_protocol_name =  'FXSREST';
cfg.demographics_csv = readtable('C:\Users\ernes\Dropbox\NN_RestingSource\Results\data-raw\fxssource_table_01_demographics_data.csv');
cfg.R_output = 'C:\Users\ernes\Dropbox\htpminimal\mvc\FXSREST\SpectralPower\R';

%% identify current study
sStudy = bst_get('Study');
sProtocol = bst_get('ProtocolInfo');
sSubjects =  bst_get('ProtocolSubjects');
sStudyList = bst_get('ProtocolStudies'); 
protocol_name = cfg.bst_protocol_name;
atlas = fx_BstGetDKAtlasFromSurfaceMat;
sCortex = in_tess_bst('@default_subject/tess_cortex_pial_low.mat');

% Require Parameters for Power (Welch) Calculation
cfg.predefinedBands = {...
    'delta', '2.5, 4', 'mean'; ...
    'theta', '4.5, 7.5', 'mean';....
    'alpha1', '8, 12', 'mean'; ...
    'alpha2', '10, 12.5', 'mean'; ...
    'beta', '15, 29', 'mean'; ...
    'gamma1', '30, 55', 'mean'; ...
    'gamma2', '65, 80', 'mean'};
cfg.timewindow = [0 80];
cfg.win_length = 2;
cfg.win_overlap = 50;

%% Gather electrode-level data
sFilesRecordings = bst_process('CallProcess', 'process_select_files_data', [], []);

%% Generate Scalp/Electrode power Datasets

% Dataset A1: Electrode Absolute Band Power
sPow.elecAbspow = fx_BstElecPow(sFilesRecordings, cfg, 'abspow');
sPow.elecAbspow = fx_bstAddTag(sPow.elecAbspow, 'Elec_ABSPOW');

% Dataset A2: Electrode Absolute (1/F Normalized) Band Power
sPow.elecAbsNorm = fx_BstElecPow(sFilesRecordings, cfg, 'abspownorm');
sPow.elecAbsNorm = fx_bstAddTag(sPow.elecAbsNorm, 'Elec_ABSNORM');

% Dataset A3: Electrode Band Relative
sPow.elecRelpow = fx_BstElecPow(sFilesRecordings, cfg, 'relpow');
sPow.elecRelpow = fx_bstAddTag(sPow.elecRelpow, 'Elec_RELPOWER');

% Dataset A4: Electrode Absolute Continuous Power
sPow.elecFFT = fx_BstElecPow(sFilesRecordings, cfg, 'FFT');
sPow.elecFFT = fx_bstAddTag(sPow.elecFFT, 'Elec_FFT');


% Dataset A4: Electrode Absolute Continuous Power
sPow.elecFFTnorm = fx_BstElecPow(sFilesRecordings, cfg, 'FFTnorm');
sPow.elecFFTnorm = fx_bstAddTag(sPow.elecFFTnorm, 'Elec_FFTnorm');

% Dataset A5: Electrode Relative Continuous Power
sPow.elecFFTrel = fx_BstElecPow(sFilesRecordings, cfg, 'FFTrel');
sPow.elecFFTrel = fx_bstAddTag(sPow.elecFFTrel, 'Elec_FFTrel');

%% Generate Individual CSV
sPowFields = fieldnames(sPow);
for sPow_i = 9 : 9 %length(sPowFields)
    [sResultsPow.(sPowFields{sPow_i}), VariableNames] = ...
        fx_BstExtractValuesElec(sPow.(sPowFields{sPow_i}));
    outfile_csv = fullfile(cfg.R_output, [protocol_name '_' sPowFields{sPow_i} '.csv']);
    fx_customSaveResultsCSV(outfile_csv, sResultsPow.(sPowFields{sPow_i}), VariableNames);
end

%% Gather source models
sFilesMne = bst_process('CallProcess', 'process_select_files_results', [], []);

% Calculate Power per Vertex
% Dataset B1: Source Absolute Band Power
sPow.mneAbspow = fx_BstElecPow(sFilesMne, cfg, 'abspow');
sPow.mneAbspow = fx_bstAddTag(sPow.mneAbspow, 'MNE_ABSPOW');
sPow.mneAbspow = fx_BstElecPow(sPow.mneAbspow, cfg, 'smooth');

% Dataset B2: Source Absolute Band Power
sPow.mneAbspowNorm = fx_BstElecPow(sPow.mneAbspow, cfg, 'abspownorm');
sPow.mneAbspowNorm = fx_bstAddTag(sPow.mneAbspowNorm, 'MNE_ABSPOWNORM');
sPow.mneAbspowNorm = fx_BstElecPow(sPow.mneAbspowNorm, cfg, 'smooth');

% Dataset B3: Source Absolute Band Power
sPow.mneRelpow = fx_BstElecPow(sPow.mneAbspow, cfg, 'relpow');
sPow.mneRelpow = fx_bstAddTag(sPow.mneRelpow, 'MNE_RELPOW');
sPow.mneRelpow = fx_BstElecPow(sPow.mneRelpow, cfg, 'smooth');


%% create subgroup label vector
[subnames, groupids] = fx_customGetSubNames(sPow.mneRelpow);
groupid_table = innerjoin( cell2table(subnames', 'VariableNames', {'eegid'}), clindata(:, {'eegid', 'sex', 'group'}), 'Keys', {'eegid','eegid'});
groupid_table.subgroups = categorical(strcat(groupid_table.group, '_', groupid_table.sex));
groupid_table.subidx = grp2idx(groupid_table.subgroups);

grpClinNames = groupid_table.subgroups;
grpIdxClin = groupid_table.subgroups;

%% Source Statistics
% Source Statistics Parameters
cfg = [];
%cfg.r = p.am.bst_generateRandomTag;
cfg.tag              = '';  % defined in each segment 
cfg.timewindow       = [0 80];
cfg.isabs            = 0;
cfg.avgtime          = 1;
cfg.avgfreq          = 0;
cfg.randomizations   = 2000;
cfg.statisticstype   = 1;
cfg.tail             = 'two';
cfg.correctiontype   = 1;  % 1 default 2 cluster  % FDR manually performed
cfg.minnbchan        = 1;
cfg.clusteralpha     = 0.05;

%%== RELATIVE POWER
sFiles = fx_getBstTimeFreqFiles();
expected_total_subjects = 141;
sFiles = fx_getBstSelectByTag(sFiles, ...
        'MNE_RELPOW | ssmooth3', 'select', expected_total_subjects);
   
    % export subject level values
    csvfile = fullfile(cfg.R_output, 'FXSREST_mneRelpow.csv');
    process_extract_values_wrapper(sFiles, csvfile, 141);
    
% Comparision: FXS vs. TDC, All Subjects
cfg.tagstr = 'sFiles_Rel_Raw_All';

sFiles_Rel_Raw_All = ...
    process_ft_sourcestatistics_wrapper(...
    sFiles(grpIdxClin == 'FXS_M' | grpIdxClin == 'FXS_F'), ...
    sFiles(grpIdxClin == 'TDC_M' | grpIdxClin == 'TDC_F'), ...
    cfg);

% Comparision: FXS vs. TDC, Males Only
cfg.tagstr = 'sFiles_Rel_Raw_Male';

sFiles_Rel_Raw_Male = ...
    process_ft_sourcestatistics_wrapper(...
    sFiles(grpIdxClin == 'FXS_M'), ...
    sFiles(grpIdxClin == 'TDC_M'), ...
    cfg);

% Comparision: FXS vs. TDC, Females Only
cfg.tagstr = 'sFiles_Rel_Raw_Female';

sFiles_Rel_Raw_Female = ...
    process_ft_sourcestatistics_wrapper(...
    sFiles(grpIdxClin == 'TDC_F'), ...
    sFiles(grpIdxClin == 'TDC_F'), ...
    cfg);

% Negative Control (same group)
cfg.tagstr = 'sFiles_Rel_TDC_Female_Neg_Control';
sFiles_Rel_NegControl= ...
    process_ft_sourcestatistics_wrapper(...
    sFiles(grpIdxClin == 'TDC_F'), ...
    sFiles(grpIdxClin == 'TDC_F'), ...
    cfg);


%== ABSOLUTE POWER
sFiles = fx_getBstTimeFreqFiles();
expected_total_subjects = 141;
sFiles = fx_getBstSelectByTag(sFiles, ...
        'MNE_ABSPOW | ssmooth3', 'select', expected_total_subjects);

    % export subject level values
    csvfile = fullfile(cfg.R_output, 'FXSREST_mneAbspow.csv');
    process_extract_values_wrapper(sFiles, csvfile, 141);

    
% Comparision: FXS vs. TDC, Males Only
cfg.tagstr = 'sFiles_ABS_Raw_Male';
sFiles_ABS_Raw_Male = ...
    process_ft_sourcestatistics_wrapper(...
    sFiles(grpIdxClin == 'FXS_M'), ...
    sFiles(grpIdxClin == 'TDC_M'), ...
    cfg);

% Comparision: FXS vs. TDC, Females Only
cfg.tagstr = 'sFiles_ABS_Raw_Female';
sFiles_ABS_Raw_Female = ...
    process_ft_sourcestatistics_wrapper(...
    sFiles(grpIdxClin == 'FXS_F'), ...
    sFiles(grpIdxClin == 'TDC_F'), ...
    cfg);

% Comparision: FXS vs. TDC, All Subjects
cfg.tagstr = 'sFiles_ABS_Raw_All';
sFiles_ABS_Raw_All = ...
    process_ft_sourcestatistics_wrapper(...
    sFiles(grpIdxClin == 'FXS_M' | grpIdxClin == 'FXS_F'), ...
    sFiles(grpIdxClin == 'TDC_M' | grpIdxClin == 'TDC_F'), ...
    cfg);

% ABSOLUTE POWER 1/F NORMALIZED
sFiles = fx_getBstTimeFreqFiles();
expected_total_subjects = 141;
sFiles = fx_getBstSelectByTag(sFiles, ...
        'MNE_ABSPOWNORM | ssmooth3', 'select', expected_total_subjects);
    
    % export subject level values
    csvfile = fullfile(cfg.R_output, 'FXSREST_mneAbsNorm.csv');
    process_extract_values_wrapper(sFiles, csvfile, 141);

% Comparision: FXS vs. TDC, Males Only
cfg.tagstr = 'sFiles_ABS_Norm_Male';
sFiles_ABS_Norm_Male = ...
    process_ft_sourcestatistics_wrapper(...
    sFiles(grpIdxClin == 'FXS_M'), ...
    sFiles(grpIdxClin == 'TDC_M'), ...
    cfg);

% Comparision: FXS vs. TDC, Females Only
cfg.tagstr = 'sFiles_ABS_Norm_Female';
sFiles_ABS_Norm_Female = ...
    process_ft_sourcestatistics_wrapper(...
    sFiles(grpIdxClin == 'FXS_F'), ...
    sFiles(grpIdxClin == 'TDC_F'), ...
    cfg);

% Comparision: FXS vs. TDC, All Subjects
cfg.tagstr = 'sFiles_ABS_Norm_All';
sFiles_ABS_Norm_All = ...
    process_ft_sourcestatistics_wrapper(...
    sFiles(grpIdxClin == 'FXS_M' | grpIdxClin == 'FXS_F'), ...
    sFiles(grpIdxClin == 'TDC_M' | grpIdxClin == 'TDC_F'), ...
    cfg);

%% == Export Statistics to CSV

% Brainstorm Source Statistics via FieldTrip
% Make sure all BST windows are closed and stats are selected.

% retreive stat result structure
sStats = fx_BstRetrieveGroupStats;
sStatsFields = {sStats.Comment}'

% create table of sig. thresholds for each comparision
sStatsSigThreshold = fx_getBstSigThresholds(sStats);
VariableNames = {'Comparison', 'Correction', 'alpha', 'pthreshold'};
outfile_csv = fullfile(cfg.R_output, [protocol_name '_sStatsSigThreshold.csv']);
fx_customSaveResultsCSV(outfile_csv, sStatsSigThreshold, VariableNames);

%% === Export Significant Values per Subject
VariableNames = {'statCompare','eegid', 'group','bandname','tail1', 'tail2'};

    %%== RELATIVE POWER
    sFiles = fx_getBstTimeFreqFiles();
    expected_total_subjects = 141;
    sFiles = fx_getBstSelectByTag(sFiles, ...
            'MNE_RELPOW | ssmooth3', 'select', expected_total_subjects);

    resultTable = fx_customStatReportSigPowerPerSubject( sStats(contains(sStatsFields', 'sFiles_Rel_Raw_All')), sFiles );
    outfile_csv = fullfile(cfg.R_output, [protocol_name '_SigOnly_REL_ALL.csv']);
    fx_customSaveResultsCSV(outfile_csv, resultTable, VariableNames);

    %== ABSOLUTE POWER
    sFiles = fx_getBstTimeFreqFiles();
    expected_total_subjects = 141;
    sFiles = fx_getBstSelectByTag(sFiles, ...
        'MNE_ABSPOW | ssmooth3', 'select', expected_total_subjects);
    
    resultTable = fx_customStatReportSigPowerPerSubject(...
        sStats(contains(sStatsFields', 'sFiles_ABS_Raw_All')), sFiles);
    outfile_csv = fullfile(cfg.R_output, [protocol_name '_SigOnly_ABS_Raw.csv']);
    fx_customSaveResultsCSV(outfile_csv, resultTable, VariableNames);
    
    % ABSOLUTE POWER 1/F NORMALIZED
    sFiles = fx_getBstTimeFreqFiles();
    expected_total_subjects = 141;
    sFiles = fx_getBstSelectByTag(sFiles, ...
        'MNE_ABSPOWNORM | ssmooth3', 'select', expected_total_subjects);
      
    resultTable = fx_customStatReportSigPowerPerSubject(...
        sStats(contains(sStatsFields', 'sFiles_ABS_Norm_All')), sFiles );
    outfile_csv = fullfile(cfg.R_output, [protocol_name '_SigOnly_ABS_Norm.csv']);
    fx_customSaveResultsCSV(outfile_csv, resultTable, VariableNames);
    
%% === 

%%
% statresfiles
% band
% label
% pos
% neg
% counts
 {sStats.Comment}'
% needs frequency Freqs cell array
Freqs = statcsd.Freqs;

roi_res = cell(length(sStats)*length(atlas.Scouts)*length(Freqs),5);
count = 1;
for stati = 1 : length(sStats)
    
    currentstat = sStats(stati);
    %statcsd =  in_bst_data(currentstat.FileName);
    
    %currentstat = sFiles_Rel_Raw_All;
    %statcsd = in_bst_data(currentstat.FileName);
    
    statcsd.pmap = currentstat.pmap;
    statcsd.tmap = currentstat.tmap;
    
    roistrip = 1 : length(atlas.Scouts);
    roilabels = {atlas.Scouts.Label};
    roiregions = {atlas.Scouts.Region};
    
    pmap = squeeze(statcsd.pmap(:,1,:));
    tmap = squeeze(statcsd.tmap(:,1,:));
    pos_tmap = tmap > 0;
    neg_tmap = tmap < 0;
    
    StatThreshOptions.pThreshold = 0.05;
    StatThreshOptions.Correction = 'fdr';
    StatThreshOptions.Control = [1 2 3];
    
    [pmask, pthresh] = bst_stat_thresh(pmap, StatThreshOptions);
    
    sigvalues = squeeze(tmap) .* squeeze(pmask); % only include sig values
    possigvalues = sigvalues .* pos_tmap; % get only positive direction
    negsigvalues = sigvalues .* neg_tmap; % get only negative direction
    possigvalues(possigvalues == 0) = NaN; % important for mean function
    negsigvalues(negsigvalues == 0) = NaN;
    
    for freqi =  1 : length(Freqs)
        
        siglabelspos = find(~isnan(possigvalues(:,freqi)));
        siglabelsneg = find(~isnan(negsigvalues(:,freqi)));
        
        roi_res_pos = arrayfun( @(x) vertex2roi( atlas, x), siglabelspos, 'uni',0);
        roi_res_neg = arrayfun( @(x) vertex2roi( atlas, x), siglabelsneg, 'uni',0);

        labelcnts_pos = categorical(cell2mat(roi_res_pos),roistrip,roilabels);
        labelcnts_neg = categorical(cell2mat(roi_res_neg),roistrip,roilabels);
        
        if isempty(labelcnts_pos)
            freq_label_count.pos = ...
                [roilabels', num2cell(zeros(length(roilabels'),1))];
        else
            freq_label_count.pos = [roilabels', num2cell(countcats(labelcnts_pos))];
        end
        
        if isempty(labelcnts_neg)
            freq_label_count.neg = ...
                [roilabels', num2cell(zeros(length(roilabels'),1))];
        else
            freq_label_count.neg = [roilabels', num2cell(countcats(labelcnts_neg))];
        end

      

        for labeli = 1 : size(freq_label_count.pos, 1)
           
            sel_scout = atlas.Scouts(labeli);
            
            roi_res{count, 1} = currentstat.Comment;
            roi_res{count, 2} = Freqs{freqi, 1};
            roi_res{count, 3} = sel_scout.Label;
            roi_res{count, 4} = freq_label_count.pos{labeli,2};
            roi_res{count, 5} = freq_label_count.neg{labeli,2};
            count = count + 1;
            
        end
    end
    
end

writetable(cell2table(roi_res, ...
    'VariableNames', {'stat', 'bandname', 'label', 'postail','negtail'}), ...
    fullfile(cfg.R_output, 'FXSREST_SigOnly_Regions.csv'));
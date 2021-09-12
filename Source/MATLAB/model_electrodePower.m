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

basename    = 'electrodePower'; % Edit
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
% POWER              Power is calculated using MATLAB pWelch function.    %
%                    Key parameter is window length with longer windows   %
%                    providing increased frequency resolution. Overlap    %
%                    is set at default at 50%. A hanning window is also   %
%                    implemented.                                         %
%   sapienlabs.org/factors-that-impact-power-spectrum-density-estimation/ %
%=========================================================================%

%=========================================================================%
% BAND PARAMETERS                                                         %
%=========================================================================%

bandDefs = {
    'delta', 2 ,4;
    'theta', 4, 7.5;
    'alpha1', 8, 10;
    'alpha2', 10.5, 12.5;
    'beta', 13, 30;
    'gamma1', 30.5, 55;
    'gamma2', 65, 80;
    'epsilon', 81, 120;
    };

bandLabels = bandDefs(:,1);
bandIntervals = cell2mat(bandDefs(:,2:3));
power_col_labels = {'eegid', 'abs','db','rel','absband','dbband','relband'};

% assign eegDataClass objects to temporary variable
sub = p.sub;
power_results = cell(numel(sub),7);

for i = 1 : numel(sub)
    s = sub(i);
    s.loadDataset('postcomps');
    
    epoch_length = s.EEG.pnts / s.EEG.srate;
    freq = bandIntervals;

    power_results{i, 1} = s.subj_basename;
%=========================================================================%
% DATA PREPARATION      Data is detrended prior to power calculation and  %
%                       converted to continuous data.
%=========================================================================%

    dat = permute(detrend3(permute(s.EEG.data, [2 3 1])), [3 1 2]);
    cdat = reshape(dat, size(dat,1), size(dat,2)*size(dat,3));

%=========================================================================%
% PWELCH PARAMETERS                                                       %
%=========================================================================%

    fs  = s.EEG.srate;    % sampling rate
    win = ceil(2 * fs);   % window
    nfft = win;           % FFT points--
    noverlap = .5 * win;  % points overlap

%=========================================================================%
% PWELCH COMPUTATION                                                      %
%=========================================================================%
 
    [pxx,f] = pwelch(cdat', hanning(win), noverlap, nfft, fs,'onesided');

    freq_col_labels = f(1:find(f==freq(end,2)));
%=========================================================================%
% PWELCH FIGURE (DEBUG)                                                   %
%=========================================================================%
 
%     semilogy(f, mean(pxx,2), 'r') % absolute
%     plot(f(1:pnt(end,2)), mean(pow_rel2,2), 'r') % relative
%     xlim([0 10])
%     xlabel('Frequency [Hz]', 'FontSize', 14)
%     ylabel('Log-PSD [V$^2$/Hz]', 'FontSize', 14)
%     title('Power using Welch method', 'FontSize', 14)

%=========================================================================%
% ABSOLUTE POWER (V^2/Hz)                                                 %
%=========================================================================%
    pow_abs = pxx(1:find(f==freq(end,2)),:);
    power_results{i,2} = pow_abs;
    
%=========================================================================%
% ABSOLUTE POWER (dB/Hz)                                                  %
%=========================================================================%
    pow_db = 10*log10(pow_abs);
    power_results{i,3} = pow_db;

%=========================================================================%
% RELATIVE POWER (Unitless)                                               %
%=========================================================================%

     pow_rel_tmp = NaN*ones(size(pow_abs));
     for chani = 1 : size(pow_rel_tmp,2)
       pow_rel(:, chani) = pow_abs(:, chani) ./ sum(pow_abs(:,chani));
     end   
     power_results{i,4} = pow_rel;

%=========================================================================%
% BAND AVERAGE POWER                                                      %
%=========================================================================%

    for bandi = 1 : length(freq)
       
        current_band = freq(bandi,:);
        freqidx = [find(f==current_band(1)):find(f==current_band(2))];
        pow_abs_band(bandi,:) = squeeze(mean(pow_abs(freqidx,:),1));
        pow_db_band(bandi,:) = squeeze(mean(pow_db(freqidx,:),1));
        pow_rel_band(bandi,:) = squeeze(mean(pow_rel(freqidx,:),1));
        
    end

    power_results{i,5} = pow_abs_band;
    power_results{i,6} = pow_db_band;
    power_results{i,7} = pow_rel_band;
    
end        

chan_col_labels = {s.EEG.chanlocs.labels};

%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%

save(target_file, 'power_results', 'power_col_labels', ...
    'freq_col_labels', 'chan_col_labels', 'bandDefs');

%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%

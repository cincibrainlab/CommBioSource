%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %
%=========================================================================%
% FUNCTION         =======================================================%
%                  Helper function for mvarClass gedBounds method checking%
%                  for valid trial number and making script for parfor.   %
%=========================================================================%

function ged = func_gedBoundsCompute( ged )
try
    minTrials = ged.minTrials;
    lowerBoundGED = ged.lowerBoundGED;
    upperBoundGED = ged.upperBoundGED;
    freqStepsGED = ged.freqStepsGED;
catch
    fprintf('Defaulting to minTrial of 60.');
    ged.setMinTrials(60);
end

% check # of trials
if ged.areRequiredTrialsPresent(minTrials), validTrials = true; ...
        ged.selectConsecutiveTrials(minTrials);
else
    validTrials = false;
end

ged.loadSensorInfo('egi128');
atlas = ged.getAtlas; % load sensor information
%ged.keepScalpElectrodesOnly;

% computation method
ged.gedBounds([lowerBoundGED upperBoundGED], freqStepsGED);

ged.clearLastEEG; % unloads dataset, but retains subject details.

end
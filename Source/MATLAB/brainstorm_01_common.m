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
%                    SETUP BRAINSTORM ENVIRONMENT                         %
%=========================================================================%
if ~brainstorm('status')
    brainstorm nogui
end

iProtocol = bst_get('Protocol', ProtocolName);
if isempty(iProtocol)
    error(['Unknown protocol: ' ProtocolName]);
end

gui_brainstorm('SetCurrentProtocol', iProtocol);

global            GlobalData;
sStudy          = bst_get('Study');
sProtocol       = bst_get('ProtocolInfo');
sSubjects       =  bst_get('ProtocolSubjects');
sStudyList      = bst_get('ProtocolStudies'); 
protocol_name   = sProtocol.Comment;
atlas           = fx_BstGetDKAtlasFromSurfaceMat;
sCortex         = in_tess_bst('@default_subject/tess_cortex_pial_low.mat');

%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%

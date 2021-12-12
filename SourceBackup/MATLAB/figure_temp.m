% Project name    FXSREST
% Analysis Group: Spectral Power
% Component:      View (MATLAB)
% Description:    Revision of source analysis EEG paper for Nature Communications Biology
% Author:         EP
% Date Created:   6/29/2021

% Views
% 1. Brainstorm Cortical Plots

%% Dataset:     Electrode Spectral Power
% Type:         CSV
% Location:     R
% Description:  Scalp spectral power by electrode
% Input:        BST Protocol

%% Required Parameters
MATLAB_Config_ProjectSettings;
MATLAB_Config_BrainStormInclude;

% retreive stat result structure
sStats = fx_BstRetrieveGroupStats;
sStatsFields = {sStats.Comment};

%% Dataset:     Electrode Spectral Power
% Type:         PNG
% Location:     /View
% Description:  Cortical Views
% Input:        BST Protocol

availableStats  = sStudy.Stat;
orientation     = 'fig';
viewports       = {...
    'top', 'bottom', ...
    'left', 'right', ...
    'left_intern', 'right_intern'};
viewport_crop   = ...
    {[520 420],[520 420], ...
    [520 530],[520 530], ...
    [520 530],[520 530]}; 
viewport_labels = ...
    {'Superior','Inferior', ...
    'L.Lateral','R. Lateral',...
    'L. Sagittal','R. Sagittal'};

colorMapMin     = -5;
colorMapMax     = +5;

newimg = {};

for stati = 1 : length(sStats)
    OverlayFile = availableStats(stati).FileName;
    OverlayDetails = in_bst(OverlayFile);
    
    if ~isempty(OverlayDetails.SurfaceFile)
        [hFig, iDS, iFig] = view_surface_data([], OverlayFile);
         %currentColorBar = fx_BstSetColormap(hFig, colorMapMin, colorMapMax);
%             saveas(currentColorBar, ...
%                 fullfile(project.view_output, ['cbar_' OverlayDetails.Comment '.pdf']));
            % close(currentColorBar);
            % create grid freq x viewport
            for viewi = 1 : length(viewports)
                currentView = viewports{viewi};
                figure_3d('ResetView', hFig);
                figure_3d('SetStandardView', hFig, currentView);
                for freqi = 1 : size(OverlayDetails.Freqs,1)
                    
                    % current frequency
                    currentFreq = OverlayDetails.Freqs{freqi, 1};
                    panel_freq('SetCurrentFreq',  freqi, true);
                    imgFile = ...
                        fullfile(project.view_output, ...
                        [OverlayDetails.Comment '_' currentView '_' currentFreq '.tif']);

                    % remove colorbar
                    bst_colormaps('SetColorbarVisible', hFig, false);

                    % modify to white background image
                    bst_figures('SetBackgroundColor', hFig, [1 1 1]);
                    
                    rawimg = out_figure_image( hFig, imgFile, []);
                    cropimg = fx_customImageCropImage(rawimg, viewport_crop{viewi});

                    %figure; imshow(fx_customImageCropImage(rawimg, [520 600] ));
                    %figure; imshow(rawimg);

                    rawimg_index{viewi, freqi} = cropimg;
                end  
            end
            currentColorBar = fx_BstSetColormap(hFig, colorMapMin, colorMapMax);

            close(hFig);
            
            % frequency strips with different viewports
            for i = 1 : size(OverlayDetails.Freqs,1)
                newimg{i} = [rawimg_index{:, i}];
            end
            
            % create full image without labels
            img_fig = vertcat(newimg{:});
            

            % create column labels (Viewports)
            view_label_str = {};
            view_label_str = cellfun( @(x,y) fx_customImageText2ImRow(x,y), ...
                viewport_labels, viewport_crop, 'uni',0);
            img_label = horzcat(view_label_str{1,:});
            
            % add viewport labels to figure
            img_fig_viewport = vertcat(img_fig, img_label);

            % add row labels (Frequencies)
            freq_label_str = {};
            for freqi = 1 : size(OverlayDetails.Freqs,1)
                currentFreq = OverlayDetails.Freqs{freqi, 1};
                imtest = fx_customImageText2ImCol(...
                    currentFreq, [520 490] );
                freq_label_str{freqi,1} = imtest;
            end
            freq_label = vertcat(freq_label_str{:,1});
            
            
            % Create panel
            whitesquare = 255 .* ones(size(img_label,1), ....
                size(freq_label,2),3, 'uint8');
            position_small_image = [25 0];
            A = whitesquare;
            B = imresize(currentColorBar,.9);
            Y=position_small_image(1);
            X=position_small_image(2);
            A((1:size(B,1))+X,(1:size(B,2))+Y,:) = B;
            
            freq_label2 = vertcat(freq_label, A);
            panel_imag = horzcat(freq_label2, img_fig_viewport);
            %figure; imshow(horzcat(view_label_str{1,:}))
            %figure; imshow(horzcat(freq_label2, img_fig_viewport))  
            %newimg{:, stati} = panel_imag;
            imwrite( panel_imag, ...
                fullfile(project.view_output, [genvarname(OverlayDetails.Comment) '_Panel.tif']))
          
    end
    
end


%% PAC-Memory 
%
% Main loop
%
% Created: Tues 23 Mar 2021, 11:23
% Author: Martin Esparza-Iaizzo
% 
%
%% Change to project directory

% Select directory:
ProjectFolder = '';

% Change current folder to Project Folder
cd(ProjectFolder);
fprintf('-----------------------------------------------------------------\n');
fprintf('Changing directories to the folder of the selected project \n');

% PATH SETUP: Set up data analysis pipeline (path folders, toolboxes...)
Fieldtrip_folder = '';
addpath(Fieldtrip_folder);
ft_defaults
fprintf('----------------------------------------\n');
fprintf('Adding FieldTrip directory to path:\n');
fprintf(' %s\n', Fieldtrip_folder);

%% Load Data

DataFolder = ''; % Define data folder
addpath(genpath(DataFolder))

% Enable a GUI to select the desired participants
contents=dir(DataFolder);
% Initialize and clear variables
n=0;
clear Files
for i=1:length(contents)
    %Check that the file inside the folder is one of the desired ones
    if (~contents(i).isdir) && strcmpi(contents(i).name(1), 's')
        n=n+1;
        Files{1,n}=contents(i).name;
    end
    
end
Names=unique(Files);
[Selection,ok]=listdlg('PromptString','Select participants','SelectionMode','multiple','ListString',Names,'ListSize',[250,400]);

% Names is a cell that contains the selected participants. 
Names=Names(Selection);


%% Define common variables

% Theta band
% Pf1 and Pf2 define the frequency range (in Hz) investigated as the
% "phase-modulating" (for example, for theta take Pf1=2 and Pf2=6)
Pf1=2;
Pf2=6;

% Gamma band
freqs = 30:10:100; % Define frequencies of interest
nbin = 18; % number of phase bins

% Notice that this measure (Modulation index) is in agreement with Surge's
% method fo selecting number of bins: Nbins = 1+log2(Ndatapoints). We have
% around 400 trials per subject, each of are 0.5 seconds long sampled at
% 500 Hz. Npoints = 400*0.5*500=100000 --> 1+log2(100000)=17.6

position=zeros(1,nbin); % this variable will get the beginning (not the center) of each phase bin (in rads)
winsize = 2*pi/nbin;
for j=1:nbin 
    position(j) = -pi+(j-1)*winsize; 
end

srate = 500; % Sampling rate in Hz.

%% Execute main loop over subjects

Subjects = length(Names);
n_freqs = length(freqs)-2; % e.g., 30-40 Hz is one frequency step
chans = 60; % number of channels of the setup

MI_global = zeros(Subjects,chans,n_freqs); 
MI_hits = zeros(Subjects,chans,n_freqs);
MI_misses = zeros(Subjects,chans,n_freqs);


for t = 1:1%Subjects
    
    load(Names{t});%Load subjects
    % Assign ft structures to different variables in order not to overlap analysis
    data_phase_theta = data_phase; 
    data_phase_gamma = data_phase;
    
    % Extract theta phase in frontal cluster
    theta_cluster = thetaProcessing(data_phase_theta,Pf1,Pf2,srate);
    
    % Extract gamma amplitude in all electrodes and compute Phase-Amplitude
    % coupling with frontal theta cluster
    % MI_global is the combination of hit and miss trials. 
    [MI_global(t,:,:), MI_hits(t,:,:), MI_misses(t,:,:)] = gammaProcessing_MI(data_phase_gamma,theta_cluster,...
        freqs,srate,chans,nbin,position,winsize);
    
end

%% Plotting

% Average MI for participants

MI_group = squeeze(mean(MI_global,1));
MI_group_hits = squeeze(mean(MI_hits,1));
MI_group_misses = squeeze(mean(MI_misses,1));
MI_diff = MI_group_hits - MI_group_misses; % Calculate difference to see the constrast
% Save MI_diff for statistical analysis

% Load information about electrode position
load Cortex_layout;

%Frequencies of interest (low and upper band limit)
foilim=30:10:100;

%Look for the center frequency of each frequency bin;
df=unique(diff(foilim));
foi=foilim(1:end-2)+df;


%% HITS + MISSES
% Create a dummy structure for plotting
dummy_data=[];
dummy_data.freq=foi; %Frequencies of interest (in Hz)
dummy_data.label=data_phase.label; %Make sure you take the electrodes in the same order as in the data structure
dummy_data.dimord='chan_freq'; %Required by Fieldtrip, to which parameter corresponds each dimension
dummy_data.MI=MI_group; %Here we insert the modulation index with chan x freq


for f=1:length(foi)
   h=figure;
   %Set plotting configuration options
   cfg=[];
   cfg.layout=layout; %Where is each electrode positioned;
   cfg.xlim=[foi(f) foi(f)]; %Select frequency of interest (upper and lower limit, Hz);
   cfg.parameter='MI'; %Parameter I want to plot;
   cfg.zlim=[1.3e-4 2.4e-4]; %Adjust the color scale limits (upper and lower limit)
   cfg.comment=' '; %Leave this field empty
   cfg.style='straight'; %To make the contour without lines (stetic decision)
   cfg.colorbar='SouthOutside'; %Where to place the colorbar
   cfg.highlightchannel={'F3','F5','F7','FT7','FC5'}; %Showing electrodes of the phase cluster
   cfg.highlight='on';
   cfg.marker='off'; %Do not show markers for electrodes outside the phase cluster
   %Call function for plotting
   ft_topoplotTFR(cfg,dummy_data);
   title(['Frequency = ' num2str(foi(f)) ' Hz']);
   str = sprintf('Hits Freq %i.png',f);
%    saveas(gcf,str)

end

%% Plot HITS
dummy_data=[];
dummy_data.freq=foi; %Frequencies of interest (in Hz)
dummy_data.label=data_phase.label; %Make sure you take the electrodes in the same order as in the data structure
dummy_data.dimord='chan_freq'; %Required by Fieldtrip, to which parameter corresponds each dimension
dummy_data.MI=MI_group_hits; %Here we insert the modulation index with chan x freq


for f=1:length(foi)
   h=figure;
   %Set plotting configuration options
   cfg=[];
   cfg.layout=layout; %Where is each electrode positioned;
   cfg.xlim=[foi(f) foi(f)]; %Select frequency of interest (upper and lower limit, Hz);
   cfg.parameter='MI'; %Parameter I want to plot;
   cfg.zlim=[1.3e-4 2.4e-4]; %Adjust the color scale limits (upper and lower limit)
   cfg.comment=' '; %Leave this field empty
   cfg.style='straight'; %To make the contour without lines (stetic decision)
   cfg.colorbar='SouthOutside'; %Where to place the colorbar
   cfg.highlightchannel={'F3','F5','F7','FT7','FC5'}; %Showing electrodes of the phase cluster
   cfg.highlight='on';
   cfg.marker='off'; %Do not show markers for electrodes outside the phase cluster
   %Call function for plotting
   ft_topoplotTFR(cfg,dummy_data);
   title(['Frequency = ' num2str(foi(f)) ' Hz']);
   str = sprintf('Hits Freq %i.png',f);
%    saveas(gcf,str)

end

%% Plot MISSES
dummy_data=[];
dummy_data.freq=foi; %Frequencies of interest (in Hz)
dummy_data.label=data_phase.label; %Make sure you take the electrodes in the same order as in the data structure
dummy_data.dimord='chan_freq'; %Required by Fieldtrip, to which parameter corresponds each dimension
dummy_data.MI=MI_group_misses; %Here we insert the modulation index with chan x freq


for f=1:length(foi)
   h=figure;
   %Set plotting configuration options
   cfg=[];
   cfg.layout=layout; %Where is each electrode positioned;
   cfg.xlim=[foi(f) foi(f)]; %Select frequency of interest (upper and lower limit, Hz);
   cfg.parameter='MI'; %Parameter I want to plot;
   cfg.zlim=[1.3e-4 2.4e-4]; %Adjust the color scale limits (upper and lower limit)
   cfg.comment=' '; %Leave this field empty
   cfg.style='straight'; %To make the contour without lines (stetic decision)
   cfg.colorbar='SouthOutside'; %Where to place the colorbar
   cfg.highlightchannel={'F3','F5','F7','FT7','FC5'}; %Showing electrodes of the phase cluster
   cfg.highlight='on';
   cfg.marker='off'; %Do not show markers for electrodes outside the phase cluster
   %Call function for plotting
   ft_topoplotTFR(cfg,dummy_data);
   title(['Frequency = ' num2str(foi(f)) ' Hz']);
   str = sprintf('Misses Freq %i.png',f);
%    saveas(gcf,str)
end

%% Plot Difference
dummy_data=[];
dummy_data.freq=foi; %Frequencies of interest (in Hz)
dummy_data.label=data_phase.label; %Make sure you take the electrodes in the same order as in the data structure
dummy_data.dimord='chan_freq'; %Required by Fieldtrip, to which parameter corresponds each dimension
dummy_data.MI=MI_diff; %Here we insert the modulation index with chan x freq


for f=1:length(foi)
   h=figure;
   %Set plotting configuration options
   cfg=[];
   cfg.layout=layout; %Where is each electrode positioned;
   cfg.xlim=[foi(f) foi(f)]; %Select frequency of interest (upper and lower limit, Hz);
   cfg.parameter='MI'; %Parameter I want to plot;
   cfg.zlim=[-7e-05 7e-5]; %Adjust the color scale limits (upper and lower limit)
   cfg.comment=' '; %Leave this field empty
   cfg.style='straight'; %To make the contour without lines (stetic decision)
   cfg.colorbar='SouthOutside'; %Where to place the colorbar
   cfg.highlightchannel={'F3','F5','F7','FT7','FC5'}; %Showing electrodes of the phase cluster
   cfg.highlight='on';
   cfg.marker='off'; %Do not show markers for electrodes outside the phase cluster
   %Call function for plotting
   ft_topoplotTFR(cfg,dummy_data);
   title(['Frequency = ' num2str(foi(f)) ' Hz']);
   str = sprintf('Diff RP sameaxis Freq %i.png',f);
%    saveas(gcf,str)
end

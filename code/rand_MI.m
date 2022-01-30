%% PAC-Memory 
%
% Null distribution of PAC differences
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

%% Iterate over subjects, frequencies, and randomizations. 

Subjects = length(Names);
n_freqs = length(freqs)-2; % e.g., 30-40 Hz is one frequency step
chans = 60; % number of channels of the setup
rands = 500; % number of randomizations

MI_diff_rand = zeros(Subjects,chans,n_freqs,rands); 


for t = 1:Subjects
    
    load(Names{t});%Load subjects
    % Assign ft structures to different variables in order not to overlap analysis
    data_phase_theta = data_phase; 
    data_phase_gamma = data_phase;
    
    % Extract theta phase in frontal cluster
    theta_cluster = thetaProcessing(data_phase_theta,Pf1,Pf2,srate);
    
    % Extract gamma amplitude in all electrodes and compute Phase-Amplitude
    % coupling with frontal theta cluster
    % MI_global is the combination of hit and miss trials. 
    [MI_diff_rand(t,:,:,:)] = gammaProcessing_rands(data_phase_gamma,theta_cluster,...
        freqs,srate,chans,nbin,position,winsize,rands);

end

% Save MI_global variable and run Cluster_statistics.m

function [theta_cluster] = thetaProcessing(data_phase_theta,Pf1,Pf2,srate)
%UNTITLED3 Summary of this function goes here
%   Author: Martin Esparza-Iaizzo, Multisensory Research Group, Centre for Brain and Cognition, Barcelona, Spain.


%% AVERAGING

% Select theta cluster and average over electrodes. 
cfg = [];
cfg.channel = {'F3';'F5';'FC5';'F7';'FT7'};
cfg.avgoverchan = 'yes';
theta_cluster = ft_selectdata(cfg, data_phase_theta);

%% FILTERING
% These parameters will be selected automatically for each participant. 

epochframes = length(theta_cluster.time{1});%3301; % frames per trial
trials = size(theta_cluster.trialinfo,1); % number of trials
trial_vec = ones(1,trials); % auxiliary vector used to call mat2cell

filtered = cell2mat(theta_cluster.trial); % Concatenate all trials
filtered = eegfilt(filtered,srate,Pf1,Pf2,epochframes); % Filter with eegfilt
filtered = reshape(filtered,epochframes,trials)'; % reshape to retrieve trials
filtered = mat2cell(filtered,trial_vec,epochframes)'; % convert to cell to return to ft structure

theta_cluster.trial = filtered; % Assigned filtered trials to filedtrip structure

%% HILBERT

phase = cell(1,length(theta_cluster.trial)); % Define an empty cell for each trial

for i = 1:length(theta_cluster.trial)
    phase{1,i} = angle(hilbert(theta_cluster.trial{1,i})); % Extract phase using hilbert
end

theta_cluster.trial = phase; % Assign phase to ft structure
%% LATENCY

% Select latency of interest. 300 ms to 800 ms in order to avoid the
% latency where phase resetting occurs and be sure no stimulus was
% presented
cfg = [];
cfg.latency = [0.3 0.8]; 
theta_cluster = ft_selectdata(cfg, theta_cluster);


end


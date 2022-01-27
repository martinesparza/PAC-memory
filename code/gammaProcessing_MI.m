function [MI_global,MI_hits,MI_misses] = gammaProcessing_MI(data_phase_gamma,theta_cluster,freqs,srate,chans,nbin,position,winsize)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

MI_global = zeros(chans,length(freqs)-2); 
MI_hits = zeros(chans,length(freqs)-2);
MI_misses = zeros(chans,length(freqs)-2);

for n = 1:length(freqs)-2 
    
    %% FILTERING

    % Af1 and Af2 define the frequency range investigated as the "amplitude
    % modulated" by the phase frequency (e.g., low gamma would be Af1=30 Af2=55)
    Af1=freqs(n);
    Af2=freqs(n+2);

    epochframes = length(data_phase_gamma.time{1});% 3301; % frames per trial
    trials = size(data_phase_gamma.trialinfo,1); % number of trials
    trial_vec = ones(1,trials); % auxiliary vector used to call mat2cell
    
    filtered = cell2mat(data_phase_gamma.trial); % Concatenate all trials
    filtered = eegfilt(filtered,srate,Af1,Af2,epochframes); % Filter with eegfilt
    filtered = reshape(filtered,chans,epochframes,trials); % reshape to retrieve trials
    filtered = squeeze(mat2cell(filtered,chans,epochframes,trial_vec))'; % convert to cell to return to ft structure

    data_phase_gamma.trial = filtered; % Assigned filtered trials to filedtrip structure

    %% HILBERT
    
    amplitude = cell(1,length(data_phase_gamma.trial)); % Define an empty cell for each trial
    for i = 1:length(data_phase_gamma.trial)
        amplitude{1,i} = abs(hilbert(data_phase_gamma.trial{1,i})); % Extract amplitude envelope
    end

    data_phase_gamma.trial = amplitude; % Assign amplitude to ft structure

    %% LATENCY
    
    % Select latency of interest. 300 ms to 800 ms in order to avoid ERP. 
    cfg = [];
    cfg.latency = [0.3 0.8];
    data_phase = ft_selectdata(cfg, data_phase_gamma);
    
    %% MODULATION INDEX

    % Concatenate all trials
    Phase = cell2mat(theta_cluster.trial);
    Amps  = cell2mat(data_phase_gamma.trial);
    
    idx_misses = find(data_phase.trialinfo(:,1) == 0)';
    idx_hits = find(data_phase.trialinfo(:,1) == 1)';
    
    Phase_misses = cell2mat(theta_cluster.trial(1,idx_misses));
    Amps_misses  = cell2mat(data_phase_gamma.trial(1,idx_misses));

    Phase_hits = cell2mat(theta_cluster.trial(1,idx_hits));
    Amps_hits  = cell2mat(data_phase_gamma.trial(1,idx_hits));


    for k = 1:chans
        MeanAmp=zeros(1,nbin); 
        MeanAmp_hits=zeros(1,nbin); 
        MeanAmp_misses=zeros(1,nbin); 
        
        Amp = Amps(k,:);
        Amp_hits = Amps_hits(k,:);
        Amp_misses = Amps_misses(k,:); 
        for j=1:nbin   
            I = find(Phase <  position(j)+winsize & Phase >=  position(j));
            MeanAmp(j)=mean(Amp(I)); 
            
            I = find(Phase_hits <  position(j)+winsize & Phase_hits >=  position(j));
            MeanAmp_hits(j)=mean(Amp_hits(I)); 
            
            I = find(Phase_misses <  position(j)+winsize & Phase_misses >=  position(j));
            MeanAmp_misses(j)=mean(Amp_misses(I)); 
        end
        
        % the center of each bin (for plotting purposes) is position+winsize/2
 
        % quantifying the amount of amp modulation by means of a
        % normalized entropy index (Tort et al PNAS 2008):

        MI_global(k,n)=(log(nbin)-(-sum((MeanAmp/sum(MeanAmp)).*log((MeanAmp/sum(MeanAmp))))))/log(nbin);
        MI_hits(k,n)=(log(nbin)-(-sum((MeanAmp_hits/sum(MeanAmp_hits)).*log((MeanAmp_hits/sum(MeanAmp_hits))))))/log(nbin);
        MI_misses(k,n)=(log(nbin)-(-sum((MeanAmp_misses/sum(MeanAmp_misses)).*log((MeanAmp_misses/sum(MeanAmp_misses))))))/log(nbin);

    end

end


function [MI_diff_rand] = gammaProcessing_rands(data_phase_gamma,theta_cluster,freqs,srate,chans,nbin,position,winsize,rands)
%gammaProcessing_rands Gamma (30-100 Hz) amplitude extraction, MI
%and null distribution
%   Author: Martin Esparza-Iaizzo, Multisensory Research Group, Centre for Brain and Cognition, Barcelona, Spain.

MI_hits = zeros(chans,length(freqs)-2,rands);
MI_misses = zeros(chans,length(freqs)-2,rands);

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
    theta_trials = theta_cluster.trial;
    gamma_trial = data_phase_gamma.trial;


    for k = 1:chans
        for pf = 1:randomizations
            theta_trials2 = theta_trials; % For parallel computing purposes
            gamma_trial2 = gamma_trial;
            
            trialinfo = data_phase.trialinfo(randperm(length(data_phase.trialinfo)))';
            idx_hits = find(trialinfo(:,1) == 1)';
            idx_misses = find(trialinfo(:,1) == 0)';
            
            Phase_hits = cell2mat(theta_trials2(1,idx_hits));
            Phase_misses = cell2mat(theta_trials2(1,idx_misses));

            Amps_hits = cell2mat(gamma_trial2(1,idx_hits));
            Amp_hits = Amps_hits(k,:);
            Amps_misses = cell2mat(gamma_trial2(1,idx_misses));
            Amp_misses = Amps_misses(k,:); 
            
            MeanAmp_hits=zeros(1,nbin); 
            MeanAmp_misses=zeros(1,nbin);
            
            for j=1:nbin    

                I = find(Phase_hits <  position(j)+winsize & Phase_hits >=  position(j));
                MeanAmp_hits(j)=mean(Amp_hits(I)); 

                I = find(Phase_misses <  position(j)+winsize & Phase_misses >=  position(j));
                MeanAmp_misses(j)=mean(Amp_misses(I)); 
            end

            % the center of each bin (for plotting purposes) is position+winsize/2

            % quantifying the amount of amp modulation by means of a
            % normalized entropy index (Tort et al PNAS 2008):

            MI_hits(t,k,n,pf)=(log(nbin)-(-sum((MeanAmp_hits/sum(MeanAmp_hits)).*log((MeanAmp_hits/sum(MeanAmp_hits))))))/log(nbin);
            MI_misses(t,k,n,pf)=(log(nbin)-(-sum((MeanAmp_misses/sum(MeanAmp_misses)).*log((MeanAmp_misses/sum(MeanAmp_misses))))))/log(nbin);
            
        end
    end

end

MI_diff_rand = MI_hits - MI_misses;

end

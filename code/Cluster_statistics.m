% Cluster-based multiple comparison correction.
% Valid for 2D data (electrode x frequency).
% Using fieldtrip toolbox



%Input variables:
%connect:        Structure containing channel labels, neighbour labels,
%                and connections between electrodes  
%observed_vals:  Matrix Subject x Electrodes x Frequencies with the MI
%                associated to each of the electrode-frequency points. Again, 
%                the electrode order has to be the same as in connect.
%null_vals:      Matrix Subject x Electrodes x Frequencies x Nrandomizations with the
%                surrogate MI associated to each of the time-frequency points
%alpha:          Number, Alpha level
%tail:           Number, -1 left tailed, 0 two tailed 1 right tailed.
%num_rnd:        Number, randomizations desired
%frequencies     Vector, 1xN: values of the frequencies tested (in Hz)

%Output variables:
%stat_corrected: Structure containing the statistic (z-score in this case),
%                and the clusters observed in the data, arranged in a
%                fieldtrip way



load('electrode_connections_for_cluster.mat')
load('Cortex_layout');
load('MI_diff');
load('MI_diff_rand')
tail=0;
num_rnd=1e4;
alpha=0.05;
observed_vals = MI_diff;
null_vals = MI_diff_rand;
frequencies = [40, 50, 60, 70, 80, 90];



%How data is arranged in the matrices
dimension_order= 'chan_freq';
%Determine critical value (depending on tail and desired alpha level)
switch tail
    case 0
        alpha=alpha/2;
        critval=icdf('normal',1-alpha,0,1);
        
    case 1
        critval=icdf('normal',1-alpha,0,1);
    case -1
        critval=icdf('normal',alpha,0,1);
end

%Now extract z-statistic from the data

mean_actual=squeeze(mean(observed_vals));
null_group=zeros(size(mean_actual,1),size(mean_actual,2),num_rnd);
%Sample from the initial randomizations to obtain the desired number of
%randomizations
for n=2:num_rnd
   samples=randsample(size(null_vals,4),size(null_vals,1),true);
   for sj=1:size(null_vals,1)
    null_group(:,:,n)=null_group(:,:,n)+squeeze(null_vals(sj,:,:,samples(sj)));  
   end
end
null_group=null_group/size(null_vals,1);
%Include actual measured value in the null distribution (unbiased
%estimation)
null_group(:,:,1)=mean_actual;

%Now calculate the stats

mean_null=squeeze(mean(null_group,3));
sd_null=squeeze(std(null_group,[],3));
% Obtain z-score
observed_stats=(mean_actual-mean_null)./sd_null;
null_stats=(null_group-repmat(mean_null,1,1,num_rnd))./repmat(sd_null,1,1,num_rnd);
%Reshape the matrices (Electrode x Frequency)x1 for observed, (Electrode x
%Frequency) x Randomizations for the null
observed_stats=observed_stats(:);
null_stats=reshape(null_stats,size(null_stats,1)*size(null_stats,2),size(null_stats,3));

%Now setup the configuration required for the cluster correction
stat_cfg=[];
stat_cfg.tail=tail;
stat_cfg.minnbchan= 2;
stat_cfg.clusterstatistic='maxsum';
stat_cfg.clusteralpha= alpha;
stat_cfg.clustertail=tail;
stat_cfg.numrandomization=size(null_stats,3);
stat_cfg.dimord=dimension_order;
stat_cfg.dim= [size(mean_actual,1) size(mean_actual,2)];
stat_cfg.clusterthreshold= 'parametric';
stat_cfg.clustercritval= critval;
stat_cfg.connectivity=connect.connectivity;
stat_cfg.feedback='text';

[stat_corrected, cfg] = clusterstat_public(stat_cfg, null_stats,observed_stats);

try
stat_corrected.negclusterslabelmat=reshape(stat_corrected.negclusterslabelmat,size(mean_actual,1), size(mean_actual,2));
catch
    disp('No negative cluster found in data');
end

try
    stat_corrected.posclusterslabelmat=reshape(stat_corrected.posclusterslabelmat,size(mean_actual,1),size(mean_actual,2));
catch
    disp('No positive cluster found in data');
end
stat_corrected.label=connect.label;
stat_corrected.prob=reshape(stat_corrected.prob,size(mean_actual,1),size(mean_actual,2));
stat_corrected.stat=reshape(observed_stats,size(mean_actual,1),size(mean_actual,2));
stat_corrected.freq=frequencies;
stat_corrected.dimord=dimension_order;

%Plot significant clusters
cfg=[];
cfg.layout=layout;
cfg.alpha=0.05;
ft_clusterplot(cfg,stat_corrected);

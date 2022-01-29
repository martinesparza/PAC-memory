# PAC-memory
Phase-amplitude coupling (PAC) in episodic memory formation between frontal theta and whole-brain gamma.

Blog post: 
***** 

### **Motivation:**
Memory is one of the most important higher brain function regarded as a cornerstone of personality formation. Neural oscillations and, in particular, low-to-high syncrhonization, are thought to play a essential role in memory formation (Jensen and Colgin 2007, Fell and Axmacher, 2011). Gamma-band (30-100 Hz) modulation of oscillatory activity has been reported in various memory paradigms and may be the result, or cause, of feature binding processes (Hassler et al., 2013; Sederberg et al., 2007). Theta oscillations (3-6 Hz) are similarly involved in memory encoding, retrieval and functioning (Jensen and Tesche 2002; Friese et al., 2013). Additionally to theta and gamma bands, beta (13-30 Hz) and alpha (8-13 Hz) decreases in activity are correlated with increased recall (Backus 2016). Various studies have shown increase PAC between theta and gamma (Canolty, 2006, Demiralp 2007, Sauseng 2008, Koster 2014). With this repository we aimed to observe these results in a previously acquired database published in 2020 (Cruzat et al. 2020).

### **Data:**
Data was acquired from Cruzat et al., 2020 approved by the clinical Research Ethical Committee of the Municipal Institute of Health Care (CIEC-IMAS) Barcelona, Spain and all subjects gave written consent before their participation according to the declaration of Helsinki. A total of 30 helathy subjects participated. For further details refer to the original publication. 

### **Task:**
Taken from Cruzat et al., 2020: "Participants performed a visual pair-associates memory task. During the encoding block, participants were asked to learn five unrelated image pairs presented side-by-side on placeholders for 500 ms. A cue—composed by a central fixation cross and placeholders—flashed once synchronously together with a sound-beep before each image pair presentation. Critically, the time-lag between the cue and the image pair to be encoded (the cue-to-target interval) was varied randomly between 0 and 1000 ms. Each encoding block was followed by a four-trials recognition block where participants judged whether a given image pair had been presented together in the previous encoding block. Each participant provided a total of 1.408 responses."

<img width="448" alt="Screenshot 2022-01-29 at 16 48 06" src="https://user-images.githubusercontent.com/96518571/151669521-d3162050-44eb-453d-826d-99e2f8bb0479.png">
<span class="figcaption_hack">Figure 1. Experimental design.</span>

### **PAC calculation:**
To compute the synchronization between the frontal theta cluster identified in Cruzat et al. 2020 (F3, F5, FC5, F7, FT7) and the gamma amplitude of the rest of the 60-channel setup, the Modulation Index (MI) parameter of Tort et al., 2010 was employed. Filtering was carried out with the pre-built "eegfilt" function of Scott Makeig and Arnaud Delorme. Phase and amplitude were extracted with the Hilbert transform and used in the MI computation. Latency was set from 300 to 800 ms to avoid the phase resetting effect. FieldTrip toolbox (Oostenveld et al. 2011) was employed for the majority of analysis. 

### **Results:**
The following topoplots show the results for trials marked as hits, misses, and the combination of both. Figure title show the frequency interval being explored. A potential cluster emerges in the parietal cortex which is only present in hits. However, statistical analyses through cluster-based multiple comparison correction did not reveal any significant electrodes. 

### **Conclusion:**
The reasons behind why no electrodes emerged statistically significant can be manifold (e.g., sample size, inter-participant variability, no theta-gamma PAC). Nevertheless, fronto parietal connectivity from low to high frequency oscillations is a long established neural correlate of memory formation. Perhaps additional PAC computation methods could be explored in the future. 

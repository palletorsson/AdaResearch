from pathlib import Path
import json
import numpy as np
from scipy.signal import welch,lfilter,freqz
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
H=Path(__file__).resolve().parent
raw=np.loadtxt(H/'raw-signals.csv',delimiter=',',skiprows=1)
assert raw.shape==(65536,3) and np.isfinite(raw).all()
B=np.array([.049922035,-.095993537,.050612699,-.004408786]);A=np.array([1,-2.494956002,2.017265875,-.522189400])
# Compare the exported recurrence against an independent implementation after its transient.
reference=lfilter(B,A,raw[:,0]);err=float(np.max(np.abs(reference[4096:]-raw[4096:,2])))
assert err<1e-8
integrator_err=float(np.max(np.abs(np.cumsum(raw[:,0])*.1-raw[:,1])))
assert integrator_err<1e-8
results=[];spectra=[]
for i,name in enumerate(['Fresh draws','Accumulated steps','Filtered / pink']):
 f,p=welch(raw[:,i],fs=1,nperseg=8192,noverlap=4096,window='hann',detrend='linear',scaling='density')
 chosen=(f>=.01)&(f<=.2);slope,intercept=np.polyfit(np.log10(f[chosen]),np.log10(p[chosen]),1)
 results.append({'channel':name,'slope':float(slope),'raw_std':float(raw[:,i].std()),'lag1':float(np.corrcoef(raw[:-1,i],raw[1:,i])[0,1])});spectra.append((f,p))
assert abs(results[0]['slope'])<.12 and -2.15<results[1]['slope']<-1.75 and -1.15<results[2]['slope']<-.85
freq,h=freqz(B,A,worN=65536,fs=1);sel=(freq>=.01)&(freq<=.2);ratio_db=10*np.log10(np.abs(h[sel])**2*freq[sel]);spread=float(np.ptp(ratio_db));assert spread<1.5
report={'source':'actual Godot weather_signals.gd export','seed':4321,'samples':65536,'preparation_samples':4096,'spectral_scope':'Raw signal before fixed display gains, clipping or motor interpolation. Not the eight visible apertures or a spectrum of the sound gallery. Walk is unbounded and nonstationary; its fitted finite-record slope is descriptive.','method':{'estimator':'Welch','window':'Hann','nperseg':8192,'overlap':4096,'detrend':'linear','band_cycles_per_sample':[.01,.2],'slope_fit':'unweighted log power versus log frequency within band'},'results':results,'independent_iir_max_error':err,'sum_max_error':integrator_err,'pink_transfer_power_times_f_spread_db':spread,'first_128_display_clipped_counts':np.sum(np.abs(raw[:128]*[1,1,11.6])>1,axis=0).tolist(),'passed':True}
(H/'signal-checks.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':11,'axes.spines.top':False,'axes.spines.right':False})
fig,axes=plt.subplots(1,2,figsize=(13,5),layout='constrained');fig.set_facecolor('#f5f1e9')
colours=['#437b85','#976323','#c64273']
for i,(f,p) in enumerate(spectra):
 refidx=np.argmin(np.abs(f-.05));axes[0].loglog(f[1:],p[1:]/p[refidx],lw=1,color=colours[i],label=f"{results[i]['channel']}: slope {results[i]['slope']:.2f}")
axes[0].axvspan(.01,.2,color='gray',alpha=.09);axes[0].set(xlabel='Cycles per sample',ylabel='Power density (aligned at 0.05 for comparison)',xlim=(.002,.45),ylim=(.004,900),title='Raw sequences — measured slopes');axes[0].legend(fontsize=9);axes[0].grid(alpha=.13,which='both')
for i in range(3):axes[1].plot(np.arange(1,129),raw[:128,i]*[1,1,11.6][i],color=colours[i],label=results[i]['channel'],lw=1.2)
axes[1].axhline(1,color='#e58927',ls='--');axes[1].axhline(-1,color='#e58927',ls='--');axes[1].set(xlabel='Accepted target number',ylabel='Value after fixed display gain, before limiting',title='The first 128 targets — display bounds');axes[1].grid(alpha=.13)
fig.suptitle('Related weather · raw data and display limits are separate',fontsize=15);fig.savefig(H/'signal-study.png',dpi=150);plt.close(fig)
print(json.dumps(report,indent=2))

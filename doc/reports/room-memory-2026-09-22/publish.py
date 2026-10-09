from pathlib import Path
import json,shutil,hashlib,sys
import markdown
import numpy as np
from scipy.io import wavfile
from scipy.signal import welch

sys.stdout.reconfigure(encoding='utf-8')
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
OUT=ROOT/'doc/book/iterations/2026-09-22-room-memory'
OUT.mkdir(parents=True,exist_ok=True)
report=json.loads((HERE/'report.json').read_text(encoding='utf-8'))
assert not report['failures']
log=(HERE/'run-log.txt').read_text(encoding='utf-8')
assert 'SCRIPT ERROR' not in log
assert 'recording_data.is_empty' not in log
clips=['pass-00.wav','pass-01.wav','pass-04.wav','pass-12.wav','soft-pass-12.wav']
diagnostics={}
spectra=[]
for name in clips:
    rate,pcm=wavfile.read(HERE/name)
    samples=pcm.astype(float)/32768
    assert np.isfinite(samples).all() and abs(samples).max()<=.551
    f,p=welch(samples,rate,nperseg=8192)
    keep=(f>=50)&(f<=6000)
    f,p=f[keep],p[keep]
    normalized=p/p.sum()
    diagnostics[name]={'seconds':len(samples)/rate,'peak':float(abs(samples).max()),
        'top_10_frequency_bins_energy_fraction':float(np.sort(normalized)[-10:].sum())}
    spectra.append((f,10*np.log10(p/p.max()+1e-12)))
assert diagnostics['pass-12.wav']['top_10_frequency_bins_energy_fraction']>diagnostics['pass-00.wav']['top_10_frequency_bins_energy_fraction']
assert diagnostics['soft-pass-12.wav']['top_10_frequency_bins_energy_fraction']<diagnostics['pass-12.wav']['top_10_frequency_bins_energy_fraction']
(HERE/'audio-analysis.json').write_text(json.dumps(diagnostics,indent=2),encoding='utf-8')
# Standalone plot of the actual saved buffers. Equal peak normalization; this
# compares spectral shape, not absolute loudness or a listening experiment.
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
fig,axs=plt.subplots(2,1,figsize=(12,6),sharex=True)
fig.set_facecolor('#f2eee5')
for ax,indices in zip(axs,[[0,1,3],[3,4]]):
    ax.set_facecolor('#f2eee5')
    for idx in indices:
        ax.semilogx(*spectra[idx],label=['Original','Pass 1','Pass 4','Pass 12 / reflective','Pass 12 / absorbent'][idx],lw=1.1,alpha=.85)
    ax.set_ylim(-65,3);ax.set_xlim(50,6000);ax.set_ylabel('Relative power (dB)')
    ax.grid(alpha=.18);ax.legend(loc='lower left',fontsize=9)
axs[1].set_xlabel('Frequency (Hz)')
fig.suptitle('The same voice, repeatedly passed through the model',fontsize=15)
fig.tight_layout();fig.savefig(HERE/'spectra.png',dpi=130);plt.close(fig)
assets=clips+['room-entry.png','room-pass-12.png','return-controls.png','absorbent-room.png','playable-entry.png','spectra.png','audio-analysis.json','report.json','run-log.txt']
for name in assets: shutil.copy2(HERE/name,OUT/name)
paths=[ROOT/'commons/artifacts/ambient_patch'/f for f in ['room_memory.gd','room_memory_audio.gd','room_memory_dsp.gd','room_memory.tscn','room_memory_demo.res','ambient_room_travel.gd']]
paths += [ROOT/'commons/scenes/room_memory.tscn',ROOT/'commons/testing/test_room_memory.gd']
manuscript_path=ROOT/'commons/maps/WaveFunctions_Synthesis_Lab/final.md'
paths.append(manuscript_path)
manuscript=manuscript_path.read_text(encoding='utf-8')
passage=manuscript.split('## What the room keeps\n',1)[1].split('<!-- @ -->',1)[0]
notes='\n\n'.join(line for line in manuscript.splitlines() if line.startswith('[^synthesis-'))
passage_html=markdown.markdown('## What the room keeps\n\n'+passage+'\n\n'+notes,extensions=['fenced_code','footnotes'])

(OUT/'sources.json').write_text(json.dumps({str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2),encoding='utf-8')
cards=''.join(f'<article><h3>{title}</h3><p>{caption}</p><audio controls preload="none" src="{file}"></audio><a href="{file}">Download WAV</a></article>' for file,title,caption in [
    (clips[0],'00 / The voice','An original synthetic phrase. No recording by Lucier.'),
    (clips[1],'01 / First return','The previous buffer passes through the room model.'),
    (clips[2],'04 / The words loosen','Resonances become more prominent with repetition.'),
    (clips[3],'12 / Reflective room','The same process has selected a narrow set of frequencies.'),
    (clips[4],'12 / Absorbent room','Start again with the same voice and stronger absorption.')])
count=len(report['checks'])
worker=report['worker_ms']
html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Room Memory · After Alvin Lucier</title>
<style>:root{color-scheme:light}*{box-sizing:border-box}body{margin:0;background:#f2eee5;color:#233d3b;font:18px/1.6 system-ui,sans-serif}main{max-width:1200px;margin:auto;padding:36px 24px 70px}a{color:#245b62}nav{display:flex;flex-wrap:wrap;gap:24px;font-size:14px}header{max-width:950px;margin:65px 0 38px}small{text-transform:uppercase;letter-spacing:.14em;color:#785632;font-size:12px}h1{font-size:clamp(48px,8vw,98px);line-height:1.02;letter-spacing:-.05em;font-weight:500;margin:25px 0}header p{font-size:24px;max-width:830px}h2{font-size:32px;font-weight:500;letter-spacing:-.02em}h3{font-size:21px;margin:0 0 12px}figure{margin:32px 0}img{width:100%;display:block;border-radius:8px}figcaption{font-size:14px;color:#596b64;margin-top:10px}section{margin:55px 0}.entry{border-left:3px solid #ae8458;padding:5px 25px;margin:35px 0}.listen{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:18px}.listen article{border:1px solid #c3c9bd;padding:23px;background:#e7e9df;border-radius:8px}.listen p{font-size:16px;min-height:77px}.listen a{font-size:13px}audio{display:block;width:100%;margin:20px 0 10px}blockquote{border-left:3px solid #789e8e;padding:12px 26px;margin:35px 0;font-size:26px;max-width:850px}.two{display:grid;grid-template-columns:1fr 1fr;gap:24px}details{padding:20px 0;border-top:1px solid #bdc6bb}summary{cursor:pointer;font-weight:600}code{font-size:14px;overflow-wrap:anywhere}.muted,footer{color:#596b64;font-size:14px}@media(max-width:800px){.listen,.two{grid-template-columns:1fr}header{margin-top:40px}.listen p{min-height:0}}</style>
<main><nav><a href="/necklace/thread?map=WaveFunctions_Synthesis_Lab">Synthesis Lab</a><a href="../2026-09-22-ambient-room/index.html">Earlier generative room</a></nav>
<header><small>Ada Research / Wavefunctions / 22 September 2026</small><h1>Room memory.</h1><p>Your voice returns through the same room. Again. With each pass, something remains and something becomes harder to hear.</p><p class="muted">An interactive VR study after Alvin Lucier’s <em>I Am Sitting in a Room</em> (1969). The previous ambient room misunderstood the reference; this experiment follows the recursive process.</p></header>
<figure><a href="playable-entry.png"><img src="playable-entry.png" alt="Actual Godot player view inside the rectangular Room Memory, with a loudspeaker, virtual microphone, physical control stations and spectrum display"></a><figcaption>The playable scene. A 6 × 5 × 3 metre room, an open floor, and three stations: Voice, Return and Surface.</figcaption></figure>
<div class="entry"><h2>Try it in the museum</h2><p>In <strong>WaveFunctions_Synthesis_Lab</strong>, press <strong>ENTER ROOM</strong> on Slow Circuits. At the Voice station, choose <strong>DEMO VOICE</strong> or press <strong>RECORD / END</strong> and speak for up to eight seconds. The microphone starts only on that press.</p><p><strong>NEXT PASS</strong> processes the previous recording. <strong>AUTO / STOP</strong> repeats the cycle after each playback. <strong>HEAR ORIGINAL</strong> gives you the voice to compare against. Changing <strong>ABSORB</strong> starts again from the same phrase.</p></div>
<section><h2>Listen to the passes</h2><p>These are buffers produced by the actual Godot implementation. The source is a synthetic voice speaking an original phrase. Each file is peak-normalized; these examples compare the changing sound, not increasing volume.</p><div class="listen">CARDS</div><p class="muted">“Listen to this voice. Each return passes through the same room. Which sounds remain?” Generated offline with Windows System.Speech. The VR room can use your own locally recorded phrase.</p></section>
<section><h2>The experiment</h2><p>In Lucier’s work, a voice is recorded, played into a room, and recorded again. Repetition gradually foregrounds the resonances of that space. <a href="https://en.wikipedia.org/wiki/I_Am_Sitting_in_a_Room">Work overview</a> · <a href="https://www.nicolascollins.com/texts/SittingInARoom.pdf">Nicolas Collins’s album notes</a>.</p><p>Here, the first recording becomes the input to a virtual acoustic model. Its output becomes the next input. You can walk around the loudspeaker, compare the first voice, and change the surface response.</p><blockquote>What does this room allow to remain audible?</blockquote><p>For Ada, that question reaches into the rules of the space. The room has an acoustic effect because a model gives it one. Its selection can be heard, compared, and changed. The spectrum is evidence of the output; the comparison with the original is yours to make.</p></section>
<div class="two"><figure><a href="return-controls.png"><img src="return-controls.png" alt="Four physical pushbuttons on a compact mounted Return console"></a><figcaption>Native physical buttons, mounting plates and flat text: next pass, automatic playback, replay and reset.</figcaption></figure><figure><a href="absorbent-room.png"><img src="absorbent-room.png" alt="The same room with darker absorbent surface panels"></a><figcaption>Surface colour follows the actual absorption parameter. Changing it resets the experiment to keep the starting voice constant.</figcaption></figure></div>
<section><h2>A model with visible limits</h2><p>This first version uses three damped delay paths whose round-trip times come from the room dimensions. It is a simplified resonance model. It does not calculate wall reflections by tracing the mesh, model the open doorway, or measure the physical room around your headset. The microphone captures the first phrase; subsequent passes happen inside the model.</p><p>Walking changes your relation to the spatial loudspeaker. It does not yet recalculate the acoustic transfer for a moving microphone. Normalization, finite recording length and a three-second tail are also part of this version’s rules.</p><figure><img src="spectra.png" alt="Frequency spectra of the actual audio buffers, showing increasing spectral concentration and a difference between reflective and absorbent cases"><figcaption>Analysis of the saved buffers. Each curve is normalized to its own spectral peak; this is a comparison of frequency content, not loudness or a subjective intelligibility test.</figcaption></figure></section>
<details><summary>What has been checked</summary><p><strong>COUNT desktop checks passed.</strong> Actual recursive PCM, original preservation, cancellation during processing, bounded recording and pass count, surface comparison, native controller grabs, reach, collision, the full room scene, and staged entry/return. A known synthetic signal tested the muted recording bus; no real microphone was opened during the tests.</p><p>Twelve reflective passes took WORKER milliseconds each on this desktop’s background worker. This is not a Quest performance measurement. Quest microphone permission, listening, comfort and frame budget remain untested. The log retains the existing unresolved startup UID and exit object-leak warnings; no script errors occurred.</p><p><a href="report.json">Checks</a> · <a href="audio-analysis.json">Audio diagnostics</a> · <a href="run-log.txt">Runtime log</a> · <a href="sources.json">Source hashes</a></p></details>
<details><summary>Implementation and local recording</summary><p>One finite voice, one worker job at a time, at most 24 recursive passes. The microphone bus is muted after capture. Your recording stays in session memory; this artifact never uploads it or saves it to disk. <a href="https://docs.godotengine.org/en/stable/tutorials/audio/recording_with_microphone.html">Godot’s microphone recording API</a> supplies capture.</p><p>Scene: <code>commons/scenes/room_memory.tscn</code><br>DSP: <code>commons/artifacts/ambient_patch/room_memory_dsp.gd</code><br>Checks: <code>python doc/reports/room-memory-2026-09-22/run.py</code></p></details>
<footer><p>BACK TO HALL returns to the Synthesis Lab. AMBIENT ROOM preserves the earlier generative instrument.</p></footer></main></html>'''
html=html.replace('CARDS',cards).replace('COUNT',str(count)).replace('WORKER',f'{min(worker)}–{max(worker)}')
html=html.replace('</nav>','<a href="#book-passage">Read the book passage</a></nav>',1)
html=html.replace('<details><summary>What has been checked</summary>',
    '<section id="book-passage" style="max-width:800px;margin:70px auto"><small>From the Synthesis Lab manuscript</small>'+passage_html+
    '<p class="muted"><a href="/book?map=WaveFunctions_Synthesis_Lab&amp;section=final">Read the complete chapter</a>. This passage is generated from final.md.</p></section>'+
    '<details><summary>What has been checked</summary>',1)
html=html.replace('</style>','pre{padding:20px;background:#e0e5dc;border-radius:6px;overflow-x:auto}pre code{font-size:16px}.footnote{font-size:14px;color:#596b64}#book-passage{scroll-margin-top:24px}</style>',1)
(OUT/'index.html').write_text(html,encoding='utf-8')
print('Published',OUT,'checks',count)

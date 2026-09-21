"""Publish the reviewed W2 encounter without replacing Claude's dated evidence."""
from pathlib import Path
import hashlib,json,shutil,wave
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/research/possible-bodies'
REC=ROOT/'doc/space/effect-sound-review-2026-09-12'
RUN=ROOT/'ada_run/effect-sound-review-2026-09-12'
MAP='WaveFunctions_Effect_Sound'
HALL=RUN/MAP
run=json.loads((RUN/'run.json').read_text(encoding='utf-8'))
assert run['exit']==0 and run['checks']==100 and not run['failures']
assert run['sources_unchanged'] and run['original_hand_unchanged']
REC.mkdir(parents=True,exist_ok=True)
manifest=[]
def copy(src,name):shutil.copyfile(src,OUT/name);manifest.append(name)
def save(name,text):(OUT/name).write_bytes(text.encode('utf-8'));manifest.append(name)

copy(HALL/'probe_effect_sound_desktop_operating_live.png','effect-sound-operating.png')
copy(HALL/'probe_effect_sound_readout_live.png','effect-sound-readout.png')
copy(HALL/'probe_effect_sound_live.json','effect-sound-check.json')
copy(RUN/'run.json','effect-sound-run.json')
for name in ['final','tutorial','technical','critical']:
    copy(ROOT/f'commons/maps/{MAP}/{name}.md',f'effect-sound-{name}.md')
audio=['audio_A_baseline_unmodulated.wav','audio_B_index4_moddecay0.5.wav','audio_B_index4_moddecay1.5.wav']
for name in audio:copy(HALL/name,'effect-sound-'+name)
def pair(a,b,name):
    with wave.open(str(HALL/a),'rb') as left, wave.open(str(HALL/b),'rb') as right:
        assert left.getframerate()==right.getframerate()==44100
        assert left.getnchannels()==right.getnchannels()==1
        assert left.getsampwidth()==right.getsampwidth()==2
        params=left.getparams();frames=left.readframes(left.getnframes())+b'\x00'*22050+right.readframes(right.getnframes())
    with wave.open(str(OUT/name),'wb') as target:target.setparams(params);target.writeframes(frames)
    manifest.append(name)
pair(audio[0],audio[1],'effect-sound-compare-index.wav')
pair(audio[1],audio[2],'effect-sound-compare-decay.wav')

text='''# One wave inside another

[Sine Space](sine-contact.html) → **Effect Sound** → [AirMusic](air-music.html)

[The primary and its book passage](/necklace/thread?map=WaveFunctions_Effect_Sound&role=primary) · [Wavefunctions work plan](/research/waves-chance-noise/index.html#WaveFunctions_Effect_Sound)

In Sine Space, a wave became a contact surface or the shape of a passage. Here it enters another wave's phase. The question changes with the construction: **what does one oscillation let another become?**

Claude built the two-desk encounter and repaired its blocked readout and overlapping names. Astra's independent review keeps that work. Both names and the low readout are visible from the operating area; the surrounding instruments remain further explorations. The book follows one primary, `DualBallFMController`.

![The reviewed standing view: carrier and modulator desks, low comparison readout and scope](effect-sound-operating.png)

## Keep one sound, change one relation

Press BASELINE and let the note end. HOLD saves it as A. Lift the orange ball while keeping its other directions steady, then let it rest and COMPARE. A plays first, followed by a quarter-second gap and the current B. Listen for where the change happens before naming a timbre.

The same comparison is available here for remote listening. These are the exact mono samples rendered by the independent probe. The pairs join two notes with 0.25 seconds of silence; they have no added gain or normalisation. Your playback equipment supplies another part of the encounter.

**1. Add modulation.** First: index 0. Second: index 4. Carrier, envelopes, ratio and modulator decay remain the same. Each note lasts 1.8 seconds.

<audio controls preload="metadata" aria-label="Compare modulation index zero and four"><source src="effect-sound-compare-index.wav" type="audio/wav">Your browser can download the comparison WAV.</audio>

**2. Let the change persist.** First: modulator decay 0.5 seconds. Second: 1.5 seconds. Both use index 4. Listen through the tail; the carrier's decay has not changed.

<audio controls preload="metadata" aria-label="Compare short and long modulator decay"><source src="effect-sound-compare-decay.wav" type="audio/wav">Your browser can download the comparison WAV.</audio>

[Baseline note](effect-sound-audio_A_baseline_unmodulated.wav) · [Index 4, short modulation decay](effect-sound-audio_B_index4_moddecay0.5.wav) · [Index 4, long modulation decay](effect-sound-audio_B_index4_moddecay1.5.wav)

## The picture makes a choice too

The modulator enters the carrier's sine argument. It changes phase rather than joining the output as a second voice. The expression is in the book after the first listening comparison.

There is a small surprise in the scope: its orange lane divides by modulation index. Once the index exceeds the small denominator threshold, raising it can change the sound while leaving that trace's height unchanged. The output lane is magnified twofold. The display selects two carrier periods near the attack, so the whole fading note is absent from the picture. These choices make particular relationships easier to inspect and leave others to uncover.

![The complete comparison readout, now outside the platform that had enclosed it](effect-sound-readout.png)

| Control | What it does |
|---|---|
| BASELINE | Sets the unmodulated 440 Hz reference, with envelope and shaping, and plays it. |
| HOLD | Saves the current six values and rendered note as A, then plays A. |
| PLAY | Renders and plays the current setting B. |
| COMPARE | Replays A, then renders B after A and a 0.25-second gap. Without A, it first holds the current note. |

The `differs:` line helps separate parameter changes; small differences below its reporting tolerances are omitted. Leave the balls still during COMPARE to hear the pair you prepared. Moving continuously can restart the note before its tail is heard.

## Review and next visit

**100 independent desktop checks passed; the engine exited normally.** The run exercised both mapper paths, audition buttons, sample comparisons, the scope, approach routes, local sound activation, cleanup and room rebuilding. The original saved hand and Claude's evidence were preserved. No gameplay code or room geometry changed in this review.

The revised supporting tutorial now teaches this instrument and uses eleven checked production-code excerpts across tutorial and final. It corrects the older unrelated waveform examples and distinguishes sample generation, the finite buffer, scope gains and listening. One primary book artifact remains aligned across the room, roles and text.

Headset reach and a person's listening observations remain open. The ball movement in the probe follows the mapper path; it does not demonstrate a tracked-hand grab. Buttons use the project's desktop input rig. The small targets and labels deserve a headset visit, and the backs of secondary displays still crowd the wider room view.

[Desktop report](effect-sound-check.json) · [Independent run receipt](effect-sound-run.json) · [Tutorial](effect-sound-tutorial.md) · [Technical notes](effect-sound-technical.md) · [Critical text](effect-sound-critical.md)

**Next: [AirMusic](air-music.html).** A strike is brief; the response continues. Keep the habit of listening through an ending before deciding what kind of body answered.
'''
final=(ROOT/f'commons/maps/{MAP}/final.md').read_text(encoding='utf-8')
save('effect-sound.md',text+'\n## Book passage\n\n'+final)
style=(OUT/'sine-contact.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style+=' audio{display:block;width:100%;margin:1rem 0 2rem} details{border:1px solid #b7b0a2;padding:20px;margin-top:36px}summary{cursor:pointer;font-weight:600}details h1{font-size:32px}'
body=markdown.markdown(text,extensions=['tables','fenced_code'])
body+='<details><summary>Read the book passage</summary>'+markdown.markdown(final,extensions=['fenced_code'])+'</details>'
save('effect-sound.html','<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>One wave inside another · Ada Research</title><style>'+style+'</style></head><body><main>'+body+'</main></body></html>\n')
(REC/'publication-manifest.json').write_bytes((json.dumps(manifest,indent=2)+'\n').encode('utf-8'))
(REC/'publication-hashes.json').write_bytes((json.dumps({n:hashlib.sha256((OUT/n).read_bytes()).hexdigest() for n in manifest},indent=2)+'\n').encode('utf-8'))
print(json.dumps({'published_files':len(manifest),'desktop_checks':run['checks'],'audio_pairs':2}))

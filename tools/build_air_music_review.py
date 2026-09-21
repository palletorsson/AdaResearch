"""Build the AirMusic review from its independent run and exact exported PCM."""
from pathlib import Path
import array
import hashlib
import json
import shutil
import sys
import wave
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/research/possible-bodies'
REC = ROOT / 'doc/space/air-music-review-2026-09-12'
RUN = ROOT / 'ada_run/air-music-review-2026-09-12'
MAP = 'WaveFunctions_AirMusic'
HALL = RUN / MAP
run = json.loads((RUN / 'run.json').read_text(encoding='utf-8'))
assert run['exit'] == 0 and run['checks'] == 67 and not run['failures']
assert run['sources_unchanged'] and run['original_hand_unchanged']
REC.mkdir(parents=True, exist_ok=True)
manifest = []


def copy(src, name):
    shutil.copyfile(src, OUT / name)
    manifest.append(name)


def save(name, text):
    (OUT / name).write_bytes(text.encode('utf-8'))
    manifest.append(name)


copy(HALL / 'probe_air_music_two_voices_live.png', 'air-music-two-voices.png')
copy(HALL / 'probe_air_music_desktop_front_live.png', 'air-music-table.png')
copy(HALL / 'probe_air_music_live.json', 'air-music-check.json')
copy(RUN / 'run.json', 'air-music-run.json')
for name in ['final', 'tutorial', 'technical', 'critical']:
    copy(ROOT / f'commons/maps/{MAP}/{name}.md', f'air-music-{name}.md')


def read_note(name):
    with wave.open(str(HALL / name), 'rb') as note:
        assert note.getframerate() == 44100 and note.getnchannels() == 1
        assert note.getsampwidth() == 2 and note.getnframes() == 330750
        samples = array.array('h', note.readframes(note.getnframes()))
        if sys.byteorder != 'little':
            samples.byteswap()
        return samples


def write_note(name, values):
    assert min(values) >= -32768 and max(values) <= 32767
    data = array.array('h', values)
    if sys.byteorder != 'little':
        data.byteswap()
    with wave.open(str(OUT / name), 'wb') as target:
        target.setparams((1, 2, 44100, 0, 'NONE', 'not compressed'))
        target.writeframes(data.tobytes())
    manifest.append(name)
    return {'frames': len(values), 'seconds': len(values) / 44100,
            'min_sample': min(values), 'max_sample': max(values)}


c4, a4 = read_note('audio_C4.wav'), read_note('audio_A4.wav')
copy(HALL / 'audio_C4.wav', 'air-music-C4.wav')
copy(HALL / 'audio_A4.wav', 'air-music-A4.wav')
separate = list(c4) + [0] * 11025 + list(a4)
overlap = [0] * (len(c4) + 44100)
for start, note in [(0, c4), (44100, a4)]:
    for i, value in enumerate(note):
        overlap[start + i] += value
audio_evidence = {
    'source': 'Exact pre-generated bar buffers exported by the live probe',
    'gain_per_source': 1.0,
    'normalisation': False,
    'spatial_audio': False,
    'separate': write_note('air-music-separate.wav', separate),
    'overlap': write_note('air-music-overlap.wav', overlap),
    'separate_gap_seconds': 0.25,
    'overlap_A4_start_seconds': 1.0,
}
save('air-music-audio.json', json.dumps(audio_evidence, indent=2) + '\n')

text = '''# After the strike

[Effect Sound](effect-sound.html) → **AirMusic** → [Synthesis Lab](synthesis-lab.html)

[The primary and its book passage](/necklace/thread?map=WaveFunctions_AirMusic&role=primary) · [Wavefunctions work plan](/research/waves-chance-noise/index.html#WaveFunctions_AirMusic)

Lift the stick away. Something continues without your hand. Strike the same bar again, then try a different one while the first still rings. **What starts over, and what is allowed to continue?**

Claude's eight-bar table, working striker and returning cradle remain the encounter. This review gives its waveform a closer relation to the notes: it now reads a short window of each bar's generated sound at that bar's own playback age. The book follows the metallophone through contact, repetition and overlap.

![Two sounding bars, two ages, and the curve made by adding their source samples](air-music-two-voices.png)

## Keep the notes; change their meeting

The same bar starts its existing player again. A second bar has another player, so its note can begin while the first continues. Try C4, the longest bar, then A4, the fifth bar from the left. Listen through the ending before deciding whether you heard two separate events or one changing sound.

These remote examples use the exact C4 and A4 sample buffers exported from the running instrument. They are constructed comparisons at equal, unit player gain, before spatial audio. They are not recordings of the probe's strikes, which had their own strengths. No normalisation, added effects or clipping is applied.

**Separate.** C4 plays for 7.5 seconds. After a quarter-second gap, A4 plays for 7.5 seconds.

<audio controls preload="metadata" aria-label="C4 and A4 with a gap"><source src="air-music-separate.wav" type="audio/wav">Download the separate notes below.</audio>

**Overlap.** C4 begins, and A4 joins one second later. Their frequencies and buffers stay the same; their meeting changes.

<audio controls preload="metadata" aria-label="C4 and A4 overlapping after one second"><source src="air-music-overlap.wav" type="audio/wav">Download the overlapping notes below.</audio>

[Separate notes](air-music-separate.wav) · [Overlapping notes](air-music-overlap.wav) · [C4 alone](air-music-C4.wav) · [A4 alone](air-music-A4.wav)

## A small window with several beginnings

The curve spans **12 milliseconds**, sampled at 512 points. It adds each playing bar's stored PCM samples after that player's gain. The readout names the voices and their different playback ages. The scale stays fixed as the sound fades; if the sum exceeds the drawing range, the label reports a display limit.

This is a view of the generated sources before distance, the audio bus and the listening equipment. The room and your position still contribute to what reaches you. The picture makes a particular part of that encounter available to inspect.

![The eight bars and striker cradle from the desktop operating position](air-music-table.png)

| Try in the hall | What to notice |
|---|---|
| Strike one bar and lift the stick away. | Contact ends while the response continues. |
| Strike that bar again before it ends. | Another attack, one voice; its age restarts. |
| Strike another bar while the first rings. | Two voices keep different beginnings. |
| Touch the same bar slowly, then quickly. | Strength affects glow and player gain through different mappings. |
| Leave the stick unheld, more than half a metre from its cradle. | After three seconds its return begins; the return does not play the bars. |

## Where the model lets go

The bars look like a material argument about length and pitch. In this implementation the note is chosen first, then length is assigned from frequency. The contact chooses when a stored sine begins and how strongly it plays. A different-looking bar could carry the same stored note.

Its exponential envelope still has about 37 percent of its initial value after three seconds. Mathematically it never reaches zero, yet this note ends at 7.5 seconds, with an extra fade in its final tenth. The program gives the response an ending. We can hear that decision and read the code that makes it.

## Review and next visit

**67 independent desktop checks passed; the engine exited normally.** They cover collision strikes, repeated and overlapping notes, the cradle return, approach routes, cleanup and rebuilding. New checks independently decode PCM, apply player gain, add the windows and compare the sum with the drawn curve. The measured voices had different ages.

All ten placed artifacts remain. The book hero now agrees with the existing primary: `resonating_metallophone`. The revised final and tutorial contain fourteen checked production-code excerpts. The supporting texts distinguish the glow, generated sound and listener's encounter.

Tracked-hand reach, label legibility in the headset and a person's listening observations remain for a later visit. The probe moved the actual striker through its collision path. It did not demonstrate a human hand playing the instrument. Some secondary captions still crowd the wider view.

[Desktop report](air-music-check.json) · [Run receipt](air-music-run.json) · [Audio construction](air-music-audio.json) · [Tutorial](air-music-tutorial.md) · [Technical notes](air-music-technical.md) · [Critical text](air-music-critical.md)

**Next: [Synthesis Lab](synthesis-lab.html).** Here the sum came from separately struck bars. The next bench makes a sum visible: what becomes possible when five harmonic amounts are chosen together, and what does their shared phase leave out?
'''
final = (ROOT / f'commons/maps/{MAP}/final.md').read_text(encoding='utf-8')
save('air-music.md', text + '\n## Book passage\n\n' + final)
style = (OUT / 'effect-sound.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
body = markdown.markdown(text, extensions=['tables', 'fenced_code'])
body += '<details><summary>Read the book passage</summary>' + markdown.markdown(final, extensions=['fenced_code']) + '</details>'
save('air-music.html', '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>After the strike · Ada Research</title><style>' + style + '</style></head><body><main>' + body + '</main></body></html>\n')
(REC / 'publication-manifest.json').write_bytes((json.dumps(manifest, indent=2) + '\n').encode('utf-8'))
(REC / 'publication-hashes.json').write_bytes((json.dumps({n: hashlib.sha256((OUT / n).read_bytes()).hexdigest() for n in manifest}, indent=2) + '\n').encode('utf-8'))
print(json.dumps({'published_files': len(manifest), 'desktop_checks': run['checks'], 'audio': audio_evidence}))

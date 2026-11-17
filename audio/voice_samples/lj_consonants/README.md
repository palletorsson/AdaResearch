# LJ consonants — desktop singing pilot

This 160 KiB bank contributes recorded consonant noise to the existing Godot
PhonemeVoice. The fold source, sung pitch, vowel formants, vibrato and timing stay
procedural. No speech neural network, aligner or original corpus is needed live.

**17 recorded components:** p b t d k g f v th dh s z sh zh h ch j.
**7 entirely synthetic consonants:** m n ng l r w y. Voicing underneath recorded
voiced stops/fricatives is also synthetic. All vowel targets stay synthesized.

Source: [LJ Speech, Keith Ito](https://keithito.com/LJ-Speech-Dataset/), recordings
by Linda Johnson from LibriVox. The upstream publisher states that text and audio
are public domain in the USA. The recordings originated as MP3, so they are not
pristine studio phoneme recordings. The pinned mirror and exact original WAV
hashes, words, time boundaries and extracted-file hashes are in `manifest.json`.
The mirror identifies its source as LJSpeech 1.0; this pilot uses those individual
clips rather than asserting it downloaded the complete upstream 1.1 archive.

## Reproduce

From the repository root, install requests, numpy, scipy, soundfile and
PocketSphinx 5.1.1 in a development environment, then run:

```powershell
python tools/probes/build_lj_consonants.py
```

The builder also accepts PocketSphinx installed in
`ada_run/phoneme-desktop/lj-hybrid/pydeps`. Source WAVs and full alignments stay in
that ignored work area. Only these 17 small WAVs and their manifest are runtime
assets. A local `.gitignore` exception deliberately includes this bank's WAVs.

Alignment uses PocketSphinx's documented two-pass forced alignment at 10 ms
resolution. Clips with unknown dictionary words or failed alignment are skipped.
Boundaries are provisional, not a manually labelled phonetic reference set.
Each selected segment is high-pass filtered to reduce recorded low-pitched
voicing, resampled to 44.1 kHz and faded at its edges. This does not remove every
trace of the source voice. One context per sound is an initial listening pilot.

Runtime keeps stop bursts at their original sample rate and stretches their
closures. Continuous frication uses overlapping unpitched grains so slowing the
song does not simply pitch down the recording. The bank is RMS-matched to each
synthetic consonant with a peak cap, then blended. Missing samples fall back to
synthesis. A/B playback additionally matches whole-phrase RMS, with a peak guard.

## Compare

In the desktop Phoneme Library bench select a phrase, then **A · CURRENT** and
**B · LJ HYBRID**. Both apply the same notes, speed and effects settings. B defaults
to 75% recorded noise; **Recorded consonant blend** changes this. The sound
library also has a hybrid toggle for individual /a–consonant–a/ auditions.

On 2026-11-17 Palle approved the hybrid for the game after listening. Point Zero
now uses 75% recorded consonants at half-speed, with five prepared phrases for
immediate playback (about 2.44 MiB total). The desktop comparison remains
available. The current Quest installation has not been replaced by this change.
Intelligibility still needs listening judgement; correct timing alone does not
prove natural speech quality.

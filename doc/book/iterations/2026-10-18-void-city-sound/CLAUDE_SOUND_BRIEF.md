# The Void / sound handoff

Core: exposed tower above a distant city; very soft wind, town far, birds sparse.
Latest direction: much more subtle. A rare siren belongs to the distant town,
not to an alarm inside the tower. Quiet should be the usual condition.
Preserve silence and space for the author's rendered MP3 music. Make original
sounds with industrial distance and material detail. Current WAVs are provisional
offline synthesis, already wired into the playable game. Replace sound assets;
keep the interaction logic, floor layouts and tutorial material intact.

## Deliver these ten files

Folder: `commons/void/audio/`. Replace in place or update `sounds` in
`manifest.json`. Runtime accepts WAV, OGG and MP3. Prefer PCM 16-bit WAV at
48 kHz for effects; OGG is useful for long beds. Keep peaks at or below -6 dBFS.
Do not master every clip to maximum loudness. Levels are mixed in the manifest.

| Slot / current file | Character | Length | Format |
| --- | --- | --- | --- |
| wind / wind.wav | Air through exposed steel/concrete; broad and soft, slight gusts; no shrill sustained whistle | 45–90 s, seamless loop | Stereo |
| city / city.wav | Distant traffic/industrial rumble; indistinct urban activity well below the player | 60–120 s, seamless loop | Mono; two offset world sources |
| bird1 / bird1.wav | One distant urban bird call, e.g. gull; natural gap/tail | 1–3 s | Mono |
| bird2 / bird2.wav | A different call in the same environment, e.g. a crow | 1–3 s | Mono |
| siren / siren.wav | Faint emergency vehicle far below; softened high frequencies, slow approach and departure, no abrupt attack | 8–14 s | Mono; no loop |
| grab / grab.wav | Small tactile contact: the hand has acquired this object | 60–140 ms | Mono |
| release / release.wav | Softer related contact; releasing is distinct from collision | 70–160 ms | Mono |
| click / click.wav | Dry button/mechanism click, precise and quiet | 30–90 ms | Mono |
| activate / activate.wav | Restrained mechanism engaging / electrical response; not a reward jingle | 150–400 ms | Mono |
| reject / reject.wav | Muted low response, readable without startling the listener | 100–250 ms | Mono |

Do not embed bird calls, sirens, music, UI cues or speech into the continuous
beds. Birds are attempted every 50–110 seconds; sirens every 120–240 seconds,
including the first delay. A call is skipped if the other is sounding. No loud
surprise effects. Wind is now 10 dB lower and city 12 dB lower than the first
pass. Keep this restrained balance; do not compensate by mastering louder files.
Positional sounds receive distance attenuation at runtime, so supply clean mono
sources rather than baked stereo panoramas. A little natural character is good;
large baked reverbs will blur the artifact's location.

The city inspiration is a sense of inhabited distance and exposed industrial
space. The Void keeps its own pink/violet sky and open architecture.

## Music from the other computer

Put rendered tracks under `commons/void/audio/music/` and list their `res://`
paths in the manifest's `music` array. The array is empty now; no soundtrack is
invented or substituted. The system uses two music players with crossfades on
switches and advances at track end. It registers them with the existing
SoundBank. Wind, city and birds continue on their separate ambience channel.
No source synthesizer or song-generation dependency is required in the tower.

## Listen and test

Restart The Void. Listen on the roof, near an exposed edge, down at Trace, while
holding the point, at the Line reset button, and while playing a music track.
Object feedback should remain legible at modest volume. Sound should stay at
its source when you turn your head. Adjacent/sleeping floors must not chatter.

Run `python tools/test_void_audio.py --capture` after replacement. This validates
files and full-project routing, MP3 playback, artifact actions and synthetic XR
grip/release. It cannot judge the sound's character or headset loudness.
Do not rerun `tools/build_void_audio.py --write` over finished sounds: that command
regenerates the provisional assets.

Acceptance: click-free loops; quiet city behind soft wind; rare birds and sirens;
related but distinct object cues; MP3 has room; no changes to artifact behaviour.

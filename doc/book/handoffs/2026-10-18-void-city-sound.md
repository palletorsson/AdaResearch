# Void city / audio first pass

## Latest direction: quieter, with rare distant sirens

User asked for much subtler ambience and occasional sirens far away. Wind now
-28 dB (10 dB lower), city -28 dB (12 lower), birds -22 dB (10 lower). Birds
wait 50–110 seconds. Sirens wait 120–240 seconds including on arrival; world
sources roughly 300 m away, y=-80 to -90, -22 dB before distance attenuation.
New original provisional mono siren.wav is 11 seconds with gentle fades and
soft harmonics. Birds/sirens skip an attempt if the other is playing. Runtime
logic uses one extra spatial voice; no per-frame synthesis. Music/effects and
floor layouts unchanged. Revised Claude brief says silence is the default.

New verification: 34 full-project checks pass on both Forward+ and Mobile,
including distant placement, first delay, no bird/siren overlap and previous
interactions. Source checks assert mono, duration and gentle fade endpoints.
Dummy audio / synthetic XR remain the limits; actual headset listening pending.
Report now has a 32-second quiet audition with compressed event timing (siren
at 10 s only in preview). `--refresh-siren` rebuilds just siren and the preview,
preserving the previous nine sound files. Restart the game to reload the mix.

## Original implementation record

User wants a City 17-like sense of distant urban atmosphere: see/hear the town,
wind, occasional birds, MP3 music made on another computer, and object click /
activation feedback. Claude may make the sounds after the playback system exists.

Implemented scene-local `commons/void/soundscape.gd`, started by game.gd. Reads
audio/manifest.json; three buses VoidAmbience, VoidMusic, VoidEffects. Stereo
wind varies modestly with exposure; two mono city sources at distant positions;
world-position bird calls at 22–48 s intervals. Eight pooled spatial object
voices. Hook existing pickup/drop/button/action/health/damage/slider signals,
including newly created objects. Ignore disabled/invisible sources (sleeping
and preview floors), distance cull 24 m, cooldowns and weak-ref cleanup. The
floor's catalyst panel emits a notification after its existing geometry update.
No input, artifact operation or authored room placement changed.

Optional MP3/OGG/WAV playlist; empty until actual user tracks arrive. Two music
players register/unregister with existing SoundBank; crossfade on manual switch,
advance at track end. Runtime can load newly delivered raw files as well as
imported resources. Music uses its own gain; ambience continues underneath.

Original temporary audio: tools/build_void_audio.py --write creates nine WAVs
offline; no synthesis runs in the VR frame loop. Never regenerate over final
artist assets. Claude brief: commons/void/audio/CLAUDE_SOUND_BRIEF.md. This was
prepared locally, not sent to another agent or computer. User's finished MP3
music is not present. Tiny MP3 under tools/probes/fixtures is test-only.

City horizon: city_horizon.gd, one MultiMesh, 72 simple silhouettes below/around
the tower, no collision. Tops visible through a separate horizon haze treatment;
bases fade into the cloud sea. Same pink/violet cycle; near-floor fog ownership
fix remains intact. This is a first spatial suggestion, not a detailed city.

Verification: tools/test_void_audio.py --capture runs the full project and real
autoloads, with Dummy audio driver. Final Forward+ and Mobile runs each passed
27 checks, including the real catalyst panel on floor 1. Real reset button and retained trace,
MP3 playback/switching, pool/culling/sleeping, new ramp ball hook, cleanup, and
real XRTools pickup/release using synthetic trackers. 117 objects have feedback
hooks across loaded first five halls. Physical headset listening not performed.
The independent source-wave check verifies nonempty, unclipped PCM data.

Report: doc/book/iterations/2026-10-18-void-city-sound/index.html with native
rooftop screenshot and illustrative 24-second sound-sketch.wav. The sketch is
an offline listening mix, not captured headset spatial audio. Mobile receipt
and screenshot live under mobile/. Existing test_void_game.py now includes
manifest audio assets in its isolated source closure.

Next: user/Claude replace and tune these provisional sounds, supply rendered
music, then listen in the headset for levels and localization. Preserve the
separation between ambient bed, spatial object response and music.

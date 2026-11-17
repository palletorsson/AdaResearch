# Point Zero / small signals

Original quiet contemporary minimalist pop accompaniment for the inner opera, 2026-11-17.

Palle chose listening comparison **3**, with full LJ consonant blend, air 0.25,
vibrato 6 cents and vocoder mix 0. Singing vowels remain synthesized at half speed.
The main voice settings are in `commons/data/opera/tower_bindings.json`; the five
prepared phrases are listed in `audio/voice_cache/lj-clarity-3-20261117.json`.

Two stereo 22.05 kHz loops use clean plucked keys, a quiet pad, rounded sub-bass,
and dry kick/snap percussion: eight bars at 96 BPM, 20 seconds each. The harmony
moves through Em9, Cmaj9, Gadd9 and Dsus2. Patterns, voicings and levels are in
`commons/data/opera/minimal_pop_score.json`. Godot generates the music with
`audio/generators/OperaMinimalPop.gd`, without third-party music samples. The two
prepared stems total 3,528,088 bytes; their hashes are in
`minimal-pop-20261117.json`. No synthesis runs during gameplay. The earlier
lo-fi score and its listening preview remain available for comparison.

Edit `commons/data/opera/minimal_pop_score.json` to change the balance. Levels are relative
to the existing VoidMusic bus (normally -16 dB). Keys rise 3 dB during singing;
the very faint percussion becomes more audible. The rise takes 0.9 seconds and
the release takes 3 seconds. The voice level is unchanged. Music starts after the
opening, fades away outside the floors with sung-artifact bindings, and obeys
the quiet test mode. Both loops keep playing through each thought.

Regenerate the music with `tools/probes/ship_opera_music.gd` in the isolated audio
project; it reads the active accompaniment from the tower bindings. Copy its two
WAVs here. Regenerate voice after tuning with
`tools/probes/ship_voice.gd`; retain the filenames produced by the actual game
cache key. Do not clean unrelated caches or restart a user's live playtest.

Validation: `tools/probes/check_opera_music.gd` exercises the real opera/voice
signals with a small floor fixture. It verifies five immediately available
phrases, singing lift, natural finish, floor-exit fade, quiet mode, failure
handling and cleanup. Both WAV loop joins match exactly and neither clips.
`tools/probes/preview_opera_music.gd` records the real Godot mixer for listening;
this is an audio comparison, not a full desktop or headset acceptance test.

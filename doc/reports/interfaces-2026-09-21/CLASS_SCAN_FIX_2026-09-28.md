# Archived interface sources and Godot class registration

28 September 2026. Desktop Endless Museum reported that `SciFiLoFiSoundscape` hid a global script class. Godot had indexed the preserved radio-console source snapshot as that class instead of the live script. The exact error reproduced with Godot 4.6's parser before the fix.

Three `.gdignore` markers now exclude source archives:

- `radio-console/before/`: SciFiLoFiSoundscape.
- `console-placement/before/sources/`: GameSoundMeter and SimpleWaveformDisplay.
- `xy-pad/before/`: VectorOpConsole.

The archived files are preserved. The report root remains visible because several report-local regression scripts are deliberately executable. When adding source backups beneath this report, put a `.gdignore` in the backup directory before adding `.gd`, `.tscn`, or UID sidecars.

The local generated class cache contained the four wrong paths. A bounded headless editor import exceeded 90 seconds, so the four cache entries were repaired directly to their verified live sources, preserving the rest of the cache. The ignore markers are the persistent project fix. An editor already open during the repair may retain the old registrations in memory; reopen the project if the old error remains.

Verification: a headless runtime smoke test with real project autoloads passed 12 checks. All four classes register at live paths and compile; AudioLoadingIndicator and SoundscapeRadioRack compile; SciFiLoFiSoundscape instantiates, enters the scene tree and initializes its five-player pool. The production soundscape script was not modified by this fix. The check used Dummy audio and did not play through the full museum or test a headset.

A separate `Unrecognized UID: uid://rwex60pqapc` diagnostic for the configured audio bus layout was present before this repair and remains. It did not prevent the focused runtime checks. Raw logs and the verification receipt are in `ada_run/soundscape-class-fix-2026-09-28/`.

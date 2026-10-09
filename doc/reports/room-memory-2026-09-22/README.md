# Room Memory - completed 2026-09-22

The user clarified that the request referred to Alvin Lucier's I Am Sitting in a Room. Built a separate recursive voice experiment; ENTER ROOM on ambient_patch now selects commons/scenes/room_memory.tscn. The earlier ambient room is kept behind AMBIENT ROOM. Existing XR wrapper and museum return contract are reused.

Voice: local, opt-in microphone capture up to eight seconds; labelled offline synthetic demo; no audio network or file saves in the artifact. Model: three damped round-trip delays tied to 6 x 5 x 3 m dimensions, worker processing of the previous PCM, fixed window with three-second tail, peak normalization, up to 24 passes. Original comparison and absorption reset allow controlled comparison. The model is explicitly simplified, not mesh acoustics or a measured response. A true 3D response depending on speaker/mic positions remains future work.

134 desktop checks passed, native recording bus tested with known synthetic PCM (no actual microphone opened), waveform/spectral comparison exported for listening. First test found the entry capsule could overlap the exit trigger; moved the trigger beyond the doorway and added a negative arrival check. Empty recording is handled without calling the native record getter on an empty buffer. Source ships as a Godot .res resource for packaged runtime loading, plus authoring WAV.

Review: http://localhost:3003/book-review/doc/book/iterations/2026-09-22-room-memory/index.html
Reproduce: python doc/reports/room-memory-2026-09-22/run.py then python doc/reports/room-memory-2026-09-22/publish.py
All review images and five audio files are actual Godot scene/buffer output. Screenshot was visually inspected. HTTP responses checked. The earlier ambient-room review now links the clarification.

Quest microphone permission, sound, comfort, and performance remain untested. Existing unresolved UID rwex60pqapc and ObjectDB exit-leak warning remain in the log; no script errors. No commit. final.md and museum map placements unchanged.

## Book addition

Added What the room keeps to WaveFunctions_Synthesis_Lab/final.md; source-aware listening instructions, copy versus recursive processing, analogue material versus assigned acoustic behaviour, and speculative material swaps. Preserved the additive bench and handoff to randomness. intent.md and field_notes.md updated. Review publisher extracts this passage and footnotes directly from final.md into #book-passage. HTTP/rendered-structure checks passed; no runtime code changed and no new gameplay tests needed.

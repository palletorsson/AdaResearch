# Primitives audiobook — complete

The captured Primitives edition has been rendered with Google Gemini 3.1 Flash TTS Preview, using the synthetic Sulafat voice.

- 10 hall tracks, in spine order, plus a separate notes track.
- Continuous MP3: approximately 96 minutes, 69.1 MB, including notes.
- 12,228 spoken words, with explicit spoken adaptations of 24 code/data blocks and all 37 footnotes.
- Playback and download: [Audiobook page](index.html).
- Audio files: google/gemini-3.1-flash-tts-preview-Sulafat/.
- Original captured manuscripts and hashes: source/ and sources.json.

All 11 MP3 tracks and the continuous MP3 passed decoding checks. The combined duration matches its chapter tracks and pauses. The HTTP page, audio MIME type, seeking ranges and download headers were checked. See audio-checks.json. No claim of a completed human listening review is made.

## Edition difference

The live Point_Line_Grid/final.md gained two sentences during recording about using PREVIOUS, NEXT and AUTO to control the coordinate-list pages. This audio edition retains the earlier captured paragraph. That small later addition can enter a subsequent audio revision. The audiobook process did not edit any manuscript.

## Google setup

The key is saved outside the repository, protected by Windows DPAPI. The user added credit after the initial billing error; synthesis then succeeded. No keys are included in these documents. The two render processes have finished; nothing is still running for narration.

For future runs, use tools/google_audiobook.py. Completed passages are cached by text, model, voice and direction. The source edition is frozen; update it deliberately for a revised narration. The existing render.json records tracks, durations and source provenance. The encyclopedia book-review route now serves MP3 and WAV with byte ranges and permits same-origin media.

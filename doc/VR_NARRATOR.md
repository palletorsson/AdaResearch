# The hall reads itself — final.md aloud, over the USB link

*2026-09-27. Palle: "Can we trigger the text of the final.md as text to speech or mp3 audio
file with adb on the desktop when we move around in VR. Best to sync every new hall, but
point_one has two chapters."*

Yes, and nothing new crosses the cable. The Quest is already on the PC's `adb reverse`
tunnel for the VR link (`tools/vr_link.py`), and the headset sends its pose twenty times a
second over it. The pose names the map, and in the endless museum the hall — `{pearl, map,
index}`. A new hall is a change in that name. The reading happens on the PC, out of the PC's
speakers.

## Run it

```
python tools/vr_link.py --narrate                 # serve the link and read halls as you enter them
python tools/vr_narrator.py --listen              # the same, beside a vr_link.py already running
python tools/vr_narrator.py --say Point_One       # hear one map now, no headset needed
python tools/vr_narrator.py --text Point_One      # print exactly what would be spoken
python tools/vr_narrator.py --voices              # the voices this PC has; pick one with --voice
python tools/vr_narrator.py --render --seq primitives   # WAV (+ mp3 if ffmpeg) into ada_run/voice/
```

The browser page at `localhost:8772` has a **narrate halls** toggle; the narrator's lines
("reading Point_One: Point One (1752 words), Point One — notes (240 words)") stream into
its log. Flags: `--voice`, `--rate -10..10`, `--no-notes`, `--repeat`, `--read-code`,
`--voice-dir`, `--settle`.

## What is read: two chapters

`commons/maps/<Map>/final.md`, cleaned for a voice. Markers and comments go; links become
their text; `Engine.get_process_frames()` is read as "Engine dot get process frames"; a
fenced code block is announced ("A short code listing.") rather than spelled, unless
`--read-code`; headings are read as sentences, and a body with no title is introduced by the
map's name. Footnote marks leave the body, and the footnotes become a **second chapter**,
"Notes for Point One", read after the essay while you are still in the hall. That is
Point_One's two chapters: a 1752-word essay and four notes. `--text` prints both.

## How it is read

A pre-rendered file wins over a live voice: `ada_run/voice/<Map>/*.mp3|wav` (what
`--render` writes, one file per chapter, with a `manifest.json`), or any `<map>*.mp3` under
`--voice-dir`, played in order. Otherwise the OS speaks: Windows `System.Speech` — the same
SAPI `tools/tts_radio.ps1` uses, shipped with Windows, no install — macOS `say`, Linux
`espeak-ng`. For an audiobook-quality voice, render with `tools/google_audiobook.py` and
point `--voice-dir` at its `mp3/` folder; the narrator finds files by map name.

Every reading is a subprocess, so a hall change stops it mid-word and the next hall begins —
"sync every new hall". A hall must hold you for `--settle` seconds (1.2) before it is read: a
threshold crossed and re-crossed is not two halls. Between halls, where the museum's pose
names no pearl, the current reading carries on. A hall read to the end is not read again in
the same session (`--repeat` changes that); a reading cut short is read again on return.
Two halls of one map (two pearls) are two readings.

## Where the pieces are

| piece | file |
|---|---|
| text cleaning, speakers, the narrator, rendering, the listener | `tools/vr_narrator.py` |
| `--narrate`, `GET/POST /narrate`, the pose hook | `tools/vr_link.py` |
| the toggle | `tools/vr_link_view.html` |
| tests (real final.md files; a NullSpeaker whose processes can be held and cut) | `tools/test_vr_narrator.py` |

The game side needed nothing: the pose already carried the hall. The in-game `tts` utility
(`commons/scenes/mapobjects/tts_speaker.gd`, `DisplayServer.tts_speak`) is a separate,
headset-side path and is untouched.

## Not done here

The Windows, macOS and Linux speakers were written in a container with none of the three
voices installed; the tests prove the narrator around a null speaker. The first `--say
Point_One` on the PC is the check that SAPI speaks and that a hall change cuts it.

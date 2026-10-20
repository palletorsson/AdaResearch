# Before, and what remains

16 October 2026. Random Definition, in the randomness sequence. A local continuation of the eight-page Recorder Edition, prompted by the preserved [critical reading](supplied-reading.md). The supplied reader's 9/10 is their assessment of that earlier edition, not a verified outcome or Palle's adoption of this revision.

[Read the illustrated chapter](illustrated.html) · [PDF](illustrated-chapter.pdf) · [Previous PDF](before/illustrated-chapter.pdf) · [Prose comparison](compare.html)

## What changed

- Keep all three arrival PNGs byte for byte. Correct “Five paths” to “Five rods.” The runtime arrival policy stays intact: abacus and counter on arrival, number page after filling and settling.
- Add two native Godot captures after declared interactions. Reconstructing the saved baseline produces a pixel-identical image in both cases. Neither after image invents marks, changes a camera or uses a different filter.
- Abacus: scripted desktop contact starts each row; advance 48 segments, release and return. Each row retains 576 phase samples. Simulated contact durations are 120, 60, 30, 15 and 60 seconds. The first four X records agree; the fifth adds Y. This is an equal-distance/segment comparison, not equal elapsed time.
- Page: hold `33442` at printed row 3, third group from the left; advance and settle two rows. The group stays at that address. Its unheld neighbour advances two rows. Amber becomes an outlined numeral under the unchanged monochrome filter. The printed row index begins at zero.
- Clarify Gaussian resemblance in the chapter. The actual target distribution is uniform. The image records interpolated positions as well as destinations; visual concentration alone establishes neither a Gaussian target source nor a fitted Gaussian distribution.
- Recompose eight PDF pages: page 3 compares the full crops vertically; page 5 carries the RGB assignment into the reference; page 6 begins the gesture encounter after the table; page 7 holds a larger, 162-point-high rule diagram beside the unchanged ending. The diagram's positions remain authored.
- Keep “Another recorder,” adding the provenance of the two new captures and distinguishing the prose's possible encounter from an identified visitor's experience.

No runtime interaction is changed by this revision. The saved map still restores MOVE / KEEP at (9.5, 18.5), yaw 180. The [prior actual-hall report](museum-report.json) contains 28 passing checks of arrival, placement, seed binding and synthetic desktop release/return. That report is carried forward, not mislabelled as a new headset test. The room/final order and the 48-value first research pilot stay fixed.

## Verification and reproducibility

`capture_pairs.gd` loads the actual artifact scenes and continues a reconstruction of the archived arrival. The full state, camera, filter and protocol are in [captures/capture.json](captures/capture.json). All 32 native checks pass. The fixture advances simulated time explicitly; it is not a recording of someone's hand or of elapsed wall-clock time.

Run Godot 4.6 with compatibility rendering, XR off and Dummy audio:

```powershell
& 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' --path . --xr-mode off --audio-driver Dummy --no-window --rendering-method gl_compatibility --script res://doc/book/iterations/2026-10-16-before-and-after/capture_pairs.gd -- --no-bridges
python -X utf8 doc/book/iterations/2026-10-16-before-and-after/publish.py
```

The publisher uses the frozen `final-source.md`, not whatever the canonical final becomes later. Do not recapture over an adopted edition: copy the trial to a new folder first. All eight PDF pages were rendered and inspected; image pixels, order, numbers and links are checked in `verification.json`.

## Reading plan and live uncertainty

The chapter remains five encounters: movement leaves marks → touch keeps digits → a kept seed produces repeatable gaps → a gesture supplies a new seed → release separates a visitor from compulsory return. The images interrupt only where a state comparison makes something examinable. This is not a page template for every hall.

Prose: 1,101 words, up from 1,082, within the provisional 600–1,500 range. Captions, numerical reference and research notes are additional. The opening and ending remain verbatim. The abacus paragraph gains a short definition and a limit on inference; no second catalogue of randomness technologies is added.

Provisional agent Ada alignment: **8/10**, for this illustrated final only. Subject/truth 2, learning/agency 1, situated encounter 2, wider possibility 2, voice/desire 1. The comparison exposes a real consequence and preserves provenance. Its principal weakness is that the page still asks close reading of small numerals; the print treatment also discards the abacus's original density. Technical checks do not establish curiosity, understanding or the quality of a reading.

Next reading: can the two page images make the kept group and displaced neighbours evident before the caption explains them? If not, test one enlarged detail against these full crops. Do not silently enhance the evidence. A destination-only abacus record beside the travelled trace is a separate candidate experiment for the Gaussian question, not a result performed in this pass.

Author response to this visual comparison remains open. No commit or push was requested in this pass.

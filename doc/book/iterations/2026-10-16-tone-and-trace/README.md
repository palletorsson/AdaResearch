# Tone and trace

16 October 2026. [Author response](author-response.md) · [Three-image study](index.html) · [Chapter](illustrated.html) · [Seven-page PDF](illustrated-chapter.pdf)

Palle declines the RAND-number comparison and redirects attention to capturing the abacus blur. This pass removes the RAND before/after images from the new edition; its encounter remains in the prose and the previously requested first-ten-values reference remains. The earlier edition and evidence are preserved. This does not remove the RAND artifact or its wall photograph from the hall.

## Finding

The unfiltered Godot capture already contains gradual darkening from overlapping translucent circles. The old contour filter detects edges and discards most of that interior tone. It therefore changes a soft accumulation into rings. Capturing the blur is partly a problem of what the print filter discards, not missing movement data.

The new `treatment = 4` in `tools/book_image_filter.gdshader` maps each source pixel's weighted RGB value continuously to grey ink on off-white paper. White point 0.94; black point 0.06. `commons/book/installation_capture.gd` passes these declared parameters. There is no spatial convolution, fitted distribution, added mark or changed position. Existing treatments and default choices remain unchanged.

The abacus still uses uniform target selection. A Gaussian-looking concentration in a travelled trace, Gaussian target sampling, and a Gaussian image-processing kernel are separate operations. This trial demonstrates a tonal record of the existing marks; it does not demonstrate Gaussian sampling or apply Gaussian blur. The question of what the blur makes perceptible is retained without turning resemblance into a statistical claim.

## Comparison

`capture_tone.gd` restores the stored native abacus state from the previous comparison: 48 segments and 576 marks on each row. The state, camera and lighting remain fixed. It renders contour and continuous tone. The unfiltered capture matches the earlier raw capture pixel for pixel; the contour image also matches its predecessor. All 14 native checks pass. Receipts: [captures/capture.json](captures/capture.json).

```powershell
& 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' --path . --xr-mode off --audio-driver Dummy --no-window --rendering-method gl_compatibility --script res://doc/book/iterations/2026-10-16-tone-and-trace/capture_tone.gd -- --no-bridges
python -X utf8 doc/book/iterations/2026-10-16-tone-and-trace/publish.py
```

This is a recorded scripted state, not a visitor's experience. The three-image study keeps the raw image, the failed contour rendition and the tonal candidate together. The chapter uses one larger tonal image. The hall continues its actual-arrival capture policy; this later image is explicitly a book study rather than a replacement arrival photograph.

## Book and research loop

The prose is unchanged at 1,101 words. Room/final order, MOVE / KEEP placement, the release ending and the first 48-value pilot stay fixed. The numerical reference and large release schematic remain; the PDF now has seven pages.

The next question is what becomes legible as the discrete positions merge into density. An image may lose the identity of each mark while making repeated passage visible. That is a proposed research direction, not a demonstrated reader response. The outlined version remains useful evidence of a recording procedure that lost the intended phenomenon.

Do not impose one treatment on every artifact. Use a contour when a boundary is the subject; use continuous tone when overlap, opacity or density is the subject. A future Gaussian-source experiment should hold the recording procedure fixed while changing target selection. A future blur-kernel experiment should hold the recorded positions fixed while changing the rendering operation. Neither was performed here.

The supplied RAND legibility question is closed for this edition. Palle has not yet judged the new tonal capture. No commit or push was requested.

# Random Definition: enough of the object, room for a world

> A later [arrival-wall edition](../2026-10-16-arrival-wall/index.html) now connects actual hall captures to the book. This folder preserves the earlier staged study; its saved HTML/PDF remain that version. Use the later edition’s rebuild instructions with the current shared image manifest.

16 October 2026. The author selected these illustrations after the initial comparison. The text and room retain their existing order.

The falling page now reads the colour window's baseline sequence from 435. Each full `randf()` value is truncated after five fractional digits and zero-padded. Its first row is `49811 52985 14221 32851 99985 42826 29628 90639 90948 55830`. Each window cell uses three values for RGB; each page group uses one. The folio starts at 1 and is independently configurable through `page_number`; it neither consumes nor skips random values. It labels this generated page, not a page from RAND's historical table. A single sentence in the final makes the connection; the tutorial and PDF reference describe the conversion.

`seed-values.gd` verifies 156 conditions against actual window colours and page arrivals, including four seeds, replay, five-digit truncation, leading zeros, separate folios, held cells and the static printed mode. `sequence-regression.json` records the existing cascade, cartridge-lifecycle and shared-hall tests. The images were recaptured after an explicit reset, so the stated 15 arrivals are independent of render timing. The retained group is now `84288`.

Open [the illustrated chapter](illustrated.html) to read the three selected fragments in the full text, with short captions and no filter controls. The comparison remains at [the image study](index.html). The [reading trial](reading.html) compares the selected treatment, all outlines, all hatching, all ink and no images. Its controls work without JavaScript. Print uses the currently selected treatment.

[The typeset PDF](illustrated-chapter.pdf) contains the chapter, the verified first ten values from 435, and a separate interpretive illustration proposal. The 180 x 250 mm pages use embedded Georgia type, warm off-white paper and the three selected images. The revised proposal was made with the built-in image tool from the original drawing and updated page capture; it is not a data record. Its prompt is saved in `interpretive-plate-v2-prompt.txt`. The original drawing remains available for comparison.

To rebuild the PDF, run `python -X utf8 doc/book/iterations/2026-10-16-book-image-study/make_pdf.py --proposal doc/book/iterations/2026-10-16-book-image-study/interpretive-plate-v2.png`. The output is `output/pdf/what-chance-is-allowed-to-do-illustrated.pdf`, with a copy beside this review for download. Run `publish.py` afterward to expose its link.

## Curation

`commons/maps/Random_Definition/book_images.json` is the editable connection between artifacts, images and text. It keeps the artifact ID, exact insertion anchor, view, treatment, caption, intended relation, omissions and next reading question. `publish.py` refuses to publish if an anchor has changed or an image is missing. It does not edit `final.md` or the writing wall.

The selected edition places three fragments in the current text: the abacus after its marks, the falling number page after keeping a group, and the Geiger instrument after the explanation of the seed. It leaves MOVE / KEEP and the ending unillustrated. The author's acceptance establishes the choice; it does not establish how another reader experiences the images. The image manifest is the curation source; the main book's general rendering pipeline has not been changed.

## Rebuild

From the repository root, with Python's `markdown` package installed:

```powershell
python -X utf8 doc/book/iterations/2026-10-16-book-image-study/run.py capture
python -X utf8 doc/book/iterations/2026-10-16-book-image-study/run.py filter
python -X utf8 doc/book/iterations/2026-10-16-book-image-study/publish.py
```

`run.py` points to the local Godot 4.6 executable. It runs without XR, audio or a visible game window. The capture script loads existing artifact scenes in isolation, suppresses the HUD, stages recorded states and uses orthographic cameras. It omits the museum architecture. Fragment views hide abacus/Geiger labels; page captures remove text outline halos. These omissions affect only the capture instances.

`tools/book_image_filter.gd` and `tools/book_image_filter.gdshader` are reusable for other screenshot sets: copy the recipe and change image filenames, size, sensitivity and line width. Sobel luminance edges produce contours. Hatching tones existing dark regions; ink fills them. No new apparatus geometry, traces or motion is synthesized.

The abacus is staged at 10.35 steps per row, with 124 phase samples per row. This compares equal progress rather than simultaneous touches, and a still cannot show the four different speeds. The number page has 15 completed row arrivals, retaining row 4 / column 4 after arrival 10. These are generated digits, not RAND's historical table. The Geiger view uses its initial 435 record of 96 simulated detections. Removing colour makes its output-cell values unreadable; the proposed fragment is about intervals.

## Evidence and next reading

`final-source.md` is a byte-identical snapshot of the current chapter. `provenance.json` hashes source code, text, images, choices and saved states. `capture-receipt.json` records cameras and staged conditions. Capture and filtering logs record native execution; both finish with exit 0. This revision changes the book's seeded draw procedure and adds one connecting sentence to the manuscript; it preserves the room and chapter order.

Read one passage with Selected and None. Record which relation becomes visible, which image fixes the imagined world too strongly, and which omission hides something necessary. Revise one framing or treatment and compare again. Do not treat successful rendering as evidence of a reader's experience.

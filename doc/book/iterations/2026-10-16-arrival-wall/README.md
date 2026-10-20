# The arrival becomes a wall work and a book image

16 October 2026. The author asked for a camera to keep the installation at arrival, hang the picture in a frame, and use the same picture in the book. The abacus and Geiger keep their **actual arrival state**. The author subsequently requested that the number page **start with ten seeded rows and wait until full before capture**. Its remaining rows arrive naturally; the camera supplies no touch or extra draw.

[Hall/book comparison](index.html) · [Illustrated chapter](illustrated.html) · [Seven-page PDF](illustrated-chapter.pdf)

## Installed pilot

Open Random Definition in the desktop or VR museum, or re-enter it after reloading the changed code. The portal arrival installs three framed works: abacus and page on the east wall, Geiger on the west wall. Each is 1.6 m wide, centred at 2 m. They occupy the wall rather than the walking route. Other maps are unchanged; another map can opt in through its own `book_images.json`.

The authored camera is attached conceptually to each installation, not to the visitor's eye. It transforms its local position, target and orthographic height through the installation's actual pose. Camera and wall positions, crop, omitted casing/labels and filter settings live together in `commons/maps/Random_Definition/book_images.json`.

`commons/book/installation_capture.gd` freezes the abacus and Geiger in the arrival frame. The page is frozen separately when `book_capture_ready()` reports that all cells contain fully visible groups and no row is moving. Only display geometry is copied. The copies have no scripts, physics or interactions; live screen textures are resolved to still pixels. The artifacts continue running. A private rendering world isolates the installation from the surrounding room, avatar and HUD, uses fixed print lighting and applies the existing contour/ink shader. Thus the object's state and pose are actual, while framing, lighting and omissions remain authored. This is not a photograph from the visitor's viewpoint.

`commons/book/arrival_wall.gd` puts the resulting image in a frame and saves that exact PNG. Cameras and temporary rendering worlds are freed afterward. Repeated calls for the same resident hall do not replace its images. A new hall instance makes a new timestamped record. Headless validation skips photography because it has no rendered arrival.

The Geiger's nine dial marks now point radially. Their angle and the needle share the same mapping in radians: a 130-degree sweep from 0 to 12 events/second. The label now describes the rate correctly as events per second, averaged over the last two seconds.

## Ten rows now; a full page for the picture

The page placement uses `initial_rows:10`. The first hundred draws from 435 fill ten rows, oldest below newest, matching natural downward flow. The next row continues from draw 101. Reset recreates the same initial field. The folio remains independent. This changes the actual installation, not just a photograph fixture.

`capture_when:page_full` in the shared manifest makes the camera wait for all 28 rows and ten columns to fill and settle. A short message occupies the frame meanwhile. The other two pictures finish immediately, and the visitor can continue moving. Per-image timestamps and `after_arrival_ms` document the different moments. At the authored 0.4 rows/second, the remaining eighteen rows take about 46 seconds. A suspended/paused page waits until it resumes; photography never accelerates it.

The original near-empty arrival remains under `captures/2026-10-16T12-02-42-13492554`. Its first row existed but was too faint for the original ink threshold. `numeral-filters.json` and `verify_numerals.py` document recovering those real strokes with local contrast, without inventing marks in blank rows. The final choice is to wait for the page to fill and use the original ink treatment. The old source and comparison PNGs remain available as evidence of what that filter lost.

The selected full-page capture is identified in `curation.json`. No group was held for it. The earlier staged `84288` image and eight-page study remain historical alternatives. The reader critique is saved as `reader-critique-eight-page.md`; its broader editorial suggestions are not silently applied to the chapter. The seven-page PDF still contains the unchanged literary text and the verified seed-value reference, with captions and image notes updated to the new capture moment.

## Keeping another visit for the book

Every capture is stored in `user://book_walls/Random_Definition/<timestamp>/`, containing three filtered PNGs, three unfiltered source PNGs and `capture.json`. On this Windows installation that is beneath:

```text
C:/Users/palle/AppData/Roaming/Godot/app_userdata/Ada Research Zero One/book_walls/Random_Definition/
```

The receipt records source and camera transforms, camera height, filter, omissions, actual source state and PNG hashes. Select a visit explicitly; a new visit does not silently rewrite the book. From the repository root:

```powershell
python -X utf8 doc/book/iterations/2026-10-16-arrival-wall/adopt.py 'ABSOLUTE/PATH/TO/capture.json'
python -X utf8 doc/book/iterations/2026-10-16-book-image-study/make_pdf.py --edition-directory doc/book/iterations/2026-10-16-arrival-wall
python -X utf8 doc/book/iterations/2026-10-16-arrival-wall/publish.py
```

`adopt.py` verifies the map, artifact IDs and image hashes, then copies the packet unchanged into a timestamped `captures` directory. It refuses to replace an existing kept packet with different bytes. It updates the shared image manifest and arrival captions. `publish.py` checks image hashes and prose anchors and takes a byte-identical `final-source.md` snapshot. The PDF builder uses those same PNG files; the raster is embedded losslessly. The wall and book therefore share the image, while the room's lighting and the printed/displayed page may change its apparent tone.

The comparison's `*-on-wall.png` files are contextual evidence from the selected museum probe, not the book images themselves. If selecting another visit, also refresh these contextual views before using the comparison as evidence for that visit.

## Verification

```powershell
python -X utf8 doc/book/iterations/2026-10-16-arrival-wall/run.py
python -X utf8 tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --output-tag arrival-wall --probe doc/book/iterations/2026-10-16-arrival-wall/museum_probe.gd
```

- 158 native checks pass: ten-row initialization and chronological continuation, replay, waiting without advancing the page, waiting for the final row to settle, independent arrival photographs, radial marks, common needle scale, unchanged page RNG/state and abacus state, saved checksums, wall texture pixels equal decoded PNG pixels, cameras released, repeated calls preserve the capture. The fixture explicitly advances rows as test input; production waits for normal processing. It checks that waiting and capturing consume no extra values.
- 16 real-hall checks pass: ten-row opening, naturally filled page, delayed capture condition, automatic arrival trigger, all three sources found, frames backed by actual walls, matching hashes, released rendering worlds and retained evidence cameras. The probe stops the museum's desktop camera guard only after the arrival capture, to take contextual screenshots; production photography never switches the visitor camera.
- No script/engine errors in the successful native or museum runs. The receipt separates waiting time from rendering time. Neither is a frame-rate or VR performance measurement.
- All seven PDF pages rendered and visually inspected; captions and the ten seed values were checked in extracted text. Original chapter bytes are unchanged. The linked HTML images load.

Headset comfort, frame readability, capture cost on Quest and the literary effect of the full page remain human/device checks. A successful photograph does not establish that the illustration helps a reader. Compare the new arrival edition with the previous staged one: does waiting become legible, or does the image need a different crop?

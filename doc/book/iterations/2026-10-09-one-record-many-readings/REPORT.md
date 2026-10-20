# One record, different readings

The saved picture stays on the left. On the right, its values become a colour field, then a field of heights. Change how the bytes are interpreted and some of those heights drop below zero. The source has not changed.

This is **P4 in the uncertainty plan**, installed in the existing camera instrument in **Shaders → Patterns**. It follows the sampling comparison in Randomness while keeping the museum's original sequence order.

<figure><a href="museum/record-3.png"><img src="museum/record-3.png" alt="Inside the museum, a retained colour grid sits beside columns extending above and below a pink zero plane." /></a><figcaption>The known byte fixture under the signed interpretation. The same eight-bit value can acquire a different numerical meaning.</figcaption></figure>

## Try it in the museum

Press **READ RECORD** on the camera console. **SAVE 8 × 8** takes one centre sample from each region of the current camera frame. Sixty-four RGB samples become 192 bytes. The saved record and its checksum stay visible while you turn EFFECT through five readings. **FIXTURE** supplies known values for comparison; **CHANNEL** chooses R, G or B for height; STRENGTH changes the height scale.

| Reading | What changes | What stays |
|---|---|---|
| RGB colour | Bytes are read as colour | The saved 192 bytes |
| BGR colour | The receiver exchanges red and blue | Source values and addresses |
| Unsigned height | Selected byte, 0–255, maps to a positive height | Source and selected channel |
| Signed height | Values 128–255 are interpreted as −128 through −1 | The same bits |
| Invalid layout | The requested 7 × 8 layout is refused | The original 8 × 8 record |

<div class="pair"><figure><a href="museum/record-2.png"><img src="museum/record-2.png" alt="Unsigned interpretation produces a rising field of coloured columns." /></a><figcaption>Unsigned: a byte divided by 255 sets height.</figcaption></figure><figure><a href="museum/record-3.png"><img src="museum/record-3.png" alt="The same record read as signed values creates columns above and below zero." /></a><figcaption>Signed: reinterpret the byte, then divide by 128. Both scales are declared.</figcaption></figure></div>

The fixture uses red values 0, 1, 63, 127, 128, 192, 254 and 255 across its columns. That makes the boundary visible: 127 and 128 are neighbours in the unsigned reading; in the signed reading they straddle a jump from 127 to −128. A witness follows one cell from its stored byte to its interpreted value and height.

The apparent break has an exact mechanism. It is not camera depth, a broken graphics card or an accidental engine error. The reading changed. The fifth mode makes a different distinction: an RGB record of 192 bytes cannot satisfy this strict 168-byte layout. The program reports that mismatch without reading outside its buffer or destroying the source.

<figure><a href="museum/record-4.png"><img src="museum/record-4.png" alt="The receiver refuses a 7 by 8 RGB layout while the saved source remains on the left." /></a><figcaption>A failed contract remains inspectable. It does not make the record disappear.</figcaption></figure>

## The existing apparatus grows

<figure><a href="museum/record-console.png"><img src="museum/record-console.png" alt="The existing two-dial console now has a pink Read Record button and grouped rectangular save, channel, fixture and reset controls." /></a><figcaption>One extra button opens the record study. The same dials and nearby controls serve it; the twenty previous FORM and PIXELS treatments remain accessible.</figcaption></figure>

<div class="pair"><figure><a href="before/museum/visitor.png"><img src="before/museum/visitor.png" alt="The original camera apparatus before the record-reading extension." /></a><figcaption>Before: camera, reference, altered image and console.</figcaption></figure><figure><a href="museum/record-camera.png"><img src="museum/record-camera.png" alt="A coarse saved record sampled from the real in-game camera appears in the same apparatus." /></a><figcaption>After: a record from the actual museum camera. The brighter images above use the explicitly selected test fixture.</figcaption></figure></div>

<figure><a href="museum/overhead.png"><img src="museum/overhead.png" alt="Overhead view of the Patterns hall, with the camera bay and the existing pattern works in place." /></a><figcaption>The existing bay and room arrangement remain. This adds a reading to one artifact, rather than another object to the circulation route.</figcaption></figure>

## What this adds to the book

Arrays supplied addresses; Colour supplied components; the camera supplied a record. This return makes their agreement explicit: width, row order, channel order, signedness and scale all participate in what the values become.

The [optional tutorial](tutorial.html) prints the complete production data core and an executable assertion script. The camera, XRTools controls and museum display are declared supplied parts. An independent exercise changes a copied byte and compares that data edit with changing only the receiver. The [new reflective passage](reflection.html) follows the pleasure and uncertainty of watching one image acquire incompatible bodies. Both additions are in the hall's canonical texts: [tutorial.md](hall-tutorial.md) and [final.md](hall-final.md); the pattern lesson remains first.

## Evidence and limits

**37 core checks and 37 checks on the printed code pass**, together with the printed example's eight assertions. Tests cover centre sampling, RGB order, reversible exchange, signed boundaries, height values, invalid layouts, copying and source identity. Two deliberately broken versions are rejected: treating 128 as positive and ignoring the requested layout width.

**121 native museum checks pass**, including 82 checks inherited from the camera/controls study. Actual desktop pointer input selects the readings, saves the camera and restores the previous bank. A simulated XRTools hand turns and releases the strength dial. Source bytes remain unchanged through every reading, camera movement and reset; only SAVE or FIXTURE replaces them. Existing supported approach and exit routes are checked again.

These checks do not establish headset comfort, Quest performance or independent learner understanding. The hall still reports its earlier authored-entry obstruction and safe spawn fallback, alongside existing renderer/shutdown warnings. The final run has no script or parse errors. The new surface geometry has no collider and does not change the room it pictures.

[Core and rejected-fault receipts](validation/results.json) · [Printed-code receipts](validation/printed-results.json) · [Native museum receipt](museum/report.json) · [Source snapshots and hashes](source-manifest.json) · [Validation scope](validation.json)

**Next in this cross-sequence strand:** feedback—a measured response returns to change an action. The saved record now gives us a concrete way to distinguish the latest reading from an earlier one.

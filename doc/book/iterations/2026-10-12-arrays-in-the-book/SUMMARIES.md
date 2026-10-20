# Arrays — five lesson summaries

12 October 2026. Current canonical tutorials; revisable teaching decisions.

## Array — A slot kept

Return to Trans_Pre's familiar collectible BoxMesh and make independent copies. Keep object references separate from occupancy. Collect one cube without shifting the remaining addresses, then open the row into a plane stored as grid_data[x][z]. Change spacing and turn a chosen instance; predict which record each edit affects. The complete reviewed draft provides construction, sensors and display. Carry the fixed-slot record and cube construction into a volume.

**Short AI:** Pre cube → row → XZ plane. Separate values/references. Collect one; keep slots. Vary spacing/one turn. Carry occupancy + construction.

**Carry:** A cube construction, collection callback and fixed-slot XZ record. Copy the chosen plane's readout explicitly for the next lesson.

**Next:** Tutorial_3D copies that plane into the bottom layer with explicit YZX conversion.

## Tutorial_3D — Another index

Continue the cube and sensor from Array. Copy the earlier four-by-four readout into an explicit plane value, then initialize a volume whose bottom layer retains that gap. Display XYZ while storing YZX; show the conversion before adding more layers. Collect an unequal-index address and preserve neighbouring cells and the source plane. Flight remains supplied by the existing enclosure. Choose another address and spacing. Carry a precise relation between coordinate, storage and placement.

**Short AI:** Copy XZ record by hand → bottom YZX layer. Upper layers full. Display XYZ; store YZX. Same cube/sensor. Unequal-index collection; source retained. Flight supplied.

**Carry:** Displayed coordinates and nested storage have declared conventions; placement and reach are separate responsibilities.

**Next:** Floor returns to a plane and makes an address choose an orientation instead of occupancy.

## Tutorial_Tiling_Floor — An address chooses a turn

Compare two four-by-four images of the same diagonal motif. The right sample uses an address-to-quarter-turn function; the left repeats one orientation. Predict a row, change one term of the rule, then isolate an exception and enlarge the field. The complete small image renderer is supplied in print, keeping focus on the rule. Save the chosen right-hand result as a PNG for Walls. Carry both the editable recipe and its distinct saved result.

**Short AI:** 4x4: same motif, address → quarter-turn via %4. Compare fixed/rule. One exception; expand. Printed raster support. Save actual PNG for Walls. Zero turn != absence.

**Carry:** The rule remains editable in code; user://ada_array_pattern.png carries the chosen pixels, not their explanation.

**Next:** Walls loads the saved image in the same project; no replacement generator is used.

## Tutorial_Tiling_Walls — The result has another surface

Load the actual PNG saved by Floor and assign it to a three-metre panel whose backing and collision are created in code. Compare a newly saved image at the same pose with a new panel angle using the same image. The first changes appearance; the second also reorients the boundary. A missing file produces an instruction, not an invented substitute. Choose another viewing angle and approach. Carry the distinction between saved input, visible receiver and physical access.

**Short AI:** Load Floor PNG. Quad image + Box backing/collision under one body. Change file ≠ turn receiver. Same-project handoff, no live sync. Missing file visible. Hinged exit supplied.

**Carry:** Stored values acquire an appearance through a reader; moving that reader need not change the record.

**Next:** Disco keeps places fixed and adds timed readers of a phase and a score.

## Tutorial_Disco — A reader returns

Begin with both clocks held. Single-step a sixteen-cell checker by changing phase, then single-step an eight-entry Boolean score with a visible playhead and a supplied click. Let each reader run independently. Preserve elapsed remainder, wrap addresses with modulo and declare the long-frame policy: advance past missed steps, sound only the final visit. Move one event without changing tempo, then change tempo without changing the score. Carry stable addresses, independently owned materials and the distinction between stored decisions and their readers into Colour.

**Short AI:** Two held clocks. Phase → checker; Boolean score → playhead/click. Separate play/step. Keep time remainder. Stall: skip missed sounds, retain final index. No footstep recording. Carry record/reader into Colour.

**Carry:** An arrangement keeps addresses while values and ways of reading them vary; material values can be assigned per instance in Colour.

**Next:** Colour continues familiar geometry and arrays, with material values and their perceptual relationships as the subject.


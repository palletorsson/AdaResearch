# The surface includes you

The point gains another role. In the previous room it carried STEP; here its held position becomes an input. The floor and wall still share one field, but losing support and losing the capacity to help a neighbour happen at different thresholds.

## Changes per track

- **Tutorial:** complete `presence.gd` and the unchanged PointBody. Build a 5 × 16 fractional field, use a three-dimensional point position, and separate colour, support and recovery. The later three-cell comparison returns to SYNC versus SCAN. The student predicts a height change, then edits one starting value from .495 to .49.
- **Reflection:** preserve the encounter with a surface that responds to your presence. Add the carried point's new role. Move three implementation blocks into prose so the reflection can keep its own pace.
- **Interaction:** a small black point sits beside the desk. Hold it near a cell and trigger: this selects HAND and steps once. Release parks the point and withdraws the input; subsequent steps can recover through healthy neighbours. VISITOR, PROBE and NONE remain available.
- **Room:** preserve the bridge, frieze, basin and ramps. Level the rear gallery and space all six secondary works around the onward passage. Fit the chair, crossway and tree at 0.12, 0.25 and 0.35 scale; lift the crossway 0.8 m as a small relief. All seven authored works remain. Remove the extra entrance gate and place portals on the thresholds. The embedded chair uses the museum's lighting.
- **Plan:** update only this hall's paragraph, prerequisites, transfer task and evidence. Its review decision remains draft.

## The teaching line

The opening created a next row. The second hall gave state a duration. The third kept a history and used it in different bodies. The fourth separated a travelling pattern from a fixed address and its lamp. **Now a position outside the cells can alter their next state.**

The tabletop lesson uses the same transition law as the installed bridge. Its view is one-fifth scale, so the code explicitly converts the point's world position back to simulation units. Its input is the held point's centre. The large bridge can instead read the visitor's body origin. Neither mode measures weight. The miniature has a lower tray; the walkable installation has a basin and recovery ramps.

The strongest distinction is tangible: health 0.3 still supplies support, but contributes nothing to neighbour recovery. A value greater than 0.5 contributes; below 0.2 support ends. The wall shares each floor tile's material while keeping a solid backing. One number can have several different consequences.

## Evidence

**32 learner checks and 37 museum checks pass in native Godot 4.6.** The learner blocks are extracted from `tutorial.md`, matched byte-for-byte with the maintained files, and executed. Tests cover the radius including height, axial neighbours and boundary, strict thresholds, clamping, independent buffers and update order. Across inputs and schedules, 160 updates match the installed solver. The .49 transfer works; deliberately ignoring height or accidentally scanning in SYNC produces the wrong result and is detected.

Native checks also cover material sharing, physical support, actual XRTools pickup/action/release with supplied controller poses, keyboard controls and the 30-second cap. In the museum, equal PROBE and HAND coordinates yield equal fields. A supplied CharacterBody loses support, lands in the basin and climbs the exit ramp. Four routes have **255 samples** of layer-1 capsule clearance and level floor. Portal approaches pass. Camera checks are included in the museum total.

The first parity fixture omitted the installed study-coordinate flag; it was corrected. The first museum run caught a duplicate chair configuration function and a path through the console foot. The function now uses the existing hook and the route goes around the desk. Those failed receipts remain in the review directory. Final successful logs contain no SCRIPT ERROR or Parse Error. Existing engine warnings remain.

The bridge solver is byte-identical to this pass's baseline. No physical headset, Quest performance, complete portal transfer, independent student assessment or secondary-artifact interaction audit is claimed. The native views retain existing blank wall frames. Secondary animations are captured at different moments. The learner model is mounted temporarily for its photograph, not added as another permanent exhibit.

## Read and inspect

- [Tutorial left · reflection right](parallel.html)
- [Complete tutorial](tutorial.html) · [Complete reflection](final.html)
- [Tutorial Markdown](tutorial.md) · [Reflection Markdown](final.md)
- [Exact presence.gd](printed/presence.gd) · [carried point_body.gd](printed/point_body.gd)
- [Learner assertions](checks.json) · [Museum assertions and routes](museum/report.json)
- [Learner log](engine.log) · [Museum log](museum/engine.log)
- [Scoped changes](changes.diff) · [Review ZIP](ca-presence-review.zip)

Next: **CA_SoftRules**—what can a neighbourhood offer beyond a count above a threshold?

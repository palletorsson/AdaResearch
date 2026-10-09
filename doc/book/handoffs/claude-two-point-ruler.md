# Claude handoff: make the two-point ruler usable

Status: prepared for delegation; not dispatched or implemented.

## Outcome

In Point_Lines, let a visitor bring the half-metre ruler to the pale block and deliberately take a measurement. The reading describes the pale block truthfully; the blue block changes size. Let the visitor discover that consequence by comparing the objects. Support the project's existing desktop and VR interaction paths.

This closes a verified gap: `two_point_ruler.gd` builds a static display and exposes `measure()`, but its scene has only a scripted Node3D and no player interaction wiring. The existing probe calls `measure()` directly, so it does not prove that a visitor can use the artifact.

## Start here

- `commons/artifacts/two_point_ruler/two_point_ruler.gd`
- `commons/artifacts/two_point_ruler/two_point_ruler.tscn`
- `commons/testing/probe_two_point_ruler.gd`
- `commons/primitives/line/grabbable_line.gd` and its scene: inspect the existing held-object conventions before implementing.
- `commons/primitives/point/grab_sphere_point_snap.gd` and its scene: another existing interaction reference.
- `commons/maps/Point_Lines/map_data.json`: inspect placement, transforms and grid configuration.
- `commons/maps/Point_Lines/final.md`: the current ruler passage honestly identifies the missing interaction.

## Implementation scope

1. Make the ruler a usable instrument through existing input conventions. Prefer a held ruler with a valid measurement zone at the pale block and one explicit activation per reading. Keep both blocks in place when carrying the ruler.
2. Reject activation away from the subject. Holding an input or resting in the zone must not repeatedly shrink the witness each frame. Leaving and returning must allow another deliberate measurement.
3. Preserve the subject's geometry. Verify the reported width against geometry and the placed transform; do not call a hard-coded value truthful under an untested scaling assumption. Keep the fixed unit clear, and document the supported transform/configuration contract.
4. Change only this instance's witness. Keep it visible, bounded and grounded as it scales. Prevent overlapping tweens from producing inconsistent results under rapid input.
5. Make the action discoverable with a short instruction grounded in the implemented controls. Do not tell the visitor the entire consequence before they try it. Do not assume they cannot see both objects simultaneously, and do not force their gaze away.
6. Preserve existing room placements, book tags, primary roles and necklace order. Avoid shared input-system changes unless a narrowly demonstrated dependency requires them.
7. Add a proposed replacement for only the ruler's book passage to your handoff report. Leave `final.md` to our ongoing hall-by-hall editorial work.

## Evidence required for review

- Test the actual packed scene and the interaction callback path, not only a direct `measure()` call.
- Show that invalid activation leaves reading/state unchanged; one valid activation produces one measurement; holding input does not repeat it; a second deliberate action works.
- Verify the subject stays unchanged, the readout matches its supported physical width, and only the witness changes.
- Verify bounds after repeated activations, rapid-input behavior, and isolation between two artifact instances.
- Exercise the placed configuration and translated/rotated instances. Explicitly document scale support and any restrictions.
- Use elapsed time or tween completion for animation checks, not a fixed count of headless frames. The existing probe's frame-count waits are not reliable evidence of elapsed animation time.
- Provide a short desktop walkthrough, files changed, exact probe commands and results, and a separate headset checklist. Mark anything not actually tested as unverified.

Use Godot with `--headless --xr-mode off` for automated probes. Do not claim headset validation from these probes. Preserve existing unrelated work in the checkout; do not reset, stash or reformat the whole repository.

## Codex review after delivery

We will inspect the diff, independently rerun the probes, trace both input paths into the measurement action, and compare the resulting behavior with the proposed prose. Acceptance requires a usable encounter, not merely a successful direct method call. We will keep physical headset acceptance separate.

## Subsequent independent tasks

### Book/primary consistency audit

Build a read-only report across the current curriculum spine comparing ordered `final.md` tags with expanded primary groups and actual room inventory. Reuse `tools/final_tags.py`, `tools/artifact_roles.py` and the configured generated-artifact resolver; inspect existing audit tools before adding another. Distinguish missing placement, book artifact outside primary, primary without a passage, and order mismatch. Notes are not artifacts; groups expand in saved order; a book tag alone cannot fabricate a placement. Point_One and Point_Lines should pass. Test injected mismatches and the configured FoldingPast entrance case. Do not automatically promote artifacts or rewrite manuscripts.

### Lost-structure restoration candidates

Use Git history to compare pre-museum map structures with current rooms, starting with the primitives sequence. Use Primitives_Melencolia as the known restoration reference. Produce candidates with exact historical commits, affected cells/platforms, current configuration and source-backed explanation of what was lost. Distinguish intentional removal from uncertain disappearance. Propose one reversible restoration with before/after evidence; do not bulk-restore old maps or replace current arrangements.

# Colour — the same parts

The first Colour tutorial returns to five familiar parts. Keep geometry fixed; use a palette and five indices to change their grouping. One complete program creates its own meshes and independent materials in the existing museum host.

216 native Godot checks passed; three printed exercise variants and one independent-choice example tested; 5 deliberate faults rejected.

## The small progression

1. One ochre: every part selects palette entry 0.
2. Group the blocks in red and the round forms in blue.
3. Change the red palette entry: the assigned group changes together.
4. Alternate the assignments, then compose another grouping.

The student changes values and assignments separately. No new mesh factory, animation, automatic shape classifier or input system is required. The supplied fixed construction reproduces the opening column’s five forms and dimensions. The rest of the gallery remains available to the reflective text.

## Read and review

- [Tutorial beside final.md](parallel.html)
- [Tutorial alone](tutorial.html) · [tutorial.md](tutorial.md)
- [Reflection alone](final.html) · [final.md](final.md)
- [Complete program](lesson.gd) · [Code and tests](colour-review.zip)
- [Verification](verification.json) · [Native checks](normal-report.json)

## What was inherited and what changes

| Bring | Change | Keep | Carry |
|---|---|---|---|
| BoxMesh, SphereMesh, transforms, arrays and instance references | RGB values and palette indices assigned to independent materials | Five parts, their order, geometry, pose and material roughness | A palette and a function that writes chosen values into known surfaces |

The existing companion was a tour of many exhibits, with a later landscape source edit. This draft chooses the opening colour assignment as the executable lesson. The historical shape association and broader compositions remain in the unchanged reflection.

## Evidence and limits

Checks extract the exact printed program, instantiate it in Godot, test the three specified edits and an independent composition, then reassign colours on the same live objects. They check reference/material independence, copied values, unchanged geometry/transforms, a translated/rotated host, and repeated application. Deliberate broken versions test whether the assertions detect shared materials, wrong assignments, movement during repainting and rebuilding meshes. Test results establish these program behaviours; they do not establish a student’s understanding or perceptual equivalence between differently lit surfaces.

The photographs below are earlier real museum captures from 23 September. The comic is an imagined illustration of the wider reflective route. Neither is a new render of this learner program.

## Status

Review draft. Canonical tutorial.md, final.md, museum logic, placement, sequence order and plan acceptance are preserved. The four later Array tutorials still need their own executable pass. Next Colour lesson: keep the material and change the light.

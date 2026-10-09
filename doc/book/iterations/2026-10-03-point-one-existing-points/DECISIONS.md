# Point One — use the points already in the corridor

Palle asked to continue with the next hall and reiterated that its artifacts already exist. The canonical tutorial now follows the shared `commons/primitives/point/point_condition.gd` used by `point_absent`, `point_visible`, `point_solid` and `point_pedestal`. No artifacts, scenes or alternate teaching room were added. The old starter remains a separate study, not the default route.

The first lesson is the difference between a position, a visible surface and a physical boundary. Its source uses `const CENTRE`, so the text explains a constant accurately rather than inventing a different variable in a duplicate script. `var` is introduced through the existing resource and node references. Station selection is named as supplied; the learner edits the relevant values without first implementing all the branches.

The small visible and solid variants share `CENTRE` and `RADIUS`. The pedestal overrides those values. The collision assignment serves both solid and pedestal: doubling it changes both boundaries, and the tutorial says so. The student's own collision body contributes to the stopping distance. The light switch is an encounter at the end; programming its rig is deferred. Coordinates retains grabbing and reference frames.

The excerpts identify source already present. The larger collision excerpt explicitly omits naming and collision-layer assignments for reading; students are told to make only specified edits. The critical `final.md`, museum map and source script are byte-for-byte unchanged from this pass's baseline. `technical.md` and the existing course handover now point to this lesson.

An independent source reader checked the draft against the script and placement chain. 38 native checks passed using the real museum and its CharacterBody3D. The player crossed absence and visible mesh, met the solid, and stopped earlier after invisible boundary growth. Height, shared radius and pedestal exceptions were checked. The existing button event removed the sun without removing collision. The test substituted edited scripts in memory at original placements; it retained their renderer masks because anonymous test scripts have no source path for the light's normal discovery. Nothing was saved into production artifacts.

The images are native views inside the museum. Physical headset use and beginner comprehension remain untested. The engine log also contains the existing unresolved audio-bus UID `uid://rwex60pqapc` and material warnings; passing these focused checks does not certify the whole project. Review links and anchors are checked programmatically; browser visual inspection was not performed.

Next: read this one lesson, then follow the existing held point into Point Coordinates.

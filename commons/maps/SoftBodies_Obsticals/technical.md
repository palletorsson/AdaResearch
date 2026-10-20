# Pressure — source and learner implementation

Registry scene `algorithms/softbodies/advanced_concepts/breathing_room.tscn` runs `breathing_room_scene.gd`. With `#lesson:true`, `_process` advances `_time` by `breath_speed * delta` and sets both walls' pressure to `(sin(_time)+1)*.5*breath_amplitude`. The separate `breathing_room.gd` generator is not the script on the placed scene.

The authored BoxMesh is 1 × 4 × 7 m, subdivided 2/6/6. Centres are x −2.3185759 and 3.5541987; y 1.9500841 and 1.9902142. There are 19 and 16 explicitly listed pinned indices, rather than every perimeter vertex. Default/second stiffness .5/.02; shrinking factors −.2/.02. The lesson pressure driver overwrites their initial .08/.105 coefficients. The map selects flesh material. These unequal starting settings prevent treating the pair as an identical-material comparison.

Desk: AMPLITUDE .5/.15/.9, RATE 1/.4/1.8; HOLD DRIVE disables only the root frame callback; STIFFNESS writes .5/.2/.8 to both walls; RESET PHASE writes zero then applies the command at that phase. Neither operation rebuilds the walls. The first click advances each preset index.

Learner files: `doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Obsticals/`. The closed panel is a BoxMesh .16 × 1.2 × 1.8 with perimeter pins prepared in `_init`. Two matching instances receive one pressure command at physics cadence. Same PointBody as Carusell; trigger holds/resumes phase. No scene-path mesh dependencies. Full code is printed in tutorial.md. Independent amplitude edit .5→.25 changes input range, not rate or geometry. The model is temporarily mounted for captures, not a new permanent exhibit.

API: https://docs.godotengine.org/en/4.6/classes/class_softbody3d.html . Test receipts and actual museum captures are in the matching pressure review. Physical headset/Quest and independent student understanding remain untested.

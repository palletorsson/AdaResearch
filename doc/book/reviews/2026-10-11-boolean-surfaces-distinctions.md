# Boolean surfaces: a surface, a rule, a passage

11 October 2026. Palle approved the selected Boolean clarifications and the correction to Works’ account of the first hall. This pass changes prose in three finals and one tutorial, plus two matching descriptions in the sequence record. It preserves the sequence order, maps, museum plan, runtime scripts, printed code and study markers.

## What changed and why

| Text | Change | Evidence / purpose |
| --- | --- | --- |
| Verbs · final | Name the visible boundary, membership rule and contact rule. | The placed demonstrations represent solid regions without enabling collision. The existing account of faceted rendering versus analytic sampling remains. |
| Gallery · final | Invite the reader to check a published claim against its specimens. | Six families have four configured variants each. Their order is default-first, not necessarily the order of decreasing separation. |
| Gallery · tutorial | Explain the raw-offset branch, named multipliers, explicit-offset priority and two different invalid-value cases. | `csg_intersection_demo.gd`, `_read_metadata_overrides`, `_cut_offset` and `_consensus_scale`. These implementation details stay out of the final. |
| Works · final | Qualify an inhabitable interior by this body’s shape, contact and clearance. | The placed burrow uses level cylindrical cutters, section off and collision enabled for rock. A region can have an interior without being a passage this player can use. |
| Works · final | Correct the return to Verbs: the recurring primitives vary in size, offset and colour. | The union, intersection and difference scripts use different defaults; their scenes do not override them into one controlled pair. |
| Sequence record | Remove the same “only the word changes” claim from the content line and first group rationale. | Match the current Verbs text and actual demonstrations; order and artifact lists remain unchanged. |

The connectedness/continuous-motion distinction is already in Verbs’ tutorial. The Gallery already explains prescribed stripes versus a live depth contest. Works already distinguishes omission from subtraction and includes symmetric difference. These are retained without duplicating their explanations.

Not restored: “the sphere has no radius” (the scripts explicitly assign one); “none of the verbs can remove anything” (subtraction excludes a represented region); “a mechanism that cannot fail” (prescribed alternation is not an infallibility guarantee); and a universal claim that Boolean vocabulary cannot express becoming (operands can move and operations can compose). The two coincident fills do not make the stripe band a live renderer diagnostic.

## Check against the existing halls

| Hall | Map and museum placements | Relevant configuration |
| --- | ---: | --- |
| Boolean_Verbs | 4 | Intersection has `forfeit:numeral`; the three demonstrations retain their individual defaults. |
| Boolean_Gallery | 25 | Twenty-four specimens in six four-value rows, plus `film_boolean_overlap`. Intersection rows explicitly select broad, unanimous, narrow and token. |
| Boolean_Works | 13 | Compose workbench `algebra:complete`; burrow `carver_profile:level` and `section:off`; film and the two art application studies remain placed. |

All map tokens and their configuration match `commons/data/museum/em_plan.json`. All 42 placements resolve through the current modular registry to existing scenes. The museum code has not been changed.

Implementation evidence:

- `algorithms/boolean_surfaces/csg_union_demo.gd`, `csg_intersection_demo.gd`, `csg_difference_demo.gd` and their scenes: different operand defaults; each sphere receives `sphere_radius`. The intersection’s analytic sample uses that radius separately from the faceted CSG surface. Godot also documents [radius and tessellation as separate properties](https://docs.godotengine.org/en/stable/classes/class_csgsphere3d.html).
- `csg_intersection_demo.gd`: `_cut_offset()` returns the raw vector when explicitly configured, when consensus is broad, or when an internal value is unknown. Named multipliers are 0.0, 1.9 and 2.6. `_read_metadata_overrides()` accepts only known consensus names, so invalid map input preserves the existing selection rather than resetting it.
- `algorithms/booleansurfaces/coincident_face/coincident_face.gd`: `i % 2` prescribes amber/blue alternation; the inverted configuration gives every stripe blue. Coplanar fills and drawn stripes are distinct constructions.
- `commons/artifacts/boolean_burrow/boolean_burrow.gd`: level-profile cylinders, shared seeded centres and `stock.use_collision = walkable and spoil == "rock"`. The map selects the level profile with the section cut off.
- `algorithms/boolean_surfaces/csg_compose_workbench.gd`: complete algebra includes `(A ∪ B) − (A ∩ B)`. The corresponding map flag is present.

## Verification

This is a source/text check, not a fresh Godot or headset run. No new claim about a tested body passage or a runnable tutorial reconstruction is made. Map/plan parity and scene resolution passed for all three halls. All six texts retain their code fences and comment markers. Verbs’ and Works’ tutorials are byte-identical to the start of this task. Only the two specified descriptions changed in the sequence JSON; it parses successfully. Scoped whitespace checks passed.

Printed code blocks preserved across the six texts: 13.

## Exact before/after receipt

### commons/maps/Boolean_Verbs/final.md

````diff
--- before/commons/maps/Boolean_Verbs/final.md
+++ after/commons/maps/Boolean_Verbs/final.md
@@ -11 +11 @@
-There are several agreements inside the word *solid*. These small exhibits have not enabled collision. You can pass through a surface that your eye has already accepted. The region still has an inside and an outside in the calculation; it has not acquired the power to stop your body. Keep that difference with you when the objects become architecture.
+A visible boundary, a rule for membership and a rule for contact are three different agreements inside the word *solid*. These small exhibits have not enabled collision. You can pass through a surface that your eye has already accepted. The region still has an inside and an outside in the calculation; it has not acquired the power to stop your body. Keep that difference with you when the objects become architecture.
````

### commons/maps/Boolean_Gallery/final.md

````diff
--- before/commons/maps/Boolean_Gallery/final.md
+++ after/commons/maps/Boolean_Gallery/final.md
@@ -5 +5 @@
-Each row changes a named setting within one artifact. Some settings alter the shape. Others alter how much of its making becomes visible. These are authored possibilities: somebody chose the values, gave them names and decided which one would meet us first.
+Each row changes a named setting within one artifact. Some settings alter the shape. Others alter how much of its making becomes visible. These are authored possibilities: somebody chose the values, gave them names and decided which one would meet us first. The row puts a published claim beside its specimens. You can check what the names promise against what changes between them.
````

### commons/maps/Boolean_Gallery/tutorial.md

````diff
--- before/commons/maps/Boolean_Gallery/tutorial.md
+++ after/commons/maps/Boolean_Gallery/tutorial.md
@@ -15 +15,5 @@
-At intersection, compare the survivors and the expectations their names bring. At subtraction_suite, follow the cutter growing relative to its body. At coincident_face, separate a picture of z-fighting from an actual depth contest. Finish with removal_room: the same survivors can be accompanied by no trace, a ghost of the removed volume, or a smaller scar.
+At intersection, compare the survivors and the expectations their names bring. Read `_cut_offset()` in `algorithms/boolean_surfaces/csg_intersection_demo.gd`: `broad` returns the stored `sphere_offset` unchanged; `unanimous`, `narrow` and `token` multiply it by 0.0, 1.9 and 2.6 respectively. An explicitly configured offset takes precedence over those names. Predict the offsets before comparing the four specimens.
+
+There are two different fallback cases. An unrecognised internal `consensus` value makes `_cut_offset()` return the stored offset. An invalid `consensus` value supplied through map configuration is ignored by `_read_metadata_overrides()`, leaving the current selection unchanged. It is not a reset to `broad`.
+
+At subtraction_suite, follow the cutter growing relative to its body. At coincident_face, separate a picture of z-fighting from an actual depth contest. Finish with removal_room: the same survivors can be accompanied by no trace, a ghost of the removed volume, or a smaller scar.
````

### commons/maps/Boolean_Works/final.md

````diff
--- before/commons/maps/Boolean_Works/final.md
+++ after/commons/maps/Boolean_Works/final.md
@@ -98 +98 @@
-The shape of the cut and the rule for contact have to work together. A collider can enforce an opening too small to enter. A generous hollow without collision can make the wall beside it equally passable. Here a body's dimensions have become part of what the room needs to get right.
+The shape of the cut and the rule for contact have to work together. A collider can enforce an opening too small to enter. A generous hollow without collision can make the wall beside it equally passable. A geometric interior becomes somewhere this body can inhabit only when shape, contact and clearance work together.
@@ -130 +130 @@
-These are three different arrangements of ovoids, using union, intersection and subtraction. Their colours and proportions differ too. The first hall held the operands still to compare the verbs. Here those verbs have become choices in making a body we might want to stay with.
+These are three different arrangements of ovoids, using union, intersection and subtraction. Their colours and proportions differ too. The first hall introduced the verbs through recurring boxes and spheres whose sizes, offsets and colours also varied. Here those verbs have become choices in making a body we might want to stay with.
````

### commons/maps/sequences/boolean_surfaces.json

````diff
--- before/commons/maps/sequences/boolean_surfaces.json
+++ after/commons/maps/sequences/boolean_surfaces.json
@@ -27 +27 @@
-        "Boolean_Verbs: A ∪ B, A ∩ B, A − B on one pair of operands — only the word changes",
+        "Boolean_Verbs: A ∪ B, A ∩ B, A − B through recurring boxes and spheres; distinguish what the operation retains from changes in size, offset and colour",
@@ -53 +53 @@
-          "rationale": "The three operators on one pair of operands, in three bays separated by sills rather than walls, so each verb stays visible from the next. the_argument_of_solids closes the hall by rebuilding all three at bench scale."
+          "rationale": "The three operators on recurring box-and-sphere operands whose sizes and offsets vary, in three bays separated by sills rather than walls, so each verb stays visible from the next. the_argument_of_solids closes the hall by rebuilding all three at bench scale."
````

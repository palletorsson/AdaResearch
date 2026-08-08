# The bench and the world reach differently

**Status:** APPROVED and LANDED 2026-08-08. See the discipline checklist below, now ticked with measurements.
**Found:** 2026-08-08, breath cycle.
**Gate:** `python tools/check_dna_declarations.py` — 924 declared axes, 911 verified, **0 broken, exit 0**.
The finding is in the trailer the gate prints *after* it declares itself green.

---

## The claim

Fourteen tokens declare eighteen DNA axes whose implementing script sits on a **child** of the
`.tscn`, not on the root. The DNA sweep reaches those axes. A map token cannot. So these axes are
measured, published, and proven to bite — in a place no player can ever stand.

Nothing is broken today. Every one of the 184 placements uses the default. The trap is armed, not
sprung: the first person to write `line#readout:gradation` into a map gets silence, a log line that
looks like housekeeping, and a default-valued artifact.

## Why the two paths disagree

The sweep searches for the node that owns the property:

```gdscript
# commons/testing/capture_config_sweep.gd:1307
func _holder_of(node: Node, key: String) -> Node:
	if key in node:
		return node
	var queue: Array[Node] = [node]
	while not queue.is_empty():
		var n: Node = queue.pop_front()
		for c in n.get_children():
			if key in c:
				return c
			queue.append(c)
	return null
```

The map path does not. It sets metadata on the root and calls the method on the root:

```gdscript
# commons/grid/GridInteractablesComponent.gd:1655-1679  (abridged)
for config_key in config_data.keys():
	artifact_object.set_meta("config_%s" % sanitized_key, config_value)   # ROOT
if artifact_object.has_method("apply_grid_config"):                       # ROOT
	artifact_object.call_deferred("apply_grid_config", config_data.duplicate(true))
elif artifact_object.has_method("configure"):
	artifact_object.call_deferred("configure", config_data.duplicate(true))
else:
	print("  → No configuration method found, using metadata only")       # <- silently lands here
```

`artifact_object` is the instantiated scene root. When the root is a bare `Node3D`:

1. `_coerce_to_export_type` finds no matching export and passes the string through untouched;
2. `config_*` metadata is written to a root that nothing reads;
3. `has_method("apply_grid_config")` is **false**, so the `else` branch prints a line indistinguishable
   from the normal case of a config-less artifact;
4. the artifact builds at its default and the map looks fine.

Every stage green. The axis never happened.

## The fourteen

Verified independently of the gate — a second parser walked each `.tscn`, found the first node
without a `parent=` attribute, and checked whether a `script =` line falls inside that block.
All fourteen are true positives; there are no false positives in this batch.

| token | axes | root node (scriptless) | script lives on | placements | maps |
|---|---|---|---|---|---|
| `branching_growth_algorithm` | aftermath | `BranchingGrowthAlgorithm` | `BranchingGrowthAlgorithm` | 59 | 43 |
| `line` | readout | `Line` | `lineContainer` | 47 | 41 |
| `GaussianBlurCircle` | sitter | `GaussianBlurCircle` | `MeshInstance3D` | 20 | 19 |
| `space_colonization_algorithm` | aftermath | `SpaceColonizationAlgorithm` | `SpaceColonizationAlgorithm` | 11 | 7 |
| `example_2_5_fluid_resistance_vr` | mass_spread, medium | `Example_2_5_FluidResistance` | `FishTank`, `FluidResistanceDemo` | 10 | 6 |
| `GaussianPaintSplatter` | refusal | `GaussianPaintSplatter` | `PaintSplatter` | 10 | 9 |
| `GeneticProgramming` | alphabet, muster | `GeneticProgramming` | `GeneticProgramming` | 8 | 8 |
| `bernini_columns` | colonnade | `BerniniScene` | `BerniniColumns` | 6 | 6 |
| `example_2_3_gravity_scaled_by_mass_vr` | evidence, mass_spread | `Example_2_3_GravityScaled` | `FishTank`, `GravityScaledByMass` | 5 | 5 |
| `ball_painting_demo` | priming | `BallPaintingDemoV2` | `PaperDrawSurface`, `PaintBalls` | 4 | 4 |
| `drawing_paper` | priming | `DrawingPaper` | `PaperDrawSurface`, `GrabPen_1` | 1 | 1 |
| `genetic_programming` | alphabet, muster | `GeneticProgramming` | `GeneticProgramming` | 1 | 1 |
| `jelly_variants` | assay | `JellyVariants` | `JellyCube`, `BouncyBall`, … | 1 | 1 |
| `line_interface` | readout | `Line` | `lineContainer` | 1 | 1 |

**184 placements across 152 maps. Zero carry a `#config`.**

The bite reports for these are real measurements of real geometry — the sweep did apply the values:

- `line.readout` — **BITES**, peak 3.61% (`numeral` → `gradation` moves 20,021 px)
- `line_interface.readout` — **BITES**, peak 4.76%
- `bernini_columns.colonnade` — **BITES**, peak 6.48% (`grid` → `aisle` moves 34,718 px)

So this is not the familiar disease. The breath log's five previous entries were all *a green verdict
that was secretly about the harness*. This one is a green verdict that is **true on the bench and
false in the world**, because the bench looks harder than the world does.

## Proposed fix — one gated forward in the grid

Give `_apply_artifact_config` the same reach the sweep already has, **gated on the root not handling
it**. An artifact whose root carries the script takes a byte-identical path to today.

```gdscript
# after the existing root checks, replace the bare `else:` branch
else:
	var holder: Node = _config_holder(artifact_object, config_data)
	if holder != null:
		for config_key in config_data.keys():
			var sk := config_key.replace(":", "_").replace(",", "_").replace(" ", "_").replace("-", "_")
			if sk.is_valid_identifier():
				holder.set_meta("config_%s" % sk, config_data[config_key])
		if holder.has_method("apply_grid_config"):
			holder.call_deferred("apply_grid_config", config_data.duplicate(true))
		else:
			holder.call_deferred("configure", config_data.duplicate(true))
		print("  → Forwarded config to child '%s' (root carries no handler)" % holder.name)
	else:
		print("  → No configuration method found, using metadata only")

## Breadth-first, mirroring capture_config_sweep._holder_of — first descendant that
## either handles the call or declares one of the keys as a property. Returns null
## when nothing claims it, which preserves today's behaviour exactly.
func _config_holder(root: Node, config_data: Dictionary) -> Node:
	var queue: Array[Node] = [root]
	while not queue.is_empty():
		var n: Node = queue.pop_front()
		for c in n.get_children():
			if c.has_method("apply_grid_config") or c.has_method("configure"):
				return c
			for k in config_data.keys():
				if String(k) in c:
					return c
			queue.append(c)
	return null
```

Alternatives considered and rejected:

- **Move each script to its `.tscn` root.** Fourteen scenes, each with node paths and transforms
  that assume the current parenting (`lineContainer` holds the two grab spheres and the transform).
  Fourteen chances to break a live artifact with 184 placements, to fix a call site that is wrong
  in exactly one place.
- **Do nothing, document the constraint.** The declaration stays a lie the corpus tells itself,
  and the gate keeps printing it under a green headline where it has evidently been ignored.

## Discipline this change owes (per CLAUDE.md)

- [x] **Additive and gated.** The forward lives in the existing `else`, which an artifact whose
      root handles config never reaches. Satisfied by construction, not by care.
- [x] **Headless compile check** — `check_compile.gd` on GridInteractablesComponent.gd, exit 0.
- [x] **Live map-load test.** `Artist_Readymades` — the one map in the corpus that places
      NON-DEFAULT config values (six `request_note` tokens), so it exercises exactly the
      root-handled path this change gates around. Renders, subject 27.4% iso / 23.2% front.
- [x] **Negative test — IT BITES.** Two scratch maps placed `line#readout:numeral` and
      `line#readout:gradation`, captured at four angles and diffed:

      | angle | px moved | max delta |
      |---|---|---|
      | iso | 16,719 | 199 |
      | front | 15,024 | 195 |
      | left | 17,917 | 156 |
      | top | 4,422 | 88 |
      | **total** | **54,082** | |

      The published bench sweep put this pair at ~20,021 px for one angle; the map now moves
      the same order of magnitude. Zero would have meant the forward never landed. The scratch
      maps were deleted after measuring — a corpus of 2,049 maps does not need two more, and
      the numbers are the artefact worth keeping.
- [x] **Pathfinder unaffected.** No grid geometry, no structure layer, no cell semantics were
      touched — only what happens to `config_data` after an artifact is already instantiated.
      Stated rather than assumed, as asked.

## Then close the loop

Once this lands, `check_dna_declarations.py` should stop printing the fourteen as a trailer under a
green headline. Either it gates on them, or it renames the block to what it would then be: a note
about scene shape, not about reachability.

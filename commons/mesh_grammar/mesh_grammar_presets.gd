## MeshGrammarPresets — the twenty named recipes of the mesh grammar, in ONE place.
##
## These were dictionaries inside mesh_grammar_demo.gd and nowhere else, so the only
## thing that could build "Extruded Spire" was the demo gallery. The registry carried
## twenty-one names (mesh_grammar_extruded_spire ... mesh_grammar_blooming_bulge) that
## all pointed at the bare MeshGrammarNode scene, and the node had no table to look a
## name up in — so every one of them, placed in a map, built the seed icosahedron.
##
## Now there is one table and one rule builder, and two readers:
##   mesh_grammar_demo.gd   lays all twenty out as a gallery (order, names, colours
##                          and layout unchanged — it iterates specs() in order);
##   mesh_grammar_node.gd   builds ONE of them when its `preset` export names an id.
## Both go through MeshGrammarNode.apply_spec() and rules_for() below. A second
## implementation of one rule drifts; this is the only one for these recipes.
##
## The id is the registry name without its `mesh_grammar_` prefix.
##
## Gate: commons/testing/probe_mesh_grammar_presets.gd
##
## NO class_name, on purpose. Readers preload this file into a const (as they do
## GridMaterialFactory), so nothing depends on the global class cache having been
## rebuilt — a headless run and a headset export see the table the moment the
## file exists.
extends RefCounted

## The seed radius every recipe below was tuned at. The rule parameters are in
## METRES (extrude distance 0.3, branch length 0.2, bead size 0.02 ...), so they
## only mean what they were written to mean at this size. It was a literal in the
## demo's _build_specimen; it lives here so the node builds at the same size.
const SEED_SCALE: float = 0.35

## ExtrudeFaceOp skips a face smaller than its `min_area`, 0.01 m2 unless a rule
## says otherwise. The largest face of the sphere seed at SEED_SCALE is 0.0062 m2
## and the smallest, at the poles, about 0.0016 m2: under the default every extrude
## on a sphere seed did nothing, and `budding`, `riveted` and `ca_growth` built
## untouched spheres. The three rules that extrude a sphere face name this
## threshold; the op's default, which other callers rely on, is not changed.
const SPHERE_MIN_AREA: float = 0.0005

## Preloaded: the op has no class_name (see its header).
const CellInsetOp = preload("res://commons/mesh_grammar/operations/cell_inset_op.gd")


## The recipes, in the demo's order. Four per row; the row headers are the demo's
## `chapter` axis (topology, organic, compound, decoration, bridge) and it reads the
## grouping off the index, so ORDER IS LOAD-BEARING — append, never insert.
##
## A fresh array of fresh dictionaries on every call: the ops keep a reference to
## their params dictionary, so two bodies must never share one.
static func specs() -> Array[Dictionary]:
	var all_specs: Array[Dictionary] = []

	# --- Row 1: Basic operations ---

	# 1. Plain icosahedron (seed reference)
	all_specs.append({
		"id": "seed",
		"name": "Seed Icosahedron",
		"seed": "icosahedron",
		"color": Color(0.5, 0.6, 0.7),
		"rules": [],
		"generations": 0
	})

	# 2. Extruded spire
	all_specs.append({
		"id": "extruded_spire",
		"name": "Extruded Spire",
		"seed": "icosahedron",
		"color": Color(0.9, 0.5, 0.2),
		"rules": [
			{"op": "extrude", "selector": "up", "params": {"distance": 0.3, "scale": 0.7}},
			{"op": "extrude", "selector": "tag:extruded_top", "params": {"distance": 0.25, "scale": 0.6}},
		],
		"generations": 1
	})

	# 3. Inset pattern
	all_specs.append({
		"id": "inset_pattern",
		"name": "Inset Pattern",
		"seed": "icosahedron",
		"color": Color(0.3, 0.8, 0.5),
		"rules": [
			{"op": "inset", "selector": "all", "params": {"amount": 0.35}},
		],
		"generations": 1
	})

	# 4. Subdivided sphere
	all_specs.append({
		"id": "subdivided",
		"name": "Subdivided",
		"seed": "icosahedron",
		"color": Color(0.4, 0.5, 0.9),
		"rules": [
			{"op": "split", "selector": "all", "params": {"pattern": "midpoint"}},
		],
		"generations": 1
	})

	# --- Row 2: Organic forms ---

	# 5. Nodule sphere (ceramic photo 1)
	all_specs.append({
		"id": "nodule_sphere",
		"name": "Nodule Sphere",
		"seed": "sphere",
		"color": Color(0.6, 0.65, 0.8),
		"rules": [
			{"op": "bulge", "selector": "random:0.12", "params": {"height": 0.15, "ring_depth": 2, "smoothing": 0.5}},
		],
		"generations": 1
	})

	# 6. Coral fingers (ceramic photos 2-3)
	all_specs.append({
		"id": "coral_fingers",
		"name": "Coral Fingers",
		"seed": "sphere",
		"color": Color(0.55, 0.65, 0.85),
		"rules": [
			{"op": "tube_branch", "selector": "up_random", "params": {"length": 0.3, "curve_amount": 0.05, "segments": 5, "rings": 3}},
		],
		"generations": 1
	})

	# 7. Crumpled vessel (ceramic photo 4)
	all_specs.append({
		"id": "crumpled",
		"name": "Crumpled Form",
		"seed": "sphere",
		"color": Color(0.9, 0.85, 0.7),
		"rules": [
			{"op": "noise", "selector": "up", "params": {"amplitude": 0.15, "frequency": 3.0, "direction": "normal"}},
		],
		"generations": 1
	})

	# 8. Budding sphere with openings (ceramic photo 5)
	all_specs.append({
		"id": "budding",
		"name": "Budding Sphere",
		"seed": "sphere",
		"color": Color(0.85, 0.8, 0.75),
		"rules": [
			{"op": "extrude", "selector": "random:0.1", "params": {"distance": 0.2, "scale": 0.8, "min_area": SPHERE_MIN_AREA}},
			{"op": "delete", "selector": "tag:extruded_top", "params": {}},
		],
		"generations": 1
	})

	# --- Row 3: Compound forms ---

	# 9. Multi-generation coral
	all_specs.append({
		"id": "branching_coral",
		"name": "Branching Coral",
		"seed": "icosahedron",
		"color": Color(0.9, 0.4, 0.5),
		"rules": [
			{"op": "tube_branch", "selector": "up_random", "params": {"length": 0.2, "curve_amount": 0.08, "segments": 5, "rings": 3, "tip_tag": "branch_tip"}},
			{"op": "tube_branch", "selector": "tag:branch_tip", "params": {"length": 0.15, "curve_amount": 0.1, "segments": 4, "rings": 2, "tip_tag": "branch_tip"}},
		],
		"generations": 2
	})

	# 10. Inset + extrude (architectural)
	all_specs.append({
		"id": "inset_towers",
		"name": "Inset Towers",
		"seed": "cube",
		"color": Color(0.8, 0.6, 0.3),
		"rules": [
			{"op": "inset", "selector": "up", "params": {"amount": 0.3}},
			{"op": "extrude", "selector": "tag:inset", "params": {"distance": 0.4, "scale": 0.7}},
		],
		"generations": 1
	})

	# 11. Split + bulge (organic detail)
	all_specs.append({
		"id": "detailed_bulge",
		"name": "Detailed Bulge",
		"seed": "icosahedron",
		"color": Color(0.7, 0.5, 0.8),
		"rules": [
			{"op": "split", "selector": "all", "params": {"pattern": "midpoint"}},
			{"op": "bulge", "selector": "random:0.08", "params": {"height": 0.1, "ring_depth": 1, "smoothing": 0.6}},
		],
		"generations": 1
	})

	# 12. Full noise crumple
	all_specs.append({
		"id": "noise_sculpture",
		"name": "Noise Sculpture",
		"seed": "sphere",
		"color": Color(0.3, 0.7, 0.6),
		"rules": [
			{"op": "noise", "selector": "all", "params": {"amplitude": 0.2, "frequency": 2.0, "direction": "radial", "noise_type": "cellular"}},
		],
		"generations": 1
	})

	# --- Row 4: Decoration operations ---

	# 13. Petal flower — petals radiating from upward faces
	all_specs.append({
		"id": "petal_flower",
		"name": "Petal Flower",
		"seed": "icosahedron",
		"color": Color(0.95, 0.5, 0.6),
		"rules": [
			{"op": "petal_splay", "selector": "up", "params": {"count": 6, "length": 0.25, "width": 0.12, "curl": 0.4, "tilt": 0.4, "segments": 5}},
		],
		"generations": 1
	})

	# 14. Scale armor — overlapping pointed scales
	all_specs.append({
		"id": "scale_armor",
		"name": "Scale Armor",
		"seed": "sphere",
		"color": Color(0.4, 0.7, 0.45),
		"rules": [
			{"op": "split", "selector": "all", "params": {"pattern": "midpoint"}},
			{"op": "scale_tile", "selector": "all", "params": {"scale_length": 0.08, "scale_width": 0.06, "tilt_degrees": 35.0, "pointed": true}},
		],
		"generations": 1
	})

	# 15. Riveted sphere — edge beads along boundary
	all_specs.append({
		"id": "riveted",
		"name": "Riveted Sphere",
		"seed": "sphere",
		"color": Color(0.8, 0.65, 0.4),
		"rules": [
			{"op": "extrude", "selector": "random:0.15", "params": {"distance": 0.15, "scale": 0.75, "min_area": SPHERE_MIN_AREA}},
			{"op": "delete", "selector": "tag:extruded_top", "params": {}},
			{"op": "edge_decorate", "selector": "all", "params": {"shape": "sphere", "size": 0.02, "spacing": 0.06, "boundary_only": true, "segments": 3}},
		],
		"generations": 1
	})

	# 16. Scatter nodules — scattered sub-meshes across surface
	all_specs.append({
		"id": "barnacle",
		"name": "Barnacle Sphere",
		"seed": "sphere",
		"color": Color(0.6, 0.75, 0.8),
		"rules": [
			{"op": "scatter", "selector": "all", "params": {"shape": "sphere", "density": 0.3, "min_size": 0.015, "max_size": 0.04}},
		],
		"generations": 1
	})

	# --- Row 5: Bridge operations + compound forms ---

	# 17. L-system tree — fractal branching from upward faces
	all_specs.append({
		"id": "lsystem_tree",
		"name": "L-System Tree",
		"seed": "icosahedron",
		"color": Color(0.45, 0.7, 0.35),
		"rules": [
			{"op": "lsystem_branch", "selector": "up", "params": {"preset": "bush", "lsystem_generations": 2, "step_length": 0.1, "start_radius": 0.02, "angle_degrees": 25.0, "max_branches": 30}},
		],
		"generations": 1
	})

	# 18. CA growth — cellular automata tags faces, then extrude alive
	all_specs.append({
		"id": "ca_growth",
		"name": "CA Growth",
		"seed": "sphere",
		"color": Color(0.7, 0.4, 0.8),
		"rules": [
			{"op": "cellular", "selector": "all", "params": {"rule": "coral", "ca_steps": 4, "initial_density": 0.25, "seed_value": 42}},
			{"op": "extrude", "selector": "tag:ca_alive", "params": {"distance": 0.1, "scale": 0.85, "min_area": SPHERE_MIN_AREA}},
		],
		"generations": 1
	})

	# 19. Spike scatter — spiky sub-meshes across surface
	all_specs.append({
		"id": "spike_ball",
		"name": "Spike Ball",
		"seed": "icosahedron",
		"color": Color(0.85, 0.35, 0.3),
		"rules": [
			{"op": "scatter", "selector": "all", "params": {"shape": "spike", "density": 0.6, "min_size": 0.06, "max_size": 0.12, "align_to_normal": true}},
		],
		"generations": 1
	})

	# 20. Petal rosette on bulge — compound decoration
	all_specs.append({
		"id": "blooming_bulge",
		"name": "Blooming Bulge",
		"seed": "sphere",
		"color": Color(0.9, 0.75, 0.5),
		"rules": [
			{"op": "bulge", "selector": "random:0.08", "params": {"height": 0.12, "ring_depth": 1, "smoothing": 0.5}},
			{"op": "petal_splay", "selector": "tag:bulge_tip", "params": {"count": 5, "length": 0.15, "width": 0.08, "curl": 0.5, "tilt": 0.5, "segments": 4}},
		],
		"generations": 1
	})

	return all_specs


## Every id, in recipe order.
static func ids() -> PackedStringArray:
	var out: PackedStringArray = []
	for s in specs():
		out.append(String(s.get("id", "")))
	return out


## The recipe for an id, or an EMPTY dictionary when nothing carries that id. The
## caller decides what an unknown name means; this never substitutes a default.
static func spec(id: String) -> Dictionary:
	var want: String = id.strip_edges().to_lower()
	if want == "":
		return {}
	for s in specs():
		if String(s.get("id", "")) == want:
			return s
	return {}


static func has_preset(id: String) -> bool:
	return not spec(id).is_empty()


## The rules a recipe names, as live MeshRule objects, in recipe order. A rule whose
## op is not known is dropped, exactly as the demo dropped it.
static func rules_for(recipe: Dictionary) -> Array[MeshRule]:
	var out: Array[MeshRule] = []
	var rule_defs: Array = recipe.get("rules", [])
	for rdef in rule_defs:
		var rule: MeshRule = create_rule(rdef)
		if rule:
			out.append(rule)
	return out


## One {"op", "selector", "params"} dictionary -> one MeshRule. Moved here from
## mesh_grammar_demo.gd unchanged.
static func create_rule(rdef: Dictionary) -> MeshRule:
	var op: String = rdef.get("op", "")
	var selector_str: String = rdef.get("selector", "all")
	var rule_params: Dictionary = rdef.get("params", {})

	var sel := parse_selector(selector_str)

	match op:
		# --- Topology ops ---
		"extrude":
			return ExtrudeFaceOp.new(sel, rule_params)
		"bulge":
			return BulgeOp.new(sel, rule_params)
		"tube_branch":
			return TubeBranchOp.new(sel, rule_params)
		"inset":
			return InsetFaceOp.new(sel, rule_params)
		"cell_inset":
			return CellInsetOp.new(sel, rule_params)
		"split":
			return SplitFaceOp.new(sel, rule_params)
		"delete":
			return DeleteFaceOp.new(sel, rule_params)
		"noise":
			return NoiseDisplaceOp.new(sel, rule_params)
		"scale":
			return ScaleFaceOp.new(sel, rule_params)
		"rotate":
			return RotateFaceOp.new(sel, rule_params)
		"scallop":
			return ScallopEdgeOp.new(sel, rule_params)
		# --- Decoration ops ---
		"petal_splay":
			return PetalSplayOp.new(sel, rule_params)
		"scale_tile":
			return ScaleTileOp.new(sel, rule_params)
		"edge_decorate":
			return EdgeDecorateOp.new(sel, rule_params)
		"scatter":
			return SurfaceScatterOp.new(sel, rule_params)
		# --- Bridge ops ---
		"lsystem_branch":
			return LSystemBranchOp.new(sel, rule_params)
		"cellular":
			return CellularSurfaceOp.new(sel, rule_params)
	return null


## A selector word -> a MeshSelector. Moved here from mesh_grammar_demo.gd unchanged.
static func parse_selector(s: String) -> MeshSelector:
	match s:
		"all":
			return MeshSelector.all_faces()
		"up":
			return MeshSelector.by_normal_direction(Vector3.UP, 60.0)
		"down":
			return MeshSelector.by_normal_direction(Vector3.DOWN, 60.0)
		"up_random":
			return MeshSelector.by_normal_direction(Vector3.UP, 60.0).and_also(
				MeshSelector.by_random(0.25))
		"boundary":
			return MeshSelector.by_boundary()
		_:
			# Parse "random:0.3", "tag:something", "depth:0-3"
			if s.begins_with("random:"):
				var prob := float(s.substr(7))
				return MeshSelector.by_random(prob)
			elif s.begins_with("tag:"):
				var tag := s.substr(4)
				return MeshSelector.by_tag(tag)
			elif s.begins_with("depth:"):
				var parts := s.substr(6).split("-")
				var min_d := int(parts[0])
				var max_d: int = int(parts[1]) if parts.size() > 1 else -1
				return MeshSelector.by_depth(min_d, max_d)
	return MeshSelector.all_faces()

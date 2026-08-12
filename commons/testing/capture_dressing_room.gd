extends SceneTree

## Dressing-room capture — uses the project's pre-authored
## commons/artifacts/dressing_rooms/<lookup>.json schema via
## DressingRoomBuilder. NOT a hand-rolled studio.
##
## For each artifact:
##   1. Load commons/artifacts/dressing_rooms/<lookup>.json (or the
##      default 1×1 fallback if absent)
##   2. Build the staging via DressingRoomBuilder — footing tiles,
##      anchor plinth, artifact at offset, extras (3t/tt/el)
##   3. Resolve vitrine_grammar (registry queries → sibling artifacts
##      placed at fractional scale)
##   4. Run 4-shot smart-frame orbit driven by AABB
##   5. Write PNGs + manifest including the dressing-room data for
##      the page to display + edit
##
## The dressing-room JSON is the canonical recipe — same one the
## map composer uses. AI improvements feed back into the same file.
##
## Config JSON shape:
##   {
##     "artifact":  "pompeii_mosaic_floor",      # required
##     "scene":     "res://...",                  # optional explicit scene path
##                                                # if absent, looks up registry
##     "shots":     [...],                        # optional override of default set
##     "wait":      2.5
##   }
##
## Output:
##   - PNGs at user://dressing_room/<id>_<shot>.png
##   - JSON manifest at user://dressing_room/<id>.json with:
##     { aabb: {center, size}, size_class, best_shot_set, shots: [...] }

const REGISTRY_DIR := "res://commons/artifacts/registry"
const DRESSING_ROOMS_DIR := "res://commons/artifacts/dressing_rooms"
const Builder := preload("res://commons/artifacts/catalog/DressingRoomBuilder.gd")

var _config_path: String = ""
var _out_id: String = "self"
## How the last measurement was reached — mesh count, what was skipped and why,
## signage and effects apart from body. Merged into the manifest beside the
## number, so provenance ships with it.
var _last_measure: Dictionary = {}
var _wait := 2.5


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var s := String(raw).strip_edges()
		if s.begins_with("--config="): _config_path = s.substr(9)
		elif s.begins_with("--id="):     _out_id = s.substr(5)
		elif s.begins_with("--wait="):   _wait = float(s.substr(7))
	call_deferred("_run")


func _run() -> void:
	if _config_path.is_empty():
		push_error("--config required"); quit(1); return
	var f := FileAccess.open(_config_path, FileAccess.READ)
	if f == null: push_error("config missing"); quit(1); return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK: push_error("bad json"); quit(1); return
	var cfg = json.data
	if not (cfg is Dictionary): push_error("config not dict"); quit(1); return

	var artifact_lookup: String = String(cfg.get("artifact", ""))
	if artifact_lookup.is_empty():
		push_error("artifact required"); quit(1); return
	var explicit_scene: String = String(cfg.get("scene", ""))
	var wait_total: float = float(cfg.get("wait", _wait))

	var root := get_root()
	var studio: String = String(cfg.get("studio", "neutral"))

	# === Studio setup (neutral, controlled) =========================
	# Soft sky + warm key + cool fill + ground-bounce. No biome, no fog.
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.025, 0.035, 0.055) if studio == "museum" else Color(0.93, 0.92, 0.90)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_color = Color(0.32, 0.42, 0.58) if studio == "museum" else Color(0.85, 0.86, 0.92)
	e.ambient_light_energy = 0.42 if studio == "museum" else 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	root.add_child(env)
	if root is Window:
		(root as Window).world_3d.environment = e
	if studio == "museum":
		RenderingServer.set_default_clear_color(Color(0.025, 0.035, 0.055))

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(35), 0)
	sun.light_energy = 0.95 if studio == "museum" else 1.4
	sun.shadow_enabled = true
	root.add_child(sun)
	if studio == "museum":
		var fill := OmniLight3D.new()
		fill.position = Vector3(-3.0, 2.6, 2.5)
		fill.light_color = Color(0.32, 0.68, 1.0)
		fill.light_energy = 1.15
		fill.omni_range = 9.0
		root.add_child(fill)

	# A separate floor plane gives the staged footprint a readable ground
	# surface instead of letting it dissolve into the studio background.
	# Keep it outside RoomRoot so it never contributes to artifact/room bounds.
	if studio == "museum":
		var studio_floor := MeshInstance3D.new()
		studio_floor.name = "StudioFloor"
		var floor_mesh := PlaneMesh.new()
		floor_mesh.size = Vector2(28.0, 28.0)
		studio_floor.mesh = floor_mesh
		studio_floor.position = Vector3(0.0, -0.025, 0.0)
		var floor_material := StandardMaterial3D.new()
		floor_material.albedo_color = Color(0.12, 0.135, 0.16)
		floor_material.roughness = 0.96
		studio_floor.material_override = floor_material
		root.add_child(studio_floor)

	# === Load the artifact's pre-authored dressing room =============
	# Canonical source: commons/artifacts/dressing_rooms/<lookup>.json
	# This is the same JSON the map composer uses. We render it faithfully.
	var room_data: Variant = Builder.load_dressing_room(artifact_lookup)
	if room_data == null:
		# No file → use the schema's documented default (1×1 floor).
		room_data = {
			"lookup_name": artifact_lookup,
			"footprint": [1, 1, 1],
			"rotations": ["0", "90", "180", "270"],
			"approach": "south",
			"exit": "north",
			"footing": {"anchor": [0, 0], "tiles": [[1]]},
			"extras": [],
			"artifact_offset": [0.0, 0.0, 0.0],
		}
	var room_dict: Dictionary = room_data
	# Allow caller override of explicit scene path (rare).
	if not explicit_scene.is_empty():
		room_dict["_scene_override"] = explicit_scene

	# Pre-load the registry so the builder can resolve the artifact scene.
	var registry := _load_full_registry()
	var registry_lookup := func(name: String) -> Dictionary:
		var entry = registry.get(name, null)
		if entry == null:
			return {}
		return entry

	# Build the dressing room (footing + anchor plinth + artifact + extras).
	# `staged: true` renders the raised footing as its real station prop
	# (Element Catalog) instead of blockout tiles — the web's prop view.
	var staged_mode: bool = bool(cfg.get("staged", false))
	var room_node := Builder.build(room_dict, 0, registry_lookup, staged_mode)
	root.add_child(room_node)

	# Resolve vitrine_grammar (registry-query siblings around the centre).
	# These are placed by hand here — the existing builder doesn't yet.
	_apply_vitrine_grammar(room_node, room_dict, registry, registry_lookup)

	# Hide the anchor marker — it's a magenta debug rectangle the
	# inspector uses to show "the artifact sits here". Not for clean
	# captures.
	var anchor_marker := room_node.get_node_or_null("AnchorMarker")
	if anchor_marker is Node3D:
		(anchor_marker as Node3D).visible = false

	# Wait for the artifact to build its meshes.
	var t := 0.0
	while t < wait_total:
		await create_timer(0.05).timeout
		t += 0.05

	# === Measure + classify =========================================
	# AABB measured from the artifact subtree only (not footing tiles).
	var artifact_root := room_node.get_node_or_null("Artifact")
	# Seat the artifact ON its surface (match the game's auto-ground) — the
	# builder puts its ORIGIN at the anchor top, so one whose origin isn't at
	# its base sinks into the footing (a board under a raised table). Do this
	# BEFORE measuring so the framing reflects the seated position.
	if artifact_root is Node3D:
		var seat_aabb := _measure_artifact_aabb(artifact_root)
		if seat_aabb.size != Vector3.ZERO:
			var seat_d: float = (artifact_root as Node3D).global_position.y - seat_aabb.position.y
			if absf(seat_d) > 0.01:
				(artifact_root as Node3D).global_position.y += seat_d
	var aabb: AABB
	if artifact_root != null:
		aabb = _measure_artifact_aabb(artifact_root)
	else:
		aabb = AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
	var size_class := _classify(aabb)
	var best_shots := _shots_for_class(size_class, aabb)

	# Question mode — different question, different shot set.
	# "visual_integrity" replaces the 4 orbit shots with 8 high-zoom
	# corner macros so we can inspect tessellation, seams, and edges
	# at fragment level.
	var question: String = String(cfg.get("question", "default"))
	if question == "visual_integrity":
		best_shots = _corner_macros_for(aabb)
	elif question == "staging":
		# Posture review — frame the WHOLE dressing room (footing + artifact)
		# so you can read HOW the thing is staged (plinth / table / platform /
		# float / floor), not just the artifact. The default shot sets tight-
		# frame the artifact and crop the footing to a sliver, which hides the
		# posture. Measured over the room node (not just the Artifact subtree).
		best_shots = _staging_shots_for(_measure_room_aabb(room_node))
	# Allow the caller to override shots entirely.
	var override_shots: Array = cfg.get("shots", [])
	var shot_list: Array = override_shots if override_shots.size() > 0 else best_shots

	print("dressing_room: %s class=%s aabb_size=%s shots=%d"
		% [artifact_lookup, size_class, str(aabb.size), shot_list.size()])

	# === Capture rig ================================================
	var rig_scene := load("res://commons/testing/capture_rig.tscn") as PackedScene
	if rig_scene == null:
		_write_failure({"error": "capture_rig.tscn missing"}); quit(1); return
	var rig := rig_scene.instantiate() as Node3D
	root.add_child(rig)
	if rig.has_method("set_clean_render"):
		rig.set_clean_render()

	# === Loop shots =================================================
	var shot_results: Array = []
	for sh in shot_list:
		var sh_name: String = String(sh.get("name", "shot"))
		var sh_pos: Vector3
		var sh_look: Vector3
		var sh_fov: float = float(sh.get("fov", 50.0))
		var padding: float = float(sh.get("padding", 1.15))
		# direction-based smart frame (preferred)
		if sh.has("direction"):
			var dir := _to_vec3(sh.get("direction", [4, 2, 4]))
			if dir.length_squared() < 0.0001: dir = Vector3(0, 4, 4)
			dir = dir.normalized()
			var fov_rad: float = deg_to_rad(sh_fov) * 0.5
			var max_half: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z)) * 0.5
			var distance: float = max(0.5, max_half / max(0.05, tan(fov_rad)) * padding)
			var center: Vector3 = aabb.get_center()
			sh_pos = center + dir * distance
			sh_look = center
		else:
			sh_pos = _to_vec3(sh.get("position", [3, 2, 3]))
			sh_look = _to_vec3(sh.get("look_at", [0, 0, 0]))

		if rig.has_method("aim"):
			rig.aim(sh_pos, sh_look, sh_fov)
		if rig.has_method("activate"):
			rig.activate()

		await create_timer(0.25).timeout
		await process_frame
		await process_frame

		var img := root.get_texture().get_image()
		if img == null:
			shot_results.append({"name": sh_name, "error": "no image"})
			continue

		var out_path := "user://dressing_room/%s_%s.png" % [_out_id, sh_name]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_path.get_base_dir()))
		img.save_png(out_path)
		shot_results.append({
			"name": sh_name,
			"out": out_path,
			"camera": {
				"position": [sh_pos.x, sh_pos.y, sh_pos.z],
				"look_at": [sh_look.x, sh_look.y, sh_look.z],
				"fov": sh_fov,
				"direction": sh.get("direction", null),
				"padding": padding,
			}
		})
		print("dressing_room: shot %s -> %s" % [sh_name, out_path])

	# === Manifest ===================================================
	var manifest := {
		"artifact": artifact_lookup,
		"dressing_room": room_dict,
		"aabb": {
			"center": [aabb.get_center().x, aabb.get_center().y, aabb.get_center().z],
			"size":   [aabb.size.x, aabb.size.y, aabb.size.z],
		},
		# Provenance beside the number, so a fallback or a signage-inflated box
		# can be recognised as such downstream instead of looking exactly as
		# authoritative as a good measurement.
		"measurement": _last_measure.duplicate(true),
		"size_class": size_class,
		"shots": shot_results,
	}
	var manifest_path := "user://dressing_room/%s.json" % _out_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(manifest_path.get_base_dir()))
	var mf := FileAccess.open(manifest_path, FileAccess.WRITE)
	if mf:
		mf.store_string(JSON.stringify(manifest, "  "))
		mf.close()
	print("dressing_room: manifest -> %s" % manifest_path)
	quit(0)


# ── Helpers ───────────────────────────────────────────────────────

## Load the entire registry as one dict: { lookup_name: entry, ... }.
## Used both for artifact scene resolution and vitrine_grammar queries.
func _load_full_registry() -> Dictionary:
	var out: Dictionary = {}
	var d := DirAccess.open(REGISTRY_DIR)
	if d == null: return out
	d.list_dir_begin()
	var fname := d.get_next()
	while fname != "":
		if fname.ends_with(".json") and not fname.ends_with(".bak"):
			var f := FileAccess.open(REGISTRY_DIR + "/" + fname, FileAccess.READ)
			if f != null:
				var j := JSON.new()
				if j.parse(f.get_as_text()) == OK:
					var data = j.data
					if data is Dictionary and data.has("artifacts"):
						var arts = data["artifacts"]
						if arts is Dictionary:
							for k in arts.keys():
								out[k] = arts[k]
		fname = d.get_next()
	return out


## Resolve `vitrine_grammar` if present — query the registry for sibling
## artifacts and place them around the central artifact at fractional
## scale. Mirrors tools/compose_map_from_dressing_rooms.py:resolve_vitrine_grammar.
func _apply_vitrine_grammar(room_node: Node3D, room: Dictionary,
		registry: Dictionary, registry_lookup: Callable) -> void:
	var g = room.get("vitrine_grammar")
	if not (g is Dictionary): return
	var select_from := String(g.get("select_from", "all"))
	var where: Dictionary = g.get("where", {})
	var limit: int = int(g.get("limit", 4))
	var layout := String(g.get("layout", "ring"))
	var radius: float = float(g.get("radius", 0.4))
	var scale: float = float(g.get("scale", 0.35))
	var exclude_self := bool(g.get("exclude_self", true))
	var self_lookup := String(room.get("lookup_name", ""))

	var candidates: Array = []
	if select_from == "all":
		candidates = registry.keys()
	elif select_from.begins_with("registry:"):
		# All entries from a single registry file — already merged above.
		candidates = registry.keys()
	# Sequence-based queries skipped here (compose_map handles those).

	var picked: Array = []
	for lookup in candidates:
		if exclude_self and lookup == self_lookup: continue
		var entry: Dictionary = registry.get(lookup, {})
		if where.size() > 0 and not _matches_filter(entry, lookup, where): continue
		picked.append(lookup)
		if picked.size() >= limit: break

	if picked.is_empty(): return

	# Layout offsets — ring around centre.
	var offsets: Array = []
	if layout == "ring":
		var n := picked.size()
		for i in range(n):
			var theta: float = TAU * (float(i) / float(n))
			offsets.append([cos(theta) * radius, sin(theta) * radius])
	else:
		# Default: stack at origin (fallback).
		for i in range(picked.size()):
			offsets.append([0.0, 0.0])

	# Get anchor world position (where the artifact sits).
	var artifact_root := room_node.get_node_or_null("Artifact") as Node3D
	if artifact_root == null: return
	var anchor_pos: Vector3 = artifact_root.global_position
	var siblings_root := Node3D.new()
	siblings_root.name = "VitrineSiblings"
	room_node.add_child(siblings_root)
	for i in range(picked.size()):
		var lookup: String = picked[i]
		var info: Dictionary = registry.get(lookup, {})
		var scene_path: String = String(info.get("scene", ""))
		if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
			continue
		var ps := ResourceLoader.load(scene_path) as PackedScene
		if ps == null: continue
		var sib := ps.instantiate()
		siblings_root.add_child(sib)
		if sib is Node3D:
			var off: Array = offsets[i]
			(sib as Node3D).global_position = anchor_pos + Vector3(off[0], 0, off[1])
			(sib as Node3D).scale = Vector3(scale, scale, scale)


func _matches_filter(entry: Dictionary, lookup: String, where: Dictionary) -> bool:
	for key in where.keys():
		var want = where[key]
		match key:
			"name_contains":
				var hay: String = String(entry.get("name", lookup)).to_lower()
				if not hay.contains(String(want).to_lower()):
					return false
			"category":
				if String(entry.get("category", "")) != String(want):
					return false
			"tag":
				var tags = entry.get("tags", [])
				if not (tags is Array) or not (want in tags):
					return false
	return true


## The artifact's BODY, with provenance in `_last_measure`.
##
## Applies doc/plans/capture_measure_faults.md (written 2026-08-10, held back
## because a second session was inside this buffer). 25 of 72 staged
## measurements described this function rather than the artifact.
func _measure_artifact_aabb(node: Node) -> AABB:
	var combined := AABB()
	var signage := AABB()
	var effects := AABB()
	var has_any := false
	var has_signage := false
	var has_effects := false
	var skipped_invisible: int = 0
	var skipped_top_level: Array[String] = []
	var counted: int = 0
	var widest: float = 0.0
	var widest_name: String = ""

	var stack: Array = [node]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n == null: continue
		for c in n.get_children():
			stack.push_back(c)
		# Physical bounds come from geometry. Lights have large influence AABBs
		# and cameras have editor helpers; neither occupies museum floor space.
		if not (n is GeometryInstance3D): continue
		var vi := n as GeometryInstance3D
		# Hidden presentation branches (for example an analysis-only graph) are
		# not part of the active artifact body and must not inflate its contract.
		if not vi.is_visible_in_tree():
			skipped_invisible += 1
			continue
		# F3 — set_as_top_level detaches a node from its parent transform, so it
		# stays at the world origin while the seating step lifts the artifact
		# away from it. draw_dot read 3.29 m for exactly this reason.
		if vi.top_level:
			skipped_top_level.append(String(vi.name))
			continue
		var local := vi.get_aabb()
		if local.size.length_squared() < 0.0001: continue
		var world: AABB = vi.global_transform * local

		# F2 — text is authored to be READ, not occupied, and it billboards.
		# force_field's 3.645 m width was its caption.
		if vi is Label3D or vi is Sprite3D:
			signage = world if not has_signage else signage.merge(world)
			has_signage = true
			continue
		# F4 — effects are shown, not stood on.
		if vi is GPUParticles3D or vi is CPUParticles3D:
			effects = world if not has_effects else effects.merge(world)
			has_effects = true
			continue

		# F1 — no 18 m guard. It failed in both directions: scale_lines' single
		# 100 m rung was thrown away (measured 10 m, is 100 m, stands in 22 live
		# maps) while laser_measure's fifty 12 mm ticks each sailed through to
		# pool out at 50 m. And it guarded nothing: StudioFloor is parented to
		# root, not RoomRoot, so it was never in this subtree. Report the widest
		# single mesh instead, so a real giant is visible as evidence.
		var reach: float = Vector2(world.size.x, world.size.z).length()
		if reach > widest:
			widest = reach
			widest_name = String(vi.name)
		counted += 1
		if not has_any:
			combined = world
			has_any = true
		else:
			combined = combined.merge(world)

	_last_measure = {
		"counted_meshes": counted,
		"skipped_invisible": skipped_invisible,
		"skipped_top_level": skipped_top_level,
		"widest_single_mesh_m": snappedf(widest, 0.001),
		"widest_single_mesh": widest_name,
		"signage": _aabb_dict(signage) if has_signage else null,
		"effects": _aabb_dict(effects) if has_effects else null,
		"fallback": not has_any,
	}
	if not has_any:
		# F5 — a fallback that cannot say it is a fallback is indistinguishable
		# from an artifact that is genuinely one metre cubed. Two of the four
		# that returned this were load-bearing design decisions.
		_last_measure["fallback_reason"] = (
			"no visible, non-signage, non-effect GeometryInstance3D in the subtree"
			+ (" (%d hidden, %d top-level skipped)" % [skipped_invisible, skipped_top_level.size()]))
		return AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
	return combined


func _aabb_dict(a: AABB) -> Dictionary:
	return {
		"center": [snappedf(a.get_center().x, 0.001), snappedf(a.get_center().y, 0.001),
			snappedf(a.get_center().z, 0.001)],
		"size": [snappedf(a.size.x, 0.001), snappedf(a.size.y, 0.001), snappedf(a.size.z, 0.001)],
	}


## Bucket the artifact by physical size into a class that picks shots.
func _classify(aabb: AABB) -> String:
	var s := aabb.size
	# Mostly-flat (height << footprint) → surface
	if s.y < 0.4 and (s.x > 0.5 or s.z > 0.5):
		return "surface"
	# Big footprint → room/architecture
	if max(s.x, s.z) > 8.0:
		return "room"
	# Tall and narrow → pole / pillar
	if s.y > 4.0 and max(s.x, s.z) < 2.5:
		return "pole"
	# Tiny — hand-held specimen
	if max(s.x, max(s.y, s.z)) < 0.6:
		return "tiny"
	# Default: object
	return "object"


## Per-class default shot set. Each shot is direction-based so smart
## framing (AABB-aware) does the actual distance work.
func _shots_for_class(size_class: String, _aabb: AABB) -> Array:
	match size_class:
		"surface":
			# Flat things — top-down + tilted reads. The grazing shot
			# was previously too low (camera near floor level) and
			# the artifact disappeared on the horizon. New defaults
			# keep the camera at sensible elevations: ~30-50° above
			# the floor for "I'm walking past this" feel.
			return [
				{"name": "top",      "direction": [0.05, 3.0, 0.05], "fov": 55, "padding": 1.1},
				{"name": "oblique",  "direction": [1.5, 1.5, 1.5],   "fov": 50, "padding": 1.2},
				{"name": "tilted",   "direction": [1.5, 0.9, 1.5],   "fov": 50, "padding": 1.25},
				{"name": "detail",   "direction": [0.6, 0.9, 0.6],   "fov": 40, "padding": 1.05},
			]
		"room":
			# Big architecture — interior + outside-looking-in.
			return [
				{"name": "interior",  "direction": [0.3, 0.4, 0.6],   "fov": 70, "padding": 0.6},
				{"name": "exterior",  "direction": [1.5, 0.8, 1.5],   "fov": 55, "padding": 1.3},
				{"name": "top",       "direction": [0.05, 3.0, 0.05], "fov": 55, "padding": 1.2},
			]
		"pole":
			# Tall+narrow — orbit + low-angle hero.
			return [
				{"name": "front",       "direction": [0, 0.4, 1.5], "fov": 50, "padding": 1.15},
				{"name": "orbit",       "direction": [1.2, 0.5, 0.8], "fov": 50, "padding": 1.15},
				{"name": "low_hero",    "direction": [0.6, 0.15, 1.2], "fov": 55, "padding": 1.1},
				{"name": "top",         "direction": [0.05, 3.0, 0.05], "fov": 55, "padding": 1.3},
			]
		"tiny":
			# Specimen — close orbit + macro detail.
			return [
				{"name": "front",   "direction": [0, 0.4, 1.0], "fov": 40, "padding": 1.15},
				{"name": "orbit",   "direction": [0.8, 0.6, 0.8], "fov": 40, "padding": 1.15},
				{"name": "top",     "direction": [0.05, 1.5, 0.05], "fov": 45, "padding": 1.15},
				{"name": "macro",   "direction": [0.3, 0.5, 0.6], "fov": 30, "padding": 1.0},
			]
		_:  # "object" default
			return [
				{"name": "front",  "direction": [0, 0.5, 1.5], "fov": 50, "padding": 1.15},
				{"name": "orbit",  "direction": [1.0, 0.6, 1.0], "fov": 50, "padding": 1.15},
				{"name": "top",    "direction": [0.05, 2.5, 0.05], "fov": 55, "padding": 1.2},
				{"name": "back",   "direction": [-0.8, 0.6, -1.2], "fov": 50, "padding": 1.2},
			]


## Visual-integrity shots: high-zoom close-ups of each artifact AABB
## corner so the user can inspect tessellation, seams, and edges at
## fragment-level. Each macro frames a small region around the corner.
##
## Anchored to the artifact_offset-aware AABB; uses absolute camera
## positions (not direction-based smart frame) because we need very
## tight focus, not "fit the whole artifact."
func _corner_macros_for(aabb: AABB) -> Array:
	var c: Vector3 = aabb.get_center()
	var s: Vector3 = aabb.size
	var max_extent: float = max(s.x, max(s.y, s.z))
	# Macro radius — frame a region of ~25% of the artifact's max extent.
	var macro_r: float = max(0.15, max_extent * 0.25)
	var cam_dist: float = macro_r * 2.5  # close enough to fill frame
	var fov: float = 35.0  # narrow FOV → less perspective distortion
	# Y-floor for flat artifacts: lift the camera slightly so we see
	# the surface, not the side.
	var lift: float = max(0.15, max_extent * 0.5)

	var corners: Array = []
	# 4 horizontal-AABB corners in XZ plane (works for both flat and 3D).
	var hx: float = s.x * 0.5
	var hz: float = s.z * 0.5
	var sign_pairs: Array = [[-1, -1], [1, -1], [-1, 1], [1, 1]]
	var corner_names: Array = ["NW", "NE", "SW", "SE"]
	for i in 4:
		var sx: int = sign_pairs[i][0]
		var sz: int = sign_pairs[i][1]
		var corner_pt: Vector3 = c + Vector3(sx * hx, 0, sz * hz)
		# Camera offset diagonally outward from the corner, looking back at it.
		var dir_out: Vector3 = Vector3(sx, 0, sz).normalized()
		var cam_pos: Vector3 = corner_pt + dir_out * cam_dist + Vector3(0, lift, 0)
		var look_at: Vector3 = corner_pt
		corners.append({
			"name": "corner_%s" % corner_names[i],
			"position": [cam_pos.x, cam_pos.y, cam_pos.z],
			"look_at": [look_at.x, look_at.y, look_at.z],
			"fov": fov,
		})

	# 4 mid-edge macros — the sawtooth bug we just fixed lives at edges,
	# not corners, so these catch broken-seam cases the corners miss.
	var edge_specs: Array = [
		{"name": "edge_N", "axis": [0, 0, -1]},
		{"name": "edge_S", "axis": [0, 0,  1]},
		{"name": "edge_W", "axis": [-1, 0, 0]},
		{"name": "edge_E", "axis": [ 1, 0, 0]},
	]
	for spec in edge_specs:
		var ax_a: Array = spec["axis"]
		var ax: Vector3 = Vector3(ax_a[0], 0, ax_a[2])
		var edge_mid: Vector3 = c + ax * Vector3(hx, 0, hz)
		var cam_pos2: Vector3 = edge_mid + ax * cam_dist + Vector3(0, lift, 0)
		corners.append({
			"name": spec["name"],
			"position": [cam_pos2.x, cam_pos2.y, cam_pos2.z],
			"look_at": [edge_mid.x, edge_mid.y, edge_mid.z],
			"fov": fov,
		})
	return corners


## Whole-room AABB: footing tiles + artifact together (the staging), NOT
## just the artifact. Unlike _measure_artifact_aabb this keeps large
## artifacts (no >18 footprint guard needed — the huge studio floor lives
## on `root`, not the room node, so it's never in scope here). Skips the
## AnchorMarker (a debug rectangle).
func _measure_room_aabb(node: Node) -> AABB:
	var combined := AABB()
	var has_any := false
	var stack: Array = [node]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n == null: continue
		for c in n.get_children():
			stack.push_back(c)
		if n is Node3D and (n as Node3D).name == "AnchorMarker":
			continue
		if not (n is GeometryInstance3D): continue
		var vi := n as GeometryInstance3D
		if not vi.is_visible_in_tree(): continue
		var local := vi.get_aabb()
		if local.size.length_squared() < 0.0001: continue
		var world: AABB = vi.global_transform * local
		if not has_any:
			combined = world
			has_any = true
		else:
			combined = combined.merge(world)
	if not has_any:
		return AABB(Vector3(-1, 0, -1), Vector3(2, 2, 2))
	return combined


## Staging shot set — reads the POSTURE. A 3/4 hero (footing plan + how the
## artifact sits on it) and a near-level side profile (the height stack: the
## floor→plinth lift, or a float's air gap, shows as a silhouette). Absolute
## positions framed to the whole-room AABB so the footing is never cropped.
func _staging_shots_for(aabb: AABB) -> Array:
	var c: Vector3 = aabb.get_center()
	var s: Vector3 = aabb.size
	var max_half: float = max(s.x, max(s.y, s.z)) * 0.5
	var fov: float = 48.0
	var pad: float = 1.4   # headroom so footing edges + a float's air gap stay in frame
	var dist: float = max(1.2, max_half / max(0.05, tan(deg_to_rad(fov) * 0.5)) * pad)
	var specs: Array = [
		{"name": "staging_hero",    "dir": Vector3(1.0, 0.85, 1.5)},   # front-right-above
		{"name": "staging_profile", "dir": Vector3(1.6, 0.32, 0.18)},  # near-side, low — reads height
	]
	var out: Array = []
	for spec in specs:
		var d: Vector3 = (spec["dir"] as Vector3).normalized()
		var pos: Vector3 = c + d * dist
		out.append({
			"name": spec["name"],
			"position": [pos.x, pos.y, pos.z],
			"look_at": [c.x, c.y, c.z],
			"fov": fov,
		})
	return out


func _to_vec3(a) -> Vector3:
	if a is Array and a.size() >= 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO


func _write_failure(d: Dictionary) -> void:
	var path := "user://dressing_room/%s.json" % _out_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "  "))
		f.close()

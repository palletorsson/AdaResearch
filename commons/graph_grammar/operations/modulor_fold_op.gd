# modulor_fold_op.gd — Fold selected nodes down one Modulor rung.
# Each selected node at level N spawns `count` children at level N+1:
#   radius = ModulorScale.red(N+1) * radius_factor
#   distance = ModulorScale.red(N+1) * distance_factor (from parent center)
#   placement = half-spiral: angle_i = (i / count) * spread_rad around parent direction
#
# Children inherit a semantic category tag read from fold_categories.gd OR
# overridden by `category_child` param. The modulor_level is tagged as
# `modulor_N+1` on each child so later ops can select "all rung 3 nodes."
#
# The fold is always relative to the parent's facing direction (node_direction).
# For the root, direction = UP by default.
#
# Params:
#   count            — children per selected node (default 3)
#   spread_rad       — angular spread of the half-spiral (default PI = half-turn)
#   distance_factor  — edge length as fraction of child Modulor rung (default 0.55)
#   radius_factor    — child radius as fraction of child Modulor rung (default 0.08)
#   pitch            — tilt angle (rad) added to direction on descent (default PI*0.35 ≈ 63°)
#   category_child   — tag for new children; if "auto" reads from CATEGORY_TABLE (default "auto")
#   series           — "red" or "blue" Modulor series (default "red")
#   jitter           — 0..1 random noise in angles (default 0.1)
#   seed             — (default 41)
extends "res://commons/graph_grammar/graph_rule.gd"

const ModulorScale = preload("res://commons/morphology/sdf/modulor_scale.gd")

# Default Modulor rung → category mapping (architectural + bodily).
# Override per-op with category_child, or set bespoke vocabularies per config.
const CATEGORY_TABLE: Array = [
	"room",    # level 0 — anchor (2.26m)
	"table",   # level 1 — standing surface (1.40m)
	"shelf",   # level 2 — seated body / shelf (0.86m)
	"cushion", # level 3 — arm / cushion / stool (0.53m)
	"book",    # level 4 — forearm / book (0.33m)
	"cup",     # level 5 — hand span / cup (0.20m)
	"pen",     # level 6 — hand length / pen (0.13m)
	"tip",     # level 7 — finger (0.078m)
	"nail",    # level 8 — fingertip (0.048m)
]


func _execute(g, selected: PackedInt32Array) -> void:
	var count: int = int(params.get("count", 3))
	var spread_rad: float = float(params.get("spread_rad", PI))
	var distance_factor: float = float(params.get("distance_factor", 0.55))
	var radius_factor: float = float(params.get("radius_factor", 0.08))
	var pitch: float = float(params.get("pitch", PI * 0.35))
	var category_child: String = str(params.get("category_child", "auto"))
	var series: String = str(params.get("series", "red"))
	var jitter: float = float(params.get("jitter", 0.1))
	var seed_val: int = int(params.get("seed", 41))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	for idx in selected:
		if idx >= g.nodes.size(): continue
		var parent_pos: Vector3 = g.nodes[idx]
		var parent_dir: Vector3 = g.node_direction(idx)
		# Read the parent's Modulor level from its tags, default 0
		var parent_level: int = _read_level(g, idx)
		var child_level: int = parent_level + 1

		# Child metrics from Modulor ladder
		var rung: float = 0.0
		if series == "blue":
			rung = ModulorScale.blue(child_level)
		else:
			rung = ModulorScale.red(child_level)
		var child_radius: float = maxf(0.005, rung * radius_factor)
		var child_distance: float = rung * distance_factor

		# Category for children
		var resolved_cat: String = category_child
		if resolved_cat == "auto":
			resolved_cat = _auto_category(child_level)

		for i in count:
			# Half-spiral angle around parent_dir
			var t: float = 0.5 if count == 1 else float(i) / float(count - 1)
			var angle: float = (t - 0.5) * spread_rad
			angle += rng.randf_range(-jitter, jitter) * spread_rad * 0.5

			# Local unit direction: parent_dir rotated by `pitch` off-axis,
			# then spun `angle` around parent_dir
			var side: Vector3 = _perpendicular(parent_dir)
			var out_dir: Vector3 = parent_dir.rotated(side, pitch)
			out_dir = out_dir.rotated(parent_dir, angle).normalized()

			var child_pos: Vector3 = parent_pos + out_dir * child_distance
			var tags := PackedStringArray([
				"modulor_%d" % child_level,
				resolved_cat,
				"leaf",
			])
			g.add_node(child_pos, child_radius, idx, tags)


static func _read_level(g, idx: int) -> int:
	if idx >= g.node_tags.size(): return 0
	var tags: PackedStringArray = g.node_tags[idx]
	for t in tags:
		if t.begins_with("modulor_"):
			var s: String = t.substr(8)
			if s.is_valid_int():
				return int(s)
	return 0


static func _auto_category(level: int) -> String:
	if level < 0 or level >= CATEGORY_TABLE.size():
		return "subtip"
	return CATEGORY_TABLE[level]


static func _perpendicular(v: Vector3) -> Vector3:
	var up := Vector3.UP if abs(v.y) < 0.9 else Vector3.RIGHT
	return v.cross(up).normalized()

extends Node3D
class_name CuratorModeWitnessWall

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: THE WITNESS WALL display mode — one vast wall carrying the names. It reads doc/book/commons_sources.json LIVE at build time and bakes every tradition the game has pressed patterns from into columns of light text on dark stone: tradition, era. A bench faces it. After the 9/11 memorial hall — scale as feeling, credit as architecture.
# desire: to make the commons ledger walkable — the return line as a room you stand in, not a JSON you query.
# critical_parameter: none to tune; the wall is as long as the debt. Grows when the ledger grows.
# triggers: _ready loads the ledger and bakes the columns; a hush-light band washes down the face.
# emerges: the fourth question answered in stone: whose knowledge is this pressed from — and the wall IS the return.
# needs: res://doc/book/commons_sources.json [live]; BakedText.make_text_block.
# relationships: mode-kit 3 of the Curator's display grammar; the built face of the commons ledger; sibling of [[mode_crown]] and [[mode_dialogue]]; kin to the pattern galleries whose makers it names.
# truth: a pattern reproduced without its makers is an enclosure; a wall of their names is the difference, standing up.

const LEDGER_PATH := "res://doc/book/commons_sources.json"
const WALL_H := 6.0
const COL_W := 3.4
const LINES_PER_COL := 16

func _ready() -> void:
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])

func _build() -> void:
	var entries := _load_entries()
	var n_cols := int(ceil(float(entries.size()) / float(LINES_PER_COL)))
	n_cols = maxi(n_cols, 1)
	var wall_w := float(n_cols) * COL_W + 1.2

	# the wall itself — dark stone
	var wall := MeshInstance3D.new()
	var wb := BoxMesh.new()
	wb.size = Vector3(wall_w, WALL_H, 0.5)
	wall.mesh = wb
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.10, 0.10, 0.12)
	wm.roughness = 0.75
	wall.material_override = wm
	wall.position = Vector3(0, WALL_H * 0.5, 0)
	add_child(wall)

	# title course
	var title: MeshInstance3D = BakedText.make_label_mesh(
		"PRESSED FROM NAMED HANDS — THE RETURN", Color(0.92, 0.88, 0.8),
		Vector2(minf(wall_w - 1.0, 10.0), 0.42), 1400, true)
	if title:
		title.position = Vector3(0, WALL_H - 0.55, 0.27)
		add_child(title)

	# the names, in columns
	for ci in n_cols:
		var lines: Array = []
		for li in LINES_PER_COL:
			var idx := ci * LINES_PER_COL + li
			if idx < entries.size():
				lines.append(entries[idx])
		if lines.is_empty():
			continue
		var block: Node3D = BakedText.make_text_block(
			lines, Color(0.85, 0.83, 0.78), 0.20, COL_W - 0.35, 0.045, true)
		var x := -wall_w * 0.5 + COL_W * (float(ci) + 0.5) + 0.6
		block.position = Vector3(x, WALL_H * 0.5 - 0.35, 0.27)
		add_child(block)

	# the hush — a warm band washing down the face
	var band := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(wall_w, 0.1, 0.1)
	band.mesh = bb
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.9, 0.75, 0.5)
	bm.emission_enabled = true
	bm.emission = Color(0.9, 0.72, 0.45)
	bm.emission_energy_multiplier = 1.4
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	band.material_override = bm
	band.position = Vector3(0, WALL_H + 0.1, 0.2)
	add_child(band)
	var wash := SpotLight3D.new()
	wash.position = Vector3(0, WALL_H + 0.4, 1.6)
	wash.look_at_from_position(wash.position, Vector3(0, WALL_H * 0.4, 0), Vector3.UP)
	wash.spot_angle = 60.0
	wash.spot_range = WALL_H + 3.0
	wash.light_energy = 1.6
	wash.light_color = Color(1.0, 0.92, 0.78)
	add_child(wash)

	# the bench, facing the names
	var bench := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(3.0, 0.45, 0.55)
	bench.mesh = hb
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.35, 0.3, 0.26)
	hm.roughness = 0.8
	bench.material_override = hm
	bench.position = Vector3(0, 0.225, 3.4)
	add_child(bench)

	# the count, small, honest
	var count_tag: Node3D = BakedText.make_tag(
		"%d sources · the wall grows when the ledger grows" % entries.size(),
		Color(0.6, 0.58, 0.54), 0.05)
	if count_tag:
		count_tag.position = Vector3(0, 0.9, 2.2)
		add_child(count_tag)

func _load_entries() -> Array:
	var out: Array = []
	if not FileAccess.file_exists(LEDGER_PATH):
		return ["the ledger was not found — that too is recorded"]
	var f := FileAccess.open(LEDGER_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return out
	var sources = parsed.get("sources", {})
	var keys: Array = sources.keys()
	keys.sort()
	for k in keys:
		var s = sources[k]
		if not (s is Dictionary):
			continue
		var tradition := str(s.get("tradition", str(k).replace("_", " ")))
		var era := str(s.get("era", "")).strip_edges()
		# strip odd encodings for the baked font
		var line := tradition
		if era != "":
			line += "  ·  " + era
		out.append(line)
	return out

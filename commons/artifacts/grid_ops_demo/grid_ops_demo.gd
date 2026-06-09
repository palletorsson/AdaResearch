extends Node3D
class_name GridOpsDemo

# @identity
# essence: the VR Grid-tab paint palette, made visible — six 8x8 grids, each one
#          op from GridOps (the GDScript port of the web /editor mutators).
# truth: editing the grid is painting a heightfield; the op is the brush.

const GridOpsLib := preload("res://commons/modifiers/grid_ops.gd")
const N := 8

var _demos: Array = [
	{"title": "raise (pyramid)", "base": "flat1", "op": {"op": "raise", "target": "all", "params": {"value": 5}}},
	{"title": "randomize (seed)", "base": "flat0", "op": {"op": "randomize", "target": "all", "params": {"min": 0, "max": 5}, "seed": 7}},
	{"title": "checker", "base": "flat0", "op": {"op": "checker", "target": "all", "params": {"value": 3}}},
	{"title": "frame", "base": "flat1", "op": {"op": "frame", "target": "all", "params": {"value": 4}}},
	{"title": "ring", "base": "flat0", "op": {"op": "ring", "target": "all", "params": {"value": 4}}},
	{"title": "ground-plane", "base": "random", "op": {"op": "ground_plane", "target": "all", "params": {"value": 1}}},
]


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	for c in get_children():
		c.queue_free()
	call_deferred("_build")


func _build() -> void:
	var spacing: float = float(N) + 3.0
	var total: float = float(_demos.size() - 1) * spacing
	for i in range(_demos.size()):
		var d: Dictionary = _demos[i]
		var base: Dictionary = _make_base(str(d["base"]), i)
		var result: Dictionary = GridOpsLib.apply(base, d["op"])
		var ox: float = float(i) * spacing - total * 0.5
		_render_grid(result, Vector3(ox, 0.0, 0.0), str(d["title"]))


func _make_base(kind: String, seed_i: int) -> Dictionary:
	var b: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + seed_i
	for r in range(N):
		for c in range(N):
			var h: int = 1
			if kind == "flat0":
				h = 0
			elif kind == "flat1":
				h = 1
			elif kind == "random":
				h = rng.randi_range(0, 5)
			b[Vector2i(r, c)] = h
	return b


func _render_grid(heights: Dictionary, origin: Vector3, title: String) -> void:
	var off: float = -float(N - 1) * 0.5
	for k in heights.keys():
		var h: int = int(heights[k])
		var hh: float = maxf(0.12, 0.32 * float(h))
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.9, hh, 0.9)
		mi.mesh = bm
		mi.position = origin + Vector3(off + float(k.y), hh * 0.5, off + float(k.x))
		var col: Color = _height_color(h)
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 0.25
		m.roughness = 0.6
		mi.material_override = m
		add_child(mi)
	var lbl := Label3D.new()
	lbl.text = title
	lbl.font_size = 44
	lbl.pixel_size = 0.004
	lbl.position = origin + Vector3(0.0, 2.6, off - 1.0)
	lbl.modulate = Color(0.95, 0.96, 1.0)
	lbl.outline_size = 6
	lbl.outline_modulate = Color(0, 0, 0, 0.7)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(lbl)


func _height_color(h: int) -> Color:
	var t: float = float(h) / float(GridOpsLib.MAX_H)
	return Color.from_hsv(lerpf(0.58, 0.02, t), 0.6, 0.45 + 0.12 * float(h))

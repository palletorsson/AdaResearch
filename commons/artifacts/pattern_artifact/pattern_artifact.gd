# pattern_artifact.gd
# Placeable wrapper around PatternSim. Renders a wallpaper-group pattern
# config to a 2D image, then displays it on a quad facing up — readable
# as a tile/floor/banner in 3D space.
#
# Mirrors dna_workstation._build_pattern. Same image, same orientation.

extends Node3D
class_name PatternArtifact

const PatternSim = preload("res://commons/pattern_grammar/pattern_sim.gd")

@export var config_path: String = ""
@export var quad_size: float = 2.0
@export var face_up: bool = true   # rotate -90° on X to lay flat as tile
@export var vr_preview: bool = true

var _current: MeshInstance3D = null


func _ready() -> void:
	if config_path.strip_edges().is_empty(): return
	_build()


func apply_grid_config(cfg: Dictionary) -> void:
	if cfg.has("config_path"): config_path = str(cfg["config_path"])
	if cfg.has("quad_size"):   quad_size = float(cfg["quad_size"])
	if cfg.has("face_up"):     face_up = bool(cfg["face_up"])
	_clear()
	_build()


func _clear() -> void:
	if _current:
		_current.queue_free()
		_current = null
	for c in get_children():
		c.queue_free()


func _build() -> void:
	if config_path.is_empty(): return
	var txt := FileAccess.get_file_as_string(config_path)
	if txt.is_empty(): return
	var j := JSON.new()
	if j.parse(txt) != OK or not (j.data is Dictionary): return
	var cfg: Dictionary = j.data
	if vr_preview:
		cfg["canvas_size"] = mini(int(cfg.get("canvas_size", 512)), 256)

	var img: Image = PatternSim.render_to_image(cfg)
	if img == null: return
	var tex := ImageTexture.create_from_image(img)
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(quad_size, quad_size)
	mi.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	if face_up:
		mi.rotation_degrees = Vector3(-90, 0, 0)   # face upward — tile read
		mi.position = Vector3(0, 0.05, 0)            # just above the floor
	else:
		mi.position = Vector3(0, quad_size * 0.5, 0)  # billboarded vertical
	add_child(mi)
	_current = mi

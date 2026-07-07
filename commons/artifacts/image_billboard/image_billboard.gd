# image_billboard.gd
# Render any PNG as a billboarded plane in 3D space.
#
# Used as the placement-side fallback for DNA-gallery findings whose grammar
# doesn't have a live builder artifact yet (graph-grammar, mesh-grammar,
# morphology, grid-substrate, map-grammar, soft-body, …). Drop one in a map
# with image_path set to the curated screenshot, and the finding shows up
# as a billboard the player can walk around.
#
# Pairs with the federation argument: each grammar that DOES have a live
# builder uses that builder directly (facade_builder, composition_artifact,
# pattern_renderer, etc.). image_billboard exists only for galleries
# without a builder — a graceful fallback that's still placeable.
#
# @identity
# essence: a 3D billboard that displays a curated PNG
# desire: every starred /dna finding is placeable, even when its grammar
#   has no live builder yet
# critical_parameter: image_path — the res:// path to the PNG to display
# triggers: instantiation; apply_grid_config rebuilds with new image
# emerges: gallery findings that aren't live-buildable still contribute
#   to maps as placeable references
# needs: a real PNG at image_path (typically commons/generated/
#   gallery_best_of/images/<gallery>__<entry_id>.png)
# relationships: the simple peer of facade_builder, composition_artifact,
#   etc. — those render live; this renders the snapshot
# truth: a placed snapshot of a finding is enough to be useful

extends Node3D
class_name ImageBillboard

## Path to the PNG to display. Typically a curated DNA-gallery image at
## res://commons/generated/gallery_best_of/images/<gallery>__<entry>.png
@export var image_path: String = ""

## Plane size in world units (square).
@export var plane_size: float = 1.5

## Vertical offset above the host cell (so the billboard sits at eye level).
@export var y_offset: float = 0.8

## If true, billboard always faces the camera. If false, it stays oriented
## according to the artifact's rotation (set by the placement token).
@export var billboard_enabled: bool = true

var _mesh_instance: MeshInstance3D = null


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("image_path"):       image_path = str(config["image_path"])
	if config.has("plane_size"):       plane_size = float(config["plane_size"])
	if config.has("y_offset"):         y_offset   = float(config["y_offset"])
	if config.has("billboard_enabled"): billboard_enabled = bool(config["billboard_enabled"])
	_clear()
	_build()


func _clear() -> void:
	if _mesh_instance:
		_mesh_instance.queue_free()
		_mesh_instance = null


func _build() -> void:
	if image_path.strip_edges().is_empty():
		_show_text("image_billboard: no image_path")
		return
	var img := Image.new()
	if not FileAccess.file_exists(image_path):
		_show_text("missing: %s" % image_path)
		return
	if img.load(image_path) != OK:
		_show_text("load failed: %s" % image_path)
		return
	var tex := ImageTexture.create_from_image(img)
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(plane_size, plane_size)
	mi.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if billboard_enabled:
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.billboard_keep_scale = true
	mi.material_override = mat
	mi.position = Vector3(0, y_offset, 0)
	add_child(mi)
	_mesh_instance = mi


func _show_text(reason: String) -> void:
	var label := Label3D.new()
	label.text = "image_billboard\n%s" % reason
	label.font_size = 24
	label.pixel_size = 0.003
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 0.7, 0.4)
	label.outline_size = 4
	label.position = Vector3(0, y_offset, 0)
	add_child(label)

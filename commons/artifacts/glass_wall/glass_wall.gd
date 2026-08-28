extends Node3D
class_name GlassWall

# @identity
# essence: a transparent pane that fills its cell, floor to head height, with collision — you see through it and cannot pass
# desire: to make a boundary that is visible rather than opaque; to be looked THROUGH at something you may not reach
# critical_parameter: tint alpha — at 0.06 the pane is nearly air and reads as a force field; at 0.35 it is architecture and the space beyond becomes an aquarium
# triggers: _ready() builds pane + optional edge glow + a StaticBody3D box; apply_grid_config rebuilds from map tokens
# emerges: a room the visitor can see into but not enter reads as PAST rather than as CLOSED — the same geometry that would be a locked door becomes a window onto time
# needs: transparent material [has]; collision [has]; edge emission [has]; per-cell placement from a map token [has]
# relationships: made for the endless museum's enter room, where Folding Past stands and the visitor is dropped past it; the sibling of large_window, which frames a view in a wall rather than being the wall
# truth: a boundary you can see through is not the same boundary as one you cannot — the museum's past is only past because it stays visible
#
# 2026-08-26, Palle: "making the annex a balcony we can not step out on. It is the
# past and it only has one artifact: the folding past. Make it like a transparent
# force field wall."

## Cell-filling by default: 1 m wide, and tall enough that nobody steps over it.
@export var width_m: float = 1.0
@export var height_m: float = 2.8
@export var thickness_m: float = 0.06
## The pane. Alpha is the whole character of the thing — see critical_parameter.
@export var tint: Color = Color(0.72, 0.84, 0.87, 0.12)
## A lit edge, which is what makes it read as a field rather than as a window that
## someone forgot to put a frame on. 0 turns it off.
@export var edge_glow: float = 1.6
@export var edge_color: Color = Color(0.55, 0.85, 1.0)
@export var edge_m: float = 0.02
## Off makes it a pure image: visible, and the visitor walks straight through.
@export var solid: bool = true

var _built: bool = false


func _ready() -> void:
	_build()


func _build() -> void:
	# remove_child as well as queue_free: on a rebuild the freed nodes are still
	# children for the rest of the frame, and the new pane would be laid inside the
	# old one. At _ready there are no children, so this is a no-op there.
	for c in get_children():
		remove_child(c)
		c.queue_free()

	var glass := StandardMaterial3D.new()
	glass.albedo_color = tint
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.04
	glass.metallic = 0.15
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	# no shadow from a pane this transparent: it would draw a grey rectangle on the
	# floor that reads as dirt, and the museum's floors are the one surface a
	# visitor is always looking at.
	var pane := MeshInstance3D.new()
	pane.name = "Pane"
	var bm := BoxMesh.new()
	bm.size = Vector3(width_m, height_m, thickness_m)
	pane.mesh = bm
	pane.material_override = glass
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pane.position = Vector3(0.0, height_m * 0.5, 0.0)
	add_child(pane)

	if edge_glow > 0.0 and edge_m > 0.0:
		var lit := StandardMaterial3D.new()
		lit.albedo_color = edge_color
		lit.emission_enabled = true
		lit.emission = edge_color
		lit.emission_energy_multiplier = edge_glow
		for e in [[Vector3(0.0, 0.0, 0.0), Vector3(width_m, edge_m, thickness_m)],
				[Vector3(0.0, height_m, 0.0), Vector3(width_m, edge_m, thickness_m)],
				[Vector3(-width_m * 0.5, height_m * 0.5, 0.0), Vector3(edge_m, height_m, thickness_m)],
				[Vector3(width_m * 0.5, height_m * 0.5, 0.0), Vector3(edge_m, height_m, thickness_m)]]:
			var bar := MeshInstance3D.new()
			var bmm := BoxMesh.new()
			bmm.size = (e[1] as Vector3)
			bar.mesh = bmm
			bar.material_override = lit
			bar.position = (e[0] as Vector3)
			bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(bar)

	if solid:
		var body := StaticBody3D.new()
		body.name = "Barrier"
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(width_m, height_m, thickness_m)
		cs.shape = bs
		cs.position = Vector3(0.0, height_m * 0.5, 0.0)
		body.add_child(cs)
		add_child(body)
	_built = true


## Config can arrive BEFORE _ready — the grid defers it, the museum and the
## necklace call it synchronously on a root that is still outside the tree — so
## nothing here may assume _build has run. It reads the keys, then builds.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	if config.has("height"):
		height_m = clampf(float(config["height"]), 0.2, 8.0)
	if config.has("width"):
		width_m = clampf(float(config["width"]), 0.1, 8.0)
	if config.has("thickness"):
		thickness_m = clampf(float(config["thickness"]), 0.01, 1.0)
	if config.has("alpha"):
		tint.a = clampf(float(config["alpha"]), 0.0, 1.0)
	if config.has("tint"):
		tint = Color.from_string(str(config["tint"]), tint)
	if config.has("edge"):
		edge_glow = clampf(float(config["edge"]), 0.0, 16.0)
	if config.has("edge_color"):
		edge_color = Color.from_string(str(config["edge_color"]), edge_color)
	if config.has("solid"):
		# a token's value is a STRING, never a bool: "true" == true is a runtime
		# error in GDScript, not false
		var v: Variant = config["solid"]
		solid = v if v is bool else (str(v).to_lower() in ["true", "1", "yes"])
	_build()

extends Node3D

## Poor Image Gate — a doorway where resolution and freedom trade against each other.
##
## @identity
## essence: two sides of one wall — high resolution and framed, or degraded and mobile; the trade is the artifact
## desire: to stand at the threshold and notice you are choosing between being seen well and being able to leave
## critical_parameter: side — which condition is foregrounded. The gate is symmetrical and the asymmetry is entirely in what each side costs you.
## triggers: crossing. The far side is built at a coarser sample and its barriers are gone
## emerges: the crisp side is the one with the frame around it and the rope in front of it, and the mush is the side you can walk out of
## needs: nothing external — degradation is built, not simulated, because a fake blur would be a picture of poverty rather than the thing
## relationships: the resolution seam of doc/CONSERVATION_OF_THE_IRREDUCIBLE.md made standable; kin to operational_eye (both show the machine's terms rather than its output)
## truth: resolution is not quality. It is a decision about who is allowed to travel.
##
## Steyerl's poor image circulates because it is light. The rich image is immobile: it
## sits in an institution, in a frame, at a resolution that costs something to move. The
## gate puts those two facts on either side of one doorway and lets them argue.
##
## The degradation is REAL geometry, not a shader trick: the far side is built from
## fewer, larger, blockier elements at a coarser sample. A blur applied over a fine mesh
## would be a picture OF a poor image. This is one.

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## Which condition is foregrounded — "rich" or "poor". Both are always built; this only
## says which one you are standing on.
@export var side: String = "rich"
## Sample rate on the poor side, in subdivisions. Lower is freer.
@export_range(2, 16, 1) var poor_samples: int = 4
@export_range(8, 40, 1) var rich_samples: int = 26
@export var wall_width: float = 2.6
@export var wall_height: float = 2.3
@export var door_width: float = 0.9
@export var finish: String = "terminal"
@export var unit_code: String = "PG-01"


func _ready() -> void:
	_build_wall()
	_build_field(true)    # rich, -Z
	_build_field(false)   # poor, +Z


func _build_wall() -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, pal["body"], 0.12)
	var side_w: float = (wall_width - door_width) * 0.5
	for sx in [-1.0, 1.0]:
		cab.add_child(HangarKit.box(
			Vector3(sx * (door_width * 0.5 + side_w * 0.5), wall_height * 0.5, 0),
			Vector3(side_w, wall_height, 0.14), shell))
	cab.add_child(HangarKit.box(Vector3(0, wall_height - 0.14, 0),
		Vector3(door_width, 0.28, 0.14), shell))
	cab.add_child(HangarKit.box(Vector3(0, wall_height - 0.30, 0.075),
		Vector3(door_width * 0.96, 0.006, 0.006), HangarKit.emissive(pal["accent"], 2.0)))
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.09, 0.020),
		pal["accent"].lightened(0.25))
	if code:
		code.position = Vector3(-wall_width * 0.5 + 0.14, 0.22, 0.075)
		cab.add_child(code)


## One side of the argument. `rich` gets fine subdivision, a frame, and a rope; `poor`
## gets a coarse sample and nothing stopping you.
func _build_field(rich: bool) -> void:
	var z: float = -1.15 if rich else 1.15
	var host := Node3D.new()
	host.name = "Rich" if rich else "Poor"
	add_child(host)

	var n: int = rich_samples if rich else poor_samples
	var span: float = 1.9
	var cell: float = span / float(n)
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.5 if rich else 0.95
	mat.metallic = 0.0

	# The SAME surface at two sample rates. On the rich side the steps are below
	# notice; on the poor side they are the whole texture of the thing.
	for ix in range(n):
		for iz in range(n):
			var u: float = (float(ix) + 0.5) / float(n)
			var v: float = (float(iz) + 0.5) / float(n)
			var h: float = 0.10 + sin(u * PI * 2.0) * cos(v * PI * 1.6) * 0.14
			var c := Color(0.32, 0.46, 0.62).lerp(Color(0.86, 0.72, 0.42), (u + v) * 0.5)
			if not rich:
				# quantised colour too — a poor image is poor in every channel
				c = Color(round(c.r * 3.0) / 3.0, round(c.g * 3.0) / 3.0, round(c.b * 3.0) / 3.0)
			var m: StandardMaterial3D = mat.duplicate()
			m.albedo_color = c
			host.add_child(HangarKit.box(
				Vector3(-span * 0.5 + cell * (float(ix) + 0.5), maxf(h, 0.02) * 0.5,
					z + (-span * 0.5 + cell * (float(iz) + 0.5)) * 0.55),
				Vector3(cell * 0.94, maxf(h, 0.02), cell * 0.52), m))

	if rich:
		# THE FRAME AND THE ROPE. What you cannot do on this side is the point of it.
		var gold := StandardMaterial3D.new()
		gold.albedo_color = Color(0.72, 0.60, 0.30)
		gold.metallic = 0.8
		gold.roughness = 0.25
		for sx in [-1.0, 1.0]:
			host.add_child(HangarKit.box(Vector3(sx * span * 0.52, 0.42, z),
				Vector3(0.05, 0.84, 0.05), gold))
		host.add_child(HangarKit.box(Vector3(0, 0.84, z), Vector3(span * 1.08, 0.05, 0.05), gold))
		# the rope: waist height, across the approach
		var rope := StandardMaterial3D.new()
		rope.albedo_color = Color(0.55, 0.13, 0.15)
		rope.roughness = 0.9
		host.add_child(HangarKit.box(Vector3(0, 0.62, z + 0.62),
			Vector3(span * 0.94, 0.035, 0.035), rope))
		for sx in [-1.0, 1.0]:
			host.add_child(HangarKit.box(Vector3(sx * span * 0.47, 0.31, z + 0.62),
				Vector3(0.045, 0.62, 0.045), gold))

	var lbl: MeshInstance3D = HangarKit.stencil(
		"HIGH RESOLUTION · DOES NOT TRAVEL" if rich else "POOR IMAGE · GOES ANYWHERE",
		Vector2(0.92, 0.026),
		Color(0.86, 0.78, 0.55) if rich else Color(0.55, 0.85, 0.95))
	if lbl:
		lbl.position = Vector3(0, 0.015, z + (0.98 if not rich else 0.92))
		lbl.rotation_degrees = Vector3(-90, 0, 0)
		host.add_child(lbl)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("side"):
		side = str(config_data["side"])
	if config_data.has("poor_samples"):
		poor_samples = int(config_data["poor_samples"])
	if config_data.has("rich_samples"):
		rich_samples = int(config_data["rich_samples"])

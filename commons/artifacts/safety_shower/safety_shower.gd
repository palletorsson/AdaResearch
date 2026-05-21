extends Node3D
class_name SafetyShower

# @identity
# essence: an emergency safety shower with an eyewash basin — Half-Life decontamination corner vocabulary. Vertical steel pipe rising from the floor (or descending from the ceiling) with a wide horizontal arm ending in a wide circular shower head; below it, a glossy white basin with two small twin eyewash spouts and a vertical valve handle; a green-painted accent stripe around the basin; a "SAFETY SHOWER" sign above. A pull chain dangles from the shower arm. Always present, never used, structurally announcing risk
# desire: every lab MUST contain its accident — a safety shower is the architectural admission that this place can hurt you. The shower wants to be the most visible piece of infrastructure in the room. Green = safety = "if it goes wrong, come here"
# critical_parameter: pipe_orientation — "wall" (rising from the floor against a wall) vs "ceiling" (descending from above the lab), changes the whole vertical reading of the chamber. Wall = corner safety station. Ceiling = fixed emergency point in the open
# triggers: _ready() builds pipe + arm + head + basin + spouts + valve + chain + accent + signage from exports; apply_grid_config rebuilds
# emerges: shower without basin = generic decontamination. Shower with basin + label = "this lab has chemicals". Green stripe + signage = code-compliant industrial safety. The presence DOES the labelling — no narration needed
# needs: vertical pipe + horizontal arm + wide circular head [present]; eyewash basin with two spouts + valve [present]; green accent stripe around basin [present]; optional pull chain [present]; Label3D for signage_text [present]
# relationships: peer to exit_sign (both say "in case of emergency, this way"); sibling to ceiling_vent (both are industrial infrastructure cues); cousin to fire alarm / first aid station (the lab's vocabulary of CARE under risk); the QFEP chamber's confession that the experiment can wound
# truth: a safety shower is the only piece of architecture in a lab that PRESUMES failure. Tables presume success. Whiteboards presume thinking. Doors presume passage. The safety shower presumes the chemical spill, the burn, the contaminated eye. It is the room's apology in advance. Its presence acknowledges that knowledge production is also bodily harm

## An emergency safety shower + eyewash basin.
##
## Built procedurally from DNA exports. Origin is at the bottom-center
## of the pipe footprint, on the floor. Faces +Z (signage reads toward
## +Z, valve handle on the +Z side of the basin). If pipe_orientation =
## "ceiling", the pipe descends from `shower_height` to the shower head
## instead of rising from the floor.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
## Top of the shower head from the floor.
@export var shower_height: float = 2.2
@export var basin_width: float = 0.45
@export var basin_depth: float = 0.35

@export_group("Color")
@export var pipe_color: Color = Color(0.20, 0.20, 0.22)
@export var basin_color: Color = Color(0.94, 0.94, 0.95)
@export var accent_color: Color = Color(0.15, 0.65, 0.25)        # safety green

@export_group("Orientation")
## "wall" (rises from floor) or "ceiling" (descends from ceiling).
@export var pipe_orientation: String = "wall"

@export_group("Signage")
@export var signage_text: String = "SAFETY SHOWER"

@export_group("Chain")
@export var chain_visible: bool = true

# ── Constants ─────────────────────────────────────────────────────────

const PIPE_RADIUS: float = 0.025
const ARM_LENGTH: float = 0.35
const HEAD_RADIUS: float = 0.16
const HEAD_THICKNESS: float = 0.04
const BASIN_HEIGHT: float = 0.95
const BASIN_WALL: float = 0.025
const BASIN_INTERIOR_DEPTH: float = 0.07
const SPOUT_RADIUS: float = 0.015
const SPOUT_HEIGHT: float = 0.08
const VALVE_HANDLE_LENGTH: float = 0.18
const VALVE_HANDLE_THICKNESS: float = 0.018
const ACCENT_STRIP_THICKNESS: float = 0.018
const ACCENT_STRIP_DEPTH: float = 0.006
const CHAIN_SEGMENTS: int = 7
const CHAIN_SEGMENT_HEIGHT: float = 0.045
const CHAIN_SEGMENT_THICKNESS: float = 0.014
const LABEL_PIXEL_SIZE: float = 0.0035
const LABEL_FONT_SIZE: int = 32

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_shower()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_shower()


func _read_metadata_overrides() -> void:
	if has_meta("config_shower_height"):
		shower_height = float(String(get_meta("config_shower_height")))
	if has_meta("config_basin_width"):
		basin_width = float(String(get_meta("config_basin_width")))
	if has_meta("config_basin_depth"):
		basin_depth = float(String(get_meta("config_basin_depth")))
	if has_meta("config_pipe_color"):
		pipe_color = _parse_color(String(get_meta("config_pipe_color")), pipe_color)
	if has_meta("config_basin_color"):
		basin_color = _parse_color(String(get_meta("config_basin_color")), basin_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)
	if has_meta("config_pipe_orientation"):
		pipe_orientation = String(get_meta("config_pipe_orientation")).to_lower()
	if has_meta("config_signage_text"):
		signage_text = String(get_meta("config_signage_text"))
	if has_meta("config_chain_visible"):
		var v := String(get_meta("config_chain_visible")).to_lower()
		chain_visible = v in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_shower() -> void:
	_built = true
	_build_pipe_and_arm()
	_build_shower_head()
	_build_basin()
	_build_eyewash_spouts()
	_build_valve_handle()
	_build_accent_strip()
	if chain_visible:
		_build_pull_chain()
	_build_signage()


func _build_pipe_and_arm() -> void:
	var root := Node3D.new()
	root.name = "PipeAndArm"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = pipe_color
	mat.roughness = 0.4
	mat.metallic = 0.75

	# Vertical pipe.
	var pipe := MeshInstance3D.new()
	pipe.name = "VerticalPipe"
	var pm := CylinderMesh.new()
	pm.top_radius = PIPE_RADIUS
	pm.bottom_radius = PIPE_RADIUS
	# Pipe runs from floor (or from arm height for "ceiling") to arm height.
	# Arm sits at shower_height - HEAD_THICKNESS so the head's top is at shower_height.
	var arm_y := shower_height - HEAD_THICKNESS
	if pipe_orientation == "ceiling":
		# Pipe descends from ceiling y = shower_height + 0.1 down to arm_y.
		var top_y := shower_height + 0.1
		pm.height = top_y - arm_y
		pipe.mesh = pm
		pipe.material_override = mat
		pipe.position = Vector3(0.0, (top_y + arm_y) * 0.5, 0.0)
	else:
		# Wall-mode: pipe rises from floor to arm height.
		pm.height = arm_y
		pipe.mesh = pm
		pipe.material_override = mat
		pipe.position = Vector3(0.0, arm_y * 0.5, 0.0)
	root.add_child(pipe)

	# Horizontal arm extending in +Z to the shower head.
	var arm := MeshInstance3D.new()
	arm.name = "HorizontalArm"
	var am := CylinderMesh.new()
	am.top_radius = PIPE_RADIUS
	am.bottom_radius = PIPE_RADIUS
	am.height = ARM_LENGTH
	arm.mesh = am
	arm.material_override = mat
	# Default cylinder axis = +Y. Lay flat along +Z.
	arm.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	arm.position = Vector3(0.0, arm_y, ARM_LENGTH * 0.5)
	root.add_child(arm)


func _build_shower_head() -> void:
	# Wide disk-like cylinder at the end of the arm, facing down.
	var head := MeshInstance3D.new()
	head.name = "ShowerHead"
	var hm := CylinderMesh.new()
	hm.top_radius = HEAD_RADIUS
	hm.bottom_radius = HEAD_RADIUS * 0.95
	hm.height = HEAD_THICKNESS
	head.mesh = hm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pipe_color
	mat.roughness = 0.5
	mat.metallic = 0.7
	head.material_override = mat
	var arm_y := shower_height - HEAD_THICKNESS
	head.position = Vector3(0.0, arm_y - HEAD_THICKNESS * 0.5, ARM_LENGTH)
	add_child(head)


func _build_basin() -> void:
	# Basin: a shallow box "bowl" sitting at BASIN_HEIGHT from the floor.
	# Walls modeled as 4 thin BoxMeshes around an open top + a thin floor.
	var basin_root := Node3D.new()
	basin_root.name = "Basin"
	add_child(basin_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = basin_color
	mat.roughness = 0.25
	mat.metallic = 0.05

	var bw := basin_width
	var bd := basin_depth
	var bh := BASIN_INTERIOR_DEPTH
	var y_floor := BASIN_HEIGHT - bh

	# Basin floor (slab).
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "BasinFloor"
	var fm := BoxMesh.new()
	fm.size = Vector3(bw, BASIN_WALL, bd)
	floor_mesh.mesh = fm
	floor_mesh.material_override = mat
	floor_mesh.position = Vector3(0.0, y_floor + BASIN_WALL * 0.5, 0.0)
	basin_root.add_child(floor_mesh)

	# Four walls.
	# Front (+Z)
	_make_basin_wall(basin_root, "WallFront", Vector3(bw, bh, BASIN_WALL),
		Vector3(0.0, y_floor + bh * 0.5 + BASIN_WALL, bd * 0.5 - BASIN_WALL * 0.5), mat)
	# Back (-Z)
	_make_basin_wall(basin_root, "WallBack", Vector3(bw, bh, BASIN_WALL),
		Vector3(0.0, y_floor + bh * 0.5 + BASIN_WALL, -bd * 0.5 + BASIN_WALL * 0.5), mat)
	# Left (-X)
	_make_basin_wall(basin_root, "WallLeft", Vector3(BASIN_WALL, bh, bd - BASIN_WALL * 2.0),
		Vector3(-bw * 0.5 + BASIN_WALL * 0.5, y_floor + bh * 0.5 + BASIN_WALL, 0.0), mat)
	# Right (+X)
	_make_basin_wall(basin_root, "WallRight", Vector3(BASIN_WALL, bh, bd - BASIN_WALL * 2.0),
		Vector3(bw * 0.5 - BASIN_WALL * 0.5, y_floor + bh * 0.5 + BASIN_WALL, 0.0), mat)

	# Basin support pedestal under it (so it isn't floating).
	var pedestal := MeshInstance3D.new()
	pedestal.name = "Pedestal"
	var pm := BoxMesh.new()
	pm.size = Vector3(bw * 0.4, BASIN_HEIGHT - bh, bd * 0.3)
	pedestal.mesh = pm
	var ped_mat := StandardMaterial3D.new()
	ped_mat.albedo_color = pipe_color
	ped_mat.roughness = 0.55
	ped_mat.metallic = 0.4
	pedestal.material_override = ped_mat
	pedestal.position = Vector3(0.0, (BASIN_HEIGHT - bh) * 0.5, 0.0)
	basin_root.add_child(pedestal)


func _make_basin_wall(parent: Node3D, n: String, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var w := MeshInstance3D.new()
	w.name = n
	var m := BoxMesh.new()
	m.size = size
	w.mesh = m
	w.material_override = mat
	w.position = pos
	parent.add_child(w)


func _build_eyewash_spouts() -> void:
	# Two small upright spouts in the basin, side-by-side along X.
	var spouts_root := Node3D.new()
	spouts_root.name = "EyewashSpouts"
	add_child(spouts_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = pipe_color
	mat.roughness = 0.4
	mat.metallic = 0.75

	var y_floor := BASIN_HEIGHT - BASIN_INTERIOR_DEPTH + BASIN_WALL
	var spout_offset := basin_width * 0.18
	for sign_x in [1, -1]:
		var sp := MeshInstance3D.new()
		sp.name = "Spout_%d" % sign_x
		var cm := CylinderMesh.new()
		cm.top_radius = SPOUT_RADIUS
		cm.bottom_radius = SPOUT_RADIUS * 1.15
		cm.height = SPOUT_HEIGHT
		sp.mesh = cm
		sp.material_override = mat
		sp.position = Vector3(spout_offset * float(sign_x), y_floor + SPOUT_HEIGHT * 0.5, 0.0)
		spouts_root.add_child(sp)


func _build_valve_handle() -> void:
	# Thin vertical handle on the +Z front face of the basin pedestal.
	var handle := MeshInstance3D.new()
	handle.name = "ValveHandle"
	var m := BoxMesh.new()
	m.size = Vector3(VALVE_HANDLE_THICKNESS, VALVE_HANDLE_LENGTH, VALVE_HANDLE_THICKNESS)
	handle.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pipe_color
	mat.roughness = 0.45
	mat.metallic = 0.7
	handle.material_override = mat
	# Sits on the front (+Z) face of the basin's lower pedestal.
	var y := BASIN_HEIGHT - BASIN_INTERIOR_DEPTH * 0.5
	var z := basin_depth * 0.5 + VALVE_HANDLE_THICKNESS * 0.5 + 0.005
	handle.position = Vector3(0.0, y, z)
	add_child(handle)


func _build_accent_strip() -> void:
	# Green safety stripe wrapping the top edge of the basin. Implemented as
	# four thin emissive box pieces along front, back, left, right.
	var strip_root := Node3D.new()
	strip_root.name = "AccentStrip"
	add_child(strip_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var bw := basin_width
	var bd := basin_depth
	var y := BASIN_HEIGHT + ACCENT_STRIP_THICKNESS * 0.5

	# Front
	var f := MeshInstance3D.new()
	f.name = "AccentFront"
	var fm := BoxMesh.new()
	fm.size = Vector3(bw + 0.01, ACCENT_STRIP_THICKNESS, ACCENT_STRIP_DEPTH)
	f.mesh = fm
	f.material_override = mat
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	f.position = Vector3(0.0, y, bd * 0.5 + ACCENT_STRIP_DEPTH * 0.5)
	strip_root.add_child(f)

	# Back
	var b := MeshInstance3D.new()
	b.name = "AccentBack"
	var bm := BoxMesh.new()
	bm.size = Vector3(bw + 0.01, ACCENT_STRIP_THICKNESS, ACCENT_STRIP_DEPTH)
	b.mesh = bm
	b.material_override = mat
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.position = Vector3(0.0, y, -bd * 0.5 - ACCENT_STRIP_DEPTH * 0.5)
	strip_root.add_child(b)

	# Left
	var l := MeshInstance3D.new()
	l.name = "AccentLeft"
	var lm := BoxMesh.new()
	lm.size = Vector3(ACCENT_STRIP_DEPTH, ACCENT_STRIP_THICKNESS, bd + 0.01)
	l.mesh = lm
	l.material_override = mat
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	l.position = Vector3(-bw * 0.5 - ACCENT_STRIP_DEPTH * 0.5, y, 0.0)
	strip_root.add_child(l)

	# Right
	var r := MeshInstance3D.new()
	r.name = "AccentRight"
	var rm := BoxMesh.new()
	rm.size = Vector3(ACCENT_STRIP_DEPTH, ACCENT_STRIP_THICKNESS, bd + 0.01)
	r.mesh = rm
	r.material_override = mat
	r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.position = Vector3(bw * 0.5 + ACCENT_STRIP_DEPTH * 0.5, y, 0.0)
	strip_root.add_child(r)


func _build_pull_chain() -> void:
	# Small Box segments forming a chain hanging from the arm/head down toward the basin.
	var chain_root := Node3D.new()
	chain_root.name = "PullChain"
	add_child(chain_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = pipe_color
	mat.roughness = 0.5
	mat.metallic = 0.8

	var arm_y := shower_height - HEAD_THICKNESS
	# Start just below the arm where it meets the head.
	var start_y := arm_y - HEAD_THICKNESS - CHAIN_SEGMENT_HEIGHT * 0.5
	var x := HEAD_RADIUS * 0.4   # offset to the side of the head
	var z := ARM_LENGTH          # at the head's z
	for i in range(CHAIN_SEGMENTS):
		var seg := MeshInstance3D.new()
		seg.name = "ChainSeg_%d" % i
		var m := BoxMesh.new()
		m.size = Vector3(CHAIN_SEGMENT_THICKNESS, CHAIN_SEGMENT_HEIGHT, CHAIN_SEGMENT_THICKNESS)
		seg.mesh = m
		seg.material_override = mat
		# Alternate rotation 90° so it reads as linked.
		if i % 2 == 1:
			seg.rotation = Vector3(0.0, PI * 0.5, 0.0)
		seg.position = Vector3(x, start_y - i * CHAIN_SEGMENT_HEIGHT * 0.9, z)
		chain_root.add_child(seg)

	# Triangle/teardrop pull at the bottom.
	var pull := MeshInstance3D.new()
	pull.name = "PullHandle"
	var pm := BoxMesh.new()
	pm.size = Vector3(0.04, 0.06, 0.012)
	pull.mesh = pm
	pull.material_override = mat
	pull.position = Vector3(x, start_y - CHAIN_SEGMENTS * CHAIN_SEGMENT_HEIGHT * 0.9 - 0.03, z)
	chain_root.add_child(pull)


func _build_signage() -> void:
	# Label3D above the shower head, facing +Z.
	if signage_text == "":
		return
	var sign := Label3D.new()
	sign.name = "Signage"
	sign.text = signage_text
	sign.font_size = LABEL_FONT_SIZE
	sign.outline_size = 4
	sign.pixel_size = LABEL_PIXEL_SIZE
	sign.modulate = accent_color
	sign.outline_modulate = Color(0.05, 0.06, 0.05)
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sign.no_depth_test = false
	# Faces +Z by default (Label3D default faces -Z), so rotate 180°.
	sign.rotation = Vector3(0.0, PI, 0.0)
	sign.position = Vector3(0.0, shower_height + 0.18, ARM_LENGTH * 0.5)
	add_child(sign)


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)

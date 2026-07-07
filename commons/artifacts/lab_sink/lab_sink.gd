extends Node3D
class_name LabSink

# @identity
# essence: a rectangular lab counter with a recessed basin and a vertical faucet at the back — Portal 2 / Half-Life utility-corner vocabulary. Glossy white counter top, a polished steel sink basin sunk into it, a swan-neck or industrial faucet rising from the back lip, twin valve discs at its base, and a single Portal-orange accent stripe along the front edge. Optional twin-spout eyewash unit beside the faucet, and an optional thin translucent water column when water_running is true. The lab's confession that EVEN CHEMISTRY NEEDS WATER.
# desire: every lab wants a place where HANDS GET CLEAN. The sink is the room's mediator between dirty-work and clean-work; the architectural beat between "I just touched the experiment" and "I can touch the world again". It wants to sit at hip height, with a clear approach side, so the body can come to it without thinking.
# critical_parameter: faucet_style — "swan_neck" reads as biology / wet-lab / pour-into-this-glass (curved beak hangs OVER the basin centerline), "industrial" reads as plumbing infrastructure / utility-room / wash-down (straight pipe, perpendicular spout). Same plumbing, two different rooms.
# triggers: _ready() builds counter + recessed basin + faucet (style-dispatched) + valve discs + optional eyewash + optional water column + accent stripe from exports; apply_grid_config rebuilds
# emerges: water_running=true reads as "the experiment is LIVE, somebody is here right now"; eyewash_present=true reads as "this lab handles things that hurt eyes"; swan_neck + no eyewash = teaching wet-lab; industrial + eyewash = chemistry workshop. Same hardware, four different rooms.
# needs: counter slab [present]; recessed basin built from 4 walls + a floor inside the counter [present]; faucet body with swan-neck OR industrial spout [present]; twin valve handles [present]; optional eyewash twin-spout unit [present]; optional translucent water column [present]; accent stripe along the front edge [present]
# relationships: sibling to safety_shower (both ANSWER chemistry's risk, the sink with cleaning, the shower with rescue); cousin to large_table (both are hip-height working surfaces — the table holds the experiment, the sink WASHES it); peer to fume_hood (a fume hood has nowhere to send its rinse if the sink isn't in the same room — chemistry corners want both)
# truth: a sink is not just a basin and a faucet. It is the lab's THRESHOLD: water marks the line between being-in-the-experiment and being-back-in-the-world. The sink is where the lab admits the body is also chemistry — sweat, skin, mucous, contamination, all crossing this metal lip every time hands move.

## A rectangular lab counter with a recessed sink basin and faucet.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTER of
## the counter footprint, on the floor. Faucet rises from the BACK of the
## counter (-Z), valve handles flank it, accent stripe runs along the FRONT
## edge (+Z). The sink "opens" toward +Z — the user approaches from +Z.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var sink_width: float = 0.60          # X
@export var sink_depth: float = 0.45          # Z
## Counter top height — standard work surface ≈ 0.95m.
@export var sink_height: float = 0.95
## Basin depth as a fraction of sink_height (default ~0.19m deep).
@export_range(0.05, 0.45, 0.01) var basin_depth_factor: float = 0.20

@export_group("Color")
@export var counter_color: Color = Color(0.94, 0.94, 0.96)
@export var basin_color: Color = Color(0.80, 0.82, 0.84)
@export var faucet_color: Color = Color(0.82, 0.84, 0.86)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)
@export var water_color: Color = Color(0.75, 0.85, 0.95, 0.80)

@export_group("Faucet")
## "swan_neck" — vertical pipe curving forward over the basin.
## "industrial" — straight vertical pipe with perpendicular spout.
@export var faucet_style: String = "swan_neck"

@export_group("Water")
## When true, render a thin translucent water column from the spout down.
@export var water_running: bool = false

@export_group("Eyewash")
## When true, add a small twin-spout eyewash unit beside the faucet.
@export var eyewash_present: bool = false

# ── Constants ─────────────────────────────────────────────────────────

const COUNTER_THICKNESS: float = 0.04
const BASIN_WALL_THICKNESS: float = 0.012
const FAUCET_PIPE_RADIUS: float = 0.018
const FAUCET_BASE_RADIUS: float = 0.038
const FAUCET_BASE_HEIGHT: float = 0.025
const FAUCET_VERTICAL_HEIGHT: float = 0.22
const FAUCET_SPOUT_LENGTH: float = 0.16
const VALVE_RADIUS: float = 0.028
const VALVE_HEIGHT: float = 0.012
const VALVE_X_OFFSET: float = 0.07
const ACCENT_STRIP_HEIGHT: float = 0.012
const ACCENT_STRIP_THICKNESS: float = 0.005
const WATER_COLUMN_RADIUS: float = 0.008
const EYEWASH_BASE_SIZE: Vector3 = Vector3(0.10, 0.025, 0.07)
const EYEWASH_SPOUT_RADIUS: float = 0.010
const EYEWASH_SPOUT_HEIGHT: float = 0.04
const EYEWASH_X_OFFSET: float = 0.18

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_sink()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_sink()


func _read_metadata_overrides() -> void:
	if has_meta("config_sink_width"):
		sink_width = float(str(get_meta("config_sink_width")))
	if has_meta("config_sink_depth"):
		sink_depth = float(str(get_meta("config_sink_depth")))
	if has_meta("config_sink_height"):
		sink_height = float(str(get_meta("config_sink_height")))
	if has_meta("config_basin_depth_factor"):
		basin_depth_factor = float(str(get_meta("config_basin_depth_factor")))
	if has_meta("config_counter_color"):
		counter_color = _parse_color(str(get_meta("config_counter_color")), counter_color)
	if has_meta("config_basin_color"):
		basin_color = _parse_color(str(get_meta("config_basin_color")), basin_color)
	if has_meta("config_faucet_color"):
		faucet_color = _parse_color(str(get_meta("config_faucet_color")), faucet_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_water_color"):
		water_color = _parse_color(str(get_meta("config_water_color")), water_color)
	if has_meta("config_faucet_style"):
		faucet_style = str(get_meta("config_faucet_style")).to_lower()
	if has_meta("config_water_running"):
		var wv := str(get_meta("config_water_running")).to_lower()
		water_running = wv in ["true", "1", "yes", "on"]
	if has_meta("config_eyewash_present"):
		var ev := str(get_meta("config_eyewash_present")).to_lower()
		eyewash_present = ev in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_sink() -> void:
	_built = true
	_build_counter_and_basin()
	_build_faucet()
	_build_valves()
	if water_running:
		_build_water_column()
	if eyewash_present:
		_build_eyewash()
	_build_accent_strip()


func _basin_inner_width() -> float:
	var w: float = sink_width * 0.7
	return w


func _basin_inner_depth() -> float:
	var d: float = sink_depth * 0.6
	return d


func _basin_well_depth() -> float:
	# Cavity depth from the counter top surface downward.
	var bd: float = sink_height * basin_depth_factor
	var max_bd: float = sink_height - COUNTER_THICKNESS - 0.04
	bd = min(bd, max_bd)
	bd = max(0.05, bd)
	return bd


func _build_counter_and_basin() -> void:
	# Counter is built as 4 rim pieces around a basin cavity, so the basin
	# reads as RECESSED rather than as a box sitting on top of the counter.
	var counter_root := Node3D.new()
	counter_root.name = "Counter"
	add_child(counter_root)

	var counter_mat := StandardMaterial3D.new()
	counter_mat.albedo_color = counter_color
	counter_mat.roughness = 0.3
	counter_mat.metallic = 0.1

	var basin_mat := StandardMaterial3D.new()
	basin_mat.albedo_color = basin_color
	basin_mat.roughness = 0.25
	basin_mat.metallic = 0.75

	var top_y: float = sink_height - COUNTER_THICKNESS * 0.5
	var bw: float = _basin_inner_width()
	var bd: float = _basin_inner_depth()
	# Counter rim pieces — front, back, left, right slabs forming a square
	# donut around the basin cutout.
	var front_z: float = sink_depth * 0.5
	var back_z: float = -sink_depth * 0.5
	var rim_front_depth: float = (front_z - (bd * 0.5))
	var rim_back_depth: float = ((-bd * 0.5) - back_z)
	var rim_left_width: float = (sink_width * 0.5 - bw * 0.5)
	# Front rim slab (the closest edge to player, +Z).
	if rim_front_depth > 0.0:
		var f := MeshInstance3D.new()
		f.name = "CounterFront"
		var fm := BoxMesh.new()
		fm.size = Vector3(sink_width, COUNTER_THICKNESS, rim_front_depth)
		f.mesh = fm
		f.material_override = counter_mat
		f.position = Vector3(0.0, top_y, (bd * 0.5) + rim_front_depth * 0.5)
		counter_root.add_child(f)
	# Back rim slab (-Z).
	if rim_back_depth > 0.0:
		var b := MeshInstance3D.new()
		b.name = "CounterBack"
		var bm := BoxMesh.new()
		bm.size = Vector3(sink_width, COUNTER_THICKNESS, rim_back_depth)
		b.mesh = bm
		b.material_override = counter_mat
		b.position = Vector3(0.0, top_y, -(bd * 0.5) - rim_back_depth * 0.5)
		counter_root.add_child(b)
	# Left rim slab (-X).
	if rim_left_width > 0.0:
		var l := MeshInstance3D.new()
		l.name = "CounterLeft"
		var lm := BoxMesh.new()
		lm.size = Vector3(rim_left_width, COUNTER_THICKNESS, bd)
		l.mesh = lm
		l.material_override = counter_mat
		l.position = Vector3(-bw * 0.5 - rim_left_width * 0.5, top_y, 0.0)
		counter_root.add_child(l)
		# Right rim slab (+X)
		var r := MeshInstance3D.new()
		r.name = "CounterRight"
		var rm := BoxMesh.new()
		rm.size = Vector3(rim_left_width, COUNTER_THICKNESS, bd)
		r.mesh = rm
		r.material_override = counter_mat
		r.position = Vector3(bw * 0.5 + rim_left_width * 0.5, top_y, 0.0)
		counter_root.add_child(r)

	# Counter side panels (the "cabinet" below the counter top, two side panels).
	var panel_height: float = sink_height - COUNTER_THICKNESS
	var panel_thickness: float = 0.04
	var z_inset: float = 0.03
	for sign_x in [1, -1]:
		var p := MeshInstance3D.new()
		p.name = "SidePanel_%d" % sign_x
		var pm := BoxMesh.new()
		pm.size = Vector3(panel_thickness, panel_height, sink_depth - z_inset * 2.0)
		p.mesh = pm
		p.material_override = counter_mat
		p.position = Vector3(float(sign_x) * (sink_width * 0.5 - panel_thickness * 0.5), panel_height * 0.5, 0.0)
		counter_root.add_child(p)
	# Counter front panel (the cabinet face the user sees).
	var fp := MeshInstance3D.new()
	fp.name = "CabinetFront"
	var fpm := BoxMesh.new()
	fpm.size = Vector3(sink_width - panel_thickness * 2.0 - 0.005, panel_height, panel_thickness)
	fp.mesh = fpm
	fp.material_override = counter_mat
	fp.position = Vector3(0.0, panel_height * 0.5, sink_depth * 0.5 - panel_thickness * 0.5 - 0.005)
	counter_root.add_child(fp)

	# Basin: built from 4 vertical walls + a floor, sitting INSIDE the
	# counter rim cutout. Top of basin walls = counter top surface.
	var basin_root := Node3D.new()
	basin_root.name = "Basin"
	add_child(basin_root)

	var well_depth: float = _basin_well_depth()
	var top_surface_y: float = sink_height
	var basin_floor_y: float = top_surface_y - well_depth

	# Basin floor slab.
	var bf := MeshInstance3D.new()
	bf.name = "BasinFloor"
	var bfm := BoxMesh.new()
	bfm.size = Vector3(bw, BASIN_WALL_THICKNESS, bd)
	bf.mesh = bfm
	bf.material_override = basin_mat
	bf.position = Vector3(0.0, basin_floor_y + BASIN_WALL_THICKNESS * 0.5, 0.0)
	basin_root.add_child(bf)

	# 4 basin walls (vertical strips).
	var wall_h: float = well_depth - BASIN_WALL_THICKNESS
	if wall_h < 0.02:
		wall_h = 0.02
	var wy: float = basin_floor_y + BASIN_WALL_THICKNESS + wall_h * 0.5
	# Front wall (+Z)
	_make_basin_wall(basin_root, "WallFront", Vector3(bw, wall_h, BASIN_WALL_THICKNESS),
		Vector3(0.0, wy, bd * 0.5 - BASIN_WALL_THICKNESS * 0.5), basin_mat)
	# Back wall (-Z)
	_make_basin_wall(basin_root, "WallBack", Vector3(bw, wall_h, BASIN_WALL_THICKNESS),
		Vector3(0.0, wy, -bd * 0.5 + BASIN_WALL_THICKNESS * 0.5), basin_mat)
	# Left wall (-X)
	_make_basin_wall(basin_root, "WallLeft",
		Vector3(BASIN_WALL_THICKNESS, wall_h, bd - BASIN_WALL_THICKNESS * 2.0),
		Vector3(-bw * 0.5 + BASIN_WALL_THICKNESS * 0.5, wy, 0.0), basin_mat)
	# Right wall (+X)
	_make_basin_wall(basin_root, "WallRight",
		Vector3(BASIN_WALL_THICKNESS, wall_h, bd - BASIN_WALL_THICKNESS * 2.0),
		Vector3(bw * 0.5 - BASIN_WALL_THICKNESS * 0.5, wy, 0.0), basin_mat)


func _make_basin_wall(parent: Node3D, n: String, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var w := MeshInstance3D.new()
	w.name = n
	var m := BoxMesh.new()
	m.size = size
	w.mesh = m
	w.material_override = mat
	w.position = pos
	parent.add_child(w)


func _build_faucet() -> void:
	# Faucet sits at the back of the counter, just behind the basin cutout.
	# Style branches on faucet_style.
	var root := Node3D.new()
	root.name = "Faucet"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = faucet_color
	mat.roughness = 0.25
	mat.metallic = 0.85

	var base_y: float = sink_height
	var faucet_z: float = -_basin_inner_depth() * 0.5 - 0.04

	# Faucet base disc (a short cylinder mounting puck).
	var base := MeshInstance3D.new()
	base.name = "FaucetBase"
	var bm := CylinderMesh.new()
	bm.top_radius = FAUCET_BASE_RADIUS
	bm.bottom_radius = FAUCET_BASE_RADIUS
	bm.height = FAUCET_BASE_HEIGHT
	base.mesh = bm
	base.material_override = mat
	base.position = Vector3(0.0, base_y + FAUCET_BASE_HEIGHT * 0.5, faucet_z)
	root.add_child(base)

	# Vertical pipe.
	var v := MeshInstance3D.new()
	v.name = "VerticalPipe"
	var vm := CylinderMesh.new()
	vm.top_radius = FAUCET_PIPE_RADIUS
	vm.bottom_radius = FAUCET_PIPE_RADIUS
	vm.height = FAUCET_VERTICAL_HEIGHT
	v.mesh = vm
	v.material_override = mat
	var vp_y: float = base_y + FAUCET_BASE_HEIGHT + FAUCET_VERTICAL_HEIGHT * 0.5
	v.position = Vector3(0.0, vp_y, faucet_z)
	root.add_child(v)

	# Spout: swan_neck = curved cylinder pointing +Z;
	# industrial = perpendicular cylinder at the top.
	var top_y: float = base_y + FAUCET_BASE_HEIGHT + FAUCET_VERTICAL_HEIGHT
	if faucet_style == "industrial":
		var spout := MeshInstance3D.new()
		spout.name = "SpoutIndustrial"
		var sm := CylinderMesh.new()
		sm.top_radius = FAUCET_PIPE_RADIUS
		sm.bottom_radius = FAUCET_PIPE_RADIUS
		sm.height = FAUCET_SPOUT_LENGTH
		spout.mesh = sm
		spout.material_override = mat
		# Lay along +Z.
		spout.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		spout.position = Vector3(0.0, top_y - FAUCET_PIPE_RADIUS, faucet_z + FAUCET_SPOUT_LENGTH * 0.5)
		root.add_child(spout)
	else:
		# Swan neck: an elbow (small cylinder at top oriented +Z extending forward,
		# slightly tilted down), forming the curve at the top of the vertical pipe.
		# Use two short cylinders: the upper "arch" + a tilted down-spout at the tip.
		var arch := MeshInstance3D.new()
		arch.name = "SwanArch"
		var am := CylinderMesh.new()
		am.top_radius = FAUCET_PIPE_RADIUS
		am.bottom_radius = FAUCET_PIPE_RADIUS
		am.height = FAUCET_SPOUT_LENGTH
		arch.mesh = am
		arch.material_override = mat
		arch.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		arch.position = Vector3(0.0, top_y + 0.01, faucet_z + FAUCET_SPOUT_LENGTH * 0.5)
		root.add_child(arch)

		# Down-spout: short cylinder dropping below the arch tip, slightly forward.
		var down := MeshInstance3D.new()
		down.name = "SwanDownspout"
		var dm := CylinderMesh.new()
		dm.top_radius = FAUCET_PIPE_RADIUS * 1.05
		dm.bottom_radius = FAUCET_PIPE_RADIUS * 0.9
		dm.height = 0.06
		down.mesh = dm
		down.material_override = mat
		# Cylinder default axis = +Y, so it already hangs down naturally.
		var down_y: float = top_y + 0.01 - 0.03
		var down_z: float = faucet_z + FAUCET_SPOUT_LENGTH - 0.005
		down.position = Vector3(0.0, down_y, down_z)
		root.add_child(down)


func _spout_tip_position() -> Vector3:
	# Returns where the water column should start from.
	var base_y: float = sink_height
	var top_y: float = base_y + FAUCET_BASE_HEIGHT + FAUCET_VERTICAL_HEIGHT
	var faucet_z: float = -_basin_inner_depth() * 0.5 - 0.04
	if faucet_style == "industrial":
		return Vector3(0.0, top_y - FAUCET_PIPE_RADIUS, faucet_z + FAUCET_SPOUT_LENGTH)
	# swan_neck spout tip drops below the arch a bit.
	return Vector3(0.0, top_y - 0.05, faucet_z + FAUCET_SPOUT_LENGTH - 0.005)


func _build_valves() -> void:
	# Two valve handle discs flanking the faucet base.
	var root := Node3D.new()
	root.name = "Valves"
	add_child(root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = faucet_color
	mat.roughness = 0.3
	mat.metallic = 0.8

	var base_y: float = sink_height + FAUCET_BASE_HEIGHT
	var faucet_z: float = -_basin_inner_depth() * 0.5 - 0.04
	for sign_x in [-1, 1]:
		var v := MeshInstance3D.new()
		v.name = "Valve_%d" % sign_x
		var cm := CylinderMesh.new()
		cm.top_radius = VALVE_RADIUS
		cm.bottom_radius = VALVE_RADIUS
		cm.height = VALVE_HEIGHT
		v.mesh = cm
		v.material_override = mat
		v.position = Vector3(float(sign_x) * VALVE_X_OFFSET, base_y + VALVE_HEIGHT * 0.5, faucet_z)
		root.add_child(v)


func _build_water_column() -> void:
	# Thin translucent vertical cylinder from spout tip down into basin floor area.
	var tip: Vector3 = _spout_tip_position()
	var basin_floor_y: float = sink_height - _basin_well_depth() + BASIN_WALL_THICKNESS
	var col_height: float = tip.y - basin_floor_y
	if col_height < 0.02:
		col_height = 0.02
	var water := MeshInstance3D.new()
	water.name = "WaterColumn"
	var wm := CylinderMesh.new()
	wm.top_radius = WATER_COLUMN_RADIUS
	wm.bottom_radius = WATER_COLUMN_RADIUS * 1.3
	wm.height = col_height
	water.mesh = wm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = water_color
	mat.emission_enabled = true
	mat.emission = Color(water_color.r, water_color.g, water_color.b)
	mat.emission_energy_multiplier = 0.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	water.material_override = mat
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.position = Vector3(tip.x, tip.y - col_height * 0.5, tip.z)
	add_child(water)


func _build_eyewash() -> void:
	# Small twin-spout eyewash unit on a base, beside the faucet.
	var root := Node3D.new()
	root.name = "Eyewash"
	add_child(root)

	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.15, 0.65, 0.25)   # safety green base
	base_mat.roughness = 0.4
	base_mat.metallic = 0.2

	var spout_mat := StandardMaterial3D.new()
	spout_mat.albedo_color = faucet_color
	spout_mat.roughness = 0.3
	spout_mat.metallic = 0.85

	var base_y: float = sink_height
	var faucet_z: float = -_basin_inner_depth() * 0.5 - 0.04
	var unit_x: float = EYEWASH_X_OFFSET

	# Eyewash base block.
	var base := MeshInstance3D.new()
	base.name = "EyewashBase"
	var bm := BoxMesh.new()
	bm.size = EYEWASH_BASE_SIZE
	base.mesh = bm
	base.material_override = base_mat
	base.position = Vector3(unit_x, base_y + EYEWASH_BASE_SIZE.y * 0.5, faucet_z + 0.02)
	root.add_child(base)

	# Two upward spouts.
	for sign_x in [-1, 1]:
		var sp := MeshInstance3D.new()
		sp.name = "EyewashSpout_%d" % sign_x
		var cm := CylinderMesh.new()
		cm.top_radius = EYEWASH_SPOUT_RADIUS
		cm.bottom_radius = EYEWASH_SPOUT_RADIUS * 1.1
		cm.height = EYEWASH_SPOUT_HEIGHT
		sp.mesh = cm
		sp.material_override = spout_mat
		sp.position = Vector3(
			unit_x + float(sign_x) * (EYEWASH_BASE_SIZE.x * 0.25),
			base_y + EYEWASH_BASE_SIZE.y + EYEWASH_SPOUT_HEIGHT * 0.5,
			faucet_z + 0.02
		)
		root.add_child(sp)


func _build_accent_strip() -> void:
	# Thin emissive accent stripe along the front edge of the counter (+Z).
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(sink_width * 0.96, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_THICKNESS)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var y: float = sink_height - COUNTER_THICKNESS - ACCENT_STRIP_HEIGHT * 0.5 - 0.002
	var z: float = sink_depth * 0.5 + ACCENT_STRIP_THICKNESS * 0.5
	strip.position = Vector3(0.0, y, z)
	add_child(strip)


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

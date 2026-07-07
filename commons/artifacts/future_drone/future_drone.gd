extends Node3D
class_name FutureDrone

# @identity
# essence: a derelict machine in the shape of a mushroom — a wide shallow domed metal cap on top, riveted in radial plates, sitting over a thin mechanical stalk that bristles with hardware: a capped canister, disc flanges and a spoked valve wheel, a small dish gauge facing out, a caged wire grille, drooping cables (one a bright failing-yellow), and at the floor a 90-degree pipe elbow with a round flange. Everything is eaten by rust. The drone does not hum; it has stopped. It is the lab's confession that machines outlive their function — that the future, too, becomes scrap.
# desire: every clean instrument pretends it will work forever. The future_drone wants to be the OPPOSITE — the device AFTER the experiment, the beacon nobody answers, the probe left in the field until the metal browned. It wants to read as time-passed, as abandonment, as a silhouette that was once purposeful and is now only weather. Even derelict it implies a former mission: a dish that listened, a valve that regulated, a cap that sheltered.
# critical_parameter: cap_radius / stalk_height + the rust palette — a wide cap over a short stalk reads as a SQUAT DERELICT BEACON, a roadside relic; a small cap over a tall stalk reads as a SLENDER PROBE, an antenna left standing. The rust_color vs steel_color balance sets the decommission: deep brown everywhere = long-abandoned; cooler steel showing through = recently failed, still half-maintained.
# triggers: _ready() builds the domed cap + radial seams + hub, the central stalk, the canister, flanges + valve wheel, the dish gauge, the wire grille, the drooping cables, and the bottom pipe elbow with flange from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single drone in a corner reads as ABANDONED SITE — something happened here and left. A wide-capped rusted one reads as MONUMENT to a dead program. A tall thin one reads as a SENTINEL nobody recalled. The bright yellow cable, the one accent of saturated color, reads as the last live wire — the thing that should have carried signal and now carries nothing. The drone is a temporal marker pointed the other way from the crate: not arrival, but afterlife.
# needs: wide shallow domed cap with radial seam plates and a hub [present]; thin central stalk pipe to the floor [present]; capped canister beside the stalk [present]; disc flanges and a spoked valve wheel [present]; small dish gauge on an arm [present]; caged wire grille panel [present]; drooping cables incl. one bright accent [present]; bottom 90-degree pipe elbow with flange [present]; heavily rusted metal materials [present]
# relationships: counterpart to crate (the crate is ARRIVAL, sealed and inbound; the drone is AFTERLIFE, opened and outbound to scrap); cousin to fire_extinguisher (both are industrial-corridor vocabulary, but the extinguisher is at-the-ready and the drone is past-its-use); peer to any beacon or antenna artifact (the drone is what the beacon becomes when the signal stops).
# truth: a derelict drone is the architectural form of OBSOLESCENCE. By placing it, the space confesses that its machines have a lifespan — that the future is not a clean room but a field of rusting equipment. The dome once sheltered electronics; now it sheds rain. The dish once listened; now it stares at nothing. Rust is not decoration — rust is time made visible on metal, the slow proof that even the apparatus of progress is mortal.

## A derelict, heavily-rusted future drone shaped like a mushroom.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE —
## the bottom pipe elbow rests at (0,0,0) and the domed cap is at the top.
## Total height is roughly 1.6m with a cap roughly 1.8m across. The front
## (the dish gauge / grille side) faces +X; the silhouette reads from +Z.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
## Radius of the wide shallow domed cap. Drives the mushroom silhouette.
@export var cap_radius: float = 0.9
## Height of the central stalk pipe from just under the cap to the floor.
@export var stalk_height: float = 1.1

@export_group("Material")
## Heavily-rusted brown — the dominant decommissioned-metal color.
@export var rust_color: Color = Color(0.42, 0.30, 0.20)
## Darker bluish steel — pipes, grille, valves that still read as metal.
@export var steel_color: Color = Color(0.28, 0.30, 0.34)
## Bright accent (failing yellow) for the one live-looking cable.
@export var accent_color: Color = Color(0.9, 0.85, 0.2)

@export_group("Hardware")
## Show the caged wire grille panel on the stalk.
@export var show_grille: bool = true
## Show the capped canister beside the central stalk.
@export var show_canister: bool = true

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_cap_radius"):
		cap_radius = float(str(get_meta("config_cap_radius")))
	if has_meta("config_stalk_height"):
		stalk_height = float(str(get_meta("config_stalk_height")))
	if has_meta("config_rust_color"):
		rust_color = _parse_color(str(get_meta("config_rust_color")), rust_color)
	if has_meta("config_steel_color"):
		steel_color = _parse_color(str(get_meta("config_steel_color")), steel_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_show_grille"):
		var sg: String = str(get_meta("config_show_grille")).to_lower()
		show_grille = sg == "true" or sg == "1" or sg == "yes"
	if has_meta("config_show_canister"):
		var sc: String = str(get_meta("config_show_canister")).to_lower()
		show_canister = sc == "true" or sc == "1" or sc == "yes"


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	# Shared materials.
	var rust_mat := _make_rust_mat(rust_color)
	var steel_mat := _make_steel_mat(steel_color)
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = accent_color
	accent_mat.roughness = 0.6
	accent_mat.metallic = 0.2

	# The cap sits at the very top; the stalk runs from just under it to the
	# floor. cap_y is the underside plane of the dome.
	var cap_y: float = stalk_height

	_build_cap(cap_y, rust_mat)
	_build_stalk(cap_y, steel_mat)
	if show_canister:
		_build_canister(cap_y, rust_mat)
	_build_flanges(rust_mat)
	_build_valve_wheel(steel_mat)
	_build_dish(steel_mat)
	if show_grille:
		_build_grille(steel_mat)
	_build_cables(cap_y, steel_mat, accent_mat)
	_build_bottom_elbow(steel_mat)


# ── Cap (top dome) ────────────────────────────────────────────────────

func _build_cap(cap_y: float, rust_mat: StandardMaterial3D) -> void:
	var cap_root := Node3D.new()
	cap_root.name = "Cap"
	cap_root.position = Vector3(0.0, cap_y, 0.0)
	add_child(cap_root)

	# Wide shallow DOME — a sphere flattened on Y so it reads as a domed
	# disc. Its flat underside sits at cap_y (the sphere is centred there
	# and we keep only the top half by sinking the lower half just below).
	var dome := MeshInstance3D.new()
	dome.name = "Dome"
	var sphere := SphereMesh.new()
	sphere.radius = cap_radius
	sphere.height = cap_radius * 2.0
	dome.mesh = sphere
	dome.material_override = rust_mat
	# Flatten to a shallow dome; the cap reads ~0.32 of its radius tall.
	dome.scale = Vector3(1.0, 0.32, 1.0)
	cap_root.add_child(dome)

	# A thin rim disc just under the dome's edge to close the silhouette.
	var rim := MeshInstance3D.new()
	rim.name = "CapRim"
	var rm := CylinderMesh.new()
	rm.top_radius = cap_radius * 0.98
	rm.bottom_radius = cap_radius * 0.92
	rm.height = cap_radius * 0.06
	rim.mesh = rm
	rim.material_override = rust_mat
	rim.position = Vector3(0.0, -cap_radius * 0.03, 0.0)
	cap_root.add_child(rim)

	# 6 thin radial SEAM boxes across the top for the riveted-plate look.
	var seam_count: int = 6
	var seam_h: float = cap_radius * 0.34
	for i in range(seam_count):
		var seam := MeshInstance3D.new()
		seam.name = "Seam_%d" % i
		var sm := BoxMesh.new()
		sm.size = Vector3(cap_radius * 1.92, 0.012, 0.03)
		seam.mesh = sm
		seam.material_override = rust_mat
		var ang: float = float(i) / float(seam_count) * PI   # 0..180, mirrored bars
		seam.rotation = Vector3(0.0, ang, 0.0)
		seam.position = Vector3(0.0, seam_h * 0.5, 0.0)
		cap_root.add_child(seam)

	# A small raised hub disc at the very top centre.
	var hub := MeshInstance3D.new()
	hub.name = "CapHub"
	var hm := CylinderMesh.new()
	hm.top_radius = cap_radius * 0.18
	hm.bottom_radius = cap_radius * 0.22
	hm.height = cap_radius * 0.10
	hub.mesh = hm
	hub.material_override = rust_mat
	hub.position = Vector3(0.0, cap_radius * 0.34, 0.0)
	cap_root.add_child(hub)


# ── Central stalk ─────────────────────────────────────────────────────

func _build_stalk(cap_y: float, steel_mat: StandardMaterial3D) -> void:
	var stalk := MeshInstance3D.new()
	stalk.name = "Stalk"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.06
	cm.bottom_radius = 0.07
	cm.height = stalk_height
	stalk.mesh = cm
	stalk.material_override = steel_mat
	# Runs from the floor up to just under the cap.
	stalk.position = Vector3(0.0, stalk_height * 0.5, 0.0)
	add_child(stalk)


# ── Canister ──────────────────────────────────────────────────────────

func _build_canister(cap_y: float, rust_mat: StandardMaterial3D) -> void:
	var canister := Node3D.new()
	canister.name = "Canister"
	# Beside the central pipe (toward -Z), high on the stalk near the cap.
	var cx: float = -0.13
	var cz: float = -0.04
	var body_h: float = 0.35
	var body_r: float = 0.09
	var top_y: float = cap_y - 0.10
	var center_y: float = top_y - body_h * 0.5
	canister.position = Vector3(cx, 0.0, cz)
	add_child(canister)

	var body := MeshInstance3D.new()
	body.name = "CanisterBody"
	var cm := CylinderMesh.new()
	cm.top_radius = body_r
	cm.bottom_radius = body_r
	cm.height = body_h
	body.mesh = cm
	body.material_override = rust_mat
	body.position = Vector3(0.0, center_y, 0.0)
	canister.add_child(body)

	# Domed top cap on the canister.
	var top_cap := MeshInstance3D.new()
	top_cap.name = "CanisterCap"
	var sphere := SphereMesh.new()
	sphere.radius = body_r
	sphere.height = body_r * 2.0
	top_cap.mesh = sphere
	top_cap.material_override = rust_mat
	top_cap.scale = Vector3(1.0, 0.5, 1.0)
	top_cap.position = Vector3(0.0, top_y, 0.0)
	canister.add_child(top_cap)

	# Flat bottom cap (thin disc).
	var bot_cap := MeshInstance3D.new()
	bot_cap.name = "CanisterBase"
	var bm := CylinderMesh.new()
	bm.top_radius = body_r * 1.05
	bm.bottom_radius = body_r * 1.05
	bm.height = 0.02
	bot_cap.mesh = bm
	bot_cap.material_override = rust_mat
	bot_cap.position = Vector3(0.0, top_y - body_h, 0.0)
	canister.add_child(bot_cap)


# ── Flanges along the central pipe ────────────────────────────────────

func _build_flanges(rust_mat: StandardMaterial3D) -> void:
	# 4 short wide disc flanges spaced along the stalk.
	var ys: Array = [
		stalk_height * 0.20,
		stalk_height * 0.45,
		stalk_height * 0.68,
		stalk_height * 0.88,
	]
	for i in range(ys.size()):
		var flange := MeshInstance3D.new()
		flange.name = "Flange_%d" % i
		var fm := CylinderMesh.new()
		fm.top_radius = 0.105
		fm.bottom_radius = 0.105
		fm.height = 0.022
		flange.mesh = fm
		flange.material_override = rust_mat
		flange.position = Vector3(0.0, float(ys[i]), 0.0)
		add_child(flange)


# ── Valve wheel ───────────────────────────────────────────────────────

func _build_valve_wheel(steel_mat: StandardMaterial3D) -> void:
	var valve := Node3D.new()
	valve.name = "ValveWheel"
	# On the +Z side, mid-stalk, standing vertically (face along Z).
	valve.position = Vector3(0.0, stalk_height * 0.55, 0.18)
	# Rotate so the torus ring stands up facing +Z (default torus lies in XZ).
	valve.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	add_child(valve)

	var ring := MeshInstance3D.new()
	ring.name = "ValveRing"
	var tm := TorusMesh.new()
	tm.inner_radius = 0.085
	tm.outer_radius = 0.12
	ring.mesh = tm
	ring.material_override = steel_mat
	valve.add_child(ring)

	# 3 thin spoke boxes across the wheel (in the ring's local XZ plane).
	var spoke_count: int = 3
	for i in range(spoke_count):
		var spoke := MeshInstance3D.new()
		spoke.name = "ValveSpoke_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(0.21, 0.016, 0.016)
		spoke.mesh = bm
		spoke.material_override = steel_mat
		var ang: float = float(i) / float(spoke_count) * PI   # 0..180, mirrored spokes
		spoke.rotation = Vector3(0.0, ang, 0.0)
		valve.add_child(spoke)

	# Small hub at the centre of the wheel.
	var hub := MeshInstance3D.new()
	hub.name = "ValveHub"
	var hm := CylinderMesh.new()
	hm.top_radius = 0.03
	hm.bottom_radius = 0.03
	hm.height = 0.04
	hub.mesh = hm
	hub.material_override = steel_mat
	valve.add_child(hub)


# ── Dish / gauge ──────────────────────────────────────────────────────

func _build_dish(steel_mat: StandardMaterial3D) -> void:
	var dish_root := Node3D.new()
	dish_root.name = "Dish"
	# On a short arm reaching out toward +X (the front).
	var arm_y: float = stalk_height * 0.72
	dish_root.position = Vector3(0.0, arm_y, 0.0)
	add_child(dish_root)

	# Short arm from the stalk to the dish.
	var arm := MeshInstance3D.new()
	arm.name = "DishArm"
	var am := CylinderMesh.new()
	am.top_radius = 0.018
	am.bottom_radius = 0.018
	am.height = 0.14
	arm.mesh = am
	arm.material_override = steel_mat
	# Lay the arm horizontal pointing +X.
	arm.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	arm.position = Vector3(0.12, 0.0, 0.0)
	dish_root.add_child(arm)

	# The dish itself — a small disc facing out (+X).
	var dish := MeshInstance3D.new()
	dish.name = "DishFace"
	var dm := CylinderMesh.new()
	dm.top_radius = 0.10
	dm.bottom_radius = 0.10
	dm.height = 0.025
	dish.mesh = dm
	dish.material_override = steel_mat
	# Face the disc along +X (default cylinder axis is +Y).
	dish.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	dish.position = Vector3(0.20, 0.0, 0.0)
	dish_root.add_child(dish)


# ── Wire grille (caged panel) ─────────────────────────────────────────

func _build_grille(steel_mat: StandardMaterial3D) -> void:
	var grille := Node3D.new()
	grille.name = "Grille"
	# On the -X side, lower-mid stalk, facing out (-X).
	var panel_w: float = 0.18
	var panel_h: float = 0.28
	var gy: float = stalk_height * 0.38
	grille.position = Vector3(-0.12, gy, 0.0)
	add_child(grille)

	var bar_t: float = 0.012

	# Frame: 4 thin boxes around the rectangle (in the YZ plane, facing -X).
	# Top and bottom rails (run along Z).
	for sign_y in [1.0, -1.0]:
		var rail := MeshInstance3D.new()
		rail.name = "GrilleRailH"
		var bm := BoxMesh.new()
		bm.size = Vector3(bar_t, bar_t, panel_w)
		rail.mesh = bm
		rail.material_override = steel_mat
		rail.position = Vector3(0.0, sign_y * panel_h * 0.5, 0.0)
		grille.add_child(rail)
	# Left and right rails (run along Y).
	for sign_z in [1.0, -1.0]:
		var rail2 := MeshInstance3D.new()
		rail2.name = "GrilleRailV"
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(bar_t, panel_h, bar_t)
		rail2.mesh = bm2
		rail2.material_override = steel_mat
		rail2.position = Vector3(0.0, 0.0, sign_z * panel_w * 0.5)
		grille.add_child(rail2)

	# 3 thin crossing bars inside (horizontal, run along Z).
	var cross_count: int = 3
	for i in range(cross_count):
		var bar := MeshInstance3D.new()
		bar.name = "GrilleBar_%d" % i
		var bm3 := BoxMesh.new()
		bm3.size = Vector3(bar_t * 0.7, bar_t * 0.7, panel_w)
		bar.mesh = bm3
		bar.material_override = steel_mat
		var t: float = float(i + 1) / float(cross_count + 1)
		var y: float = lerp(-panel_h * 0.5, panel_h * 0.5, t)
		bar.position = Vector3(0.0, y, 0.0)
		grille.add_child(bar)


# ── Cables ────────────────────────────────────────────────────────────

func _build_cables(cap_y: float, steel_mat: StandardMaterial3D,
		accent_mat: StandardMaterial3D) -> void:
	var cables := Node3D.new()
	cables.name = "Cables"
	add_child(cables)

	# 3 drooping cables sagging from near the cap edge down to the stalk.
	# Each is two short angled segments forming a sag. One is the accent.
	# (start_offset on the cap rim, mid sag point, mats).
	var specs: Array = [
		{ "x": 0.55, "z": 0.20, "mat": steel_mat },
		{ "x": -0.45, "z": 0.30, "mat": accent_mat },
		{ "x": 0.30, "z": -0.45, "mat": steel_mat },
	]
	for i in range(specs.size()):
		var spec: Dictionary = specs[i]
		var top: Vector3 = Vector3(spec["x"], cap_y - 0.06, spec["z"])
		# Cable sags toward the stalk and downward.
		var stalk_anchor: Vector3 = Vector3(0.04, cap_y * 0.55, 0.04)
		var sag: Vector3 = Vector3(
			(top.x + stalk_anchor.x) * 0.5,
			lerp(top.y, stalk_anchor.y, 0.5) - 0.12,
			(top.z + stalk_anchor.z) * 0.5)
		_add_cable_segment(cables, "Cable_%d_a" % i, top, sag, spec["mat"])
		_add_cable_segment(cables, "Cable_%d_b" % i, sag, stalk_anchor, spec["mat"])


# Build one cable segment as a cylinder spanning a -> b.
func _add_cable_segment(parent: Node3D, seg_name: String,
		a: Vector3, b: Vector3, mat: StandardMaterial3D) -> void:
	var delta: Vector3 = b - a
	var length: float = delta.length()
	if length < 0.0001:
		return
	var seg := MeshInstance3D.new()
	seg.name = seg_name
	var cm := CylinderMesh.new()
	cm.top_radius = 0.014
	cm.bottom_radius = 0.014
	cm.height = length
	seg.mesh = cm
	seg.material_override = mat
	seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Orient local +Y along delta.
	var up: Vector3 = delta.normalized()
	var ref: Vector3 = Vector3(0.0, 0.0, 1.0)
	if abs(up.dot(ref)) > 0.95:
		ref = Vector3(1.0, 0.0, 0.0)
	var side: Vector3 = up.cross(ref).normalized()
	var fwd: Vector3 = side.cross(up).normalized()
	seg.transform.basis = Basis(side, up, fwd)
	seg.position = a + up * (length * 0.5)
	parent.add_child(seg)


# ── Bottom pipe elbow ─────────────────────────────────────────────────

func _build_bottom_elbow(steel_mat: StandardMaterial3D) -> void:
	var elbow := Node3D.new()
	elbow.name = "BottomElbow"
	add_child(elbow)

	var pipe_r: float = 0.07

	# Vertical pipe segment rising from the floor (meets the stalk base).
	var vert_h: float = 0.18
	var vert := MeshInstance3D.new()
	vert.name = "ElbowVertical"
	var vm := CylinderMesh.new()
	vm.top_radius = pipe_r
	vm.bottom_radius = pipe_r
	vm.height = vert_h
	vert.mesh = vm
	vert.material_override = steel_mat
	vert.position = Vector3(0.0, vert_h * 0.5, 0.0)
	elbow.add_child(vert)

	# Corner sphere at the bend.
	var bend := MeshInstance3D.new()
	bend.name = "ElbowBend"
	var bs := SphereMesh.new()
	bs.radius = pipe_r * 1.05
	bs.height = pipe_r * 2.1
	bend.mesh = bs
	bend.material_override = steel_mat
	bend.position = Vector3(0.0, vert_h, 0.0)
	elbow.add_child(bend)

	# Horizontal pipe segment running out toward +X.
	var horiz_len: float = 0.30
	var horiz := MeshInstance3D.new()
	horiz.name = "ElbowHorizontal"
	var hm := CylinderMesh.new()
	hm.top_radius = pipe_r
	hm.bottom_radius = pipe_r
	hm.height = horiz_len
	horiz.mesh = hm
	horiz.material_override = steel_mat
	# Lay it horizontal pointing +X.
	horiz.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	horiz.position = Vector3(horiz_len * 0.5, vert_h, 0.0)
	elbow.add_child(horiz)

	# Round flange disc at the horizontal opening (+X end).
	var flange := MeshInstance3D.new()
	flange.name = "ElbowFlange"
	var fm := CylinderMesh.new()
	fm.top_radius = pipe_r * 1.6
	fm.bottom_radius = pipe_r * 1.6
	fm.height = 0.03
	flange.mesh = fm
	flange.material_override = steel_mat
	# Face the flange along +X.
	flange.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	flange.position = Vector3(horiz_len, vert_h, 0.0)
	elbow.add_child(flange)


# ── Material helpers ──────────────────────────────────────────────────

func _make_rust_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.92
	m.metallic = 0.3
	return m


func _make_steel_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.7
	m.metallic = 0.6
	return m

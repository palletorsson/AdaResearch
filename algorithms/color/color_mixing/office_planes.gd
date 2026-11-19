extends RefCounted
## Open partition score for Color_Walls, with tripod work lights and no enclosure.
## One QuadMesh per pane: the tint is applied once, from either side.
## Its thin box collider stays present in filter, additive-light, and opaque modes.

const PANES := [
	# x, z, yaw, width, height, colour; gaps are part of the score.
	[-2.65,-4.70,90.0,3.6,3.55,"39e7ee"],
	[2.80,-4.40,90.0,4.0,3.55,"ffe82f"],
	[-2.10,-1.90,0.0,4.8,3.10,"f431ba"],
	[2.10,0.50,0.0,4.8,3.30,"5075f5"],
	[-3.20,2.00,90.0,4.0,3.50,"67e9ec"],
	[-2.00,3.10,0.0,4.6,3.00,"fae54a"],
	[2.80,2.70,90.0,3.6,3.50,"54df70"],
	[-2.20,5.80,15.0,3.0,3.20,"ef66c0"],
	[-4.05,-5.20,-15.0,1.6,2.85,"fc805d"],
	[4.00,-5.10,15.0,1.6,2.85,"6987f4"],
	[2.20,5.95,0.0,3.8,3.45,"78dee6"],
	[-4.10,3.90,32.0,1.4,2.75,"fbb268"],
]

## Maximized 24-pane constellation under color_constellation_office's own logic:
## wider 12.2 x 15.0 m open field (notched clear of structural columns at +/-5, +/-7),
## taller 3.70..4.70 m panes, central 60-degree RGB additive prism triad, and
## multi-corridor CMY/RGB wing intersections — all with >= 1.25 m walkable gaps.
const EXPANDED_PANES := [
	# 0..11 Core 12 enlarged in height & span
	[-3.10, -5.00, 90.0, 3.8, 4.45, "19e8f5"],
	[ 3.15, -4.75, 90.0, 4.1, 4.55, "ffeb24"],
	[-2.45, -2.05,  0.0, 5.1, 4.05, "ff24b8"],
	[ 2.45,  0.55,  0.0, 5.1, 4.25, "3b6bff"],
	[-3.65,  2.10, 90.0, 4.2, 4.50, "4beeff"],
	[-2.20,  3.35,  0.0, 4.9, 3.95, "ffe336"],
	[ 3.20,  2.85, 90.0, 3.9, 4.45, "2ce862"],
	[-2.35,  6.20, 16.0, 3.1, 4.15, "ff47b3"],
	[-3.60, -5.55,-18.0, 1.9, 3.70, "ff6938"],
	[ 3.55, -5.45, 18.0, 1.9, 3.70, "5978ff"],
	[ 2.25,  6.30,  0.0, 3.5, 4.35, "4be8f2"],
	[-4.65,  4.20, 32.0, 1.9, 3.75, "ff9c38"],
	# 12..14 Central 60-degree RGB triad (sums toward luminous white core in LIGHT mode!)
	[-0.95, -0.75, 60.0, 2.5, 4.70, "ff2442"],
	[ 0.00, -0.55, 60.0, 2.5, 4.70, "1ee860"],
	[ 0.95, -0.35, 60.0, 2.5, 4.70, "2660ff"],
	# 15..23 Flanking CMY/spectral wing filters & entry prisms (4-5x overlapping depth)
	[-5.55, -2.70, 90.0, 3.9, 4.65, "ff2b9c"],
	[-5.55,  2.05, 90.0, 3.9, 4.55, "ffe824"],
	[ 5.55, -2.55, 90.0, 3.9, 4.65, "00e8ff"],
	[ 5.55,  2.20, 90.0, 3.9, 4.55, "9c42ff"],
	[-0.20, -4.15,-22.0, 3.6, 4.20, "00e5a8"],
	[ 0.35,  4.65, 22.0, 3.6, 4.25, "ff622b"],
	[-1.40, -6.55,-14.0, 2.8, 3.85, "943cff"],
	[ 1.75, -6.55, 14.0, 2.8, 3.85, "00e8ff"],
	[ 4.65, -4.10,-32.0, 1.9, 3.80, "ff3878"],
]

static func build(office: Node3D) -> void:
	office.office_panes.clear()
	office.floor_washes.clear()
	office.extra_panes.clear()
	office.extra_washes.clear()
	office.glass_visible = true
	office.plane_mode = 0
	office.expanded_density = true
	var expanded: bool = bool(office.get_meta("config_expanded", false))
	var score: Array = EXPANDED_PANES if expanded else PANES

	if expanded:
		# Clean neutral pale architectural ground sized to the larger 12.2 x 15.0 m field
		# (split cleanly as a wide central bay + N/S tongues to stay clear of +/-5, +/-7 columns).
		office._office_box(office, "QuietFloor", Vector3(0, 0.009, 0.0), Vector3(12.2, 0.018, 12.2), Color("e5e0d7"), false)
		office._office_box(office, "QuietFloorNorth", Vector3(0, 0.009, 6.85), Vector3(8.6, 0.018, 1.8), Color("e5e0d7"), false)
		office._office_box(office, "QuietFloorSouth", Vector3(0, 0.009, -6.85), Vector3(8.6, 0.018, 1.8), Color("e5e0d7"), false)
	else:
		office._office_box(office, "QuietFloor", Vector3(0, 0.009, -0.1), Vector3(9.8, 0.018, 13.4), Color("e3ded4"), false)

	for background in office.get_children():
		if background is MeshInstance3D:
			# Neutral display backing, independent of the dark museum sky.
			background.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			background.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for i in score.size():
		add_pane(office, score[i], i, expanded)

	if expanded:
		# 6 Tripod Work Lights aimed across all RGB/CMY filter zones (each >= 0.90 m clear of all 24 panes)
		work_light(office, Vector3(-4.50, 0.018, -3.20), -65.0, 0, 4.2, 8.5)
		work_light(office, Vector3( 4.35, 0.018, -2.10),  65.0, 1, 4.2, 8.5)
		work_light(office, Vector3(-4.55, 0.018,  0.15), -90.0, 2, 4.2, 8.5)
		work_light(office, Vector3( 4.35, 0.018,  1.65),  90.0, 3, 4.2, 8.5)
		work_light(office, Vector3(-3.75, 0.018,  5.25),  25.0, 4, 4.0, 8.0)
		work_light(office, Vector3( 4.10, 0.018,  5.30), -25.0, 5, 4.0, 8.0)
		office.set_meta("em_visibility_bounds", AABB(Vector3(-6.4, 0, -8.2), Vector3(12.8, 5.1, 16.4)))
	else:
		work_light(office, Vector3(-3.85, 0.018, -3.55), -90, 0, 3.5, 6.0)
		work_light(office, Vector3(3.95, 0.018, 1.7), 90, 1, 3.5, 6.0)
		work_light(office, Vector3(-3.5, 0.018, 5.0), 0, 2, 3.5, 6.0)
		office.set_meta("em_visibility_bounds", AABB(Vector3(-5.5, 0, -8.5), Vector3(11, 4.3, 16.2)))

	if str(office.get_meta("config_compare",""))=="visibility":
		var controls: Node3D = load("res://commons/ui/control_panel.gd").new()
		controls.name = "VisibilityConsole"
		controls.title = "A VIEW / A WAY THROUGH"
		var cpos := Vector3(-3.45, 1.1, -7.35) if expanded else Vector3(-3.8, 1.1, -7.55)
		controls.position = cpos
		controls.rotation_degrees.y = 180
		office.add_child(controls)
		if expanded:
			office.glass_button = controls.add_button("FILTER / LIGHT / OPAQUE")
			office.glass_button.pressed.connect(office.toggle_office_glass)
			var dens_btn: Node3D = controls.add_button("24 FULL / 12 CORE")
			dens_btn.pressed.connect(office.toggle_office_density)
			office.glass_readout = controls.add_readout("FILTER • 24 PANES / SAME PASSAGES")
		else:
			office.glass_button = controls.add_button("FILTER / OPAQUE")
			office.glass_button.pressed.connect(office.toggle_office_glass)
			office.glass_readout = controls.add_readout("FILTER / SAME PASSAGES")
		office._office_box(office, "VisibilityPlinth", Vector3(cpos.x, 0.45, cpos.z), Vector3(1.15 if expanded else 0.8, 0.9, 0.6), Color("dcd8d1"))

static func add_pane(office: Node3D, spec: Array, index: int, expanded: bool = false) -> void:
	var width: float = float(spec[3])
	var height: float = float(spec[4])
	var colour := Color(str(spec[5]))
	var pane := MeshInstance3D.new()
	pane.name = "FilterPane_%02d" % index
	var mesh := QuadMesh.new()
	mesh.size = Vector2(width, height)
	pane.mesh = mesh
	pane.position = Vector3(float(spec[0]), height * 0.5 + 0.025, float(spec[1]))
	pane.rotation_degrees.y = float(spec[2])
	var surface := StandardMaterial3D.new()
	surface.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	surface.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# The background already receives the museum fog; keep each tint clear.
	surface.disable_fog = true
	surface.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.albedo_color = colour
	surface.albedo_color.a = 0.54 if expanded else 0.52
	surface.roughness = 0.18
	pane.material_override = surface
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var body := StaticBody3D.new()
	body.name = "PaneBody"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, height, 0.035)
	collision.shape = shape
	body.add_child(collision)
	pane.add_child(body)
	office.add_child(pane)
	office.office_panes.append(pane)
	if expanded and index >= 12:
		office.extra_panes.append(pane)

	# Fine luminous edges make a transparent obstacle visible without outlining a cube.
	var edge_colour := colour.lightened(0.48)
	for x in [-width * 0.5, width * 0.5]:
		var edge: MeshInstance3D = office._office_box(pane, "GlassEdge", Vector3(x, 0, 0), Vector3(0.022 if expanded else 0.018, height, 0.026 if expanded else 0.024), edge_colour, false)
		if expanded and edge != null:
			var emat: StandardMaterial3D = edge.material_override as StandardMaterial3D
			if emat != null:
				emat.emission_enabled = true
				emat.emission = edge_colour
				emat.emission_energy_multiplier = 0.45
		office._office_box(pane, "Foot", Vector3(x, -height * 0.5 + 0.04, 0), Vector3(0.14, 0.08, 0.34), Color("b5b6b6"), false)

	# Transmitted chromatic floor wash (light-through-filter pool on the pale QuietFloor!)
	# Overlaps directly with neighbouring pane pools to show live colour mixing on the floor.
	if expanded:
		var wash := MeshInstance3D.new()
		wash.name = "FloorColorWash_%02d" % index
		var wquad := QuadMesh.new()
		wquad.size = Vector2(width * 0.98, 2.35)
		wash.mesh = wquad
		wash.rotation_degrees = Vector3(-90.0, float(spec[2]), 0.0)
		var yaw_rad := deg_to_rad(float(spec[2]))
		var cast_dir := Vector3(sin(yaw_rad), 0.0, cos(yaw_rad))
		var side_sign := -1.0 if (index % 2 == 0) else 1.0
		wash.position = Vector3(float(spec[0]), 0.021 + float(index % 5) * 0.0012, float(spec[1])) + cast_dir * (1.12 * side_sign)
		var wmat := StandardMaterial3D.new()
		wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wmat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		wmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		wmat.disable_fog = true
		wmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		wmat.albedo_color = Color(colour.r, colour.g, colour.b, 0.26)
		wash.material_override = wmat
		wash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		office.add_child(wash)
		office.floor_washes.append(wash)
		if index >= 12:
			office.extra_washes.append(wash)

static func work_light(office: Node3D, at: Vector3, yaw: float, index: int, energy: float = 3.5, range_m: float = 6.0) -> void:
	var lamp: Node3D = preload("res://commons/artifacts/construction_site/work_light.tscn").instantiate()
	lamp.name = "TripodWorkLight_%d" % index
	lamp.position = at
	lamp.rotation_degrees.y = yaw
	lamp.beam_energy = energy
	lamp.beam_range = range_m
	office.add_child(lamp)

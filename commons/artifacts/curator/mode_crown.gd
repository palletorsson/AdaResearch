extends Node3D
class_name CuratorModeCrown

# @identity
# essence: THE CROWN display mode — the room bows to one thing. A dark inverted canopy with a glowing underside hovers above the anchor's cell, a dais gathers the floor beneath it, a single downlight makes the object own its shadows. After the Grand Egyptian Museum's pharaoh.
# desire: to spend a whole room's attention on a single artifact — reverence as light rig.
# critical_parameter: span — canopy width (fit the anchor); the anchor itself is placed by the compiler at the same cell, this kit only builds the architecture of attention around it.
# triggers: _ready builds canopy + dais + light; apply_grid_config({span, height}) resizes.
# emerges: sightlines resolve on whatever stands beneath — the crown declares importance before the visitor can read a label.
# needs: nothing; purely architectural. Pairs with any anchor artifact.
# relationships: mode-kit 1 of the Curator's display grammar; sibling of [[mode_dialogue]] and [[mode_witness_wall]]; assigned to argument-role ANCHOR.
# truth: importance is not a property of objects; it is a decision a room makes. The crown is that decision, built.

@export var span: float = 6.0
@export var hover_height: float = 4.2

func _ready() -> void:
	_read_meta_overrides()
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_meta_overrides()

func _read_meta_overrides() -> void:
	if has_meta("config_span"):
		span = float(str(get_meta("config_span")))
	if has_meta("config_height"):
		hover_height = float(str(get_meta("config_height")))

func _build() -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.07, 0.06, 0.08)
	dark.roughness = 0.4
	dark.metallic = 0.3

	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(0.98, 0.95, 0.86)
	glow.emission_enabled = true
	glow.emission = Color(0.98, 0.93, 0.8)
	glow.emission_energy_multiplier = 1.6
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# the canopy: an inverted truncated pyramid of four dark sloped panels
	var top_w := span
	var bot_w := span * 0.55
	var depth := 1.6
	for i in 4:
		var ang := float(i) * 90.0
		var panel := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(top_w, depth, (top_w - bot_w) * 0.5)
		panel.mesh = pm
		panel.material_override = dark
		var rot := Basis(Vector3.UP, deg_to_rad(ang))
		var off := rot * Vector3(0, 0, -(bot_w + (top_w - bot_w) * 0.5) * 0.5)
		panel.position = Vector3(off.x, hover_height + depth * 0.5, off.z)
		panel.rotation_degrees = Vector3(-90, ang, 0)
		add_child(panel)
	# the lit underside — the light the object stands in
	var under := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(bot_w, bot_w)
	under.mesh = qm
	under.material_override = glow
	under.position = Vector3(0, hover_height, 0)
	under.rotation_degrees = Vector3(-90, 0, 0)
	add_child(under)
	# dark rim above the glow (the canopy's mouth)
	var rim := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(top_w + 0.3, 0.35, top_w + 0.3)
	rim.mesh = rb
	rim.material_override = dark
	rim.position = Vector3(0, hover_height + depth + 0.15, 0)
	add_child(rim)

	# the downlight
	var light := SpotLight3D.new()
	light.position = Vector3(0, hover_height - 0.1, 0)
	light.rotation_degrees = Vector3(-90, 0, 0)
	light.spot_angle = 38.0
	light.spot_range = hover_height + 1.0
	light.light_energy = 3.0
	light.light_color = Color(1.0, 0.96, 0.88)
	add_child(light)

	# the dais
	var dais := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = bot_w * 0.62
	cm.bottom_radius = bot_w * 0.68
	cm.height = 0.18
	dais.mesh = cm
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.12, 0.11, 0.13)
	dm.roughness = 0.5
	dais.material_override = dm
	dais.position = Vector3(0, 0.09, 0)
	add_child(dais)

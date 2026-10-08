extends Node3D
## Twelve persistent panels; placement and colour assignment are independent.
## Original study informed by Liam Gillick's secondary architectural structures.
signal state_changed(arrangement: int, colour_rule: int)

const PANEL_COUNT := 12
const PANEL_SIZE := Vector2(2.32,2.52)
const PALETTE: Array[Color] = [Color("db3768"),Color("efad25"),Color("22a9ad"),Color("4263c9")]
const ARRANGEMENTS := ["Canopy","Screens","Gathering"]
const COLOUR_RULES := ["Alternating","Groups of three","One colour"]
var arrangement := 0
var colour_rule := 0
var panels: Array[Node3D] = []
var materials: Array[StandardMaterial3D] = []
var suspensions: Array[Node3D] = []
var frame_material: StandardMaterial3D

func _ready() -> void:
	frame_material = StandardMaterial3D.new()
	frame_material.albedo_color = Color("c8cbd0")
	frame_material.metallic = 0.65
	frame_material.roughness = 0.32
	for i in PANEL_COUNT:
		panels.append(_make_panel(i))
		var wires := Node3D.new()
		wires.name = "Suspension%02d" % i
		add_child(wires)
		for side in [-1,1]:
			var rod := _box(wires,"Wire",Vector3(0.012,2.98,0.012),Vector3(side*1.10,4.74,0),frame_material)
			rod.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		suspensions.append(wires)
	set_arrangement(0)
	set_colour_rule(0)
	set_meta("em_visibility_bounds",AABB(Vector3(-5.3,0,-5),Vector3(10.6,6.3,10)))

func _make_panel(index: int) -> Node3D:
	var panel := Node3D.new()
	panel.name = "Panel%02d" % index
	panel.set_meta("array_index",index)
	add_child(panel)
	for side in [-1,1]:
		_box(panel,"Stile",Vector3(0.06,2.52,0.10),Vector3(side*1.13,0,0),frame_material)
		_box(panel,"Rail",Vector3(2.20,0.06,0.10),Vector3(0,side*1.23,0),frame_material)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.46
	materials.append(material)
	var pane := MeshInstance3D.new()
	pane.name = "ColourPane"
	var mesh := QuadMesh.new()
	mesh.size = Vector2(2.20,2.40)
	pane.mesh = mesh
	pane.material_override = material
	# Godot alpha compositing, not a simulation of coloured transmitted shadows.
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.add_child(pane)
	var body := StaticBody3D.new()
	body.name = "SolidPane"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(PANEL_SIZE.x,PANEL_SIZE.y,0.10)
	collision.shape = shape
	body.add_child(collision)
	panel.add_child(body)
	var label := Label3D.new()
	label.text = "%02d" % index
	label.font_size = 36
	label.pixel_size = 0.0024
	label.outline_size = 0
	label.modulate = Color("303944")
	label.position = Vector3(-0.94,-1.23,0.055)
	panel.add_child(label)
	return panel

func panel_transform(index: int, layout: int) -> Transform3D:
	var origin: Vector3
	var basis := Basis.IDENTITY
	match layout:
		0:
			origin = Vector3((index%4-1.5)*2.5,3.25,(floori(index/4.0)-1)*2.65)
			basis = Basis(Vector3.RIGHT,PI/2)
		1:
			var row := floori(index/3.0)
			var offset := 0.6 if row%2 else -0.6
			origin = Vector3((index%3-1)*3.3+offset,1.32,(row-1.5)*2.2)
			basis = Basis(Vector3.UP,deg_to_rad(18 if row%2 else -18))
		2:
			if index < 6:
				origin = Vector3((index%3-1)*2.5,3.25,(floori(index/3.0)-0.5)*2.65)
				basis = Basis(Vector3.RIGHT,PI/2)
			elif index < 9:
				origin = Vector3(-4.15,1.32,(index-7)*2.65)
				basis = Basis(Vector3.UP,PI/2)
			elif index < 11:
				origin = Vector3(4.15,1.32,(index-9.5)*2.65)
				basis = Basis(Vector3.UP,PI/2)
			else:
				origin = Vector3(0,1.32,-4.3)
	return Transform3D(basis,origin)

func set_arrangement(value: int) -> void:
	arrangement = clampi(value,0,ARRANGEMENTS.size()-1)
	for i in panels.size():
		panels[i].transform = panel_transform(i,arrangement)
		var overhead := is_equal_approx(panels[i].position.y,3.25)
		suspensions[i].visible = overhead
		suspensions[i].position = Vector3(panels[i].position.x,0,panels[i].position.z)
	state_changed.emit(arrangement,colour_rule)

func colour_for(index: int, rule: int) -> Color:
	var palette_index := index%PALETTE.size()
	if rule == 1: palette_index = floori(index/3.0)
	if rule == 2: palette_index = 0
	var colour := PALETTE[palette_index]
	colour.a = 0.62
	return colour

func set_colour_rule(value: int) -> void:
	colour_rule = clampi(value,0,COLOUR_RULES.size()-1)
	for i in materials.size(): materials[i].albedo_color = colour_for(i,colour_rule)
	state_changed.emit(arrangement,colour_rule)

func _box(parent: Node3D,label: String,size: Vector3,at: Vector3,material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = at
	part.material_override = material
	parent.add_child(part)
	return part

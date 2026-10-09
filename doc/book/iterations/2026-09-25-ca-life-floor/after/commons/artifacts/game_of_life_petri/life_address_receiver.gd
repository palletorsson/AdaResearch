extends Node3D
## A lamp receives occupancy, not a glider identity or a timed choreography.
var site: Vector2i
var occupied: bool = false
var connected: bool = true
var rises: int = 0
var material: StandardMaterial3D
var light: OmniLight3D
var reading: Label3D
var letter: String

func _ready() -> void:
	var foot := _box(Vector3(0.58,0.12,0.58),Vector3(0,0.06,0),Color("715e50"))
	var body := StaticBody3D.new()
	var bounds := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.58,0.12,0.58)
	bounds.shape = shape
	foot.add_child(body);body.add_child(bounds)
	_box(Vector3(0.065,1.35,0.065),Vector3(0,0.79,0),Color("c8a576"))
	var globe := MeshInstance3D.new()
	globe.name = "OpalReceiver"
	var sphere := SphereMesh.new()
	sphere.radius = 0.24;sphere.height = 0.48
	material = StandardMaterial3D.new()
	material.roughness = 0.3
	material.emission_enabled = true
	sphere.material = material
	globe.mesh = sphere
	globe.position.y = 1.55
	add_child(globe)
	light = OmniLight3D.new()
	light.name = "OccupancyLight"
	light.position.y = 1.65
	light.light_color = Color("90efd6")
	light.omni_range = 2.1
	light.shadow_enabled = false
	add_child(light)
	_box(Vector3(0.64,0.28,0.045),Vector3(0,1.02,-0.075),Color("153237"))
	reading = Label3D.new()
	reading.font_size = 28;reading.pixel_size = 0.0015;reading.outline_size = 0
	reading.position = Vector3(0,1.02,-0.101)
	reading.rotation_degrees.y = 180
	reading.modulate = Color("ffdfb8")
	add_child(reading)
	_refresh()

func reset_events() -> void:
	rises = 0
	occupied = false

func receive(value: bool, link: bool, count_event: bool = true) -> void:
	if count_event and link and value and not occupied: rises += 1
	occupied = value
	connected = link
	_refresh()

func _refresh() -> void:
	var lit: bool = occupied and connected
	material.albedo_color = Color("9bf4d7") if lit else Color("50495b")
	material.emission = Color("62c4a4") if lit else Color.BLACK
	material.emission_energy_multiplier = 1.3 if lit else 0.0
	light.light_energy = 1.2 if lit else 0.0
	reading.text = "%s / (%d,%d)\nCELL %d  /  %s\nONSETS %d" % [letter,site.x,site.y,int(occupied),"LINKED" if connected else "UNLINKED",rises]

func _box(size: Vector3,at: Vector3,colour: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new();mesh.size = size
	var mat := StandardMaterial3D.new();mat.albedo_color = colour
	mesh.material = mat;n.mesh=mesh;n.position=at;add_child(n)
	return n

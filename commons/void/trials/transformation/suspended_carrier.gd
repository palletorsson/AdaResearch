extends Node3D
## One editable assembly: ceiling tracks, moving hangers and original tc carry.
const Transport = preload("res://commons/scenes/mapobjects/transport_cube.tscn")
const Ride = preload("res://commons/void/trials/transformation/suspended_platform.gd")
const Finish = preload("res://commons/void/abstract_finish.gd")
var displacement := Vector3(0, 0, -8)
var speed := 1.0
var pause := 4.0
var platform: Node3D
var ceiling_y := 0.0
var cables: Array[MeshInstance3D] = []
var tracks: Array[MeshInstance3D] = []
var trolleys: Array[MeshInstance3D] = []
const CORNERS := [Vector3(-.86,0,-.86), Vector3(.86,0,-.86), Vector3(-.86,0,.86), Vector3(.86,0,.86)]

func _ready() -> void:
	platform = Transport.instantiate()
	platform.set_script(Ride)
	platform.name = "Transport"
	platform.position.y = -.5
	platform.move_speed = speed
	platform.start_delay = pause
	platform.return_delay = pause + 1.0
	platform.auto_start = false
	add_child(platform)
	var steel := Finish.material(Color("596269"), .05)
	for i in range(4):
		var cable := MeshInstance3D.new()
		cable.name = "Suspension%d" % i
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = .018; cylinder.bottom_radius = .018; cylinder.radial_segments = 8
		cable.mesh = cylinder; cable.material_override = steel
		add_child(cable); cables.append(cable)
		var trolley := _box("Trolley%d" % i, Vector3(.22,.12,.22), steel)
		trolleys.append(trolley)
	for i in range(2): tracks.append(_box("CeilingTrack%d" % i, Vector3(.12,.14,displacement.length()+2.0), steel))
	rebase()

func _box(title: String, size: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	var mesh := BoxMesh.new(); mesh.size = size
	node.mesh = mesh; node.material_override = mat
	add_child(node)
	return node

func rebase() -> void:
	if not is_instance_valid(platform): return
	var host: Node = get_parent()
	ceiling_y = get_parent().global_position.y + 5.64
	while host != null:
		if host is Node3D and host.has_meta("void_content_floor"):
			ceiling_y = host.global_position.y + 5.64; break
		host = host.get_parent()
	platform.auto_start = true
	platform.reset_route(to_global(Vector3(0,-.5,0)), to_global(displacement+Vector3(0,-.5,0)))
	for i in range(2):
		var middle := to_global(displacement*.5 + Vector3(-.86 if i==0 else .86,0,0))
		middle.y = ceiling_y
		tracks[i].position = to_local(middle)
		var horizontal := Vector3(displacement.x,0,displacement.z)
		tracks[i].mesh.size.z = horizontal.length()+2.0
		if horizontal.length()>.01: tracks[i].rotation.y = atan2(horizontal.x,horizontal.z)
	_update_suspension()

func _process(_delta: float) -> void:
	_update_suspension()

func _update_suspension() -> void:
	if not is_instance_valid(platform): return
	for i in range(4):
		var bottom: Vector3 = platform.to_global(CORNERS[i]+Vector3.UP*.5)
		var top := Vector3(bottom.x,ceiling_y,bottom.z)
		var a := to_local(bottom); var b := to_local(top)
		cables[i].position = (a+b)*.5
		cables[i].mesh.height = maxf(.01,a.distance_to(b))
		cables[i].quaternion = Quaternion(Vector3.UP,(b-a).normalized())
		trolleys[i].position = b

func prepare_editor_preview() -> void:
	platform.set_physics_process(false)
	platform.global_position = to_global(Vector3(0,-.5,0))
	_update_suspension()

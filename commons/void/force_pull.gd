extends Node3D
## Short-lived pull cue. XRTools remains the sole owner of the object's motion.
const Rules := preload("player_rules.gd")
var hand: Node3D
var object: XRToolsPickable
var sparks: Array[MeshInstance3D] = []
var elapsed := 0.0

static func reachable(source: Node3D, target: Node3D) -> bool:
	if not is_instance_valid(target) or not target.is_visible_in_tree():return false
	if source.global_position.distance_to(target.global_position)>Rules.GRAB_DISTANCE+.001:return false
	var ray := PhysicsRayQueryParameters3D.create(source.global_position,target.global_position,1|2|4)
	if target is CollisionObject3D:ray.exclude = [target.get_rid()]
	return source.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

static func begin(source: Node3D, target: XRToolsPickable) -> void:
	var cue: Node3D = load("res://commons/void/force_pull.gd").new()
	cue.hand = source;cue.object = target;cue.name = "ForcePull"
	source.add_child(cue)

func _ready() -> void:
	var material := StandardMaterial3D.new();material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("f7b4df");material.emission_enabled = true;material.emission = material.albedo_color
	var mesh := SphereMesh.new();mesh.radius = .012;mesh.height = .024;mesh.radial_segments = 8;mesh.rings = 4
	for i in 5:
		var spark := MeshInstance3D.new();spark.mesh = mesh;spark.material_override = material
		add_child(spark);spark.top_level = true;sparks.append(spark)

func _process(delta: float) -> void:
	if not is_instance_valid(hand) or not is_instance_valid(object) or not object.is_picked_up():queue_free();return
	var driver = object._grab_driver
	if not is_instance_valid(driver) or driver.state!=XRToolsGrabDriver.GrabState.LERP:queue_free();return
	elapsed += delta
	var a := object.global_position;var b := hand.global_position
	var side := (b-a).cross(Vector3.UP).normalized()
	for i in sparks.size():
		var t := fposmod(elapsed*1.8+float(i)/sparks.size(),1.0)
		sparks[i].global_position = a.lerp(b,t)+side*sin(t*TAU+elapsed*9)*.025*sin(t*PI)

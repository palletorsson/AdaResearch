extends Node3D

const Look := preload("res://supplied/look.gd")
const Member := preload("res://borrowed/member.gd")
const Tunnel := preload("res://borrowed/tunnel.gd")
const Scan := preload("res://borrowed/scan.gd")

const UNION := CSGShape3D.OPERATION_UNION
const MINUS := CSGShape3D.OPERATION_SUBTRACTION
const INTERSECT := CSGShape3D.OPERATION_INTERSECTION
const ORDERS := ["(A union B) minus C", "(A minus C) union B", "(A intersect B) minus C", "A minus (B union C)"]

@export_range(0, 3) var order := 0   # which line of ORDERS
@export var baked := true            # false: the combiner as it is, a picture with nothing in it for a body
@export var b_x := 0.2               # where B stands: metres to the right of the middle

var carver: CSGCombiner3D     # holds the operands, in order
var body: MeshInstance3D      # the baked result
var listed := 0               # triangles the operands list
var built := 0                # triangles of the result

func _ready() -> void:
	carver = CSGCombiner3D.new()
	add_child(carver)
	var a := operand(Member.make(16), Look.BODY)
	a.position = Vector3(-0.22, 1.2, 0.0)
	a.scale = Vector3(0.96, 4.2, 1.5)
	var b := operand(Member.make(4), Look.SECOND)
	b.position = Vector3(b_x, 1.2, 0.0)
	b.scale = Vector3(1.633, 4.2, 1.633)
	b.rotation.y = PI / 4.0
	var c := operand(Tunnel.make(24), Look.THIRD)
	c.position = Vector3(0.0, 0.3, 0.0)
	var s := operand(Scan.make(true), Look.BONE)
	put(a, UNION)
	if order == 0:
		put(b, UNION)
		put(c, MINUS)
	elif order == 1:
		put(c, MINUS)
		put(b, UNION)
	elif order == 2:
		put(b, INTERSECT)
		put(c, MINUS)
	else:
		var bracket := CSGCombiner3D.new()
		put(bracket, MINUS)
		put(b, UNION, bracket)
		put(c, UNION, bracket)
	put(s, INTERSECT)
	await get_tree().process_frame
	built = triangles(carver.bake_static_mesh())
	print(verbs(), ": ", listed, " triangles listed, ", built, " in the result")
	if baked:
		bake()
	if has_node("../Walker"):
		var walker := $"../Walker"
		walker.walk_to([Vector3(0.0, 0.0, 2.0), Vector3(0.0, 0.0, 0.0)])
		var how: String = await walker.walk_ended
		print("the walker ", how, ", its feet at ", snappedf(walker.global_position.y, 0.01), " m")

func operand(mesh: Mesh, color: Color) -> CSGMesh3D:
	var shape := CSGMesh3D.new()
	shape.mesh = mesh
	shape.material = Look.paint(color)
	listed += triangles(mesh)
	return shape

func put(shape: CSGShape3D, verb: int, into: CSGShape3D = carver) -> void:
	shape.operation = verb
	into.add_child(shape)

func verbs() -> String:
	return "(" + ORDERS[order] + ") intersect S"

func bake() -> void:
	body = MeshInstance3D.new()
	body.mesh = carver.bake_static_mesh()
	add_child(body)
	var solid := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	collider.shape = carver.bake_collision_shape()
	solid.add_child(collider)
	body.add_child(solid)
	carver.queue_free()

func triangles(mesh: Mesh) -> int:
	if mesh == null:
		return 0
	@warning_ignore("integer_division")
	return mesh.get_faces().size() / 3

func keep(path := "res://guests/combine/carved.tres") -> void:
	if body == null:
		print("nothing to keep: nothing is baked")
		return
	body.mesh.set_meta("verbs", verbs())
	body.mesh.set_meta("listed", listed)
	ResourceSaver.save(body.mesh, path)
	print("kept ", path, ": ", built, " triangles and one line of verbs")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		keep()

extends Node3D

const Genes := preload("res://guests/genome/genes.gd")

const FILE := "res://guests/genome/specimen.tres"

var genes: Genes

func _ready() -> void:
	if genes == null:
		genes = load(FILE) if ResourceLoader.exists(FILE) else Genes.new()
	genes.changed.connect(build)
	build()

func build() -> void:
	for part in $Parts.get_children():
		part.free()
	var paint := StandardMaterial3D.new()
	paint.albedo_color = genes.colour
	paint.roughness = 0.8
	var rng := RandomNumberGenerator.new()
	rng.seed = genes.body_seed
	var hub := Vector3.ZERO    # the middle of the lowest ball
	var top := 0.0             # where the next ball begins
	for i in genes.segments:
		var ball := SphereMesh.new()
		ball.radius = 0.22 * pow(0.8, i) * rng.randf_range(0.85, 1.15)
		ball.height = ball.radius * 2.0
		var part := add_part(ball, paint)
		part.position.y = top + ball.radius
		if i == 0:
			hub = part.position
		top += ball.radius * 1.6
	for i in genes.limb_count:
		var limb := CapsuleMesh.new()
		limb.radius = 0.05
		limb.height = 0.5
		var part := add_part(limb, paint)
		part.rotation = Vector3(0.0, TAU * i / genes.limb_count, deg_to_rad(genes.limb_angle) - PI / 2.0)
		part.position = hub + part.basis.y * 0.4

func add_part(mesh: Mesh, paint: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = paint
	$Parts.add_child(part)
	return part

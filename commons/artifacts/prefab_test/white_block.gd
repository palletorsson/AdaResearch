# WhiteBlock.gd - white wall slabs stood so close they read as one block; nothing in it stops a body
#
# @identity
# essence: a ten metre block of white wall slabs with no colliders; inside it, a crowd of coloured primitives standing in each other; a small pagoda at its face shows where to walk in
# desire: the learner finds out, by walking, that a wall in this world is a picture until something makes it solid
# critical_parameter: count - how many primitives stand inside; side - the block's size
# triggers: none; the visitor walks through
# emerges: from outside a plain white block; one step through the wall, a room where every form passes through every other
# relationships: the collider is a separate decision from the mesh, as [[contact_study]] THROUGH shows for two meshes; the primitives are the floor's own vocabulary ([[void_primitive_columns]], the Primitives halls)
# truth: seeing a wall and being stopped by it are two things, and only one of them was built here.
extends Node3D

## WHERE THIS COMES FROM. Palle, 22 November 2026: "In the middle have white wall slabs stuck closely together like
## one big 10 meter block without colliders. Inside block place a lot of color overlapping geometry primitives
## inside and a simple pagoda show you should enter the wall."
##
## Then, the same night, seeing the first build (a shell of slabs round an open room): "the inside should be the full
## segments no open space, so we get a glitch work between the surfaces when we walk inside."
##
## The block: wall slabs stood face to face through the whole depth of the block, each `slab` thick with a joint of
## `joint` between two, every slab made of segments `panel` wide, every other slab shifted half a segment so no
## joint runs through. There is no room in it. All of it is one MultiMesh, drawn on both sides, in two whites that
## differ a little from slab to slab, without a body: there is no collider anywhere in this work.
## Walking in, the eye is inside a slab, then in a joint, then inside the next: each face it crosses cuts the view.
## In the slabs: `count` primitives of seven kinds (box, sphere, cylinder, cone, prism, torus, capsule), one MultiMesh
## a kind, their places, turns, sizes and colours drawn from `seed`, standing in each other and in the slabs, so that
## inside a slab one sees the slice of every primitive that crosses it; a lamp, since no daylight reaches in.
## The pagoda stands half in the south wall (+z, towards the arrival): four posts, three roofs, a carpet that runs
## under it into the block.
## Origin: the middle of the block, on the floor.

const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const WHITE := Color("f4f2ee")
const VERMILION := Color("d5352b")
const ROOF := Color("27383d")
const GOLD := Color("d9b45a")
const SHADE := Color("e7e3dc")            # every other slab, a little darker: a joint shows as a line
const JOINT := 0.014                      # between two segments of one slab

@export var side := 10.0
@export var height := 5.4
@export var slab := 0.18
@export var panel := 1.25
@export var joint := 0.008
@export var count := 72
@export var seed_value := 12
@export var pagoda := true

var walls: MultiMeshInstance3D
var shapes: Array[MultiMeshInstance3D] = []
var gate: Node3D
var shape_count := 0
var slab_count := 0                  # slabs through the depth of the block


func apply_grid_config(config: Dictionary) -> void:
	for key in ["side", "height", "slab", "panel", "joint", "count", "pagoda"]:
		if config.has(key): set(key, config[key])
	if config.has("seed"): seed_value = int(config.seed)
	if is_node_ready():
		for child in get_children(): child.queue_free()
		shapes.clear()
		_build()


func _ready() -> void:
	for key in ["side", "height", "slab", "panel", "joint", "count", "pagoda"]:
		if has_meta("config_" + key): set(key, get_meta("config_" + key))
	if has_meta("config_seed"): seed_value = int(get_meta("config_seed"))
	_build()


## Is a point (in the world) inside the block?
func holds(at: Vector3) -> bool:
	var p := to_local(at)
	return absf(p.x) < side * 0.5 and absf(p.z) < side * 0.5 and p.y > -0.2 and p.y < height


func _build() -> void:
	_walls()
	_inside()
	if pagoda: _pagoda()


func _walls() -> void:
	var places: Array[Transform3D] = []
	var tones: Array[Color] = []
	var across := maxi(2, int(round(side / panel)))
	var wide := side / across
	var pitch := slab + joint
	slab_count = int(floor((side + joint) / pitch))
	var first := -(slab_count * pitch - joint) * 0.5 + slab * 0.5
	for n in slab_count:
		var z := first + n * pitch
		var shifted := n % 2 == 1
		var tone := WHITE if n % 2 == 0 else SHADE
		for i in (across + 1 if shifted else across):
			var w := wide
			var x := -side * 0.5 + (i + 0.5) * wide
			if shifted:
				# half a segment along, with a half segment at each end
				x = -side * 0.5 + i * wide
				if i == 0: w = wide * 0.5; x = -side * 0.5 + wide * 0.25
				elif i == across: w = wide * 0.5; x = side * 0.5 - wide * 0.25
			places.append(Transform3D(Basis.from_scale(Vector3(w - JOINT, height, slab)), Vector3(x, height * 0.5, z)))
			tones.append(tone)
	walls = _many("Slabs", BoxMesh.new(), places, tones, _glowing(true, 0.62))


func _inside() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.5
	cone.height = 1.0
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.5
	cylinder.height = 1.0
	var ball := SphereMesh.new()
	ball.radius = 0.5
	ball.height = 1.0
	var ring := TorusMesh.new()
	ring.inner_radius = 0.28
	ring.outer_radius = 0.5
	var pill := CapsuleMesh.new()
	pill.radius = 0.3
	pill.height = 1.0
	var kinds := [["Boxes", BoxMesh.new()], ["Spheres", ball], ["Cylinders", cylinder], ["Cones", cone], ["Prisms", PrismMesh.new()], ["Rings", ring], ["Capsules", pill]]
	var paint := _glowing(false, 0.5)
	var inner := side * 0.5 - 0.05      # the block's own faces
	var under := height - 0.05          # and its top
	shape_count = 0
	for k in kinds.size():
		var share := count / kinds.size() + (1 if k < count % kinds.size() else 0)
		var places: Array[Transform3D] = []
		var colours: Array[Color] = []
		for i in share:
			var big := rng.randf_range(0.55, 2.3)
			var squash := Vector3(big * rng.randf_range(0.7, 1.25), big * rng.randf_range(0.7, 1.35), big * rng.randf_range(0.7, 1.25))
			var turn := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
			# however it is turned, it reaches no further than half its diagonal: placed that far from every wall and
			# from the roof. It may stand up to its middle in the floor, which hides what is under it.
			var reach := squash.length() * 0.5
			var span := maxf(inner - reach, 0.2)
			var low := minf(reach * 0.5, under - reach)
			places.append(Transform3D(turn * Basis.from_scale(squash), Vector3(rng.randf_range(-span, span), rng.randf_range(low, maxf(under - reach, low + 0.05)), rng.randf_range(-span, span))))
			colours.append(Color.from_hsv(rng.randf(), rng.randf_range(0.72, 1.0), rng.randf_range(0.88, 1.0)))
		shapes.append(_many(str(kinds[k][0]), kinds[k][1], places, colours, paint))
		shape_count += share
	# no daylight reaches into a closed block
	var lamp := OmniLight3D.new()
	lamp.name = "Lamp"
	lamp.position = Vector3(0, height - 1.3, 0)
	lamp.light_energy = 1.8
	lamp.omni_range = side * 0.95
	lamp.omni_attenuation = 0.6
	lamp.shadow_enabled = false
	add_child(lamp)


## A surface in its instance's own colour that also lights itself by `glow`: inside a slab no lamp is on the side one
## sees a face from, and a white that is only lit turns grey there. `both`: drawn from both sides (the slabs).
func _glowing(both: bool, glow: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nrender_mode %s;\nuniform float glow = 0.5;\nvoid fragment() {\n\tALBEDO = COLOR.rgb;\n\tROUGHNESS = 0.8;\n\tEMISSION = COLOR.rgb * glow;\n}\n" % ("cull_disabled" if both else "cull_back")
	var paint := ShaderMaterial.new()
	paint.shader = shader
	paint.set_shader_parameter("glow", glow)
	return paint


func _many(title: String, mesh: Mesh, places: Array[Transform3D], colours: Array[Color], paint: Material) -> MultiMeshInstance3D:
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.use_colors = not colours.is_empty()
	many.mesh = mesh
	many.instance_count = places.size()
	for i in places.size():
		many.set_instance_transform(i, places[i])
		if many.use_colors: many.set_instance_color(i, colours[i])
	var node := MultiMeshInstance3D.new()
	node.name = title
	node.multimesh = many
	node.material_override = paint
	add_child(node)
	return node


## Four posts, three roofs, a carpet into the wall: here is where one walks in.
func _pagoda() -> void:
	gate = Node3D.new()
	gate.name = "Pagoda"
	gate.position = Vector3(0, 0, side * 0.5 + 0.35)
	add_child(gate)
	var span := 1.3
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_part(BoxMesh.new(), Vector3(sx * span, 1.3, sz * span), Vector3(0.18, 2.6, 0.18), VERMILION, "Post")
	for sz in [-1.0, 1.0]:
		_part(BoxMesh.new(), Vector3(0, 2.52, sz * span), Vector3(span * 2.0 + 0.5, 0.16, 0.16), VERMILION, "Beam")
	for sx in [-1.0, 1.0]:
		_part(BoxMesh.new(), Vector3(sx * span, 2.52, 0), Vector3(0.16, 0.16, span * 2.0 + 0.5), VERMILION, "Beam")
	var at := 2.6
	for tier in [[4.0, 2.0, 0.5, 0.36], [3.1, 1.5, 0.45, 0.3], [2.3, 0.3, 0.72, 0.0]]:
		var roof := CylinderMesh.new()
		roof.radial_segments = 4
		roof.rings = 1
		roof.bottom_radius = float(tier[0]) / sqrt(2.0)
		roof.top_radius = float(tier[1]) / sqrt(2.0)
		roof.height = float(tier[2])
		var part := _part(roof, Vector3(0, at + float(tier[2]) * 0.5, 0), Vector3.ONE, ROOF, "Roof")
		part.rotation.y = PI / 4.0
		# a thin gold eave under each roof
		_part(BoxMesh.new(), Vector3(0, at + 0.02, 0), Vector3(float(tier[0]) + 0.06, 0.04, float(tier[0]) + 0.06), GOLD, "Eave")
		at += float(tier[2])
		if float(tier[3]) > 0.0:
			_part(BoxMesh.new(), Vector3(0, at + float(tier[3]) * 0.5, 0), Vector3(float(tier[1]) * 0.9, float(tier[3]), float(tier[1]) * 0.9), VERMILION, "Neck")
			at += float(tier[3])
	var knob := SphereMesh.new()
	knob.radius = 0.15
	knob.height = 0.3
	_part(knob, Vector3(0, at + 0.12, 0), Vector3.ONE, GOLD, "Finial")
	# the way in: a carpet from in front of the pagoda, under it, into the block
	var carpet := Kit.block(self, Vector3(1.5, 0.012, 5.4), Vector3(0, 0.007, side * 0.5 - 0.3), Color("e2574c"), false)
	carpet.name = "Carpet"
	carpet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var plate := _part(BoxMesh.new(), Vector3(0, 2.2, span + 0.1), Vector3(1.9, 0.42, 0.03), Color("fbf7ee"), "Plate")
	var words := Kit.label(gate, "WALK IN\nthis wall stops nobody", plate.position + Vector3(0, 0, 0.02), 0.0024)
	words.name = "Words"
	words.modulate = Color("1d1d1f")


func _part(mesh: Mesh, at: Vector3, size: Vector3, colour: Color, title: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = mesh
	node.position = at
	node.scale = size
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colour
	paint.roughness = 0.7
	node.material_override = paint
	gate.add_child(node)
	return node

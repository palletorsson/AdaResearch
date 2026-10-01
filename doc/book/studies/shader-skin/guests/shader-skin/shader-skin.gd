extends Node3D
## The body the Shader skin kit hands to the room: one member of the sphere
## family, 1 m across, standing on the ground, in a skin that is computed.
## Everything it needs is in this folder: this script and skin.gdshader. It
## names nothing outside the folder, so the palette is written out here, and it
## declares no class_name.
## The four lines under the colours are yours to change in your room.

const BODY := Color("c6ff3d")     # the look's BODY: the skin's own colour
const SHADE := Color("0d0620")    # the look's SHADE: the stripes
const SECOND := Color("22d9ff")   # the look's SECOND: the rim, the walker's colour

var segments := 64                # the member of the family: 4 to 64
var rim_power := 3.0              # the rim's exponent: 0.5 floods, 8 is a hairline
var drift := 0.1                  # how many bands a second the stripes crawl
var rim_colour := SECOND

var material := ShaderMaterial.new()

func _ready() -> void:
	var member := MeshInstance3D.new()
	member.name = "Member"
	var sphere := SphereMesh.new()
	sphere.radial_segments = clampi(segments, 4, 64)
	sphere.rings = sphere.radial_segments / 2
	member.mesh = sphere
	member.position.y = 0.5       # it stands on the ground at the guest's origin
	member.rotation.y = PI        # the seam of its UV is at the back
	add_child(member)
	material.shader = load("res://guests/shader-skin/skin.gdshader")
	member.material_override = material
	material.set_shader_parameter("body_colour", BODY)
	material.set_shader_parameter("band_colour", SHADE)
	material.set_shader_parameter("rim_colour", rim_colour)
	material.set_shader_parameter("drift", drift)
	material.set_shader_parameter("rim_power", rim_power)
	# The mesh is what the eye gets. This is what a marble and a walker get.
	var solid := StaticBody3D.new()
	solid.name = "Body"
	var collider := CollisionShape3D.new()
	collider.name = "CollisionShape3D"
	var shape := SphereShape3D.new()
	shape.radius = 0.5
	collider.shape = shape
	solid.add_child(collider)
	member.add_child(solid)

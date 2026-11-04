extends Node3D
class_name CrystalSconce

# @identity
# essence: a primitive as a lamp - a faceted bipyramid of coloured light on a curved arm, mounted on a wall or column
# desire: the primitives a learner has just met turn up again as fittings of the building, lit from inside
# critical_parameter: shape - which bipyramid the light is (hexagonal crystal, square diamond, long kite)
# triggers: built procedurally in _ready(); rebuilt by apply_grid_config
# needs: a vertical face to hang on; the origin is the wall plate's centre, the lamp projects along +Z
# truth: a light fitting is a solid like any other - its facets are flat, its glow is a material and a lamp
#
# Palle, 2026-11-04 (Primitives_Polythedra): "on the pillar ... put these kind of primitive lights" - a photo of
# glowing polyhedral wall lights on bent arms. Config: #shape:crystal|diamond|kite #colour:white|yellow|blue|violet|green|pink

## Which bipyramid the light is: crystal (hexagonal, tall), diamond (square, wide), kite (square, long).
@export_enum("crystal", "diamond", "kite") var shape: String = "crystal"
## The light's colour; the arm takes a darker tone of it.
@export_enum("white", "yellow", "blue", "violet", "green", "pink") var colour: String = "white"
## The lamp inside, so the light falls on the column and the floor, not only on the glass.
@export var glow: float = .9

const COLOURS := {"white": Color("fff6e3"), "yellow": Color("ffd84a"), "blue": Color("5aa8ff"), "violet": Color("8a5cff"),
	"green": Color("8fe36a"), "pink": Color("ff7fc0")}
## ring sides, ring radius, height above the ring, depth below it
const SHAPES := {"crystal": [6, .15, .30, .20], "diamond": [4, .2, .2, .2], "kite": [4, .13, .36, .2]}
const ARM_REACH := .24
const ARM_RISE := .14

func _ready() -> void:
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("shape") and str(config_data.shape) in SHAPES: shape = str(config_data.shape)
	if config_data.has("colour") and str(config_data.colour) in COLOURS: colour = str(config_data.colour)
	if config_data.has("glow"): glow = float(config_data.glow)
	if is_inside_tree(): _build()

func _build() -> void:
	for child in get_children(): child.queue_free()
	var light: Color = COLOURS.get(colour, COLOURS.white)
	var arm_colour := light.darkened(.35)
	var metal := StandardMaterial3D.new();metal.albedo_color=arm_colour;metal.roughness=.35;metal.metallic=.3
	var plate_material := StandardMaterial3D.new();plate_material.albedo_color=Color("eeeae2");plate_material.roughness=.6
	# The wall plate, then the arm: out from the wall, an elbow, and up.
	_box("Plate", Vector3(0, 0, .015), Vector3(.16, .2, .03), plate_material)
	_tube("ArmOut", Vector3(0, 0, .03), Vector3(0, 0, ARM_REACH), .022, metal)
	var elbow := MeshInstance3D.new();elbow.name="Elbow";var ball := SphereMesh.new();ball.radius=.026;ball.height=.052
	elbow.mesh=ball;elbow.material_override=metal;elbow.position=Vector3(0, 0, ARM_REACH);add_child(elbow)
	_tube("ArmUp", Vector3(0, 0, ARM_REACH), Vector3(0, ARM_RISE, ARM_REACH), .022, metal)
	var cup := MeshInstance3D.new();cup.name="Cup";var c := CylinderMesh.new();c.top_radius=.045;c.bottom_radius=.03;c.height=.04
	cup.mesh=c;cup.material_override=metal;cup.position=Vector3(0, ARM_RISE+.02, ARM_REACH);add_child(cup)
	# The crystal: a bipyramid with flat facets, its lower apex in the cup.
	var spec: Array = SHAPES.get(shape, SHAPES.crystal)
	var depth: float = spec[3]
	var crystal := MeshInstance3D.new();crystal.name="Crystal"
	crystal.mesh=_bipyramid(int(spec[0]), float(spec[1]), float(spec[2]), depth)
	var glass := StandardMaterial3D.new()
	glass.albedo_color=Color(light, .82);glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	# White glass at full glow is a blob of light: dimmer, so its flat facets still read as a polyhedron.
	glass.emission_enabled=true;glass.emission=light;glass.emission_energy_multiplier=.45 if colour=="white" else 1.4
	glass.roughness=.15;glass.metallic=.1;glass.rim_enabled=true;glass.rim=.6
	crystal.material_override=glass;crystal.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	crystal.position=Vector3(0, ARM_RISE+.03+depth, ARM_REACH);add_child(crystal)
	var lamp := OmniLight3D.new();lamp.name="Lamp";lamp.light_color=light;lamp.light_energy=glow;lamp.omni_range=3.2
	lamp.shadow_enabled=false;lamp.position=crystal.position;add_child(lamp)

## A bipyramid: an n-gon ring of radius r, apexes `up` above and `down` below it; flat facets, outward normals,
## Godot's clockwise front faces.
func _bipyramid(sides: int, r: float, up: float, down: float) -> ArrayMesh:
	var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring: Array[Vector3] = []
	for i in sides:
		var a := TAU*i/sides+(PI/sides if sides==4 else 0.0)
		ring.append(Vector3(cos(a)*r, 0, sin(a)*r))
	for i in sides:
		var p := ring[i];var q := ring[(i+1)%sides]
		for apex in [Vector3(0, up, 0), Vector3(0, -down, 0)]:
			var tri: Array[Vector3] = [p, q, apex]
			var normal: Vector3 = (tri[1]-tri[0]).cross(tri[2]-tri[0]).normalized()
			var mid: Vector3=(tri[0]+tri[1]+tri[2])/3.0
			if normal.dot(mid) < 0: normal=-normal
			# Godot's front faces are clockwise seen from outside: the cross product of the listed order points inward.
			if (tri[1]-tri[0]).cross(tri[2]-tri[0]).dot(normal) > 0:
				var swap: Vector3=tri[1];tri[1]=tri[2];tri[2]=swap
			for v in tri:
				st.set_normal(normal);st.add_vertex(v)
	return st.commit()

func _box(title: String, at: Vector3, size: Vector3, material: Material) -> void:
	var m := MeshInstance3D.new();m.name=title;var b := BoxMesh.new();b.size=size;m.mesh=b;m.material_override=material
	m.position=at;add_child(m)

func _tube(title: String, a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var m := MeshInstance3D.new();m.name=title
	var cyl := CylinderMesh.new();cyl.top_radius=radius;cyl.bottom_radius=radius;cyl.height=a.distance_to(b);cyl.radial_segments=12
	m.mesh=cyl;m.material_override=material
	var y := (b-a).normalized()
	var reference := Vector3.RIGHT if absf(y.dot(Vector3.UP))>.95 else Vector3.UP
	var x := reference.cross(y).normalized()
	m.transform=Transform3D(Basis(x, y, x.cross(y)), (a+b)*.5)
	add_child(m)

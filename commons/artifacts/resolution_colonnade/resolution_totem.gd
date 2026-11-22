extends Node3D
## Five authored profiles; height, width and sampling remain separate decisions.
## profile_rings is subdivisions PER curved section, not decorative collars.

@export_range(4, 64, 1) var radial_segments: int = 8
@export_range(2, 64, 1) var profile_rings: int = 8
@export_enum("Vessel", "Reed", "Bell", "Spindle", "Cairn") var profile_kind: int = 0
@export_range(1.0, 6.0, 0.05) var column_height: float = 4.67
@export_range(0.5, 1.05, 0.01) var width_factor: float = 1.0
@export var collisions := true
## Which family of outlines profile_kind picks from. Classical is the five authored profiles.
@export_enum("Classical", "Alien") var outline_family: int = 0
## "black": every section in one black finish, so the body reads as its outline.
## "gradient": one body coloured by height, gradient_low at the foot to gradient_high at the top.
@export_enum("authored", "black", "gradient") var finish: String = "authored"
@export var gradient_low := Color("0a0a0a")
@export var gradient_high := Color("f21876")
## false: the gradient is drawn as it is, without the room's light (a colour rule, as on the pillar colour floor).
@export var gradient_lit := true
## Metres above the column's foot where the gradient begins; below it the body is gradient_low.
@export var gradient_start := 0.0
const PROFILE_NAMES: Array[String] = ["Vessel", "Reed", "Bell", "Spindle", "Cairn"]
const ALIEN_NAMES: Array[String] = ["Plug", "Taper", "Beads", "Ripple", "Twin"]
var column_mesh := ArrayMesh.new()
var surface := MeshInstance3D.new()
var body: StaticBody3D
var triangle_count := 0
var height := 0.0

func _ready() -> void:
    var chalk := _material(Color("e7dec9"),0.78,0.0)
    var rose := _material(Color("b47d73"),0.67,0.08)
    var bronze := _material(Color("af8854"),0.34,0.65)
    var charcoal := _material(Color("27272d"),0.58,0.12)
    if finish == "black":
        var black := _material(Color("0c0c0e"),0.30,0.0)
        chalk = black;rose = black;bronze = black;charcoal = black
    elif finish == "gradient":
        # white under the vertex colours _section writes: the colour is the height
        var blend := _material(Color.WHITE,0.62,0.0)
        blend.vertex_color_use_as_albedo = true
        blend.vertex_color_is_srgb = true   # the colours are written as seen, not as linear light
        if not gradient_lit: blend.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        chalk = blend;rose = blend;bronze = blend;charcoal = blend
    # Relative height, start radius, end radius, bulge, material.
    # Each recipe has five curved sections and four straight collars. Keeping
    # this topology shared makes the two sampling budgets comparable.
    var profiles := [[
        [0.22,0.82,0.82,0.0,chalk],
        [0.20,0.70,0.34,0.10,bronze],
        [1.05,0.34,0.29,0.36,chalk],
        [0.16,0.39,0.39,0.0,charcoal],
        [1.12,0.29,0.28,0.43,chalk],
        [0.14,0.38,0.38,0.0,rose],
        [0.96,0.28,0.24,0.09,chalk],
        [0.64,0.24,0.74,0.12,chalk],
        [0.18,0.85,0.85,0.0,bronze],
    ], [
        [0.18,0.68,0.68,0.0,chalk],
        [0.26,0.58,0.23,0.05,bronze],
        [1.60,0.23,0.19,0.035,chalk],
        [0.08,0.30,0.30,0.0,charcoal],
        [0.42,0.19,0.20,0.19,chalk],
        [0.08,0.30,0.30,0.0,rose],
        [1.48,0.20,0.17,0.03,chalk],
        [0.46,0.17,0.72,0.08,chalk],
        [0.11,0.77,0.77,0.0,bronze],
    ], [
        [0.22,0.80,0.80,0.0,chalk],
        [0.75,0.74,0.21,0.10,bronze],
        [0.92,0.21,0.62,-0.08,chalk],
        [0.13,0.69,0.69,0.0,charcoal],
        [0.90,0.62,0.20,-0.08,chalk],
        [0.12,0.30,0.30,0.0,rose],
        [0.78,0.20,0.32,0.10,chalk],
        [0.66,0.32,0.84,-0.04,chalk],
        [0.19,0.87,0.87,0.0,bronze],
    ], [
        [0.16,0.71,0.71,0.0,chalk],
        [0.28,0.60,0.17,0.08,bronze],
        [1.32,0.17,0.20,0.55,chalk],
        [0.10,0.28,0.28,0.0,charcoal],
        [1.32,0.20,0.16,0.45,chalk],
        [0.10,0.25,0.25,0.0,rose],
        [0.56,0.16,0.18,0.22,chalk],
        [0.65,0.18,0.11,0.08,chalk],
        [0.08,0.14,0.14,0.0,bronze],
    ], [
        [0.22,0.86,0.86,0.0,chalk],
        [0.30,0.71,0.36,0.10,bronze],
        [1.12,0.36,0.34,0.46,chalk],
        [0.15,0.55,0.55,0.0,charcoal],
        [0.86,0.34,0.28,0.43,chalk],
        [0.14,0.45,0.45,0.0,rose],
        [0.72,0.28,0.22,0.35,chalk],
        [0.96,0.22,0.15,0.29,chalk],
        [0.20,0.24,0.24,0.0,bronze],
    ]]
    # ALIEN (Palle, 22 November 2026: "imagine them as alien butt plug dildo outline, no offence, it is just a
    # form"). The same nine sections - four straight collars, five curved - so the sampling comparisons still
    # compare. Heights are written in metres of a 5.42 m body; each recipe sums to 5.42. Every one keeps a flared
    # foot, a slender neck through walking height and its swelling above the head, and ends in a rounded tip.
    var alien := [[
        [0.12,0.86,0.86,0.0,bronze],
        [0.45,0.86,0.20,-0.10,chalk],
        [1.45,0.20,0.22,0.02,chalk],
        [0.08,0.28,0.28,0.0,charcoal],
        [1.25,0.24,0.52,0.40,chalk],
        [0.08,0.54,0.54,0.0,rose],
        [1.15,0.52,0.30,0.16,chalk],
        [0.78,0.30,0.08,0.12,chalk],
        [0.06,0.08,0.08,0.0,bronze],
    ], [
        [0.12,0.80,0.80,0.0,bronze],
        [0.40,0.80,0.30,-0.12,chalk],
        [1.80,0.30,0.34,0.05,chalk],
        [0.08,0.40,0.40,0.0,charcoal],
        [1.45,0.34,0.32,0.07,chalk],
        [0.08,0.24,0.24,0.0,rose],
        [0.55,0.38,0.44,0.08,chalk],
        [0.88,0.44,0.08,0.16,chalk],
        [0.06,0.08,0.08,0.0,bronze],
    ], [
        [0.12,0.84,0.84,0.0,bronze],
        [0.36,0.84,0.16,-0.08,chalk],
        [1.15,0.16,0.16,0.26,chalk],
        [0.10,0.18,0.18,0.0,charcoal],
        [1.10,0.16,0.16,0.36,chalk],
        [0.10,0.18,0.18,0.0,rose],
        [1.05,0.16,0.16,0.46,chalk],
        [1.38,0.16,0.08,0.56,chalk],
        [0.06,0.08,0.08,0.0,bronze],
    ], [
        [0.14,0.78,0.78,0.0,bronze],
        [0.42,0.70,0.34,-0.06,chalk],
        [1.20,0.34,0.40,0.10,chalk],
        [0.12,0.60,0.60,0.0,charcoal],
        [1.15,0.40,0.44,0.12,chalk],
        [0.12,0.62,0.62,0.0,rose],
        [1.10,0.42,0.42,0.14,chalk],
        [1.11,0.42,0.10,0.22,chalk],
        [0.06,0.10,0.10,0.0,bronze],
    ], [
        [0.12,0.86,0.86,0.0,bronze],
        [0.40,0.86,0.22,-0.10,chalk],
        [1.50,0.22,0.24,0.02,chalk],
        [0.08,0.30,0.30,0.0,charcoal],
        [1.20,0.24,0.26,0.44,chalk],
        [0.08,0.30,0.30,0.0,rose],
        [0.50,0.22,0.22,-0.03,chalk],
        [1.48,0.24,0.12,0.50,chalk],
        [0.06,0.12,0.12,0.0,bronze],
    ]]
    if outline_family == 1: profiles = alien
    var sections: Array = profiles[clampi(profile_kind,0,profiles.size()-1)]
    var recipe_height := 0.0
    for section in sections:
        recipe_height += float(section[0])
    for section in sections:
        _section(float(section[0])*column_height/recipe_height,
            float(section[1])*width_factor,float(section[2])*width_factor,
            float(section[3])*width_factor,section[4])
    surface.mesh = column_mesh
    add_child(surface)
    if collisions:
        body = StaticBody3D.new()
        var shape := CollisionShape3D.new()
        shape.shape = column_mesh.create_trimesh_shape()
        body.add_child(shape)
        add_child(body)
    set_meta("radial_segments",radial_segments)
    set_meta("profile_rings",profile_rings)
    set_meta("triangle_count",triangle_count)
    set_meta("profile",names(outline_family)[clampi(profile_kind,0,PROFILE_NAMES.size()-1)])
    set_meta("height_metres",height)

## The names of a family's five outlines, in profile_kind order.
static func names(family: int) -> Array[String]:
    return ALIEN_NAMES if family == 1 else PROFILE_NAMES

func _material(colour: Color, roughness: float, metal: float) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = colour
    result.roughness = roughness
    result.metallic = metal
    result.cull_mode = BaseMaterial3D.CULL_BACK
    return result

func _section(h: float, start: float, finish: float, bulge: float, material: Material) -> void:
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    # Extra height divisions change a curved profile. A straight collar needs one.
    var steps := profile_rings if bulge != 0.0 else 1
    for j in range(steps):
        var u := float(j)/steps
        var v := float(j+1)/steps
        var r0 := lerpf(start,finish,u)+bulge*sin(PI*u)
        var r1 := lerpf(start,finish,v)+bulge*sin(PI*v)
        for i in radial_segments:
            var a := TAU*float(i)/radial_segments
            var b := TAU*float(i+1)/radial_segments
            var p0 := Vector3(cos(a)*r0,height+u*h,sin(a)*r0)
            var p1 := Vector3(cos(a)*r1,height+v*h,sin(a)*r1)
            var p2 := Vector3(cos(b)*r1,height+v*h,sin(b)*r1)
            var p3 := Vector3(cos(b)*r0,height+u*h,sin(b)*r0)
            _triangle(vertices,normals,p0,p1,p2)
            _triangle(vertices,normals,p0,p2,p3)
    for i in radial_segments:
        var a := TAU*float(i)/radial_segments
        var b := TAU*float(i+1)/radial_segments
        _triangle(vertices,normals,Vector3(0,height,0),Vector3(cos(a)*start,height,sin(a)*start),Vector3(cos(b)*start,height,sin(b)*start))
        _triangle(vertices,normals,Vector3(0,height+h,0),Vector3(cos(b)*finish,height+h,sin(b)*finish),Vector3(cos(a)*finish,height+h,sin(a)*finish))
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    # self.finish: this function's own "finish" is the section's end radius
    if self.finish == "gradient":
        var colours := PackedColorArray()
        for vertex in vertices:
            colours.append(gradient_low.lerp(gradient_high,clampf((vertex.y-gradient_start)/maxf(column_height-gradient_start,0.01),0.0,1.0)))
        arrays[Mesh.ARRAY_COLOR] = colours
    column_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    column_mesh.surface_set_material(column_mesh.get_surface_count()-1,material)
    height += h

func _triangle(vertices: PackedVector3Array, normals: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
    var normal := (b-a).cross(c-a).normalized()
    # Godot treats clockwise triangles as front faces; keep the outward normal.
    vertices.append_array(PackedVector3Array([a,c,b]))
    normals.append_array(PackedVector3Array([normal,normal,normal]))
    triangle_count += 1

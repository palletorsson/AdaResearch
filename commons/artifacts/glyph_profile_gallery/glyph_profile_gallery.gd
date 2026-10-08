# glyph_profile_gallery.gd
# Six unchanged glyph sweeps hosted by Endless Museum. The museum owns the room,
# player, lighting and input. Local y=0 is the finished floor; there is no floor here.
extends Node3D

const Sweep = preload("profile_sweep.gd")
const FONT_PATH := "res://commons/artifacts/glyph_profile_gallery/JetBrainsMono-Medium.ttf"
const GLYPHS := ["O", "O", "B", "C", "I", ":"]
const TITLES := ["01  /  A PASSAGE", "02  /  A FLARED VESSEL", "03  /  TWO WELLS", "04  /  A CURLED CHANNEL", "05  /  A NEW HOLE", "06  /  TWO BODIES"]
const OPERATIONS := ["O  +  depth", "O  +  changing width", "B  +  rising turn", "C  +  curved path", "I  +  closed path", ":  +  one shared path"]
const LIMITS := [
    "The lower stroke is a sill; this is not a level doorway.",
    "Both ends stay open. No base has been added.",
    "Two separate channels; no branch connects them.",
    "An open-sided curve is not a closed hole.",
    "The path closes. The starting I has no hole.",
    "One character, two bodies. Their separation remains."
]
const COLOURS := ["edcad7", "dcafa8", "bfc9bd", "a9b9d5", "d0bedf", "ded5b7"]
const PLINTH_SIZE := Vector3(8.6, 0.24, 8.8)
const COLUMN_OFFSET := 7.0
const ROW_SPACING := 11.0

## Static world collision. Concave sculpture shapes retain each opening and sill.
@export_flags_3d_physics var collision_layer: int = 1
@export_flags_3d_physics var collision_mask: int = 1

var specimens: Array[MeshInstance3D] = []
var stations: Array[Node3D] = []
var sections: Array[Dictionary] = []
var section_frames: Array = []
var font := FontFile.new()

func _ready() -> void:
    if font.load_dynamic_font(FONT_PATH) != OK:
        push_error("Glyph Profile Gallery: could not load the included OFL font.")
        return
    for i in GLYPHS.size():
        _build_station(i)

func _build_station(index: int) -> void:
    var station := Node3D.new()
    station.name = "Station%02d" % (index + 1)
    # Faces the central aisle. These transforms change placement, never sweep geometry.
    var left := index % 2 == 0
    station.position = Vector3(-COLUMN_OFFSET if left else COLUMN_OFFSET, 0.0, (floori(index / 2.0) - 1) * ROW_SPACING)
    station.rotation.y = PI / 2.0 if left else -PI / 2.0
    add_child(station)
    stations.append(station)
    _box(station, "Plinth", PLINTH_SIZE, Vector3(0, PLINTH_SIZE.y / 2.0, 0), Color("bab6b0"))
    var section := Sweep.profile(font, GLYPHS[index])
    var frames := _frames(index)
    sections.append(section)
    section_frames.append(frames)
    var sculpture := MeshInstance3D.new()
    sculpture.name = "Sculpture"
    sculpture.mesh = Sweep.make(section, frames, index == 4)
    sculpture.position.y = PLINTH_SIZE.y
    sculpture.material_override = _material(Color(COLOURS[index]), .28 if index == 4 else .48, .50 if index == 4 else .08)
    station.add_child(sculpture)
    specimens.append(sculpture)
    _mesh_collision(sculpture)
    # Low labels retain the standalone gallery's plinth reading, without obstructing
    # the O's approach or claiming that its existing sill has become accessible.
    _label(station, TITLES[index], Vector3(0, .72, 4.31), .005, 30)
    _label(station, OPERATIONS[index], Vector3(0, .51, 4.31), .0045, 23)
    _label(station, LIMITS[index], Vector3(0, .30, 4.31), .0038, 20)
    # Each original 2D profile remains visible beside the body it supplies.
    var profile := MeshInstance3D.new()
    profile.name = "SourceProfile"
    var slab_frames: Array[Transform3D] = [Transform3D(Basis.IDENTITY, Vector3.ZERO), Transform3D(Basis.IDENTITY, Vector3(0, 0, .06))]
    profile.mesh = Sweep.make(section, slab_frames)
    profile.position = Vector3(-3.25, 1.24, 2.8)
    profile.material_override = _material(Color("eadcd1"), .72, 0)
    station.add_child(profile)
    _box(station, "ProfileBacking", Vector3(1.3, 1.45, .14), Vector3(-3.25, 1.02, 2.69), Color("36333e"))

func _material(colour: Color, rough: float, metal: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.roughness = rough
    material.metallic = metal
    return material

func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, colour: Color) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = at
    mesh_instance.material_override = _material(colour, .8, 0)
    parent.add_child(mesh_instance)
    var shape := BoxShape3D.new()
    shape.size = size
    _collision(mesh_instance, shape)

func _mesh_collision(mesh_instance: MeshInstance3D) -> void:
    var shape := mesh_instance.mesh.create_trimesh_shape()
    shape.backface_collision = true
    _collision(mesh_instance, shape)

func _collision(parent: Node3D, shape: Shape3D) -> void:
    var body := StaticBody3D.new()
    body.name = "StaticCollision"
    body.collision_layer = collision_layer
    body.collision_mask = collision_mask
    var collider := CollisionShape3D.new()
    collider.shape = shape
    body.add_child(collider)
    parent.add_child(body)

func _label(parent: Node3D, words: String, at: Vector3, pixel: float, size: int) -> void:
    var caption := Label3D.new()
    caption.text = words
    caption.font = font
    caption.position = at
    caption.font_size = size
    caption.pixel_size = pixel
    caption.outline_size = 0
    caption.modulate = Color("322c3c")
    caption.no_depth_test = false
    parent.add_child(caption)

## The original six recipes are copied verbatim from the preserved standalone study.
func _frames(kind: int) -> Array[Transform3D]:
    var frames: Array[Transform3D] = []
    var upright := Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP)
    var steps := 96 if kind==4 else (1 if kind==0 else 48)
    for i in range(steps if kind==4 else steps+1):
        var t := float(i)/float(steps)
        var basis := Basis.IDENTITY
        var centre := Vector3.ZERO
        var width := 1.0
        match kind:
            0: # O is an upright doorway, extrusion front to back.
                width = 5.4
                centre = Vector3(0,2.7,lerpf(-1.1,1.1,t))
            1: # The annulus stays open at BOTH ends: vessel, not a sealed cup.
                width = 2.3-.65*sin(PI*t)+2.5*pow(t,3)
                basis = upright * Basis(Vector3.BACK,.22*PI*t)
                centre = Vector3(0,4.6*t,0)
            2: # Both B holes remain channels while the profile turns.
                width = 3.5
                basis = upright * Basis(Vector3.BACK,PI*.38*t)
                centre = Vector3(0,5.2*t,0)
            3: # Section frame follows the tangent of an open circular path.
                var angle := lerpf(-PI*.69,PI*.69,t)
                var radial := Vector3(cos(angle),0,sin(angle))
                basis = Basis(radial,Vector3.UP,Vector3(-sin(angle),0,cos(angle)))
                width = 2.2
                centre = radial*2.6+Vector3(0,1.1,0)
            4: # The I has no hole; joining the sweep creates one.
                var angle := TAU*t
                var radial := Vector3(cos(angle),0,sin(angle))
                basis = Basis(radial,Vector3.UP,Vector3(-sin(angle),0,cos(angle)))
                width = 1.4
                centre = radial*2.25+Vector3(0,.7,0)
            5: # Separate dots remain separate along the same bending frames.
                width = 3.8
                basis = upright * Basis(Vector3.BACK,-.35*PI*t)
                centre = Vector3(.9*sin(PI*t),4.8*t,0)
        frames.append(Transform3D(basis.scaled_local(Vector3(width,width,1)),centre))
    return frames



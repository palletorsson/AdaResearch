extends Node3D

signal side_changed(side: int)
var side := 4
var track: XRToolsInteractableSlider
var caption: Label3D
const TRAVEL := 0.8

class Track extends XRToolsInteractableSlider:
    func _process(_delta: float) -> void:
        if grabbed_handles.is_empty(): return
        var positions: Array[Vector3] = []
        var offset := 0.0
        for handle in grabbed_handles:
            positions.append(handle.global_position)
            offset += to_local(handle.global_position).x - to_local(handle.handle_origin.global_position).x
        move_slider(slider_position + offset / grabbed_handles.size())
        for i in range(grabbed_handles.size()):
            grabbed_handles[i].global_position = positions[i]

func box(parent: Node3D, size: Vector3, colour: Color) -> void:
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    visual.material_override = material
    parent.add_child(visual)

func _ready() -> void:
    box(self, Vector3(TRAVEL + 0.1, 0.025, 0.025), Color(0.65, 0.65, 0.65))
    var origin := Node3D.new()
    origin.position.x = -TRAVEL / 2
    track = Track.new()
    track.slider_limit_max = TRAVEL
    track.slider_steps = TRAVEL / 14
    track.slider_position = float(side - 2) / 14 * TRAVEL
    track.default_on_release = false
    var grip := Node3D.new()
    var handle := XRToolsInteractableHandle.new()
    handle.freeze = true
    handle.collision_layer = 1 << 18
    handle.collision_mask = 0
    handle.picked_up_layer = 0
    handle.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(0.08, 0.12, 0.08)
    collision.shape = shape
    handle.add_child(collision)
    grip.add_child(handle)
    track.add_child(grip)
    box(track, shape.size, Color(0.9, 0.4, 0.6))
    origin.add_child(track)
    add_child(origin)
    caption = Label3D.new()
    caption.position.y = -0.13
    caption.pixel_size = 0.002
    caption.font_size = 24
    add_child(caption)
    set_side(side)
    track.slider_moved.connect(on_slide)

func set_side(value: int) -> void:
    side = clampi(value, 2, 16)
    if track: track.slider_position = float(side - 2) / 14 * TRAVEL
    if caption: caption.text = "MATRIX %d x %d | drag handle" % [side, side]

func on_slide(metres: float) -> void:
    set_side(2 + roundi(metres / TRAVEL * 14))
    side_changed.emit(side)

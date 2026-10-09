extends Node3D

class Sample:
    var position: Vector3
    var time: float

    func _init(at: Vector3, seconds: float) -> void:
        position = at
        time = seconds

@export var sample_interval := 0.025
@export var trail_speed := 0.6
var length := 1.0
var gravity := 9.8
var initial_angle := PI / 4.0
var angle := initial_angle
var angular_velocity := 0.0
var elapsed := 0.0
var sample_clock := 0.0
var max_samples := 120
var max_age := 6.0
var history: Array[Sample] = []
var marks: Array[MeshInstance3D] = []
var pivot := Node3D.new()
var cube := MeshInstance3D.new()
var label := Label3D.new()

func _ready() -> void:
    assert(sample_interval > 0.0 and length > 0.0)
    var mesh := BoxMesh.new()
    pivot.position = Vector3(0, 2.0, 0)
    add_child(pivot)
    cube.mesh = mesh
    cube.scale = Vector3.ONE * 0.4
    cube.position.y = -length
    pivot.add_child(cube)
    var rod := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.008
    cylinder.bottom_radius = 0.008
    cylinder.height = length
    rod.mesh = cylinder
    rod.position.y = -length / 2.0
    pivot.add_child(rod)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.08, 0.65, 0.7)
    ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    for i in range(max_samples):
        var mark := MeshInstance3D.new()
        mark.mesh = mesh
        mark.material_override = ink
        mark.scale = Vector3.ONE * 0.035
        mark.visible = false
        add_child(mark)
        marks.append(mark)
    label.position = Vector3(0, 2.35, 0)
    label.font_size = 36
    label.pixel_size = 0.0025
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)
    draw_state()

func _physics_process(delta: float) -> void:
    var acceleration := -(gravity / length) * sin(angle)
    angular_velocity += acceleration * delta
    angle += angular_velocity * delta
    elapsed += delta
    pivot.rotation.z = angle
    sample_clock += delta
    if sample_clock >= sample_interval:
        sample_clock = fmod(sample_clock, sample_interval)
        history.append(Sample.new(to_local(cube.global_position), elapsed))
    while history.size() > max_samples:
        history.pop_front()
    while not history.is_empty() and elapsed - history[0].time > max_age:
        history.pop_front()

func _process(_delta: float) -> void:
    draw_state()

func display_position(sample: Sample) -> Vector3:
    var age := elapsed - sample.time
    return sample.position + Vector3.FORWARD * age * trail_speed

func draw_state() -> void:
    pivot.rotation.z = angle
    for i in range(marks.size()):
        marks[i].visible = i < history.size()
        if i < history.size():
            marks[i].position = display_position(history[i])
    label.text = "swing %.2f rad   time %.2f s\n%d marks   request %.3f s" % [
        angle, elapsed, history.size(), sample_interval]

func set_sampling(seconds: float) -> void:
    assert(seconds > 0.0)
    sample_interval = seconds
    sample_clock = 0.0
    history.clear()
    draw_state()

func reset_experiment() -> void:
    angle = initial_angle
    angular_velocity = 0.0
    elapsed = 0.0
    sample_clock = 0.0
    history.clear()
    draw_state()

extends Node3D
## Supplied comparison equipment. Three small feelers move through the stations.
## Actual physics contact stops each feeler; the repeating sweep lets us compare
## visible radius and collision radius without supplying an XR player.

const SPEED := 0.4
const HALF_TRAVEL := 0.5
const CENTRE_HEIGHT := 1.12
const CYCLE_SECONDS := 4.5
const PROBE_SIZE := Vector3(0.035, 0.14, 0.06)
var probes: Array[CharacterBody3D] = []
var labels: Array[Label3D] = []
var origins: Array[Vector3] = []
var stopped: Array[bool] = []
var elapsed: float = 0.0
var paused: bool = false

func _ready() -> void:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.95, 0.38, 0.62)
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    for station_name: String in ["Position", "Visible", "Solid"]:
        var station := get_parent().get_node(station_name) as Node3D
        var start := to_local(station.to_global(Vector3(-HALF_TRAVEL, CENTRE_HEIGHT, 0)))
        origins.append(start)
        var probe := CharacterBody3D.new()
        probe.name = station_name + "Probe"
        probe.collision_layer = 0
        probe.collision_mask = 1
        probe.safe_margin = 0.001
        var shape := BoxShape3D.new()
        shape.size = PROBE_SIZE
        var collision := CollisionShape3D.new()
        collision.shape = shape
        probe.add_child(collision)
        var mesh := BoxMesh.new()
        mesh.size = PROBE_SIZE
        var visible := MeshInstance3D.new()
        visible.mesh = mesh
        visible.material_override = material
        probe.add_child(visible)
        add_child(probe)
        probes.append(probe)
        stopped.append(false)
        var label := Label3D.new()
        label.name = station_name + "Contact"
        label.font_size = 40
        label.pixel_size = 0.002
        label.outline_size = 0
        label.modulate = Color(0.97, 0.75, 0.83)
        label.position = to_local(station.to_global(Vector3(0, 0.48, 0)))
        add_child(label)
        labels.append(label)
    reset_sweep()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_SPACE:
            paused = not paused
        elif event.physical_keycode == KEY_R:
            reset_sweep()

func reset_sweep() -> void:
    elapsed = 0.0
    for i in probes.size():
        probes[i].position = origins[i]
        probes[i].velocity = Vector3.ZERO
        stopped[i] = false
        labels[i].text = "approaching"

func _physics_process(delta: float) -> void:
    if paused:
        return
    elapsed += delta
    if elapsed >= CYCLE_SECONDS:
        reset_sweep()
        return
    for i in probes.size():
        if stopped[i]:
            continue
        var remaining: float = origins[i].x + 2.0 * HALF_TRAVEL - probes[i].position.x
        if remaining <= 0.0001:
            labels[i].text = "crossed"
            continue
        var hit := probes[i].move_and_collide(Vector3(minf(SPEED * delta, remaining), 0, 0))
        if hit:
            stopped[i] = true
            labels[i].text = "stopped"

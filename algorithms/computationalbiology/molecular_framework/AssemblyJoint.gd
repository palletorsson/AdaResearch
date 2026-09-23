extends XRToolsPickable
## A destination the visitor can leave elsewhere. The assembly owns the pose.
var study: Node3D
var joint_index: int
var desktop_held := false

func _init() -> void:
	freeze = true
	release_mode = ReleaseMode.FROZEN
	gravity_scale = 0.0
	lock_rotation = true
	ranged_grab_method = RangedMethod.LERP
	collision_layer = 4
	collision_mask = 0

func _ready() -> void:
	super._ready()
	picked_up.connect(_taken)
	dropped.connect(_released)
	highlight_updated.connect(_highlight)

func _taken(_part: Node3D) -> void:
	study.begin_edit(joint_index)

func _released(_part: Node3D) -> void:
	study.finish_edit(joint_index)

func on_desktop_grab(_pointer: Node) -> void:
	desktop_held = true
	study.begin_edit(joint_index)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_held = false
	study.finish_edit(joint_index)

func _highlight(_part: Node3D, on: bool) -> void:
	var material := $Mesh.material_override as StandardMaterial3D
	material.emission_energy_multiplier = 1.1 if on else 0.25

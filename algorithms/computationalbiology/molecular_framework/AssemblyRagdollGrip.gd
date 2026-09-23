extends XRToolsPickable
## A hand target, not a teleported limb. The study pulls its physics body by force.
var study: Node3D
var point_id: String
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
	picked_up.connect(func(_part): study.begin_pull(point_id))
	dropped.connect(func(_part): study.end_pull(point_id))

func on_desktop_grab(_pointer: Node) -> void:
	desktop_held = true
	study.begin_pull(point_id)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_held = false
	study.end_pull(point_id)

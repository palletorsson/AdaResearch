extends "point_body.gd"

func _ready() -> void:
    super()
    release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
    freeze = false
    gravity_scale = 0.0
    linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
    linear_damp = 0.0
    angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
    angular_damp = 0.0
    can_sleep = false
    var black := StandardMaterial3D.new()
    black.albedo_color = Color("17191c")
    black.roughness = 0.16
    get_child(0).material_override = black


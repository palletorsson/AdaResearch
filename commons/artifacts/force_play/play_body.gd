extends XRToolsPickable
## Shared physical prefab, using the museum's normal hand and desktop pickup.
func _init() -> void:
	release_mode=ReleaseMode.UNFROZEN
	freeze_mode=RigidBody3D.FREEZE_MODE_KINEMATIC
	collision_layer=4; collision_mask=524293
	continuous_cd=true

func on_desktop_grab(_pointer: Node3D) -> void:
	set_meta("capability_desktop_held",true)

func on_desktop_drop(_pointer: Node3D) -> void:
	remove_meta("capability_desktop_held")
	freeze=false; sleeping=false

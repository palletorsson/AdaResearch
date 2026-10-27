extends Node
## Keep the real record/controls, with room to stand in front after the walk
## field is rotated across the tower. All new poses stay artifact-local.
const Block = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn")
func _ready() -> void:install.call_deferred()
func install() -> void:
	var work: Node3D = get_parent();var study: Node3D = work.get_node("HistoryStudy")
	var config: Dictionary = work.get_meta("config_curated_console",{})
	if config.is_empty():return
	var yaw := deg_to_rad(float(config.yaw));var basis := Basis(Vector3.UP,yaw);var at := v(config.position)
	study.console.transform = Transform3D(basis*Basis(Vector3.RIGHT,deg_to_rad(-60)),at)
	for name_ in ["DeskFoot","DeskStem"]:study.get_node(name_).queue_free()
	var podium: Node3D = Block.instantiate();podium.name = "OperatingPodium";podium.platform_size = Vector3(1.7,.88,.7)
	work.add_child(podium);podium.position = at-Vector3(0,1.4,0);podium.rotation.y = yaw
	var badge: Node3D = study.get_node("ReadoutHousing");badge.transform = Transform3D(basis,v(config.readout))
	var stem: Node3D = study.get_node("ReadoutStem");stem.transform = Transform3D(basis,v(config.readout)-Vector3(0,.925,0))
func v(a: Array) -> Vector3:return Vector3(a[0],a[1],a[2])

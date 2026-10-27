extends Node
## The broad Life field is turned across the tower. Its original console would
## face a shaft; remount those same controls and carried point on the south rim.
const Block = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn")
func _ready() -> void:install.call_deferred()
func install() -> void:
	var work: Node3D = get_parent();var study: Node3D = work.get_node("AddressStudy")
	var config: Dictionary = work.get_meta("config_curated_console",{})
	if config.is_empty():return
	var yaw := deg_to_rad(float(config.yaw));var basis := Basis(Vector3.UP,yaw)
	var at := v(config.position)
	study.console.transform = Transform3D(basis*Basis(Vector3.RIGHT,deg_to_rad(-35)),at)
	var podium := Block.instantiate() as Node3D;podium.name = "OperatingPodium";podium.platform_size = Vector3(1.7,.88,.7)
	work.add_child(podium);podium.position = at-Vector3(0,1.06,0);podium.rotation.y = yaw
	var dock := v(config.dock)
	var hand: Node3D = study.get_node("LifeHand")
	hand.basis = basis;hand.position = dock-basis*Vector3(1.35,0,-2.3)
	for child in hand.get_children():
		if child is Label3D:child.rotation.y = 0
	for name_ in ["HandShelf","HandStem","HandInstructions"]:
		var n: Node3D = study.get_node(name_);var relative: Vector3 = n.position-Vector3(1.35,0,-2.3)
		n.transform = Transform3D(basis,dock+basis*relative)
	var read: Node3D = study.get_node("ReadoutHousing");read.transform = Transform3D(basis,v(config.readout))
	var stem: Node3D = study.get_node("ReadoutStem");stem.transform = Transform3D(basis,v(config.readout)-Vector3(0,.95,0))
func v(a: Array) -> Vector3:return Vector3(a[0],a[1],a[2])

extends Node3D
## The family in the editor. The spire leans with the rail, and behind it Ada's
## pyramid stands once for each value of its own enum: a sweep sheet of our own.

const Look := preload("res://supplied/look.gd")
const AdaPyramid := preload("res://borrowed/ada_pyramid.gd")

@export var axis := "apex_stance"   # the field of Ada's pyramid that we sweep
@export var spacing := 1.2          # metres from one member's middle to the next

func _ready() -> void:
	$Rail.value = $Spire.lean
	var values := values_of(AdaPyramid, axis)
	for i in values.size():
		var member := AdaPyramid.new()
		member.set(axis, values[i])    # before add_child(): this class builds once, in _ready()
		member.set_base_color(Look.BODIES[i % 4])
		member.position = Vector3(i * spacing, 0, 0)
		$Wall.add_child(member)
		var apex := built_apex(member)
		var title := values[i]
		if maxf(absf(apex.x), absf(apex.z)) > member.base_size / 2 + 0.001:
			title += "\noff its base"
		var plate := Look.label(title)
		plate.font_size = 36
		plate.position = member.position + Vector3(0, 1.1, 0)
		$Wall.add_child(plate)
		print(values[i], " asked: apex built over ", Vector2(apex.x, apex.z))

func _process(_delta: float) -> void:
	if $Rail.held:
		$Spire.lean = $Rail.value
	$Readout.text = "lean %.2f    over its base: %s    built %d times" % [$Spire.lean, $Spire.over_base(), $Spire.rebuilds]

## The values an exported enum offers, read from the class and not typed again.
func values_of(script: Script, field: String) -> PackedStringArray:
	for property: Dictionary in script.get_script_property_list():
		if property["name"] == field:
			return property["hint_string"].split(",")
	return PackedStringArray()

## Where the apex of a built member is: the highest corner of its mesh.
func built_apex(member: Node3D) -> Vector3:
	var top := Vector3.ZERO
	for corner: Vector3 in member.get_node("Pyramid").mesh.get_faces():
		if corner.y > top.y:
			top = corner
	return top

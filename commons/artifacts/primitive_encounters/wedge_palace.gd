extends Node3D
const Kit=preload("geometry.gd")
## In the Polythedra hall the structure layer and wp utilities own the geometry.
## Keep this anchor for writing-wall references without adding a second platform.
var layout: String = "standalone"
func apply_grid_config(config: Dictionary) -> void:
	if str(config.get("layout", layout)) == layout: return
	layout = str(config.get("layout", layout))
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if layout != "map" and is_node_ready(): _build_standalone()

## A single broad prism on either side, equal runs and equal rises.
func _ready() -> void:
	layout = str(get_meta("config_layout", layout))
	if layout != "map": _build_standalone()

func _build_standalone() -> void:
	Kit.box(self,"Platform",Vector3(0,0.45,0),Vector3(4,0.9,4),Color("d6c8be"))
	for side in [-1,1]:
		var ramp:=Kit.solid(self,"WestWedge" if side<0 else "EastWedge",Kit.wedge(2.4,0.9,3),Kit.wedge_faces(),Color("b5a4c6"))
		ramp.position=Vector3(side*3.5,0,0);ramp.rotation.y=-side*PI/2
	var down:=Kit.solid(self,"DescentWedge",Kit.wedge(2.4,0.9,3),Kit.wedge_faces(),Color("b5a4c6"))
	down.position=Vector3(0,0,3.5);down.rotation.y=PI
	# Low edge accents leave both side approaches and the far descent open.
	Kit.box(self,"FrontEdge",Vector3(0,0.92,-1.96),Vector3(4,0.035,0.05),Color("9b577a"),false)
	Kit.label(self,"THE SAME WEDGE SUPPORTS A JOURNEY",Vector3(0,0.012,-3.4),26).rotation.x=-PI/2
func get_museum_occupied_cells() -> Array:
	# All surfaces are walkable; runtime probes check all three ramps.
	return []

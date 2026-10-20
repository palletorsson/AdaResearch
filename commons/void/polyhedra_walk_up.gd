extends Node3D
## Architectural shaft cover; the learning objects here are six-vertex wp prisms.
## Reusable one-metre cubes first enter on the following Cube floor.
const Geometry = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Ramp = preload("res://commons/artifacts/primitive_encounters/wedge_blocker.tscn")
# The support area faces 90 degrees: local 6 x 5 m covers the world 5 x 6 m shaft.
const DECK_SIZE := Vector3(6, 1, 5)
func _ready() -> void:
	var platform := Node3D.new()
	platform.name="ShaftCover"
	add_child(platform)
	Geometry.box(platform,"Slab",Vector3.UP*DECK_SIZE.y/2,DECK_SIZE,Color("b8b5ab"))
	# Three adjacent one-metre wp units form each three-metre-wide approach.
	for side in [-1,1]:
		for lane in [-1,0,1]:
			add_ramp("West" if side<0 else "East",Vector3(side*(DECK_SIZE.x/2+1),0,lane),-side*90)
	for lane in [-1,0,1]: add_ramp("Descent",Vector3(lane,0,DECK_SIZE.z/2+1),180)
	set_meta("construction_definition","wp_shaft_cover")
	set_meta("deck_height",1.0)

func add_ramp(title: String, at: Vector3, facing: float) -> void:
	var ramp := Ramp.instantiate() as Node3D
	ramp.name=title+str(get_child_count());ramp.position=at;ramp.rotation_degrees.y=facing
	add_child(ramp)

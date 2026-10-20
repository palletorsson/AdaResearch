extends "res://tools/probes/transformation_encounters.gd"
const SOURCES={
	"shannon_entropy_meter":"/shannon_entropy_meter.gd", "entropy_jar_states":"/ordinary_entropies/jar_states.gd",
	"entropy_jar":"/entropy_jar/entropy_jar.gd", "entropy_sorting_table":"/entropy_sorting_table/entropy_sorting_table.gd",
	"entropy_compartments":"/entropy_compartments/entropy_compartments.gd", "prefab_disorder":"/prefab_disorder/prefab_disorder.gd",
	"hardware_entropy_decay":"/hardware_entropy_decay/hardware_entropy_decay.gd", "entropy_axiom":"/entropy_axiom/entropy_axiom_multimesh.gd",
	"entropy_ruin":"/randomness_space/entropy_ruin_physics.gd", "signal_room":"/spine_studies/station.gd",
	"weathering_wall":"/em/em_weathering_wall.gd"}
func map_world(p: Vector3) -> Vector3:
	return hall.to_global(p+Vector3(0,0,float(museum.get("VESTIBULE_H"))))
func measured(node: Node3D) -> Dictionary:
	var bounds:=AABB();var first:=true;var meshes:=0
	for n in node.find_children("*","VisualInstance3D",true,false):
		if not n.is_visible_in_tree() or n is Label3D:continue
		if not (n is MeshInstance3D or n is MultiMeshInstance3D):continue
		var box: AABB=n.global_transform*n.get_aabb()
		bounds=box if first else bounds.merge(box);first=false;meshes+=1
	return {"at":xyz(node.global_position),"yaw":node.global_rotation_degrees.y,"min":xyz(bounds.position),"max":xyz(bounds.end),"meshes":meshes,"script":node.get_script().resource_path}
func landing_checks() -> void:
	root.size=Vector2i(1700,1200);museum.call("flush_stamps");await create_timer(0.5).timeout
	observations.artifacts={}
	for key in SOURCES:
		var node:=find_scene(SOURCES[key])
		check("present: "+key,node!=null)
		if node!=null:observations.artifacts[key]=measured(node)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=39
	await snapshot("hall-plan",map_world(Vector3(12.5,46,16.51)),map_world(Vector3(12.5,0,16.5)),60)
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("arrival",map_world(Vector3(8.5,1.65,2.6)),map_world(Vector3(10,1.4,9)),72)
	await snapshot("first-bay",map_world(Vector3(14.8,5,28)),map_world(Vector3(8,1.5,10)),65)

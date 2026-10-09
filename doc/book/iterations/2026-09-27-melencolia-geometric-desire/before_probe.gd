extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
 museum.flush_stamps();await create_timer(1.0).timeout
 var old := find_scene("/DurerScene.gd")
 check("old tableau present",old!=null)
 if old==null:return
 await snapshot("before-tableau",Vector3(6.5,3.7,14.0),Vector3(6.5,3.7,17.0),74)

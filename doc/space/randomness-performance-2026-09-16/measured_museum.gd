extends "res://commons/scenes/endless_museum.gd"
## Instrumentation confined to the diagnostic; production loading is unchanged.
var stamp_times: Array = []
var segment_times: Array = []

func _stamp_inner(seg: Node3D, scene_path: String, lookup: String, cell: Dictionary,
		zbase: int, fp: int, axis_entry: Dictionary, drop_if_unvaried: bool,
		span_cap: float = 0.0, yaw_deg: float = 0.0,
		plan_config: Dictionary = {}, defer_bk: Dictionary = {}) -> bool:
	var started := Time.get_ticks_usec()
	var success := super._stamp_inner(seg,scene_path,lookup,cell,zbase,fp,axis_entry,
		drop_if_unvaried,span_cap,yaw_deg,plan_config,defer_bk)
	stamp_times.append({"lookup":lookup,"ms":(Time.get_ticks_usec()-started)/1000.0,"success":success,"queued":defer_bk.is_empty(),"scene":scene_path})
	return success

func _build_segment() -> void:
	var started := Time.get_ticks_usec()
	super._build_segment()
	segment_times.append({"ms":(Time.get_ticks_usec()-started)/1000.0,"shell":_vr_shell_building})

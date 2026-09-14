extends RefCounted
## Where a PROBE writes its evidence — screenshots, JSON results, review frames.
## The GDScript twin of tools/evidence_root.py (2026-09-14).
##
## Palle chose the encyclopedia's captures/ folder, on disk only, for everything that is
## evidence rather than game data. Probes move to this helper as they are touched;
## tools/sweep_evidence.py collects whatever still lands in ada_run/.
##
## NEVER for game data. The museum reads ada_run/em_plan.json, necklace_hand.json and
## em_cartridges/ every run; those stay where they are, and nothing here may route them.
##
## preload, not class_name — a new class_name is not in the global cache until the next
## editor import, and a probe that names it fails to compile until then:
##
##   const Evidence := preload("res://commons/testing/evidence_root.gd")
##   var out: String = Evidence.dir("voxel-review-2026-09-13")   # absolute, created
##
## An absolute OS path, because captures/ is outside res://. FileAccess and
## Image.save_png take one in a dev run. With no encyclopedia on this machine it returns
## the old res://ada_run/ path, so a probe never fails because of where evidence goes.


static func encyclopedia() -> String:
	var env: String = OS.get_environment("ADA_ENCYCLOPEDIA_PATH").strip_edges()
	if env != "" and FileAccess.file_exists(env.path_join("package.json")):
		return env
	var sibling: String = ProjectSettings.globalize_path("res://").path_join("../ada_encyclopedia").simplify_path()
	if FileAccess.file_exists(sibling.path_join("package.json")):
		return sibling
	return ""


## kind "ada-run" replaces res://ada_run/<rel>; "doc-reports" replaces res://doc/reports/<rel>.
static func dir(rel: String = "", kind: String = "ada-run") -> String:
	var enc: String = encyclopedia()
	var base: String
	if enc == "":
		base = "res://ada_run" if kind == "ada-run" else "res://doc/reports"
	else:
		base = enc.path_join("captures").path_join(kind)
	var d: String = base.path_join(rel) if rel != "" else base
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d) if d.begins_with("res://") else d)
	return d

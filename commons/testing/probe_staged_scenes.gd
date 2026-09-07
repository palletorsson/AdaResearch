extends SceneTree
## EVERY SCENE STAGING LOADS MUST BE A SCENE BASE.
##
## 2026-09-07, from the headset:
##
##     Trying to assign value of type 'death_scene.gd' to a variable of type
##     'scene_base.gd'.  vrStaging.gd:718 @ load_scene()
##
## XRToolsStaging assigns what it instantiates into `current_scene`, typed
## XRToolsSceneBase. A plain Node3D root is refused AT THE ASSIGNMENT, so the
## transition dies with no fade, no scene, and nothing said about why. The death
## scene had been reached only by change_scene_to_file until now, which does not
## care — routing it through staging is what surfaced it.
##
## This is a gate rather than one test, because the next scene handed to
## staging will hit the same wall and the message names a .gd file, not the call
## site. Add any new staged destination to the list.

const STAGED := [
	"res://commons/scenes/endless_museum_staged.tscn",
	"res://commons/scenes/death_scene_staged.tscn",
]

const BASE := "res://addons/godot-xr-tools/staging/scene_base.gd"


func _init() -> void:
	var fails := 0
	var base_script: Script = load(BASE)
	print("staging accepts only: %s" % BASE)
	print("")

	for path in STAGED:
		if not ResourceLoader.exists(path):
			print("  MISSING  %s" % path)
			fails += 1
			continue
		var root = (load(path) as PackedScene).instantiate()
		var ok := _derives(root.get_script(), base_script)
		# THE SECOND HALF OF THE CONTRACT, and the one that bit next.
		# scene_base.scene_loaded() does `$XROrigin3D/XRCamera3D.current = true`,
		# so a staged scene must CONTAIN a rig as well as BE a scene base. The
		# first version of this gate checked only the class, passed a rigless
		# death scene, and the headset answered with
		#   Node not found: "XROrigin3D/XRCamera3D"
		# — no camera at all, which is the black screen again by a new road.
		var rig: bool = root.get_node_or_null("XROrigin3D/XRCamera3D") != null
		print("  %-7s %s%s" % ["ok" if (ok and rig) else "REFUSED", path,
			"" if rig else "   (no XROrigin3D/XRCamera3D)"])
		if not ok:
			print("      its root script is %s, which does not derive scene_base —"
				% str(root.get_script().resource_path if root.get_script() else "<none>"))
			print("      staging would refuse it at the current_scene assignment")
			fails += 1
		if not rig:
			print("      it carries no rig, so scene_loaded() has no camera to make")
			print("      current — the headset would render nothing")
			fails += 1
		root.free()

	# THE NEGATIVE. A plain Node3D must be REFUSED, or this gate passes anything
	# and would have passed death_scene.gd on the day it broke.
	var plain := Node3D.new()
	var plain_ok := _derives(plain.get_script(), base_script)
	print("")
	print("a bare Node3D is accepted: %s (must be false)" % plain_ok)
	if plain_ok:
		print("  FAIL the check does not discriminate — it would have missed the bug")
		fails += 1
	plain.free()

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)


## Walk the inheritance chain by resource path — base_script identity is not
## enough, since a scene may extend something that extends scene_base.
func _derives(s: Script, base: Script) -> bool:
	var cur: Script = s
	while cur != null:
		if cur == base or cur.resource_path == base.resource_path:
			return true
		cur = cur.get_base_script()
	return false

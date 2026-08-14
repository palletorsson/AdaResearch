class_name BareHands
extends RefCounted
## Movement-only VR hands — the gadgets removed, the walk kept.
##
## The hands carry a lot besides locomotion: pickups, pointers, ghost hands,
## per-hand Area3Ds, the message console, the wrist workstation, a gravity
## gun, wrist stats. When "the left stick is strange" the honest experiment
## is a rig with NOTHING on it but movement — if walking works bare, the
## fault lives in a gadget, and the strip list below is the suspect list,
## restorable one name at a time.
##
## OPT-IN, three ways (any one enables it):
##   - vr_staging's exported `movement_only_hands` (editor toggle)
##   - `--bare-hands` on the command line
##   - a marker file `user://movement_only_hands.txt`
##     (desktop: %APPDATA%/Godot/app_userdata/<app>/ · Quest: the app's
##      files dir via adb — push an empty file, delete it to restore)
##
## What stays: both hands' Movement* providers (direct, turn, jump, flight),
## XRToolsCollisionHand (the providers are its children), the visible hand
## meshes, PlayerBody, wall-walk, the deadzone calibrator, customization.
## What goes is exactly INTERACTION, never locomotion. The catalyst needs no
## entry here: with FunctionPickup gone the bracelet can never be picked up.
##
## Applied to LOADED scenes' rigs only — the staging menu keeps its pointers,
## because a menu you cannot click is not a diagnosis, it is a lockout.

const STRIP: Array[String] = [
	"FunctionPickup",       # both hands — grab/ranged grab
	"FunctionPointer",      # both hands — laser UI pointer
	"FunctionGazePointer",  # camera gaze pointer
	"GhostHand",            # both hands
	"LeftHandArea3D",       # per-hand interaction areas
	"RightHandArea3D",
	"messageconsole",       # left-hand console
	"HandWorkstationVR",    # left-hand wrist workstation
	"GravityGun",           # right hand
	"WristStatsDisplay",    # right wrist
	"PickupXPListener",     # meaningless without pickups
]


static func wanted() -> bool:
	for a in OS.get_cmdline_args():
		if a == "--bare-hands":
			return true
	for a in OS.get_cmdline_user_args():
		if a == "--bare-hands":
			return true
	return FileAccess.file_exists("user://movement_only_hands.txt")


## Strips every STRIP-named node under the given XR origin. Returns how many
## went; prints each so the log records what tonight's rig did NOT carry.
static func apply(origin: Node) -> int:
	if origin == null:
		return 0
	var gone: int = 0
	for name in STRIP:
		while true:
			var n: Node = origin.find_child(name, true, false)
			if n == null:
				break
			print("[bare-hands] removed %s (%s)" % [name, origin.get_path_to(n)])
			n.get_parent().remove_child(n)
			n.queue_free()
			gone += 1
	if gone > 0:
		print("[bare-hands] MOVEMENT-ONLY RIG: %d gadget(s) removed, locomotion untouched" % gone)
	return gone

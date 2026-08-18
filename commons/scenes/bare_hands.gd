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
## What stays (2026-08-18): both hands' Movement* providers (direct, turn,
## jump, flight), XRToolsCollisionHand, FunctionPickup, FunctionPointer,
## GhostHand, the hand areas, the visible hand meshes, PlayerBody, wall-walk,
## the deadzone calibrator, customization — i.e. THE VR HANDS. What goes is
## the wrist furniture. (Until 08-18 this list also removed the pickups and
## pointers, which is why nothing could be grabbed in any loaded scene.) The
## museum keeps the catalyst bracelet off by disarming catalyst pickables
## itself (endless_museum.gd _plain_hands).
##
## Applied to LOADED scenes' rigs only — the staging menu keeps its pointers,
## because a menu you cannot click is not a diagnosis, it is a lockout.

const STRIP: Array[String] = [
	# THE VR HANDS STAY (2026-08-18). Palle: "Can I have just the hands we've
	# been working with for most of the project. No bracelet, no editing tool,
	# just the VR hands." and, on the museum: "the grab function of the object
	# in the VR endless museum does not work. They did in the grid." It did not
	# work because THIS list took FunctionPickup and FunctionPointer off every
	# loaded scene since 08-14 — the joystick experiment shipped as the default
	# rig. The hands we worked with all year are XRToolsCollisionHand +
	# FunctionPickup + FunctionPointer + GhostHand + the hand areas; those are
	# no longer gadgets here. What goes is the wrist furniture.
	"messageconsole",       # left-hand console
	"HandWorkstationVR",    # left-hand wrist workstation
	"GravityGun",           # right hand
	"WristStatsDisplay",    # right wrist
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

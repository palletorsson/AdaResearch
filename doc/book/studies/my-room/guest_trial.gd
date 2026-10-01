extends "res://supplied/verify_tools.gd"
## The room's test of ONE guest. Copy the guest's folder into guests/, add its
## line to GUESTS in room.gd, then, from this folder:
##   godot --headless --path . --xr-mode off --script res://guest_trial.gd -- <name>
## where <name> is the folder's name: the guest is guests/<name>/<name>.tscn.
## It runs the room for 180 frames, finds the guest, and walks the walker to it
## by the aisles, on its autopilot. It prints what happened, writes
## guest_trial.json, and its exit code is the number of checks that failed.
## What the walker did is reported, not judged: "arrived" means it stands on
## the middle of the place (the guest is low enough to step onto, or has no
## collider there), "blocked" that the guest's collider stopped it.

const CheckGuest := preload("res://supplied/check_guest.gd")

func run() -> void:
	result_file = "res://guest_trial.json"
	var args := OS.get_cmdline_user_args()
	check(args.size() == 1, "one name was given after `--`: %s" % [args])
	if args.size() != 1:
		return
	var folder := "res://guests/%s/" % args[0]
	var scene := folder + args[0] + ".tscn"
	var needs := CheckGuest.outside(folder)
	check(needs.is_empty(), "the guest's folder names nothing outside itself: %s" % [needs])
	var declared := CheckGuest.class_names(folder)
	check(declared.is_empty(), "it declares no class_name: %s" % [declared])
	var room: Node3D = load("res://room.tscn").instantiate()
	root.add_child(room)
	await frames(180)
	check(errors.is_empty(), "the room ran 180 frames with this guest in its list and Godot logged no error: %s" % [errors])
	var number := 0
	for i in room.guests.size():
		if room.guests[i].scene_file_path == scene:
			number = i + 1
	check(number > 0, "the guest stands in the room: %s is at place %d of %d taken" % [scene, number, room.guests.size()])
	if number == 0:
		print("Is its line in GUESTS in room.gd? The room said: ", room.said)
		return
	var place: Vector3 = room.place(number)
	var walker: CharacterBody3D = room.get_node("Walker")
	# By the aisles: along the left wall to the aisle in front of the guest's row, then along that aisle.
	var how := await walk(walker, [Vector3(-9.0, 0.0, 4.0), Vector3(-9.0, 0.0, place.z + 2.0), Vector3(place.x, 0.0, place.z + 2.0)])
	check(how == "arrived", "the walker reached the aisle in front of place %d: \"%s\"" % [number, how])
	how = await walk(walker, [place])
	var at: Vector3 = walker.global_position
	var gap := Vector2(at.x - place.x, at.z - place.z).length()
	check(how == "arrived" or how == "blocked", "then it walked at the guest and the walk ended \"%s\", %.2f m from the middle of the place, its feet at %.2f m" % [how, gap, at.y])
	measured["guest"] = scene
	measured["place"] = number
	measured["walk_ended"] = how
	measured["metres_from_the_middle_of_the_place"] = snappedf(gap, 0.01)
	measured["feet_at_m"] = snappedf(at.y, 0.01)
	await frames(60)
	check(errors.is_empty(), "and Godot logged no error to the end: %s" % [errors])
	room.free()

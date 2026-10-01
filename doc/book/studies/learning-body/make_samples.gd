extends SceneTree
## How samples.json was made. Run it again and the same file comes back:
##   godot --headless --path . --xr-mode off --script res://make_samples.gd
## NOBODY IN THIS FILE IS A PERSON. The course asks for your own walk trace and
## your classmates', with their consent. A kit built at a desk has neither, so
## every labeller here is a stand-in, and the file says so in `about`.
##   the builder   36 places along a figure-eight walk, labelled one by one by
##                 a session that built this kit, looking at a plot of them
##                 (the text LABELS below): where it would stay. That is the front
##                 left loop of the walk but for one place in it, the crossing in the
##                 middle, two places at the back right and one alone at the right edge
##   classmate 1, 2, 3   12 places each, along walks of their own. Each answers
##                 one question by a rule: stay where the floor is near the front,
##                 with a line of its own, and each flips its answer one time in six
##   nobody        the default dataset: two round blobs, pass on the left and
##                 stay on the right. Nobody in the room chose a label of it
##   a coin        the builder's 36 places, each label thrown by a seeded coin
## It also writes the guest's own file, guests/learning-body/samples.json: the
## builder's 36 samples, in the floor's own metres. The guest shrinks them itself.

const SEED := 38
const HALF := Vector2(3.7, 2.2)   # samples stay this far from the middle of the floor, at most

# The builder's 36 labels, in the order of the walk: s is stay, p is pass.
const LABELS := "pppppppsppsspppsssssspssspppppppppsp"

func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var samples: Array = []

	var walk := trace(rng, 36, 0.4, 0.0)
	for i in walk.size():
		samples.append(sample(walk[i], "stay" if LABELS[i] == "s" else "pass", "the builder"))

	var lines := [Vector2(0.15, -0.3), Vector2(-0.1, 0.2), Vector2(0.0, 0.5)]   # stay where z > x * slope + offset
	for c in 3:
		for at: Vector2 in trace(rng, 12, 1.3 + c * 2.1, 0.9 + c):
			var stay: bool = at.y > at.x * lines[c].x + lines[c].y
			if rng.randi_range(1, 6) == 1:
				stay = not stay
			samples.append(sample(at, "stay" if stay else "pass", "classmate %d" % (c + 1)))

	for i in 36:
		var left := i < 18
		var at := Vector2(rng.randfn(-2.0 if left else 2.0, 0.8), rng.randfn(0.0, 0.8))
		samples.append(sample(at.clamp(-HALF, HALF), "pass" if left else "stay", "nobody"))

	for at: Vector2 in walk:
		samples.append(sample(at, "stay" if rng.randi_range(0, 1) == 1 else "pass", "a coin"))

	var data := {
		"about": "Stand-in data, made by make_samples.gd. Nobody in this file is a person.",
		"consent": {"the builder": true, "classmate 1": true, "classmate 2": true, "classmate 3": true},
		"samples": samples,
	}
	write("res://samples.json", data)

	var small: Array = []
	for one: Dictionary in samples:
		if one.labelled_by == "the builder":
			small.append(one)
	write("res://guests/learning-body/samples.json", {"about": data.about, "consent": {"the builder": true}, "samples": small})
	plot(samples, "the builder")
	quit(0)

## A walk as a list of places: a figure-eight, begun at `phase`, each place a little off the curve.
func trace(rng: RandomNumberGenerator, count: int, phase: float, twist: float) -> Array:
	var out: Array = []
	for i in count:
		var t := TAU * i / count + phase
		var at := Vector2(3.3 * sin(t), 1.9 * sin(2.0 * t + twist))
		at += Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.25, 0.25))
		out.append(at.clamp(-HALF, HALF))
	return out

func sample(at: Vector2, label: String, who: String) -> Dictionary:
	return {"x": snappedf(at.x, 0.01), "z": snappedf(at.y, 0.01), "label": label, "labelled_by": who}

func write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t") + "\n")
	file.close()
	print(path, ": ", data.samples.size(), " samples")

## The floor as text, 0.25 m to a letter, for whoever labels by looking: the
## number of each of `who`'s places (its last digit), capital where it says stay.
func plot(samples: Array, who: String) -> void:
	var rows: Array = []
	for z in 20:
		rows.append(".".repeat(32))
	var n := 0
	for one: Dictionary in samples:
		if one.labelled_by != who:
			continue
		var cx := clampi(int((one.x + 4.0) / 0.25), 0, 31)
		var cz := clampi(int((one.z + 2.5) / 0.25), 0, 19)
		rows[cz][cx] = ("S" if one.label == "stay" else "p")
		print("%2d  x %5.2f  z %5.2f  %s" % [n, one.x, one.z, one.label])
		n += 1
	for row: String in rows:
		print(row)

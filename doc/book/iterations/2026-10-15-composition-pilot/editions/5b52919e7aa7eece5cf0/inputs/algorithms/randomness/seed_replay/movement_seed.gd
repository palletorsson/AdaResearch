extends RefCounted
## A recorded measurement becomes a seed. This does not estimate entropy.
const VERSION := "pose-sample-v1"
const MAX_SAMPLES := 300
const MIN_SAMPLES := 30
var samples: Array = []
var changes := 0
var rejected := 0
var source := ""
var _previous: Array = []

func start(kind: String) -> void:
	samples.clear()
	_previous.clear()
	changes = 0
	rejected = 0
	source = kind

func add_pose(pose: Transform3D, elapsed_usec: int, valid: bool = true) -> bool:
	if samples.size() >= MAX_SAMPLES: return false
	if not valid or not pose.is_finite() or pose.basis.determinant() <= 0.000001 or elapsed_usec < 0 or source.is_empty():
		rejected += 1
		return false
	if not samples.is_empty() and elapsed_usec <= int(samples[-1][0]):
		rejected += 1
		return false
	var q := pose.basis.orthonormalized().get_rotation_quaternion()
	# q and -q represent the same orientation. Keep one convention.
	if q.w < 0: q = -q
	var p := pose.origin
	# Integer encoding makes the measurement and replay procedure explicit.
	# Position: 10 micrometre steps; quaternion: one part in a million.
	var values := [roundi(p.x*100000), roundi(p.y*100000), roundi(p.z*100000),
		roundi(q.x*1000000), roundi(q.y*1000000), roundi(q.z*1000000), roundi(q.w*1000000)]
	if not _previous.is_empty() and values != _previous: changes += 1
	_previous = values.duplicate()
	var record := [elapsed_usec]
	record.append_array(values)
	samples.append(record)
	return true

static func digest_for(kind: String, records: Array) -> PackedByteArray:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update((VERSION + "\n" + kind + "\n").to_utf8_buffer())
	for record in records:
		var words := PackedStringArray()
		for value in record: words.append(str(int(value)))
		hash.update((",".join(words) + "\n").to_utf8_buffer())
	return hash.finish()

static func seed_for(kind: String, records: Array) -> int:
	# Retain the bench's 0-999 vocabulary. Many gestures can share a seed.
	# This bounded mapping is for the exhibit, not a cryptographic key.
	return int(digest_for(kind, records).decode_u32(0) % 1000)

func finish() -> Dictionary:
	if samples.size() < MIN_SAMPLES or changes == 0: return {}
	return {"provider":"movement", "source":source, "seed":seed_for(source,samples),
		"sample_count":samples.size(), "changed_samples":changes, "rejected_samples":rejected,
		"duration_usec":int(samples[-1][0]), "recipe":VERSION,
		"sha256":digest_for(source,samples).hex_encode(), "samples":samples.duplicate(true),
		"recorded":true, "minimum":0, "maximum":999,
		"received_utc":Time.get_datetime_string_from_system(true)+"Z"}

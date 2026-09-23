extends Node3D
## Explicit boundary between a displayed specimen and its floor-standing controls.
## The owner opts in via exhibit_control_parts(): console first, then its supports.
## The furniture origin is the authored floor reference; no guessed floor ray.
var floor_host: Node3D
var front_extent := 0.0
var _authored: Dictionary = {}
var _pending := false
var _syncing := false

static func refresh(artifact: Node3D) -> void:
	var mount := artifact.get_node_or_null("ExhibitControlMount")
	if mount != null: mount.sync_now()

func _ready() -> void:
	set_notify_transform(true)
	sync_now()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_inside_tree() and not _pending:
		_pending = true
		_sync_later.call_deferred()

func _sync_later() -> void:
	_pending = false
	sync_now()

func sync_now() -> void:
	if _syncing or not is_inside_tree() or not is_instance_valid(floor_host): return
	var artifact := get_parent() as Node3D
	if artifact == null or not artifact.has_method("exhibit_control_parts"): return
	var parts: Array = artifact.exhibit_control_parts()
	if parts.is_empty(): return
	# A rebuild may temporarily have no complete station. Wait for its explicit
	# refresh rather than caching a partial set of authored transforms.
	for part in parts:
		if not is_instance_valid(part) or not part is Node3D: return
	_syncing = true
	var live: Dictionary = {}
	for part: Node3D in parts:
		var id := part.get_instance_id()
		live[id] = true
		if not _authored.has(id): _authored[id] = part.transform
	for id in _authored.keys():
		if not live.has(id): _authored.erase(id)
	var console: Node3D = parts[0]
	var reference: Transform3D = _authored[console.get_instance_id()]
	var forward := artifact.global_basis.z
	forward.y = 0
	if forward.length_squared() < .0001:
		_syncing = false
		return
	forward = forward.normalized()
	var upright := Basis(Vector3.UP.cross(forward), Vector3.UP, forward)
	# Keep 40 cm from the furniture lip to the station centre, enough for the
	# checked inclined cases to sit completely in front of it at metre scale.
	var host_scale := maxf(floor_host.global_basis.x.length(), floor_host.global_basis.z.length())
	var distance := maxf(reference.origin.z * artifact.global_basis.z.length(), front_extent * host_scale + .40)
	var at := artifact.global_position + forward * distance + upright.x * reference.origin.x
	at.y = floor_host.global_position.y + reference.origin.y
	for part: Node3D in parts:
		var authored: Transform3D = _authored[part.get_instance_id()]
		part.global_transform = Transform3D(upright * authored.basis, at + upright * (authored.origin-reference.origin))
	_syncing = false

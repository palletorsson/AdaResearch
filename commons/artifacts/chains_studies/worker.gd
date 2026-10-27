extends Node3D
## A fictional worker with authored preferences, not an LLM or a consciousness model.
## Uses original museum figures or a versioned modular recipe. Requests can be refused.
const Bodies := preload("res://commons/artifacts/dream_bodies/dream_bodies.gd")
const Futures := preload("res://commons/artifacts/chains_studies/futures_graph.gd")
var body: Node3D
var pose_root: Node3D
var identity := ""
var family := ""
var body_seed := 1
var options: Dictionary = {}
var clock := 0.0
var performing := false
var authority := "commission"
var memory: Array = []
var recipe: Dictionary = {}
var version_id := ""
var inhabitable := false

func configure(who: String, figure: String, number: int, opts: Dictionary) -> void:
	identity = who
	family = figure
	body_seed = number
	options = opts.duplicate(true)
	if is_inside_tree(): _build_body()

func _ready() -> void:
	pose_root = Node3D.new()
	pose_root.name = "Pose"
	add_child(pose_root)
	_build_body()

func _build_body() -> void:
	if pose_root == null: return
	if is_instance_valid(body):
		pose_root.remove_child(body)
		body.queue_free()
	if not recipe.is_empty():
		body = Futures.build_body(recipe)
		if body == null: return
		body.name = "ModularBody"
	else:
		body = Bodies.new()
		body.name = "MuseumBody"
		var config := options.duplicate(true)
		config.merge({"figure": family, "seed": body_seed}, true)
		body.apply_grid_config(config)
	pose_root.add_child(body)

func show_version(record: Dictionary) -> void:
	if version_id == str(record.id): return
	version_id = str(record.id)
	inhabitable = bool(record.get("inhabitable", false))
	if inhabitable: neutral_pose() # Reset before static colliders enter the physics tree.
	body_seed = int(record.seed)
	recipe = record.recipe.duplicate(true)
	# Replay never reconstructs the resident or erases memory/relationships.
	_build_body()

func choose_form(opts: Dictionary, reason: String) -> void:
	options = opts.duplicate(true)
	memory.append({"event": "chosen_form", "reason": reason, "seed": body_seed, "options": options.duplicate(true)})
	_build_body()

func form_signature() -> String:
	return JSON.stringify([identity, family, body_seed, recipe if not recipe.is_empty() else options])

func tick(delta: float, phase: float = 0.0) -> void:
	if inhabitable: return # A resident can offer a stationary room, not moving walls.
	clock += delta
	# An explicit pose animation; no claim of simulated cloth or articulated gait.
	var amount := 1.0 if performing else 0.18
	pose_root.rotation.y = sin(clock * 0.48 + phase) * 0.32 * amount
	pose_root.rotation.z = sin(clock * 0.72 + phase) * 0.045 * amount
	pose_root.scale = Vector3(1.0 + 0.025 * sin(clock * 0.8 + phase), 1.0, 1.0)

func neutral_pose() -> void:
	pose_root.transform = Transform3D.IDENTITY

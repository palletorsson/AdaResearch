# GrowthChamber.gd — Spatial zone where a single specimen grows from seed to maturity
#
# Feeds a CritterDNA through GrowthInterpolator over time, rebuilding the
# morphology at each tick so the player watches the organism develop.
# Time-lapse speed is controllable via VR slider.
#
# Usage:
#   var chamber := GrowthChamber.new()
#   add_child(chamber)
#   chamber.start_growth(my_dna)

class_name GrowthChamber
extends Node3D

# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

## Total time (in seconds at 1x speed) for a full growth cycle.
@export var total_growth_time: float = 30.0

## Growth speed multiplier (1.0 = real-time, 10.0 = 10x fast-forward).
@export_range(0.1, 20.0) var growth_speed: float = 1.0

## How often to rebuild the mesh (seconds). Lower = smoother but more CPU.
@export var rebuild_interval: float = 0.15

## LOD for the growing specimen (0 = highest detail for close inspection).
@export var specimen_lod: int = 0


# ─────────────────────────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────────────────────────

## Fired when growth stage changes (e.g., "Seed" → "Sprout").
signal growth_stage_changed(stage_name: String, progress: float)

## Fired when growth completes (t reaches 1.0).
signal growth_complete(entity: CritterEntity, dna: CritterDNA)

## Fired on every growth tick with current progress.
signal growth_tick(progress: float, stage_name: String)


# ─────────────────────────────────────────────────────────────
#  Runtime state
# ─────────────────────────────────────────────────────────────

## The target (adult) DNA being grown.
var _target_dna: CritterDNA = null

## The current CritterEntity being displayed.
var _entity: CritterEntity = null

## Growth progress (0.0 = seed, 1.0 = fully grown).
var _growth_t: float = 0.0

## Whether growth is actively running.
var _growing: bool = false

## Time accumulator for rebuild interval.
var _rebuild_timer: float = 0.0

## Current growth stage index (for detecting stage transitions).
var _current_stage_index: int = -1

## Shared trait mapper.
var _trait_mapper: CritterTraitMapper = null

## Pedestal position (center of the chamber).
var _pedestal_position: Vector3 = Vector3.ZERO


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	_trait_mapper = CritterTraitMapper.new()
	_build_pedestal()


func _process(delta: float) -> void:
	if not _growing or not _target_dna:
		return

	# Advance growth
	_growth_t += (delta * growth_speed) / total_growth_time
	_growth_t = clampf(_growth_t, 0.0, 1.0)

	# Check for stage transitions
	var new_stage: int = GrowthInterpolator.get_stage_index(_growth_t)
	if new_stage != _current_stage_index:
		_current_stage_index = new_stage
		var stage_name: String = GrowthInterpolator.get_stage_name(_growth_t)
		growth_stage_changed.emit(stage_name, _growth_t)

	# Rebuild mesh at interval
	_rebuild_timer += delta
	if _rebuild_timer >= rebuild_interval:
		_rebuild_timer = 0.0
		_update_specimen()

	# Emit tick
	growth_tick.emit(_growth_t, GrowthInterpolator.get_stage_name(_growth_t))

	# Check completion
	if _growth_t >= 1.0:
		_growing = false
		_finalize_growth()


# ═══════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════

## Start growing a new specimen from DNA.
func start_growth(dna: CritterDNA) -> void:
	# Clear any existing specimen
	clear()

	_target_dna = dna
	_growth_t = 0.0
	_growing = true
	_current_stage_index = -1
	_rebuild_timer = 0.0

	# Create the entity
	_entity = CritterEntity.new()
	_entity.name = "GrowingSpecimen_%s" % dna.get_kingdom_name()
	add_child(_entity)
	_entity.position = _pedestal_position + Vector3(0, 0.3, 0)

	# Build initial (seed) morphology
	var seed_dna: CritterDNA = GrowthInterpolator.interpolate(_target_dna, 0.0)
	MorphologyRouter.build(seed_dna, _entity, _trait_mapper, specimen_lod)
	_entity.init_from_dna(seed_dna)

	# Trigger first stage
	_current_stage_index = 0
	growth_stage_changed.emit("Seed", 0.0)


## Pause/resume growth.
func set_paused(paused: bool) -> void:
	_growing = not paused and _target_dna != null and _growth_t < 1.0


## Whether growth is currently active.
func is_growing() -> bool:
	return _growing


## Get current growth progress (0-1).
func get_progress() -> float:
	return _growth_t


## Get the current stage name.
func get_stage_name() -> String:
	return GrowthInterpolator.get_stage_name(_growth_t)


## Jump to a specific growth point (for scrubbing).
func set_progress(t: float) -> void:
	_growth_t = clampf(t, 0.0, 1.0)
	if _target_dna and _entity:
		_update_specimen()
		var new_stage: int = GrowthInterpolator.get_stage_index(_growth_t)
		if new_stage != _current_stage_index:
			_current_stage_index = new_stage
			growth_stage_changed.emit(GrowthInterpolator.get_stage_name(_growth_t), _growth_t)


## Get the entity (may be at any growth stage).
func get_entity() -> CritterEntity:
	return _entity


## Get the target (adult) DNA.
func get_target_dna() -> CritterDNA:
	return _target_dna


## Clear the chamber (remove current specimen).
func clear() -> void:
	_growing = false
	_target_dna = null
	_growth_t = 0.0
	_current_stage_index = -1

	if _entity and is_instance_valid(_entity):
		_entity.queue_free()
	_entity = null


# ═══════════════════════════════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════════════════════════════

## Update the specimen's visual form to match current growth factor.
func _update_specimen() -> void:
	if not _entity or not is_instance_valid(_entity) or not _target_dna:
		return

	# Get interpolated DNA for current growth
	var current_dna: CritterDNA = GrowthInterpolator.interpolate(_target_dna, _growth_t)

	# Rebuild mesh
	MorphologyRouter.rebuild(_entity, current_dna, _trait_mapper, specimen_lod)

	# Update entity DNA (for shader params, scale, etc.)
	_entity.init_from_dna(current_dna)


## Called when growth reaches 1.0 — finalize with the real target DNA.
func _finalize_growth() -> void:
	if not _entity or not is_instance_valid(_entity) or not _target_dna:
		return

	# Apply the full adult DNA one final time
	MorphologyRouter.rebuild(_entity, _target_dna, _trait_mapper, specimen_lod)
	_entity.init_from_dna(_target_dna)

	growth_complete.emit(_entity, _target_dna)


## Build a simple pedestal for the specimen to grow on.
func _build_pedestal() -> void:
	var pedestal := MeshInstance3D.new()
	pedestal.name = "Pedestal"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.6
	cyl.height = 0.15
	cyl.radial_segments = 16
	pedestal.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.12, 0.18)
	mat.roughness = 0.3
	mat.metallic = 0.1
	pedestal.material_override = mat

	pedestal.position = _pedestal_position
	add_child(pedestal)

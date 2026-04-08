# PokemonStudio.gd — Root orchestrator for the breeding/growth/ecosystem lab
#
# Three spatial zones: GrowthChamber, BreedingLab, EcosystemViewport
# Connected by a ReleaseGate. The player grows, breeds, and releases
# life forms — then watches them live, evolve, and mate.
#
# This is the Pokemon Studio. Life from code.
#
# Usage:
#   var studio := preload("res://algorithms/nature_system/studio/pokemon_studio.tscn").instantiate()
#   add_child(studio)

class_name PokemonStudio
extends Node3D

# ─────────────────────────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────────────────────────

signal specimen_added(id: String, dna: CritterDNA)
signal specimen_released(entity: CritterEntity, dna: CritterDNA)
signal breeding_complete(child_dna: CritterDNA)
signal growth_complete(entity: CritterEntity, dna: CritterDNA)


# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

## Spacing between zones (meters).
@export var zone_spacing: float = 12.0

## Start the ecosystem automatically.
@export var auto_start_ecosystem: bool = true

## Seed initial ecosystem population on first run.
@export var seed_on_first_run: bool = true

## Initial population per kingdom when seeding.
@export var initial_pop_per_kingdom: int = 5


# ─────────────────────────────────────────────────────────────
#  Subsystems
# ─────────────────────────────────────────────────────────────

var growth_chamber: GrowthChamber = null
var breeding_lab: BreedingLab = null
var release_gate: ReleaseGate = null
var ecosystem: EcosystemViewport = null
var collection: SpecimenCollection = null
var lineage: LineageTracker = null
var vr_interface: StudioVRInterface = null

## Stats snapshot timer (writes JSON for web editor).
var _stats_timer: float = 0.0
var _stats_interval: float = 10.0


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	# Initialize shared systems
	collection = SpecimenCollection.new()
	lineage = LineageTracker.new()
	lineage.load_data()

	# Build zones
	_build_growth_chamber()
	_build_breeding_lab()
	_build_ecosystem()
	_build_release_gate()
	_build_vr_interface()

	# Wire signals
	_wire_signals()

	# Seed ecosystem if first run
	if seed_on_first_run and ecosystem.spawner.get_population_count() == 0:
		ecosystem.seed_initial_population(initial_pop_per_kingdom)

	# Start ecosystem
	if auto_start_ecosystem:
		ecosystem.start()


func _process(delta: float) -> void:
	# Periodic stats snapshot for web editor
	_stats_timer += delta
	if _stats_timer >= _stats_interval:
		_stats_timer = 0.0
		_save_state_snapshot()


# ═══════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════

## Add a new random specimen to the collection and start growing it.
func add_random_specimen(kingdom: int = -1) -> String:
	var dna: CritterDNA
	if kingdom >= 0 and kingdom <= 4:
		dna = CritterDNA.random_kingdom(kingdom)
	else:
		dna = CritterDNA.random()

	var id: String = collection.add(dna)
	if id.is_empty():
		return ""

	lineage.record_birth(dna, "", "", id)
	specimen_added.emit(id, dna)
	return id


## Start growing a specimen from the collection.
func grow_specimen(specimen_id: String) -> void:
	var dna: CritterDNA = collection.get_dna(specimen_id)
	if not dna:
		push_warning("[PokemonStudio] Specimen not found: %s" % specimen_id)
		return
	growth_chamber.start_growth(dna)


## Place a specimen on a breeding pedestal.
func set_breeding_parent(slot: String, specimen_id: String) -> void:
	var dna: CritterDNA = collection.get_dna(specimen_id)
	if not dna:
		return
	if slot == "a":
		breeding_lab.set_parent_a(dna)
	elif slot == "b":
		breeding_lab.set_parent_b(dna)


## Breed the current parents in the lab.
func breed() -> CritterDNA:
	var child: CritterDNA = breeding_lab.breed()
	if child:
		var id: String = collection.add(child)
		lineage.record_birth(child, "", "", id)
		breeding_complete.emit(child)

		# Auto-grow the child
		growth_chamber.start_growth(child)
	return child


## Release a specimen into the ecosystem.
func release(specimen_id: String) -> CritterEntity:
	var dna: CritterDNA = collection.get_dna(specimen_id)
	if not dna:
		return null

	var entity: CritterEntity = release_gate.release_specimen(dna, specimen_id)
	if entity:
		entity.is_released = true
		specimen_released.emit(entity, dna)
	return entity


## Get the full studio state for web editor.
func get_state() -> Dictionary:
	return {
		"collection_count": collection.get_count(),
		"collection_capacity": collection.get_remaining_capacity(),
		"growth_active": growth_chamber.is_growing(),
		"growth_progress": growth_chamber.get_progress(),
		"growth_stage": growth_chamber.get_stage_name(),
		"breeding_ready": breeding_lab.is_ready(),
		"breeding_distance": breeding_lab.get_genetic_distance(),
		"ecosystem_running": ecosystem.is_running(),
		"ecosystem_population": ecosystem.get_population_summary(),
		"ecosystem_diversity": ecosystem.get_diversity(),
		"ecosystem_generation": ecosystem.evolution.current_generation,
		"lineage_entries": lineage.get_summary(),
		"releases": release_gate.get_release_count(),
	}


## Save all persistent data.
func save_all() -> void:
	collection.save_all()
	lineage.save()
	ecosystem.save_stats_snapshot()


# ═══════════════════════════════════════════════════════════════
# ZONE BUILDING
# ═══════════════════════════════════════════════════════════════

func _build_growth_chamber() -> void:
	growth_chamber = GrowthChamber.new()
	growth_chamber.name = "GrowthChamber"
	growth_chamber.position = Vector3(-zone_spacing, 0, 0)
	add_child(growth_chamber)


func _build_breeding_lab() -> void:
	breeding_lab = BreedingLab.new()
	breeding_lab.name = "BreedingLab"
	breeding_lab.position = Vector3(0, 0, 0)
	add_child(breeding_lab)


func _build_ecosystem() -> void:
	ecosystem = EcosystemViewport.new()
	ecosystem.name = "Ecosystem"
	ecosystem.position = Vector3(zone_spacing * 2, 0, zone_spacing)
	add_child(ecosystem)


func _build_release_gate() -> void:
	release_gate = ReleaseGate.new()
	release_gate.name = "ReleaseGate"
	release_gate.position = Vector3(zone_spacing, 0, zone_spacing / 2.0)
	release_gate.ecosystem_spawner = ecosystem.spawner
	release_gate.collection = collection
	release_gate.lineage_tracker = lineage
	add_child(release_gate)


func _build_vr_interface() -> void:
	vr_interface = StudioVRInterface.new()
	vr_interface.name = "VRInterface"
	vr_interface.studio = self
	vr_interface.growth_chamber = growth_chamber
	vr_interface.breeding_lab = breeding_lab
	vr_interface.release_gate = release_gate
	vr_interface.collection = collection
	add_child(vr_interface)


# ═══════════════════════════════════════════════════════════════
# SIGNAL WIRING
# ═══════════════════════════════════════════════════════════════

func _wire_signals() -> void:
	# Growth chamber
	growth_chamber.growth_complete.connect(_on_growth_complete)

	# Breeding lab
	breeding_lab.breeding_complete.connect(_on_breeding_complete)

	# Release gate
	release_gate.specimen_released.connect(_on_specimen_released)

	# VR interface
	vr_interface.breed_requested.connect(func(): breed())
	vr_interface.release_requested.connect(func(dna: CritterDNA, sid: String): release(sid))


func _on_growth_complete(entity: CritterEntity, dna: CritterDNA) -> void:
	growth_complete.emit(entity, dna)


func _on_breeding_complete(child_dna: CritterDNA, _pa: CritterDNA, _pb: CritterDNA) -> void:
	# Collection and lineage handled in breed() method
	pass


func _on_specimen_released(entity: CritterEntity, dna: CritterDNA, _sid: String) -> void:
	specimen_released.emit(entity, dna)


# ═══════════════════════════════════════════════════════════════
# PERSISTENCE
# ═══════════════════════════════════════════════════════════════

func _save_state_snapshot() -> void:
	DirAccess.make_dir_recursive_absolute("user://pokemon_studio/")
	var state: Dictionary = get_state()
	var path: String = "user://pokemon_studio/studio_state.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state, "\t"))
		file.close()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		save_all()

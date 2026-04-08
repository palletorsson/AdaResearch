# ReleaseGate.gd — Portal between the studio and the living ecosystem
#
# When a mature specimen is brought to the gate, it transfers from the
# studio spawner to the ecosystem spawner and enters the wild.
# Released specimens are subject to evolution, ecology, and natural selection.
#
# Usage:
#   var gate := ReleaseGate.new()
#   gate.ecosystem_spawner = my_ecosystem_spawner
#   add_child(gate)
#   gate.release_specimen(dna, specimen_id)

class_name ReleaseGate
extends Node3D

# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

## The spawner for the ecosystem (where specimens go when released).
var ecosystem_spawner: CritterSpawner = null

## Specimen collection (to mark specimens as released).
var collection: SpecimenCollection = null

## Lineage tracker (to record releases).
var lineage_tracker: LineageTracker = null

## Spawn offset from gate position (where the entity appears in the ecosystem).
@export var spawn_offset: Vector3 = Vector3(0, 0, 3.0)

## Visual gate width and height.
@export var gate_width: float = 2.0
@export var gate_height: float = 3.0


# ─────────────────────────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────────────────────────

## Fired when a specimen is released into the ecosystem.
signal specimen_released(entity: CritterEntity, dna: CritterDNA, specimen_id: String)

## Fired when release fails (ecosystem at capacity, etc.).
signal release_failed(reason: String)


# ─────────────────────────────────────────────────────────────
#  Runtime state
# ─────────────────────────────────────────────────────────────

var _gate_mesh: MeshInstance3D = null
var _release_count: int = 0


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	_build_gate_visual()


# ═══════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════

## Release a specimen into the ecosystem by DNA and collection ID.
## Returns the spawned CritterEntity, or null if release failed.
func release_specimen(dna: CritterDNA, specimen_id: String = "") -> CritterEntity:
	if not ecosystem_spawner:
		release_failed.emit("No ecosystem spawner connected")
		push_error("[ReleaseGate] Cannot release: no ecosystem spawner")
		return null

	if not dna:
		release_failed.emit("No DNA provided")
		return null

	# Spawn into ecosystem
	var spawn_pos: Vector3 = global_position + global_transform.basis * spawn_offset
	var entity: CritterEntity = ecosystem_spawner.spawn(dna, spawn_pos)

	if not entity:
		release_failed.emit("Ecosystem at capacity")
		return null

	_release_count += 1

	# Mark as released in collection
	if collection and not specimen_id.is_empty():
		collection.mark_released(specimen_id)

	# Record in lineage
	if lineage_tracker:
		var lin_id: String = lineage_tracker.record_birth(dna, dna.parent_a_id, dna.parent_b_id)
		lineage_tracker.mark_released(lin_id)

	specimen_released.emit(entity, dna, specimen_id)
	return entity


## Release directly from a CritterEntity (transfers from studio to ecosystem).
func release_entity(entity: CritterEntity, specimen_id: String = "") -> CritterEntity:
	if not entity or not entity.dna:
		release_failed.emit("Invalid entity")
		return null
	return release_specimen(entity.dna, specimen_id)


## How many specimens have been released through this gate.
func get_release_count() -> int:
	return _release_count


## Whether the ecosystem has capacity for more specimens.
func can_release() -> bool:
	if not ecosystem_spawner:
		return false
	return ecosystem_spawner.get_population_count() < ecosystem_spawner.max_population


# ═══════════════════════════════════════════════════════════════
# INTERNAL — Gate visual
# ═══════════════════════════════════════════════════════════════

## Build the gate frame visual.
func _build_gate_visual() -> void:
	var frame := Node3D.new()
	frame.name = "GateFrame"
	add_child(frame)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.15, 0.4)
	mat.roughness = 0.3
	mat.metallic = 0.2
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.2, 0.5)
	mat.emission_energy_multiplier = 0.3

	# Left pillar
	_add_pillar(frame, Vector3(-gate_width / 2.0, gate_height / 2.0, 0), mat)
	# Right pillar
	_add_pillar(frame, Vector3(gate_width / 2.0, gate_height / 2.0, 0), mat)

	# Top arch
	var arch := MeshInstance3D.new()
	arch.name = "Arch"
	var arch_mesh := BoxMesh.new()
	arch_mesh.size = Vector3(gate_width + 0.2, 0.15, 0.15)
	arch.mesh = arch_mesh
	arch.material_override = mat
	arch.position = Vector3(0, gate_height, 0)
	frame.add_child(arch)

	# Portal glow (transparent quad in the gate opening)
	var portal := MeshInstance3D.new()
	portal.name = "PortalGlow"
	var quad := QuadMesh.new()
	quad.size = Vector2(gate_width - 0.2, gate_height - 0.2)
	portal.mesh = quad

	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.5, 0.3, 0.7, 0.15)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.5, 0.3, 0.7)
	glow_mat.emission_energy_multiplier = 0.5
	glow_mat.no_depth_test = true
	portal.material_override = glow_mat
	portal.position = Vector3(0, gate_height / 2.0 + 0.1, 0)
	frame.add_child(portal)


## Add a pillar mesh to the gate frame.
func _add_pillar(parent: Node3D, pos: Vector3, mat: StandardMaterial3D) -> void:
	var pillar := MeshInstance3D.new()
	pillar.name = "Pillar"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.08
	cyl.height = gate_height
	cyl.radial_segments = 8
	pillar.mesh = cyl
	pillar.material_override = mat
	pillar.position = pos
	parent.add_child(pillar)

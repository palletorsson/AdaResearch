# body_recipe.gd
# Abstract base for every kingdom body — flower, fungus, tree, walker, cave.
# A body is a small tree of SDFs built from DNA genes, smooth-unioned
# into a single manifold form.
#
# Subclasses override _build_from_dna() to populate _parts. Genes come from
# a Dictionary for prototype simplicity; later this reads a CritterDNA
# resource directly.
#
# Every recipe:
#   • reads the minimal gene set it needs
#   • composes FormSDF parts (capsule, ellipsoid, symmetry ops)
#   • emits a smooth-union across parts so the body reads as one surface

extends "res://commons/morphology/sdf/form_sdf.gd"

const SdfOps = preload("res://commons/morphology/sdf/sdf_ops.gd")

## DNA — the parameter space. Keys named after CritterDNA fields:
##   scale, segments, symmetry, pattern_type, pattern_density, body_type, etc.
@export var dna: Dictionary = {}

## Smoothness for the union across parts. Higher = rounder joints.
@export_range(0.0, 1.0) var joint_k: float = 0.15

var _parts: Array = []  # array of FormSDF resources
var _part_slots: Array = []  # parallel slot name per part (e.g. "stem", "petal")
var _dirty: bool = true
var _cached_aabb: AABB = AABB(Vector3(-2, -0.5, -2), Vector3(4, 4, 4))


func build() -> void:
	_parts.clear()
	_part_slots.clear()
	_build_from_dna()
	_recompute_aabb()
	_dirty = false


## Subclasses call this to add a part with an optional slot name. Slot
## names drive material assignment when build_mesh_body() runs. Unknown
## slots fall back to materials["default"] then to an auto white material.
func _add_part(sdf: Resource, slot: String = "body") -> void:
	_parts.append(sdf)
	_part_slots.append(slot)


## Build a Node3D scene of MeshInstance3Ds representing this body with
## per-slot materials/shaders. `materials` maps slot names → Material.
## Walking works for primitives (capsule, ellipsoid, symmetry wrapping those)
## that implement build_mesh_parts(). Blended SDFs can't mesh directly —
## for those, fall back to voxel preview or marching cubes.
func build_mesh_body(materials: Dictionary = {}) -> Node3D:
	if _dirty:
		build()
	var root := Node3D.new()
	root.name = "MeshBody"
	for i in _parts.size():
		var part: Resource = _parts[i]
		var slot: String = _part_slots[i] if i < _part_slots.size() else "body"
		var mesh_parts: Array = part.build_mesh_parts()
		if mesh_parts.is_empty():
			push_warning("BodyRecipe: part %d (slot '%s') has no direct mesh representation — skipped" % [i, slot])
			continue
		var slot_material: Material = _resolve_material(materials, slot)
		for spec in mesh_parts:
			var mi := MeshInstance3D.new()
			mi.mesh = spec["mesh"]
			mi.transform = spec["transform"]
			var part_slot: String = spec.get("slot", "self")
			# Part-level slot override: if the primitive advertised its own
			# slot ("petal" from a flower's symmetry wrapping a petal ellipsoid),
			# prefer that when looking up materials.
			var effective_slot: String = part_slot if part_slot != "self" else slot
			var mat: Material = _resolve_material(materials, effective_slot)
			if mat != null:
				mi.material_override = mat
			mi.name = "%s_%d" % [effective_slot, i]
			root.add_child(mi)
	return root


static func _resolve_material(materials: Dictionary, slot: String) -> Material:
	if materials.has(slot):
		return materials[slot]
	if materials.has("default"):
		return materials["default"]
	return null


## Subclasses override this to populate _parts from self.dna.
func _build_from_dna() -> void:
	push_error("BodyRecipe subclasses must override _build_from_dna()")


func signed_distance(p: Vector3) -> float:
	if _dirty:
		build()
	if _parts.is_empty():
		return INF
	var d: float = _parts[0].signed_distance(p)
	for i in range(1, _parts.size()):
		var di: float = _parts[i].signed_distance(p)
		d = SdfOps.smooth_union(d, di, joint_k)
	return d


func get_aabb() -> AABB:
	if _dirty:
		build()
	return _cached_aabb


## Mark the recipe dirty so the next distance query rebuilds. Call after
## mutating dna genes.
func mark_dirty() -> void:
	_dirty = true


func _recompute_aabb() -> void:
	if _parts.is_empty():
		_cached_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
		return
	var combined: AABB = _parts[0].get_aabb()
	for i in range(1, _parts.size()):
		combined = combined.merge(_parts[i].get_aabb())
	_cached_aabb = combined.grow(0.2)


# ─── Helpers for subclasses to build parts ───────────────────────

static func make_capsule(a: Vector3, b: Vector3, r: float) -> Resource:
	return (load("res://commons/morphology/sdf/capsule_sdf.gd") as GDScript).new_from_args(a, b, r) if false \
		else _capsule_helper(a, b, r)

static func _capsule_helper(a: Vector3, b: Vector3, r: float) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/capsule_sdf.gd")
	var c: Resource = script.new()
	c.a = a
	c.b = b
	c.radius = r
	return c

static func make_ellipsoid(center: Vector3, radii: Vector3, basis: Basis = Basis.IDENTITY) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/ellipsoid_sdf.gd")
	var e: Resource = script.new()
	e.center = center
	e.radii = radii
	e.basis = basis
	return e

static func make_symmetry(base_sdf: Resource, n: int, axis: Vector3 = Vector3.UP, origin: Vector3 = Vector3.ZERO) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/symmetry_op.gd")
	var op: Resource = script.new()
	op.base = base_sdf
	op.count = max(1, n)
	op.axis = axis
	op.origin = origin
	return op

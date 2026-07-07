# BotanicalFlower.gd
# Procedural flower generator grounded in real botanical taxonomy.
# Based on Swedish plant morphology (Växternas byggnad):
# stem shapes, phyllotaxis, leaf forms, flower anatomy, inflorescence patterns.
#
# @identity
# essence: Procedural botanical generator — stem, leaves, sepals, petals, stamens, pistil assembled in correct anatomical order
# desire: To make flower form a parameter space rather than a fixed mesh, so morphology becomes legible as decisions
# critical_parameter: phyllotaxis_angle and inflorescence_pattern — they organize how parts arrange in space
# triggers: Changing petal_count produces tulip→daisy→chrysanthemum; switching inflorescence shifts single bloom to raceme to umbel
# emerges: Eight inflorescence patterns and six flower forms compose a small botanical vocabulary that yields infinite plausible flowers
# needs: configure() API [has], rebuild on parameter change [has], grid wrapper for VR [has via BotanicalFlowerArtifact]
# relationships: Core engine consumed by botanical_flower (artifact wrapper), evolving_flowers (phenotype), Flower_* maps in flowers sequence
# truth: A flower is the parameter set that decided how to repeat — petals are the trace of phyllotaxis, not the flower itself.
#
# Each flower is built from anatomically correct parts in botanical order:
#   Stem → Leaves (via phyllotaxis) → Flower head(s)
#     └─ Sepals (foderblad) → Petals (kronblad) → Stamens (ståndare) → Pistil (pistill)
#
# Supports 8 inflorescence patterns from real botany:
#   single, raceme (klase), spike (ax), umbel (flock), head (huvud),
#   cyme (kvast), panicle, catkin (hänge)
#
# Usage:
#   var flower = BotanicalFlower.new()
#   flower.preset = "bluebell"
#   add_child(flower)   # Builds in _ready()
#
# Or:
#   flower.configure({"petal_count": 6, "flower_form": BotanicalFlower.FlowerForm.BELL})
#   flower.rebuild()

extends Node3D
class_name BotanicalFlower


# ── Botanical Taxonomy Enums ─────────────────────────────────────────
# Named after Swedish botanical classification (Växternas byggnad)

## Stem cross-section shape (Stammar)
enum StemShape { ROUND, TRIANGULAR, SQUARE }

## Leaf placement pattern (Bladens placering)
enum Phyllotaxis { ALTERNATE, OPPOSITE, WHORLED, ROSETTE, SPIRAL }

## Leaf outline shape (Bladformer)
enum LeafShape { LINEAR, LANCEOLATE, ELLIPTIC, OVATE, OBOVATE, CORDATE, SPATULATE, RENIFORM }

## Leaf edge type (Bladskivans kant)
enum LeafEdge { ENTIRE, SERRATE, DENTATE, CRENATE, LOBED }

## Flower form (Blommor)
enum FlowerForm { OPEN, BELL, TUBULAR, FUNNEL, BOWL, COMPOSITE }

## Flower symmetry
enum Symmetry { RADIAL, BILATERAL }

## Inflorescence arrangement (Blomställningar)
enum InflorescenceType { SINGLE, RACEME, SPIKE, UMBEL, HEAD, CYME, PANICLE }


# ── LOD segment counts ───────────────────────────────────────────────

const LOD_SEGMENTS := [4, 8, 14, 20]


# ── Default configuration ────────────────────────────────────────────

const DEFAULT_CONFIG := {
	# Stem
	"stem_height": 0.25,
	"stem_radius": 0.005,
	"stem_color": Color(0.2, 0.45, 0.15),
	"stem_curve": 0.0,       # 0 = straight, 1 = dramatic arch
	"pendant": false,         # true = flower heads droop downward (e.g. bluebell)

	# Leaves
	"leaf_count": 4,
	"leaf_shape": 1,          # LeafShape.LANCEOLATE
	"leaf_edge": 0,           # LeafEdge.ENTIRE
	"phyllotaxis": 0,         # Phyllotaxis.ALTERNATE
	"leaf_length": 0.1,
	"leaf_width": 0.04,
	"leaf_color": Color(0.22, 0.48, 0.16),
	"leaf_angle": 40.0,       # degrees from stem
	"leaf_curve": 0.3,        # lengthwise curvature

	# Flower head
	"flower_form": 0,         # FlowerForm.OPEN
	"symmetry": 0,            # Symmetry.RADIAL
	"petal_count": 5,
	"petal_length": 0.08,
	"petal_width": 0.04,
	"petal_color": Color(0.85, 0.3, 0.55),
	"petal_opening": 60.0,    # degrees from vertical
	"petal_curve": 0.2,

	# Sepals (foderblad)
	"sepal_count": 5,
	"sepal_length": 0.04,
	"sepal_color": Color(0.2, 0.4, 0.12),

	# Reproductive organs
	"stamen_count": 5,
	"stamen_length": 0.05,
	"stamen_color": Color(0.9, 0.8, 0.3),
	"pistil_height": 0.04,
	"pistil_color": Color(0.5, 0.7, 0.3),

	# Inflorescence
	"inflorescence": 0,       # InflorescenceType.SINGLE
	"flower_count": 1,
	"flower_spacing": 0.04,

	# Overall
	"overall_scale": 1.0,
	"lod": 2,
	"seed": 0,
}


# ── Species presets ──────────────────────────────────────────────────
# Real Swedish wildflowers from the botanical illustrations

const PRESETS := {
	"bluebell": {
		"stem_height": 0.22, "stem_curve": 0.4, "stem_radius": 0.004,
		"stem_color": Color(0.18, 0.4, 0.15), "pendant": true,
		"leaf_count": 3, "leaf_shape": 0, "phyllotaxis": 3,
		"leaf_length": 0.15, "leaf_width": 0.015,
		"leaf_color": Color(0.2, 0.45, 0.15),
		"flower_form": 1, "petal_count": 6,
		"petal_length": 0.04, "petal_width": 0.018,
		"petal_color": Color(0.35, 0.35, 0.82),
		"petal_opening": 15.0, "petal_curve": 0.6,
		"sepal_count": 0, "stamen_count": 6,
		"stamen_length": 0.025, "stamen_color": Color(0.8, 0.85, 0.55),
		"pistil_height": 0.02,
		"inflorescence": 1, "flower_count": 6, "flower_spacing": 0.035,
	},

	"iris": {
		"stem_height": 0.35, "stem_radius": 0.005,
		"stem_color": Color(0.2, 0.42, 0.18),
		"leaf_count": 4, "leaf_shape": 0, "phyllotaxis": 3,
		"leaf_length": 0.22, "leaf_width": 0.025,
		"leaf_color": Color(0.22, 0.45, 0.2),
		"flower_form": 0, "symmetry": 1, "petal_count": 6,
		"petal_length": 0.1, "petal_width": 0.055,
		"petal_color": Color(0.4, 0.2, 0.72),
		"petal_opening": 70.0, "petal_curve": 0.35,
		"sepal_count": 0, "stamen_count": 3,
		"stamen_length": 0.04, "stamen_color": Color(0.85, 0.75, 0.35),
		"pistil_color": Color(0.6, 0.5, 0.75),
	},

	"fritillaria": {
		"stem_height": 0.3, "stem_radius": 0.004,
		"stem_color": Color(0.25, 0.38, 0.15), "pendant": true,
		"leaf_count": 6, "leaf_shape": 0, "phyllotaxis": 0,
		"leaf_length": 0.1, "leaf_width": 0.012,
		"leaf_color": Color(0.25, 0.45, 0.18),
		"flower_form": 1, "petal_count": 6,
		"petal_length": 0.065, "petal_width": 0.035,
		"petal_color": Color(0.62, 0.22, 0.32),
		"petal_opening": 8.0, "petal_curve": 0.1,
		"sepal_count": 0, "stamen_count": 6,
		"stamen_length": 0.04, "stamen_color": Color(0.85, 0.7, 0.3),
	},

	"allium": {
		"stem_height": 0.35, "stem_radius": 0.004,
		"stem_color": Color(0.2, 0.42, 0.12),
		"leaf_count": 2, "leaf_shape": 0, "phyllotaxis": 3,
		"leaf_length": 0.2, "leaf_width": 0.018,
		"flower_form": 0, "petal_count": 6,
		"petal_length": 0.018, "petal_width": 0.008,
		"petal_color": Color(0.72, 0.38, 0.58), "petal_opening": 65.0,
		"sepal_count": 0, "stamen_count": 6, "stamen_length": 0.012,
		"inflorescence": 4, "flower_count": 20, "flower_spacing": 0.02,
	},

	"orchid": {
		"stem_height": 0.25, "stem_radius": 0.004,
		"stem_color": Color(0.2, 0.38, 0.15),
		"leaf_count": 4, "leaf_shape": 2, "phyllotaxis": 3,
		"leaf_length": 0.12, "leaf_width": 0.06,
		"leaf_color": Color(0.2, 0.42, 0.18),
		"flower_form": 0, "symmetry": 1, "petal_count": 6,
		"petal_length": 0.05, "petal_width": 0.03,
		"petal_color": Color(0.68, 0.32, 0.52), "petal_opening": 50.0,
		"sepal_count": 0, "stamen_count": 1,
		"stamen_length": 0.02, "stamen_color": Color(0.9, 0.85, 0.4),
		"inflorescence": 1, "flower_count": 5, "flower_spacing": 0.05,
	},

	"corydalis": {
		"stem_height": 0.16, "stem_curve": 0.25, "stem_radius": 0.003,
		"stem_color": Color(0.25, 0.4, 0.18),
		"leaf_count": 3, "leaf_shape": 3, "leaf_edge": 4,
		"phyllotaxis": 0,
		"leaf_length": 0.06, "leaf_width": 0.045,
		"leaf_color": Color(0.28, 0.5, 0.22),
		"flower_form": 2, "symmetry": 1, "petal_count": 4,
		"petal_length": 0.03, "petal_width": 0.012,
		"petal_color": Color(0.72, 0.42, 0.62), "petal_opening": 25.0,
		"sepal_count": 2, "sepal_length": 0.01,
		"stamen_count": 2, "stamen_length": 0.015,
		"inflorescence": 1, "flower_count": 8, "flower_spacing": 0.025,
	},

	"daisy": {
		"stem_height": 0.1, "stem_radius": 0.003,
		"stem_color": Color(0.22, 0.45, 0.15),
		"leaf_count": 6, "leaf_shape": 6, "phyllotaxis": 3,
		"leaf_length": 0.06, "leaf_width": 0.02,
		"leaf_color": Color(0.25, 0.48, 0.18),
		"flower_form": 5, "petal_count": 13,
		"petal_length": 0.03, "petal_width": 0.008,
		"petal_color": Color(0.95, 0.95, 0.95), "petal_opening": 85.0,
		"sepal_count": 8, "sepal_length": 0.015,
		"stamen_count": 0,
		"pistil_height": 0.025, "pistil_color": Color(0.92, 0.82, 0.2),
	},

	"crown_imperial": {
		"stem_height": 0.5, "stem_radius": 0.008,
		"stem_color": Color(0.22, 0.38, 0.12), "pendant": true,
		"leaf_count": 8, "leaf_shape": 0, "phyllotaxis": 2,
		"leaf_length": 0.12, "leaf_width": 0.018,
		"leaf_color": Color(0.22, 0.45, 0.15),
		"flower_form": 1, "petal_count": 6,
		"petal_length": 0.07, "petal_width": 0.04,
		"petal_color": Color(0.92, 0.5, 0.15), "petal_opening": 10.0,
		"sepal_count": 0, "stamen_count": 6,
		"stamen_length": 0.055, "stamen_color": Color(0.85, 0.7, 0.2),
		"inflorescence": 5, "flower_count": 5,
	},

	"clover": {
		"stem_height": 0.1, "stem_radius": 0.003,
		"stem_color": Color(0.2, 0.42, 0.15),
		"leaf_count": 3, "leaf_shape": 3, "phyllotaxis": 2,
		"leaf_length": 0.035, "leaf_width": 0.028,
		"leaf_color": Color(0.22, 0.48, 0.15), "leaf_angle": 25.0,
		"flower_form": 5, "petal_count": 25,
		"petal_length": 0.012, "petal_width": 0.005,
		"petal_color": Color(0.8, 0.38, 0.55), "petal_opening": 55.0,
		"sepal_count": 0, "stamen_count": 0, "pistil_height": 0.0,
	},
}


# ── State ────────────────────────────────────────────────────────────

@export var preset: String = ""
var config: Dictionary = {}
var _built := false

# Stem joint chain — populated by _build_stem, consumed by inflorescence
# and leaf placement so attachments follow the curved stem rather than
# floating in straight-line coordinates.
var _stem_joints: Array[Node3D] = []
var _stem_seg_h: float = 0.0


# ═══════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════

func _ready() -> void:
	if not _built:
		if preset != "" and PRESETS.has(preset):
			configure(PRESETS[preset])
		build()


## Merge overrides into config.
func configure(overrides: Dictionary) -> void:
	for key in overrides:
		config[key] = overrides[key]


## Clear children and rebuild from current config.
func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_built = false
	build()


## Build the complete flower from config.
func build() -> void:
	if _built:
		return

	# Merge defaults with config
	var c := DEFAULT_CONFIG.duplicate()
	for key in config:
		c[key] = config[key]

	var rng := RandomNumberGenerator.new()
	rng.seed = c.seed as int

	var s: float = c.overall_scale

	var inf_type: int = c.inflorescence as int
	if inf_type == InflorescenceType.SINGLE or (c.flower_count as int) <= 1:
		_build_complete_flower(c, rng, s)
	else:
		_build_inflorescence(c, rng, s)

	_built = true


# ═══════════════════════════════════════════════════════════════════════
# COMPLETE FLOWER — single stem + leaves + one flower head
# ═══════════════════════════════════════════════════════════════════════

func _build_complete_flower(c: Dictionary, rng: RandomNumberGenerator, s: float) -> void:
	var stem_top: Node3D = _build_stem(c, self, s)
	_place_leaves(c, self, c.stem_height * s, s, rng)
	_build_flower_head(c, stem_top, s, rng)


# ═══════════════════════════════════════════════════════════════════════
# INFLORESCENCE — multiple flower heads arranged botanically
# ═══════════════════════════════════════════════════════════════════════

func _build_inflorescence(c: Dictionary, rng: RandomNumberGenerator, s: float) -> void:
	var stem_h: float = c.stem_height * s
	var count: int = c.flower_count as int
	var spacing: float = c.flower_spacing * s
	var inf_type: int = c.inflorescence as int

	# Main stem
	var stem_top: Node3D = _build_stem(c, self, s)

	# Leaves on main stem
	_place_leaves(c, self, stem_h, s, rng)

	# Sub-flower scale — smaller than solo bloom
	var sub_s: float = s * 0.65

	match inf_type:
		InflorescenceType.RACEME:
			# Flowers along stem axis — klase
			for i in count:
				var t: float = 0.4 + float(i) / maxf(count - 1.0, 1.0) * 0.55
				var angle: float = TAU * float(i) * 0.618  # Golden angle for spiral
				var pedicel_len: float = spacing * (1.0 + rng.randf_range(-0.2, 0.2))
				var attach: Dictionary = _stem_attach_at(t)

				var joint := Node3D.new()
				joint.name = "Pedicel_%d" % i
				joint.position = Vector3(0, attach.local_y, 0)
				joint.rotation = Vector3(
					deg_to_rad(30 + rng.randf_range(-10, 10)),
					angle, 0
				)
				attach.parent.add_child(joint)

				var head_pos := Node3D.new()
				head_pos.name = "HeadMount_%d" % i
				head_pos.position = Vector3(0, 0, pedicel_len)
				joint.add_child(head_pos)

				# Small pedicel stem
				_build_pedicel(joint, pedicel_len, c.stem_color, s)

				if c.pendant:
					head_pos.rotation.x = deg_to_rad(120 + rng.randf_range(-15, 15))
				_build_flower_head(c, head_pos, sub_s, rng)

		InflorescenceType.SPIKE:
			# Dense flowers directly on stem — ax
			for i in count:
				var t: float = 0.5 + float(i) / maxf(count - 1.0, 1.0) * 0.45
				var angle: float = TAU * float(i) * 0.618
				var attach: Dictionary = _stem_attach_at(t)

				var mount := Node3D.new()
				mount.name = "SpikeFlower_%d" % i
				mount.position = Vector3(0, attach.local_y, 0)
				mount.rotation.y = angle
				attach.parent.add_child(mount)
				_build_flower_head(c, mount, sub_s * 0.7, rng)

		InflorescenceType.UMBEL:
			# All radiate from one point at top — flock.
			# Attach to stem_top so the umbel rides the curved stem.
			for i in count:
				var angle: float = TAU * float(i) / count
				var tilt: float = deg_to_rad(25 + rng.randf_range(-8, 8))
				var stalk_len: float = spacing * 3.0 + rng.randf_range(0, spacing)

				var ray := Node3D.new()
				ray.name = "Ray_%d" % i
				ray.position = Vector3.ZERO
				ray.rotation = Vector3(tilt, angle, 0)
				stem_top.add_child(ray)

				var tip := Node3D.new()
				tip.position = Vector3(0, stalk_len, 0)
				ray.add_child(tip)

				_build_pedicel(ray, stalk_len, c.stem_color, s)
				_build_flower_head(c, tip, sub_s * 0.6, rng)

		InflorescenceType.HEAD:
			# Dense sphere at top — huvud (e.g. allium, clover).
			# Attach to stem_top so the cluster sits on the actual stem tip.
			var head_r: float = maxf(c.petal_length * s * 1.5, spacing) * sqrt(count) * 0.25
			var golden := (1.0 + sqrt(5.0)) / 2.0

			for i in count:
				# Fibonacci sphere distribution
				var theta: float = acos(1.0 - 2.0 * (float(i) + 0.5) / count)
				var phi: float = TAU * float(i) / golden

				var pos := Vector3(
					sin(theta) * cos(phi),
					cos(theta),
					sin(theta) * sin(phi)
				) * head_r

				var mount := Node3D.new()
				mount.name = "HeadFlower_%d" % i
				mount.position = pos
				stem_top.add_child(mount)
				# Point outward from center (must be in tree for look_at)
				if pos.length() > 0.001:
					mount.look_at(mount.global_position + pos.normalized(), Vector3.UP)
				_build_flower_head(c, mount, sub_s * 0.35, rng)

		InflorescenceType.CYME:
			# Central flower first, then branching — kvast.
			# Top sits on stem_top; branches attach to lower stem joints
			# at fraction (1 - drop_frac) so they follow any stem curve.
			var top_mount := Node3D.new()
			top_mount.position = Vector3.ZERO
			stem_top.add_child(top_mount)
			_build_flower_head(c, top_mount, sub_s, rng)

			for i in range(1, count):
				var angle: float = TAU * float(i) / (count - 1)
				var drop_frac: float = float(i) / count * 0.3   # 0..0.3
				var t: float = 1.0 - drop_frac
				var spread: float = spacing * 3.0
				var attach: Dictionary = _stem_attach_at(t)

				var branch := Node3D.new()
				branch.name = "CymeBranch_%d" % i
				branch.position = Vector3(
					sin(angle) * spread,
					attach.local_y,
					cos(angle) * spread
				)
				attach.parent.add_child(branch)

				_build_pedicel(branch, spread * 0.6, c.stem_color, s)
				_build_flower_head(c, branch, sub_s * 0.75, rng)

		InflorescenceType.PANICLE:
			# Branching raceme — compound
			for i in count:
				var t: float = 0.3 + float(i) / maxf(count - 1.0, 1.0) * 0.65
				var angle: float = TAU * float(i) * 0.618
				var spread: float = spacing * 2.0 * (1.0 - t)
				var attach: Dictionary = _stem_attach_at(t)

				var mount := Node3D.new()
				mount.name = "PanicleFlower_%d" % i
				mount.position = Vector3(
					sin(angle) * spread,
					attach.local_y,
					cos(angle) * spread
				)
				attach.parent.add_child(mount)
				_build_flower_head(c, mount, sub_s * 0.5, rng)


# ═══════════════════════════════════════════════════════════════════════
# STEM — segmented cylinder chain with natural curve
# ═══════════════════════════════════════════════════════════════════════

## Builds a stem and returns the topmost node (for attaching the flower head).
func _build_stem(c: Dictionary, parent: Node3D, s: float) -> Node3D:
	var height: float = c.stem_height * s
	var radius: float = c.stem_radius * s
	var curve: float = c.stem_curve as float
	var color: Color = c.stem_color
	var mat := _make_material(color, 0.75)

	var n_segs: int = 1 if curve < 0.05 else 4
	var seg_h: float = height / n_segs
	var current: Node3D = parent

	# Reset chain for this build — leaves and inflorescence attach via these.
	_stem_joints.clear()
	_stem_seg_h = seg_h

	for i in n_segs:
		var t: float = float(i) / n_segs

		# Create a joint node — each rotates relative to parent for natural curve
		var joint := Node3D.new()
		joint.name = "StemSeg_%d" % i
		if i > 0:
			joint.position.y = seg_h
			# Curve increases toward the top (quadratic)
			joint.rotation.x = curve * t * 0.3
		current.add_child(joint)
		_stem_joints.append(joint)

		# Tapered cylinder segment
		var cyl := CylinderMesh.new()
		cyl.bottom_radius = radius * (1.0 - t * 0.3)
		cyl.top_radius = radius * (1.0 - (t + 1.0 / n_segs) * 0.3)
		cyl.height = seg_h
		cyl.radial_segments = 6
		cyl.rings = 1

		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.material_override = mat
		mi.position.y = seg_h * 0.5
		joint.add_child(mi)

		current = joint

	# Return topmost joint — flower head attaches here
	var tip := Node3D.new()
	tip.name = "StemTip"
	tip.position.y = seg_h
	current.add_child(tip)
	return tip


## Find an attachment point along the stem at fraction t (0 = base, 1 = tip).
## Returns {parent: Node3D, local_y: float} — the caller should add its node
## as a child of `parent` at local position (0, local_y, 0) and any radial
## offsets in (x, z). This honors stem curve: straight-line coords like
## (0, stem_h * t, 0) on `self` drift away from the actual curved stem.
func _stem_attach_at(t: float) -> Dictionary:
	if _stem_joints.is_empty():
		return {"parent": self, "local_y": 0.0}
	var n: int = _stem_joints.size()
	var tc: float = clampf(t, 0.0, 1.0)
	var seg_idx: int = clampi(int(tc * n), 0, n - 1)
	var local_y: float = (tc * float(n) - float(seg_idx)) * _stem_seg_h
	return {"parent": _stem_joints[seg_idx], "local_y": local_y}


## Short pedicel (flower stalk) for inflorescence sub-flowers.
func _build_pedicel(parent: Node3D, length: float, color: Color, s: float) -> void:
	var mat := _make_material(color, 0.75)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.002 * s
	cyl.bottom_radius = 0.003 * s
	cyl.height = length
	cyl.radial_segments = 4
	cyl.rings = 1

	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = mat
	mi.position.y = length * 0.5
	parent.add_child(mi)


# ═══════════════════════════════════════════════════════════════════════
# LEAVES — placed via phyllotaxis along the stem
# ═══════════════════════════════════════════════════════════════════════

func _place_leaves(c: Dictionary, parent: Node3D, stem_h: float, s: float, rng: RandomNumberGenerator) -> void:
	var count: int = c.leaf_count as int
	if count <= 0:
		return

	var phyl: int = c.phyllotaxis as int
	var leaf_angle_deg: float = c.leaf_angle
	var leaf_mesh: Mesh = _generate_flat_mesh(
		c.leaf_length * s, c.leaf_width * s,
		c.leaf_shape as int, c.leaf_edge as int,
		c.leaf_curve as float, c.lod as int
	)
	var leaf_mat := _make_material(c.leaf_color, 0.7, true)

	for i in count:
		var t: float       # Fraction along stem 0..1
		var y_angle: float  # Rotation around stem axis

		match phyl:
			Phyllotaxis.ALTERNATE:
				t = 0.15 + float(i) / count * 0.55
				y_angle = TAU * float(i) * 0.618  # Golden angle

			Phyllotaxis.OPPOSITE:
				t = 0.15 + float(i / 2) / max(count / 2, 1) * 0.55
				y_angle = PI * float(i % 2)  # 0 or 180 degrees

			Phyllotaxis.WHORLED:
				t = 0.35
				y_angle = TAU * float(i) / count

			Phyllotaxis.ROSETTE:
				t = 0.0  # All at base
				y_angle = TAU * float(i) / count

			Phyllotaxis.SPIRAL:
				t = 0.1 + float(i) / count * 0.6
				y_angle = TAU * float(i) * 0.3819660113  # Golden angle / TAU

			_:
				t = 0.15 + float(i) / count * 0.55
				y_angle = TAU * float(i) / count

		# Slight randomness for organic feel — small jitter in t (±0.04)
		t += rng.randf_range(-0.04, 0.04)
		y_angle += rng.randf_range(-0.1, 0.1)

		# Resolve to a stem joint so leaves follow the curved stem.
		var attach: Dictionary = _stem_attach_at(t)
		# Special case for ROSETTE: nudge slightly above ground so leaves
		# don't z-fight the floor; otherwise use the joint-relative offset.
		var local_y: float = attach.local_y
		if phyl == Phyllotaxis.ROSETTE:
			local_y = max(local_y, 0.02 * s)

		var leaf_node := MeshInstance3D.new()
		leaf_node.name = "Leaf_%d" % i
		leaf_node.mesh = leaf_mesh
		leaf_node.material_override = leaf_mat

		# Position relative to the stem joint that covers this fraction;
		# leaf rotation is local to that joint, so leaves spiral around
		# the stem's actual axis rather than world Y.
		leaf_node.position = Vector3(0, local_y, 0)
		leaf_node.rotation = Vector3(
			deg_to_rad(leaf_angle_deg + rng.randf_range(-5, 5)),
			y_angle,
			0
		)

		# Fall back to the originally-passed parent if no stem chain was
		# built (defensive — shouldn't happen in normal flow).
		if attach.parent == self and _stem_joints.is_empty():
			parent.add_child(leaf_node)
		else:
			(attach.parent as Node3D).add_child(leaf_node)


# ═══════════════════════════════════════════════════════════════════════
# FLOWER HEAD — the complete floral structure
# ═══════════════════════════════════════════════════════════════════════

func _build_flower_head(c: Dictionary, parent: Node3D, s: float, rng: RandomNumberGenerator) -> void:
	var head := Node3D.new()
	head.name = "FlowerHead"

	# Pendant flowers face downward
	if c.pendant:
		head.rotation.x = deg_to_rad(160 + rng.randf_range(-10, 10))

	parent.add_child(head)

	var form: int = c.flower_form as int

	# ── Sepals (foderblad) — protective outer whorl ──
	var sepal_count: int = c.sepal_count as int
	if sepal_count > 0:
		var sepal_mesh := _generate_flat_mesh(
			c.sepal_length * s, c.sepal_length * s * 0.4,
			LeafShape.LANCEOLATE, LeafEdge.ENTIRE,
			0.15, c.lod as int
		)
		var sepal_mat := _make_material(c.sepal_color, 0.65, true)

		for i in sepal_count:
			var angle: float = TAU * float(i) / sepal_count
			var mi := MeshInstance3D.new()
			mi.name = "Sepal_%d" % i
			mi.mesh = sepal_mesh
			mi.material_override = sepal_mat
			mi.rotation = Vector3(deg_to_rad(75), angle, 0)
			head.add_child(mi)

	# ── Petals (kronblad) — the colorful whorl ──
	var petal_count: int = c.petal_count as int
	if petal_count > 0:
		var petal_opening: float = c.petal_opening
		var petal_curve: float = c.petal_curve as float
		var sym: int = c.symmetry as int

		# Adjust petal shape by flower form
		var effective_curve: float = petal_curve
		var effective_opening: float = petal_opening
		match form:
			FlowerForm.BELL:
				effective_curve = maxf(petal_curve, 0.4)
				effective_opening = minf(petal_opening, 25.0)
			FlowerForm.TUBULAR:
				effective_curve = 0.05
				effective_opening = minf(petal_opening, 15.0)
			FlowerForm.FUNNEL:
				effective_curve = 0.15
			FlowerForm.BOWL:
				effective_opening = clampf(petal_opening, 30.0, 60.0)
			FlowerForm.COMPOSITE:
				effective_opening = maxf(petal_opening, 75.0)
				effective_curve = 0.05

		var petal_mesh := _generate_flat_mesh(
			c.petal_length * s, c.petal_width * s,
			LeafShape.ELLIPTIC if form != FlowerForm.COMPOSITE else LeafShape.LINEAR,
			LeafEdge.ENTIRE,
			effective_curve, c.lod as int
		)
		var petal_mat := _make_petal_material(c.petal_color)

		for i in petal_count:
			var angle: float
			var tilt: float

			if sym == Symmetry.BILATERAL and petal_count == 6:
				# Iris-like: 3 standards (upright) + 3 falls (drooping)
				if i < 3:
					angle = TAU * float(i) / 3.0
					tilt = deg_to_rad(effective_opening * 0.3)  # Standards: upright
				else:
					angle = TAU * float(i - 3) / 3.0 + TAU / 6.0  # Offset
					tilt = deg_to_rad(effective_opening * 1.3)  # Falls: drooping
			else:
				angle = TAU * float(i) / petal_count + rng.randf_range(-0.05, 0.05)
				tilt = deg_to_rad(effective_opening + rng.randf_range(-3, 3))

			var mi := MeshInstance3D.new()
			mi.name = "Petal_%d" % i
			mi.mesh = petal_mesh
			mi.material_override = petal_mat
			mi.rotation = Vector3(tilt, angle, 0)
			head.add_child(mi)

		# ── Composite center disk (for daisies, sunflowers) ──
		if form == FlowerForm.COMPOSITE:
			var disk_r: float = c.petal_length * s * 0.6
			_build_composite_disk(head, disk_r, c.pistil_color, s)

	# ── Stamens (ståndare) — filament + anther ──
	var stamen_count: int = c.stamen_count as int
	if stamen_count > 0 and form != FlowerForm.COMPOSITE:
		_build_stamens(head, c, s, rng)

	# ── Pistil (pistill) — style + stigma ──
	var pistil_h: float = c.pistil_height * s
	if pistil_h > 0.001 and form != FlowerForm.COMPOSITE:
		_build_pistil(head, pistil_h, c.pistil_color, s)


func _build_stamens(head: Node3D, c: Dictionary, s: float, rng: RandomNumberGenerator) -> void:
	var count: int = c.stamen_count as int
	var length: float = c.stamen_length * s
	var color: Color = c.stamen_color

	var fil_mat := _make_material(color.darkened(0.3), 0.6)
	var ant_mat := _make_material(color, 0.5)

	for i in count:
		var angle: float = TAU * float(i) / count + rng.randf_range(-0.1, 0.1)
		var tilt: float = deg_to_rad(15 + rng.randf_range(-5, 5))

		var stamen := Node3D.new()
		stamen.name = "Stamen_%d" % i
		stamen.rotation = Vector3(tilt, angle, 0)
		head.add_child(stamen)

		# Filament (thin cylinder)
		var fil := CylinderMesh.new()
		fil.top_radius = 0.001 * s
		fil.bottom_radius = 0.0015 * s
		fil.height = length
		fil.radial_segments = 4

		var fil_mi := MeshInstance3D.new()
		fil_mi.mesh = fil
		fil_mi.material_override = fil_mat
		fil_mi.position.y = length * 0.5
		stamen.add_child(fil_mi)

		# Anther (small ellipsoid at tip)
		var anther := SphereMesh.new()
		anther.radius = 0.003 * s
		anther.height = 0.005 * s
		anther.radial_segments = 6
		anther.rings = 3

		var ant_mi := MeshInstance3D.new()
		ant_mi.mesh = anther
		ant_mi.material_override = ant_mat
		ant_mi.position.y = length
		stamen.add_child(ant_mi)


func _build_pistil(head: Node3D, height: float, color: Color, s: float) -> void:
	var style_mat := _make_material(color.darkened(0.15), 0.6)
	var stigma_mat := _make_material(color.lightened(0.1), 0.4)

	# Style (central cylinder)
	var style := CylinderMesh.new()
	style.top_radius = 0.002 * s
	style.bottom_radius = 0.003 * s
	style.height = height
	style.radial_segments = 5

	var style_mi := MeshInstance3D.new()
	style_mi.name = "Style"
	style_mi.mesh = style
	style_mi.material_override = style_mat
	style_mi.position.y = height * 0.5
	head.add_child(style_mi)

	# Stigma (rounded tip)
	var stigma := SphereMesh.new()
	stigma.radius = 0.004 * s
	stigma.height = 0.006 * s
	stigma.radial_segments = 6
	stigma.rings = 3

	var stigma_mi := MeshInstance3D.new()
	stigma_mi.name = "Stigma"
	stigma_mi.mesh = stigma
	stigma_mi.material_override = stigma_mat
	stigma_mi.position.y = height
	head.add_child(stigma_mi)


func _build_composite_disk(head: Node3D, radius: float, color: Color, s: float) -> void:
	# Central disk for composite flowers (daisy, sunflower)
	# Dense cluster of tiny florets
	var disk := CylinderMesh.new()
	disk.top_radius = radius
	disk.bottom_radius = radius * 0.9
	disk.height = radius * 0.4
	disk.radial_segments = 12
	disk.rings = 1

	var mat := _make_material(color, 0.6)

	var mi := MeshInstance3D.new()
	mi.name = "CompositeDisk"
	mi.mesh = disk
	mi.material_override = mat
	mi.position.y = radius * 0.2
	head.add_child(mi)


# ═══════════════════════════════════════════════════════════════════════
# MESH GENERATION — parametric flat mesh via SurfaceTool
# ═══════════════════════════════════════════════════════════════════════

## Generate a flat mesh for leaves or petals with the given botanical shape.
## The mesh extends along +Z (length) with width along X.
## Uses cull-disabled material for double-sided rendering.
static func _generate_flat_mesh(length: float, width: float, shape: int, edge: int, curve_amount: float, lod: int) -> Mesh:
	var segments: int = LOD_SEGMENTS[clampi(lod, 0, 3)]

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var prev_left := Vector3.ZERO
	var prev_right := Vector3.ZERO
	var prev_t: float = 0.0

	for i in segments:
		var t: float = float(i) / maxf(segments - 1.0, 1.0)

		# Position along length
		var z: float = t * length
		var y: float = curve_amount * sin(t * PI) * length * 0.15

		# Width at this position from botanical profile
		var hw: float = _leaf_profile(t, shape) * width * 0.5

		# Apply edge modulation (serration, lobing)
		hw *= _edge_modulator(t, edge, i)

		var left := Vector3(-hw, y, z)
		var right := Vector3(hw, y, z)

		if i > 0:
			var face_normal := Vector3(0, 1, 0)
			var uv_prev := prev_t
			var uv_curr := t

			# Triangle 1: prev_left → left → prev_right
			st.set_normal(face_normal)
			st.set_uv(Vector2(0, uv_prev))
			st.add_vertex(prev_left)
			st.set_normal(face_normal)
			st.set_uv(Vector2(0, uv_curr))
			st.add_vertex(left)
			st.set_normal(face_normal)
			st.set_uv(Vector2(1, uv_prev))
			st.add_vertex(prev_right)

			# Triangle 2: prev_right → left → right
			st.set_normal(face_normal)
			st.set_uv(Vector2(1, uv_prev))
			st.add_vertex(prev_right)
			st.set_normal(face_normal)
			st.set_uv(Vector2(0, uv_curr))
			st.add_vertex(left)
			st.set_normal(face_normal)
			st.set_uv(Vector2(1, uv_curr))
			st.add_vertex(right)

		prev_left = left
		prev_right = right
		prev_t = t

	st.generate_normals()
	return st.commit()


# ═══════════════════════════════════════════════════════════════════════
# PARAMETRIC SHAPE FUNCTIONS — botanical leaf/petal profiles
# ═══════════════════════════════════════════════════════════════════════

## Returns half-width at position t (0=base, 1=tip) for the given botanical leaf shape.
## Normalized to 0-1 range; multiply by actual width.
static func _leaf_profile(t: float, shape: int) -> float:
	match shape:
		LeafShape.LINEAR:
			# Linjär — constant width, tapers at tip
			if t < 0.05: return t / 0.05 * 0.9
			if t > 0.85: return (1.0 - t) / 0.15 * 0.9
			return 0.9

		LeafShape.LANCEOLATE:
			# Lansettlik — widest at ~30%, tapers both ways
			return sin(t * PI) * (1.0 - t * 0.25) * (0.5 + t * 0.8)

		LeafShape.ELLIPTIC:
			# Elliptisk — symmetric widest at center
			return sin(t * PI)

		LeafShape.OVATE:
			# Äggrund — widest below center (egg-shaped)
			return sin(t * PI * 0.85) * (1.0 - t * 0.15)

		LeafShape.OBOVATE:
			# Omvänt äggrund — widest above center
			return sin(t * PI) * (0.5 + t * 0.7)

		LeafShape.CORDATE:
			# Hjärtlik — heart-shaped, wide at base with notch
			if t < 0.08: return 0.6 + t * 5.0  # Broad base
			return sin(t * PI) * 1.1 * (1.0 - t * 0.1)

		LeafShape.SPATULATE:
			# Spatellik — narrow base, wide rounded tip
			return t * sin(t * PI) * 1.3

		LeafShape.RENIFORM:
			# Njurtlik — kidney-shaped, very wide center
			return sin(t * PI) * 1.4 * (1.0 - (t - 0.5) * (t - 0.5) * 2.0)

	return sin(t * PI)  # Fallback: elliptic


## Modulates width for leaf edge effects (serration, lobing, etc.)
static func _edge_modulator(t: float, edge: int, seg_idx: int) -> float:
	match edge:
		LeafEdge.ENTIRE:
			return 1.0  # Helbräddad — smooth edge

		LeafEdge.SERRATE:
			# Sågad — saw-tooth edge
			return 1.0 - 0.08 * absf(sin(float(seg_idx) * PI * 2.5))

		LeafEdge.DENTATE:
			# Tandad — tooth-like indentations
			return 1.0 - 0.12 * absf(sin(float(seg_idx) * PI * 1.8))

		LeafEdge.CRENATE:
			# Naggad — rounded scallops
			return 1.0 - 0.06 * (0.5 + 0.5 * cos(float(seg_idx) * PI * 2.0))

		LeafEdge.LOBED:
			# Flikig — deep lobes
			return 1.0 - 0.25 * absf(sin(float(seg_idx) * PI * 1.2))

	return 1.0


# ═══════════════════════════════════════════════════════════════════════
# MATERIALS
# ═══════════════════════════════════════════════════════════════════════

## Create a StandardMaterial3D for stems, leaves, etc.
static func _make_material(color: Color, roughness: float = 0.7, double_sided: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic_specular = 0.1
	if double_sided:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


## Create a petal material — double-sided with slight translucency.
static func _make_petal_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.45
	mat.metallic_specular = 0.15
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Slight subsurface scattering feel via emission
	mat.emission_enabled = true
	mat.emission = color.lightened(0.3)
	mat.emission_energy_multiplier = 0.08
	return mat


# ═══════════════════════════════════════════════════════════════════════
# MULTIMESH BATCHING — collect-then-batch for VR performance
# ═══════════════════════════════════════════════════════════════════════

## Compose a local Transform3D from position, euler rotation, and optional scale.
static func _xform(pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot).scaled(scl), pos)


## Compute a basis that looks along `direction` (like look_at but without needing scene tree).
static func _look_basis(direction: Vector3) -> Basis:
	var fwd: Vector3 = direction.normalized()
	if fwd.length_squared() < 0.0001:
		return Basis.IDENTITY
	var up := Vector3.UP
	if absf(fwd.dot(up)) > 0.99:
		up = Vector3.FORWARD
	var right := up.cross(fwd).normalized()
	var actual_up := fwd.cross(right).normalized()
	return Basis(right, actual_up, fwd)


## Create a StandardMaterial3D with vertex_color_use_as_albedo for MultiMesh batching.
static func _make_material_batched(base_color: Color, roughness: float = 0.7, double_sided: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.roughness = roughness
	mat.metallic_specular = 0.1
	mat.vertex_color_use_as_albedo = true
	if double_sided:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


## Create a petal material with vertex_color_use_as_albedo for MultiMesh batching.
static func _make_petal_material_batched(base_color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.roughness = 0.45
	mat.metallic_specular = 0.15
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = base_color.lightened(0.3)
	mat.emission_energy_multiplier = 0.08
	return mat


## Pre-generate all meshes for a species config. Returns dict keyed by component name.
static func _generate_species_meshes(c: Dictionary, s: float) -> Dictionary:
	var meshes := {}
	var lod: int = c.lod as int

	# Stem segments — generate for each taper level
	var n_segs: int = 1 if (c.stem_curve as float) < 0.05 else 4
	var radius: float = c.stem_radius * s
	var seg_h: float = c.stem_height * s / n_segs
	for seg_i in n_segs:
		var t: float = float(seg_i) / n_segs
		var cyl := CylinderMesh.new()
		cyl.bottom_radius = radius * (1.0 - t * 0.3)
		cyl.top_radius = radius * (1.0 - (t + 1.0 / n_segs) * 0.3)
		cyl.height = seg_h
		cyl.radial_segments = 6
		cyl.rings = 1
		meshes["stem_%d" % seg_i] = cyl

	# Pedicel mesh
	var ped := CylinderMesh.new()
	ped.top_radius = 0.002 * s
	ped.bottom_radius = 0.003 * s
	ped.height = 1.0  # Scaled per-instance
	ped.radial_segments = 4
	ped.rings = 1
	meshes["pedicel"] = ped

	# Leaf mesh
	if (c.leaf_count as int) > 0:
		meshes["leaf"] = _generate_flat_mesh(
			c.leaf_length * s, c.leaf_width * s,
			c.leaf_shape as int, c.leaf_edge as int,
			c.leaf_curve as float, lod
		)

	# Sepal mesh
	if (c.sepal_count as int) > 0:
		meshes["sepal"] = _generate_flat_mesh(
			c.sepal_length * s, c.sepal_length * s * 0.4,
			LeafShape.LANCEOLATE, LeafEdge.ENTIRE, 0.15, lod
		)

	# Petal mesh
	if (c.petal_count as int) > 0:
		var form: int = c.flower_form as int
		var effective_curve: float = c.petal_curve as float
		match form:
			FlowerForm.BELL:
				effective_curve = maxf(c.petal_curve as float, 0.4)
			FlowerForm.TUBULAR:
				effective_curve = 0.05
			FlowerForm.FUNNEL:
				effective_curve = 0.15
			FlowerForm.COMPOSITE:
				effective_curve = 0.05
		meshes["petal"] = _generate_flat_mesh(
			c.petal_length * s, c.petal_width * s,
			LeafShape.ELLIPTIC if form != FlowerForm.COMPOSITE else LeafShape.LINEAR,
			LeafEdge.ENTIRE, effective_curve, lod
		)

	# Stamen meshes
	if (c.stamen_count as int) > 0 and (c.flower_form as int) != FlowerForm.COMPOSITE:
		var fil := CylinderMesh.new()
		fil.top_radius = 0.001 * s
		fil.bottom_radius = 0.0015 * s
		fil.height = c.stamen_length * s
		fil.radial_segments = 4
		meshes["filament"] = fil

		var anther := SphereMesh.new()
		anther.radius = 0.003 * s
		anther.height = 0.005 * s
		anther.radial_segments = 6
		anther.rings = 3
		meshes["anther"] = anther

	# Pistil meshes
	var pistil_h: float = c.pistil_height * s
	if pistil_h > 0.001 and (c.flower_form as int) != FlowerForm.COMPOSITE:
		var style := CylinderMesh.new()
		style.top_radius = 0.002 * s
		style.bottom_radius = 0.003 * s
		style.height = pistil_h
		style.radial_segments = 5
		meshes["style"] = style

		var stigma := SphereMesh.new()
		stigma.radius = 0.004 * s
		stigma.height = 0.006 * s
		stigma.radial_segments = 6
		stigma.rings = 3
		meshes["stigma"] = stigma

	# Composite disk
	if (c.flower_form as int) == FlowerForm.COMPOSITE:
		var disk_r: float = c.petal_length * s * 0.6
		var disk := CylinderMesh.new()
		disk.top_radius = disk_r
		disk.bottom_radius = disk_r * 0.9
		disk.height = disk_r * 0.4
		disk.radial_segments = 12
		disk.rings = 1
		meshes["disk"] = disk

	return meshes


## Pre-generate all materials for a species config. Returns dict keyed by component name.
static func _generate_species_materials(c: Dictionary) -> Dictionary:
	var mats := {}
	mats["stem"] = _make_material_batched(c.stem_color, 0.75)
	mats["leaf"] = _make_material_batched(c.leaf_color, 0.7, true)
	mats["sepal"] = _make_material_batched(c.sepal_color, 0.65, true)
	mats["petal"] = _make_petal_material_batched(c.petal_color)
	mats["filament"] = _make_material_batched((c.stamen_color as Color).darkened(0.3), 0.6)
	mats["anther"] = _make_material_batched(c.stamen_color, 0.5)
	mats["style"] = _make_material_batched((c.pistil_color as Color).darkened(0.15), 0.6)
	mats["stigma"] = _make_material_batched((c.pistil_color as Color).lightened(0.1), 0.4)
	mats["disk"] = _make_material_batched(c.pistil_color, 0.6)
	mats["pedicel"] = mats["stem"]
	return mats


## Collect all component placements for a single flower into buckets.
## `buckets` maps bucket_key -> {mesh, material, transforms: Array, colors: Array}
static func _collect_flower_placements(c: Dictionary, flower_xform: Transform3D,
		rng: RandomNumberGenerator, s: float, species_meshes: Dictionary,
		species_mats: Dictionary, buckets: Dictionary, bucket_prefix: String) -> void:

	var stem_h: float = c.stem_height * s
	var n_segs: int = 1 if (c.stem_curve as float) < 0.05 else 4
	var seg_h: float = stem_h / n_segs
	var curve: float = c.stem_curve as float

	# ── Stem segments ──
	var current_xform := flower_xform
	for seg_i in n_segs:
		var t: float = float(seg_i) / n_segs
		var joint_pos := Vector3.ZERO if seg_i == 0 else Vector3(0, seg_h, 0)
		var joint_rot := Vector3.ZERO
		if seg_i > 0:
			joint_rot.x = curve * t * 0.3

		current_xform = current_xform * _xform(joint_pos, joint_rot)
		var mesh_xform := current_xform * _xform(Vector3(0, seg_h * 0.5, 0))

		var key: String = bucket_prefix + "stem_%d" % seg_i
		_bucket_add(buckets, key, species_meshes["stem_%d" % seg_i],
			species_mats["stem"], mesh_xform, c.stem_color)

	# Stem tip transform
	var tip_xform := current_xform * _xform(Vector3(0, seg_h, 0))

	# ── Leaves ──
	var leaf_count: int = c.leaf_count as int
	if leaf_count > 0 and species_meshes.has("leaf"):
		var phyl: int = c.phyllotaxis as int
		var leaf_angle_deg: float = c.leaf_angle

		for i in leaf_count:
			var y_pos: float
			var y_angle: float

			match phyl:
				Phyllotaxis.ALTERNATE:
					y_pos = stem_h * (0.15 + float(i) / leaf_count * 0.55)
					y_angle = TAU * float(i) * 0.618
				Phyllotaxis.OPPOSITE:
					y_pos = stem_h * (0.15 + float(i / 2) / (leaf_count / 2) * 0.55)
					y_angle = PI * float(i % 2)
				Phyllotaxis.WHORLED:
					y_pos = stem_h * 0.35
					y_angle = TAU * float(i) / leaf_count
				Phyllotaxis.ROSETTE:
					y_pos = 0.02 * s
					y_angle = TAU * float(i) / leaf_count
				Phyllotaxis.SPIRAL:
					y_pos = stem_h * (0.1 + float(i) / leaf_count * 0.6)
					y_angle = TAU * float(i) * 0.3819660113
				_:
					y_pos = stem_h * (0.15 + float(i) / leaf_count * 0.55)
					y_angle = TAU * float(i) / leaf_count

			y_pos += rng.randf_range(-0.01, 0.01) * s
			y_angle += rng.randf_range(-0.1, 0.1)

			var leaf_rot := Vector3(
				deg_to_rad(leaf_angle_deg + rng.randf_range(-5, 5)),
				y_angle, 0
			)
			var leaf_xform := flower_xform * _xform(Vector3(0, y_pos, 0), leaf_rot)

			var key: String = bucket_prefix + "leaf"
			_bucket_add(buckets, key, species_meshes["leaf"],
				species_mats["leaf"], leaf_xform, c.leaf_color)

	# ── Flower head(s) — depends on inflorescence type ──
	var inf_type: int = c.inflorescence as int
	if inf_type == InflorescenceType.SINGLE or (c.flower_count as int) <= 1:
		_collect_flower_head(c, tip_xform, s, rng, species_meshes, species_mats, buckets, bucket_prefix)
	else:
		_collect_inflorescence(c, flower_xform, tip_xform, stem_h, s, rng,
			species_meshes, species_mats, buckets, bucket_prefix)


## Collect placements for a single flower head (sepals, petals, stamens, pistil).
static func _collect_flower_head(c: Dictionary, parent_xform: Transform3D, s: float,
		rng: RandomNumberGenerator, meshes: Dictionary, mats: Dictionary,
		buckets: Dictionary, prefix: String) -> void:

	var head_rot := Vector3.ZERO
	if c.pendant:
		head_rot.x = deg_to_rad(160 + rng.randf_range(-10, 10))
	var head_xform := parent_xform * _xform(Vector3.ZERO, head_rot)

	var form: int = c.flower_form as int

	# Sepals
	var sepal_count: int = c.sepal_count as int
	if sepal_count > 0 and meshes.has("sepal"):
		for i in sepal_count:
			var angle: float = TAU * float(i) / sepal_count
			var rot := Vector3(deg_to_rad(75), angle, 0)
			var xf := head_xform * _xform(Vector3.ZERO, rot)
			_bucket_add(buckets, prefix + "sepal", meshes["sepal"], mats["sepal"], xf, c.sepal_color)

	# Petals
	var petal_count: int = c.petal_count as int
	if petal_count > 0 and meshes.has("petal"):
		var petal_opening: float = c.petal_opening
		var sym: int = c.symmetry as int
		var effective_opening: float = petal_opening
		match form:
			FlowerForm.BELL:
				effective_opening = minf(petal_opening, 25.0)
			FlowerForm.TUBULAR:
				effective_opening = minf(petal_opening, 15.0)
			FlowerForm.BOWL:
				effective_opening = clampf(petal_opening, 30.0, 60.0)
			FlowerForm.COMPOSITE:
				effective_opening = maxf(petal_opening, 75.0)

		for i in petal_count:
			var angle: float
			var tilt: float
			if sym == Symmetry.BILATERAL and petal_count == 6:
				if i < 3:
					angle = TAU * float(i) / 3.0
					tilt = deg_to_rad(effective_opening * 0.3)
				else:
					angle = TAU * float(i - 3) / 3.0 + TAU / 6.0
					tilt = deg_to_rad(effective_opening * 1.3)
			else:
				angle = TAU * float(i) / petal_count + rng.randf_range(-0.05, 0.05)
				tilt = deg_to_rad(effective_opening + rng.randf_range(-3, 3))

			var rot := Vector3(tilt, angle, 0)
			var xf := head_xform * _xform(Vector3.ZERO, rot)
			_bucket_add(buckets, prefix + "petal", meshes["petal"], mats["petal"], xf, c.petal_color)

		# Composite disk
		if form == FlowerForm.COMPOSITE and meshes.has("disk"):
			var disk_r: float = c.petal_length * s * 0.6
			var xf := head_xform * _xform(Vector3(0, disk_r * 0.2, 0))
			_bucket_add(buckets, prefix + "disk", meshes["disk"], mats["disk"], xf, c.pistil_color)

	# Stamens
	var stamen_count: int = c.stamen_count as int
	if stamen_count > 0 and form != FlowerForm.COMPOSITE and meshes.has("filament"):
		var length: float = c.stamen_length * s
		for i in stamen_count:
			var angle: float = TAU * float(i) / stamen_count + rng.randf_range(-0.1, 0.1)
			var tilt: float = deg_to_rad(15 + rng.randf_range(-5, 5))
			var stamen_rot := Vector3(tilt, angle, 0)
			var stamen_xform := head_xform * _xform(Vector3.ZERO, stamen_rot)

			# Filament
			var fil_xf := stamen_xform * _xform(Vector3(0, length * 0.5, 0))
			_bucket_add(buckets, prefix + "filament", meshes["filament"], mats["filament"],
				fil_xf, (c.stamen_color as Color).darkened(0.3))

			# Anther
			var ant_xf := stamen_xform * _xform(Vector3(0, length, 0))
			_bucket_add(buckets, prefix + "anther", meshes["anther"], mats["anther"],
				ant_xf, c.stamen_color)

	# Pistil
	var pistil_h: float = c.pistil_height * s
	if pistil_h > 0.001 and form != FlowerForm.COMPOSITE and meshes.has("style"):
		# Style
		var style_xf := head_xform * _xform(Vector3(0, pistil_h * 0.5, 0))
		_bucket_add(buckets, prefix + "style", meshes["style"], mats["style"],
			style_xf, (c.pistil_color as Color).darkened(0.15))
		# Stigma
		var stigma_xf := head_xform * _xform(Vector3(0, pistil_h, 0))
		_bucket_add(buckets, prefix + "stigma", meshes["stigma"], mats["stigma"],
			stigma_xf, (c.pistil_color as Color).lightened(0.1))


## Collect placements for inflorescence sub-flowers.
static func _collect_inflorescence(c: Dictionary, flower_xform: Transform3D,
		tip_xform: Transform3D, stem_h: float, s: float,
		rng: RandomNumberGenerator, meshes: Dictionary, mats: Dictionary,
		buckets: Dictionary, prefix: String) -> void:

	var count: int = c.flower_count as int
	var spacing: float = c.flower_spacing * s
	var inf_type: int = c.inflorescence as int
	var sub_s: float = s * 0.65

	# Sub-flower config with adjusted scale
	var sub_c := c.duplicate()
	sub_c["overall_scale"] = sub_s

	match inf_type:
		InflorescenceType.RACEME:
			for i in count:
				var t: float = 0.4 + float(i) / maxf(count - 1.0, 1.0) * 0.55
				var angle: float = TAU * float(i) * 0.618
				var pedicel_len: float = spacing * (1.0 + rng.randf_range(-0.2, 0.2))

				var joint_rot := Vector3(
					deg_to_rad(30 + rng.randf_range(-10, 10)), angle, 0
				)
				var joint_xform := flower_xform * _xform(Vector3(0, stem_h * t, 0), joint_rot)
				var head_xform := joint_xform * _xform(Vector3(0, 0, pedicel_len))

				# Pedicel
				_collect_pedicel(joint_xform, pedicel_len, c.stem_color, s, meshes, mats, buckets, prefix)

				if c.pendant:
					head_xform = head_xform * _xform(Vector3.ZERO, Vector3(
						deg_to_rad(120 + rng.randf_range(-15, 15)), 0, 0))

				_collect_flower_head(c, head_xform, sub_s, rng, meshes, mats, buckets, prefix)

		InflorescenceType.SPIKE:
			for i in count:
				var t: float = 0.5 + float(i) / maxf(count - 1.0, 1.0) * 0.45
				var angle: float = TAU * float(i) * 0.618
				var mount_xform := flower_xform * _xform(
					Vector3(0, stem_h * t, 0), Vector3(0, angle, 0))
				_collect_flower_head(c, mount_xform, sub_s * 0.7, rng, meshes, mats, buckets, prefix)

		InflorescenceType.UMBEL:
			for i in count:
				var angle: float = TAU * float(i) / count
				var tilt: float = deg_to_rad(25 + rng.randf_range(-8, 8))
				var stalk_len: float = spacing * 3.0 + rng.randf_range(0, spacing)

				var ray_xform := flower_xform * _xform(
					Vector3(0, stem_h, 0), Vector3(tilt, angle, 0))
				var ray_tip := ray_xform * _xform(Vector3(0, stalk_len, 0))

				_collect_pedicel(ray_xform, stalk_len, c.stem_color, s, meshes, mats, buckets, prefix)
				_collect_flower_head(c, ray_tip, sub_s * 0.6, rng, meshes, mats, buckets, prefix)

		InflorescenceType.HEAD:
			var head_r: float = maxf(c.petal_length * s * 1.5, spacing) * sqrt(count) * 0.25
			var golden := (1.0 + sqrt(5.0)) / 2.0

			for i in count:
				var theta: float = acos(1.0 - 2.0 * (float(i) + 0.5) / count)
				var phi: float = TAU * float(i) / golden

				var pos := Vector3(
					sin(theta) * cos(phi),
					cos(theta),
					sin(theta) * sin(phi)
				) * head_r

				var mount_pos := Vector3(0, stem_h, 0) + pos
				var mount_xform: Transform3D
				if pos.length() > 0.001:
					mount_xform = flower_xform * Transform3D(
						_look_basis(pos.normalized()), mount_pos)
				else:
					mount_xform = flower_xform * _xform(mount_pos)

				_collect_flower_head(c, mount_xform, sub_s * 0.35, rng, meshes, mats, buckets, prefix)

		InflorescenceType.CYME:
			var top_xform := flower_xform * _xform(Vector3(0, stem_h, 0))
			_collect_flower_head(c, top_xform, sub_s, rng, meshes, mats, buckets, prefix)

			for i in range(1, count):
				var angle: float = TAU * float(i) / (count - 1)
				var drop: float = float(i) / count * stem_h * 0.3
				var spread_val: float = spacing * 3.0

				var branch_pos := Vector3(
					sin(angle) * spread_val,
					stem_h - drop,
					cos(angle) * spread_val
				)
				var branch_xform := flower_xform * _xform(branch_pos)
				_collect_flower_head(c, branch_xform, sub_s * 0.75, rng, meshes, mats, buckets, prefix)

		InflorescenceType.PANICLE:
			for i in count:
				var t: float = 0.3 + float(i) / maxf(count - 1.0, 1.0) * 0.65
				var angle: float = TAU * float(i) * 0.618
				var spread_val: float = spacing * 2.0 * (1.0 - t)

				var mount_pos := Vector3(
					sin(angle) * spread_val,
					stem_h * t,
					cos(angle) * spread_val
				)
				var mount_xform := flower_xform * _xform(mount_pos)
				_collect_flower_head(c, mount_xform, sub_s * 0.5, rng, meshes, mats, buckets, prefix)


## Collect a pedicel placement.
static func _collect_pedicel(parent_xform: Transform3D, length: float, color: Color,
		s: float, meshes: Dictionary, mats: Dictionary,
		buckets: Dictionary, prefix: String) -> void:
	# Scale the unit-height pedicel mesh to desired length
	var xf := parent_xform * _xform(Vector3(0, length * 0.5, 0), Vector3.ZERO,
		Vector3(1, length, 1))
	_bucket_add(buckets, prefix + "pedicel", meshes["pedicel"], mats["pedicel"], xf, color)


## Add a placement to a bucket, creating the bucket if needed.
static func _bucket_add(buckets: Dictionary, key: String, mesh: Mesh, material: Material,
		xform: Transform3D, color: Color) -> void:
	if not buckets.has(key):
		buckets[key] = {
			"mesh": mesh,
			"material": material,
			"transforms": [],
			"colors": [],
		}
	buckets[key].transforms.append(xform)
	buckets[key].colors.append(color)


## Build a MultiMeshInstance3D from a bucket of collected placements.
static func _build_bucket_multimesh(parent: Node3D, key: String, bucket: Dictionary) -> void:
	var transforms: Array = bucket.transforms
	var colors: Array = bucket.colors
	var count: int = transforms.size()
	if count == 0:
		return

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = bucket.mesh
	mm.instance_count = count

	for i in count:
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "MM_%s" % key
	mmi.multimesh = mm
	mmi.material_override = bucket.material
	parent.add_child(mmi)


## Generate natural flock cluster positions for a garden.
## Returns Array of {position: Vector3, rotation_y: float}
static func _generate_flock_positions(count: int, radius: float, rng: RandomNumberGenerator) -> Array:
	var positions := []

	# Determine cluster count — 2-5 clusters, scaled by flower count
	var n_clusters: int = clampi(roundi(float(count) / 5.0), 2, 5)

	# Generate cluster centers within 70% of garden radius
	var centers := []
	for _c in n_clusters:
		var angle: float = rng.randf_range(0, TAU)
		var dist: float = rng.randf_range(0.15, 0.7) * radius
		centers.append(Vector3(cos(angle) * dist, 0, sin(angle) * dist))

	# Distribute flowers across clusters
	var per_cluster := []
	var remaining := count
	for ci in n_clusters:
		var alloc: int
		if ci == n_clusters - 1:
			alloc = remaining
		else:
			alloc = clampi(rng.randi_range(3, 8), 1, remaining - (n_clusters - ci - 1))
		per_cluster.append(alloc)
		remaining -= alloc

	# Place flowers within each cluster — tight Gaussian spacing
	for ci in n_clusters:
		var center: Vector3 = centers[ci]
		var cluster_count: int = per_cluster[ci]
		var tight_radius: float = 0.1 + 0.1 * sqrt(cluster_count)  # 0.1-0.2m base

		for fi in cluster_count:
			# Box-Muller Gaussian approximation — sum of uniform randoms
			var dx: float = (rng.randf() + rng.randf() + rng.randf() - 1.5) * tight_radius
			var dz: float = (rng.randf() + rng.randf() + rng.randf() - 1.5) * tight_radius
			var pos := center + Vector3(dx, 0, dz)

			# Clamp to garden radius
			var flat_dist: float = Vector2(pos.x, pos.z).length()
			if flat_dist > radius:
				pos.x *= radius / flat_dist
				pos.z *= radius / flat_dist

			positions.append({
				"position": pos,
				"rotation_y": rng.randf_range(0, TAU),
			})

	return positions


# ═══════════════════════════════════════════════════════════════════════
# BRIDGES — connect to existing systems
# ═══════════════════════════════════════════════════════════════════════

## Configure from a CritterDNA resource (kingdom 2 = flower).
## Maps DNA genes to botanical parameters for ecosystem integration.
func from_dna(dna: Resource) -> void:
	config = {
		"stem_height": dna.get("scent_strength") * 0.5 + 0.1 if dna.get("scent_strength") else 0.3,
		"stem_color": dna.get("secondary_color") if dna.get("secondary_color") else Color(0.2, 0.45, 0.15),
		"leaf_count": clampi(roundi(dna.get("segments") * 3.0) if dna.get("segments") else 4, 2, 8),
		"leaf_length": dna.get("part_length") * 0.4 if dna.get("part_length") else 0.06,
		"leaf_color": (dna.get("secondary_color") if dna.get("secondary_color") else Color(0.22, 0.48, 0.16)),
		"petal_count": clampi(roundi(dna.get("symmetry")) if dna.get("symmetry") else 5, 3, 12),
		"petal_length": dna.get("part_length") * 0.3 if dna.get("part_length") else 0.05,
		"petal_width": dna.get("part_width") * 0.3 if dna.get("part_width") else 0.025,
		"petal_color": dna.get("primary_color") if dna.get("primary_color") else Color(0.85, 0.3, 0.55),
		"petal_opening": dna.get("branch_angle") if dna.get("branch_angle") else 60.0,
		"petal_curve": dna.get("part_curve") if dna.get("part_curve") else 0.2,
		"stamen_count": clampi(roundi(dna.get("symmetry")) if dna.get("symmetry") else 5, 1, 8),
		"stamen_color": dna.get("tertiary_color") if dna.get("tertiary_color") else Color(0.9, 0.8, 0.3),
		"seed": dna.get("dna_seed") if dna.get("dna_seed") else 0,
	}

	# Map inflorescence gene to type
	var inf: float = dna.get("inflorescence") if dna.get("inflorescence") else 0.0
	if inf < 0.05:
		config["inflorescence"] = InflorescenceType.SINGLE
	elif inf < 0.2:
		config["inflorescence"] = InflorescenceType.RACEME
		config["flower_count"] = clampi(roundi(dna.get("segments") * 2.0), 3, 12)
	elif inf < 0.5:
		config["inflorescence"] = InflorescenceType.UMBEL
		config["flower_count"] = clampi(roundi(dna.get("segments") * 3.0), 4, 15)
	else:
		config["inflorescence"] = InflorescenceType.HEAD
		config["flower_count"] = clampi(roundi(dna.get("segments") * 4.0), 8, 30)


## Grid system integration — configure from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("preset"):
		preset = config_data.preset
	if config_data.has("scale"):
		config["overall_scale"] = config_data.scale
	if config_data.has("seed"):
		config["seed"] = config_data.seed


## Generate a random but botanically plausible flower.
func randomize_species(seed_val: int = 0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val if seed_val != 0 else randi()

	config = {
		"stem_height": rng.randf_range(0.1, 0.5),
		"stem_radius": rng.randf_range(0.004, 0.012),
		"stem_curve": rng.randf_range(0.0, 0.4),

		"leaf_count": rng.randi_range(2, 8),
		"leaf_shape": rng.randi_range(0, 7),
		"leaf_edge": rng.randi_range(0, 4),
		"phyllotaxis": rng.randi_range(0, 4),
		"leaf_length": rng.randf_range(0.03, 0.12),
		"leaf_width": rng.randf_range(0.008, 0.04),
		"leaf_color": Color(
			rng.randf_range(0.15, 0.3),
			rng.randf_range(0.35, 0.55),
			rng.randf_range(0.1, 0.25)
		),

		"flower_form": rng.randi_range(0, 5),
		"petal_count": rng.randi_range(3, 12),
		"petal_length": rng.randf_range(0.02, 0.06),
		"petal_width": rng.randf_range(0.008, 0.03),
		"petal_color": Color(
			rng.randf_range(0.3, 1.0),
			rng.randf_range(0.2, 0.9),
			rng.randf_range(0.3, 1.0)
		),
		"petal_opening": rng.randf_range(15.0, 85.0),

		"sepal_count": rng.randi_range(0, 6),
		"stamen_count": rng.randi_range(1, 8),
		"stamen_color": Color(
			rng.randf_range(0.7, 1.0),
			rng.randf_range(0.6, 0.9),
			rng.randf_range(0.2, 0.5)
		),

		"seed": seed_val,
	}

	# 40% chance of inflorescence
	if rng.randf() < 0.4:
		config["inflorescence"] = rng.randi_range(1, 6)
		config["flower_count"] = rng.randi_range(3, 15)


# ═══════════════════════════════════════════════════════════════════════
# GARDEN HELPER — create a cluster of varied botanical flowers
# ═══════════════════════════════════════════════════════════════════════

## Create a garden of flowers using MultiMesh batching and flock clustering.
## Returns a Node3D containing MultiMeshInstance3D nodes (~8 draw calls instead of ~900).
static func create_garden(count: int = 12, radius: float = 1.0, base_seed: int = 42, preset_name: String = "") -> Node3D:
	var garden := Node3D.new()
	garden.name = "BotanicalGarden"

	var rng := RandomNumberGenerator.new()
	rng.seed = base_seed

	var preset_names: Array = PRESETS.keys()

	# Generate flock cluster positions
	var positions := _generate_flock_positions(count, radius, rng)

	# Collect all mesh placements into buckets
	var buckets := {}

	# Cache species meshes/materials to avoid regenerating
	var species_cache := {}  # species_key -> {meshes, materials, config}

	for i in count:
		# Determine species config
		var c := DEFAULT_CONFIG.duplicate()
		var species_key: String

		if preset_name != "" and PRESETS.has(preset_name):
			for k in PRESETS[preset_name]:
				c[k] = PRESETS[preset_name][k]
			species_key = preset_name
		elif rng.randf() < 0.7:
			var chosen: String = preset_names[rng.randi() % preset_names.size()]
			for k in PRESETS[chosen]:
				c[k] = PRESETS[chosen][k]
			species_key = chosen
		else:
			# Random species — unique per flower
			var rand_rng := RandomNumberGenerator.new()
			rand_rng.seed = base_seed + i * 137
			c["stem_height"] = rand_rng.randf_range(0.1, 0.5)
			c["stem_radius"] = rand_rng.randf_range(0.004, 0.012)
			c["stem_curve"] = rand_rng.randf_range(0.0, 0.4)
			c["leaf_count"] = rand_rng.randi_range(2, 8)
			c["leaf_shape"] = rand_rng.randi_range(0, 7)
			c["leaf_edge"] = rand_rng.randi_range(0, 4)
			c["phyllotaxis"] = rand_rng.randi_range(0, 4)
			c["leaf_length"] = rand_rng.randf_range(0.03, 0.12)
			c["leaf_width"] = rand_rng.randf_range(0.008, 0.04)
			c["leaf_color"] = Color(rand_rng.randf_range(0.15, 0.3), rand_rng.randf_range(0.35, 0.55), rand_rng.randf_range(0.1, 0.25))
			c["flower_form"] = rand_rng.randi_range(0, 5)
			c["petal_count"] = rand_rng.randi_range(3, 12)
			c["petal_length"] = rand_rng.randf_range(0.02, 0.06)
			c["petal_width"] = rand_rng.randf_range(0.008, 0.03)
			c["petal_color"] = Color(rand_rng.randf_range(0.3, 1.0), rand_rng.randf_range(0.2, 0.9), rand_rng.randf_range(0.3, 1.0))
			c["petal_opening"] = rand_rng.randf_range(15.0, 85.0)
			c["sepal_count"] = rand_rng.randi_range(0, 6)
			c["stamen_count"] = rand_rng.randi_range(1, 8)
			c["stamen_color"] = Color(rand_rng.randf_range(0.7, 1.0), rand_rng.randf_range(0.6, 0.9), rand_rng.randf_range(0.2, 0.5))
			if rand_rng.randf() < 0.4:
				c["inflorescence"] = rand_rng.randi_range(1, 6)
				c["flower_count"] = rand_rng.randi_range(3, 15)
			species_key = "random_%d" % i

		# Per-flower variation
		var scale_var: float = rng.randf_range(0.7, 1.3)
		c["overall_scale"] = scale_var
		c["seed"] = base_seed + i
		var s: float = scale_var

		# Get or create cached meshes/materials for this species
		var bucket_prefix: String = species_key + "_"
		if not species_cache.has(species_key):
			species_cache[species_key] = {
				"meshes": _generate_species_meshes(c, s),
				"materials": _generate_species_materials(c),
			}

		var cached = species_cache[species_key]

		# Flower transform from flock position
		var pos_data: Dictionary = positions[i]
		var flower_xform := Transform3D(
			Basis(Vector3.UP, pos_data.rotation_y),
			pos_data.position
		)

		# Per-flower RNG
		var flower_rng := RandomNumberGenerator.new()
		flower_rng.seed = base_seed + i

		_collect_flower_placements(c, flower_xform, flower_rng, s,
			cached.meshes, cached.materials, buckets, bucket_prefix)

	# Phase 2: Build one MultiMeshInstance3D per bucket
	var total_instances := 0
	for key in buckets:
		_build_bucket_multimesh(garden, key, buckets[key])
		total_instances += buckets[key].transforms.size()

	print("BotanicalGarden: %d flowers → %d buckets, %d instances" % [
		count, buckets.size(), total_instances])

	return garden

extends RefCounted
class_name GroundPatch

## ground_patch.gd
##
## Helper for the DNA gallery labs: drops a small subdivided PlaneMesh
## under the rendered organism and applies the living_ground shader,
## seeded with a presence texture appropriate to the organism's
## kingdom. Result: every gallery shot stands on kingdom-context
## ground (flowers on grass, fungus on mossy log, trees on soil,
## critters on packed earth) instead of floating in grey void.
##
## Doubles as a diagnostic for the "black rectangle in VR" issue
## (see commons/managers/NatureRenderer.gd:295). If a single PNG
## render in headless mode shows the ground correctly, the shader
## itself is fine and the VR-only failure is in lighting or scale.
##
## Usage:
##   GroundPatch.attach(parent_node, "tree", Vector2(2.0, 2.0))
##   GroundPatch.attach(parent_node, "fungus", Vector2(1.5, 1.5))
##
## Kingdoms: "tree" / "creature" / "flower" / "fungus" / "alien"
## Mixed presence is also supported via attach_mixed().

const SHADER_PATH := "res://algorithms/nature_system/shaders/living_ground.gdshader"
const GROUND_TYPES_PATH := "res://commons/biome_layers/ground_types.json"
const PRESENCE_TEX_SIZE: int = 64  # Smaller than NatureRenderer's 128, plenty for a small patch.

# Cached ground type catalog — loaded lazily on first attach_type call.
static var _ground_types_cache: Dictionary = {}


## Load and return the ground types catalog (commons/biome_layers/
## ground_types.json). Cached after first call.
static func get_ground_types() -> Dictionary:
	if not _ground_types_cache.is_empty():
		return _ground_types_cache
	var f := FileAccess.open(GROUND_TYPES_PATH, FileAccess.READ)
	if f == null:
		push_warning("[GroundPatch] catalog missing: %s" % GROUND_TYPES_PATH)
		return {}
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_warning("[GroundPatch] catalog bad JSON")
		return {}
	_ground_types_cache = (parsed as Dictionary).get("types", {})
	return _ground_types_cache


## Attach a ground patch using a TYPE from the catalog (soil, moss,
## stone, sand, snow, ash, wood, void). Optional `presence` dict
## adds kingdom signatures on top of the base type material.
##
## Examples:
##   GroundPatch.attach_type(parent, "moss", Vector2(2, 2))
##   GroundPatch.attach_type(parent, "ash", Vector2(2, 2),
##       {"fungus": 0.6})  # ash with mycelium colonising it
static func attach_type(parent: Node3D, type_id: String,
		size: Vector2 = Vector2(2.0, 2.0),
		presence: Dictionary = {}) -> MeshInstance3D:
	var catalog := get_ground_types()
	var type_def: Dictionary = catalog.get(type_id, {})
	if type_def.is_empty():
		push_warning("[GroundPatch] unknown type '%s' — falling back to soil"
			% type_id)
		type_def = catalog.get("soil", {})

	var mi := MeshInstance3D.new()
	mi.name = "GroundPatch_%s" % type_id
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = 32
	plane.subdivide_depth = 32
	mi.mesh = plane

	var mat := _make_material_from_type(type_def, presence, size)
	mi.material_override = mat
	mi.position = Vector3(0.0, -0.01, 0.0)
	parent.add_child(mi)
	return mi


static func _make_material_from_type(type_def: Dictionary,
		presence: Dictionary, size: Vector2) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	var shader: Shader = null
	if ResourceLoader.exists(SHADER_PATH):
		shader = load(SHADER_PATH)
	if shader == null:
		return mat
	mat.shader = shader

	var tex := _build_presence_texture(presence)
	mat.set_shader_parameter("presence_map", tex)
	mat.set_shader_parameter("world_size", size)
	mat.set_shader_parameter("world_offset", Vector2.ZERO)

	# Apply per-type material params from the catalog. RGB triples are
	# stored as JSON arrays, so convert to Color.
	var warm_arr: Array = type_def.get("base_color_warm",
		[0.28, 0.22, 0.15])
	var cool_arr: Array = type_def.get("base_color_cool",
		[0.18, 0.20, 0.16])
	mat.set_shader_parameter("base_color_warm",
		Color(float(warm_arr[0]), float(warm_arr[1]), float(warm_arr[2])))
	mat.set_shader_parameter("base_color_cool",
		Color(float(cool_arr[0]), float(cool_arr[1]), float(cool_arr[2])))
	mat.set_shader_parameter("displacement_strength",
		float(type_def.get("displacement_strength", 0.04)))
	mat.set_shader_parameter("base_texture_scale",
		float(type_def.get("base_texture_scale", 8.0)))

	return mat



## Attach a ground patch under `parent` for the given kingdom.
## Returns the MeshInstance3D so the caller can position it.
static func attach(parent: Node3D, kingdom: String,
		size: Vector2 = Vector2(2.0, 2.0)) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "GroundPatch_%s" % kingdom

	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = 32
	plane.subdivide_depth = 32
	mi.mesh = plane

	var mat := _make_material(kingdom, size)
	mi.material_override = mat

	# Position slightly below world origin so the organism sits ON it.
	mi.position = Vector3(0.0, -0.01, 0.0)

	parent.add_child(mi)
	return mi


## Attach a ground patch with mixed kingdom presence (RGBA channels).
## values: { "tree": 0..1, "creature": 0..1, "flower": 0..1, "fungus": 0..1 }
static func attach_mixed(parent: Node3D, presence: Dictionary,
		size: Vector2 = Vector2(2.0, 2.0)) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "GroundPatch_mixed"
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = 32
	plane.subdivide_depth = 32
	mi.mesh = plane

	var mat := _make_material_mixed(presence, size)
	mi.material_override = mat
	mi.position = Vector3(0.0, -0.01, 0.0)
	parent.add_child(mi)
	return mi


# ─────────────────────────────────────────────────────────────────────
# Material construction
# ─────────────────────────────────────────────────────────────────────

static func _make_material(kingdom: String, size: Vector2) -> ShaderMaterial:
	var presence := _kingdom_to_presence(kingdom)
	return _make_material_mixed(presence, size)


static func _make_material_mixed(presence: Dictionary, size: Vector2) -> ShaderMaterial:
	var mat := ShaderMaterial.new()

	# Load shader (shared resource — first call caches it).
	var shader: Shader = null
	if ResourceLoader.exists(SHADER_PATH):
		shader = load(SHADER_PATH)
	if shader == null:
		push_warning("[GroundPatch] shader not found: %s" % SHADER_PATH)
		return mat
	mat.shader = shader

	# Build a presence texture that paints the organism's kingdom into
	# the centre of the patch with quadratic falloff toward the edges.
	# Result: ground reads strong-kingdom under the organism, fades to
	# neutral earth at the patch edge.
	var tex := _build_presence_texture(presence)
	mat.set_shader_parameter("presence_map", tex)
	mat.set_shader_parameter("world_size", size)
	mat.set_shader_parameter("world_offset", Vector2.ZERO)
	# Restrained displacement for gallery scale (organism is ~0.5m tall).
	mat.set_shader_parameter("displacement_strength", 0.04)
	mat.set_shader_parameter("base_texture_scale", 8.0)

	# Override base earth colours per dominant kingdom so the gallery
	# patch reads as kingdom-context immediately, even where the
	# presence falls off. The shader's kingdom-specific tints
	# (moss / pollen / mycelium) then LAYER on top of this base —
	# preserving the noise / sparkle / vein patterns that make the
	# ground feel alive.
	var base_warm: Color
	var base_cool: Color
	var dominant: String = _dominant_kingdom(presence)
	match dominant:
		"tree":
			base_warm = Color(0.18, 0.30, 0.10)   # mossy ground
			base_cool = Color(0.12, 0.22, 0.10)
		"creature":
			base_warm = Color(0.36, 0.28, 0.18)   # packed dusty earth
			base_cool = Color(0.30, 0.24, 0.16)
		"flower":
			base_warm = Color(0.32, 0.28, 0.18)   # meadow soil with pollen
			base_cool = Color(0.24, 0.26, 0.14)
		"fungus":
			base_warm = Color(0.20, 0.13, 0.18)   # rotting wood / dark organic
			base_cool = Color(0.14, 0.10, 0.16)
		"alien":
			base_warm = Color(0.18, 0.10, 0.22)   # alien iridescent
			base_cool = Color(0.10, 0.12, 0.20)
		_:
			base_warm = Color(0.28, 0.22, 0.15)   # neutral warm earth (shader default)
			base_cool = Color(0.18, 0.20, 0.16)
	mat.set_shader_parameter("base_color_warm", base_warm)
	mat.set_shader_parameter("base_color_cool", base_cool)

	return mat


## Pick the kingdom with the strongest presence to drive base colour.
static func _dominant_kingdom(presence: Dictionary) -> String:
	# Treat "alien" as a special composite — flag when both fungus + flower
	# are high simultaneously.
	var fungus: float = float(presence.get("fungus", 0.0))
	var flower: float = float(presence.get("flower", 0.0))
	var tree:   float = float(presence.get("tree", 0.0))
	var creature: float = float(presence.get("creature", 0.0))
	if fungus > 0.5 and flower > 0.5:
		return "alien"
	var max_v: float = 0.0
	var max_k: String = ""
	for k in ["tree", "creature", "flower", "fungus"]:
		var v: float = float(presence.get(k, 0.0))
		if v > max_v:
			max_v = v
			max_k = k
	return max_k


static func _kingdom_to_presence(kingdom: String) -> Dictionary:
	# Single-kingdom presets — map gallery kingdom names onto the
	# living_ground shader's RGBA channels.
	# Note: living_ground reads R=tree, G=creature, B=flower, A=fungus.
	# Values pushed close to 1.0 because the shader's tree / creature /
	# fungus colour blends are intentionally subtle ("not gaudy") —
	# strong presence at the centre is needed for the kingdom signature
	# to read clearly in a small gallery patch. Flower's bright sparkle
	# branch reads at lower values; kept here for visual balance.
	match kingdom:
		"tree":     return {"tree": 1.0, "flower": 0.15}                 # moss + bit of pollen
		"creature": return {"creature": 0.9, "tree": 0.3}                # trail through grass
		"flower":   return {"flower": 0.85, "tree": 0.45}                # meadow
		"fungus":   return {"fungus": 1.0, "tree": 0.35}                 # mycelium on moss
		"alien":    return {"fungus": 0.85, "flower": 0.65, "tree": 0.2} # iridescent
		_:          return {}                                             # pure earth


## Build a 64×64 RGBA8 texture with quadratic-falloff presence centred
## in the texture. Each kingdom's strength fills its channel.
static func _build_presence_texture(presence: Dictionary) -> ImageTexture:
	var img := Image.create(
		PRESENCE_TEX_SIZE, PRESENCE_TEX_SIZE, false, Image.FORMAT_RGBA8
	)
	var tree:     float = float(presence.get("tree", 0.0))
	var creature: float = float(presence.get("creature", 0.0))
	var flower:   float = float(presence.get("flower", 0.0))
	var fungus:   float = float(presence.get("fungus", 0.0))

	var center := PRESENCE_TEX_SIZE * 0.5
	var max_d_sq: float = center * center
	for y in PRESENCE_TEX_SIZE:
		for x in PRESENCE_TEX_SIZE:
			# Distance from centre, normalised 0..1.
			var dx: float = float(x) - center
			var dy: float = float(y) - center
			var t: float = clampf(1.0 - (dx * dx + dy * dy) / max_d_sq, 0.0, 1.0)
			# Quadratic falloff (smoother than linear).
			t = t * t
			img.set_pixel(x, y, Color(
				tree * t,
				creature * t,
				flower * t,
				fungus * t
			))
	return ImageTexture.create_from_image(img)

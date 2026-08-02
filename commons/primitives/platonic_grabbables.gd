extends Node3D

# @identity
# essence: the DNA head over the table of five platonic solids — a thin root that restates all seventy-five grabbable bodies in one of three states of showing, touching nothing but material_override
# desire: to let the canonical claim that form can be perfect be MET three ways, so a learner picking up a dodecahedron can ask whether its perfection is in the volume or in the edge count
# critical_parameter: facture — which state of showing every solid on the table is in; every position, scale, colour, collider and pickable setting in platonic_grabbables.tscn is the legacy scene and is never written to
# triggers: _ready() reads facture, returns immediately on the default, and otherwise walks the tree setting material_override on each MeshInstance3D — skipping the XR highlight rings, which are an affordance and not a picture
# emerges: the five regular solids as three different arguments — a set of coloured volumes, a set of edge graphs, a set of plates in a treatise — and the recognition that "there are exactly five" is a fact about the edge graphs, not about the volumes
# needs: the seventy-five authored grab_* instances [present]; SimpleGrid's show_interior uniform [present]; a base colour per solid [present, read from each pickable's base_color export]
# relationships: the perfect half of the primitives tier — [[capsule]] is the claim that form cannot be perfect, this is the claim that it can; shares the facture vocabulary with [[capsule]], [[folded_strip]] and [[triangleprofiles]]
# truth: antiquity thought the five regular solids were the elements themselves. There are exactly five and no more are possible — a scarcity built into space, and one you can only see once the volumes are taken away and the edges left.

## AXIS — WHAT STATE OF SHOWING THE WHOLE TABLE IS IN. The set never changes: the same five
## solids, the same fifteen copies each, the same colours, sizes, positions and colliders.
## What changes is what the seventy-five bodies are shown AS. A platonic solid is the
## canonical claim that form can be perfect, and the claim lands differently depending on
## whether you are shown a volume or the edge graph that proves the volume is possible.
##
##   plate     the treatise plate — the solid drawn AND its edges drawn over it, fill and
##             wireframe at once. This is the legacy scene, byte for byte.
##   cast      poured — matte volumes in their own colours, no edges at all. Five kinds of
##             coloured stone; the regularity is something you have to take on trust.
##   armature  wired — the fill gone entirely, only the glowing edge graph standing in
##             space. Plato's proof made visible: it is the edges and vertices that can
##             only close five ways, and with the volumes removed you are looking at the
##             actual argument rather than at its result.
##
## APPEARANCE ONLY, deliberately and without exception. Every solid here is an
## XRToolsPickable the learner picks up. Nothing in this file touches a collision shape, a
## layer, a mask, a mass, a snap point or a grab signal; the only property written is
## MeshInstance3D.material_override, which outranks the surface override that
## grab_tetrahedron restores on drop, so the variant survives a pick-up-and-drop unchanged.
## The XR highlight rings are skipped outright — they are an affordance, not a picture.
@export var facture: String = "plate"
const FACTURES: PackedStringArray = ["plate", "cast", "armature"]

const GRID_SHADER_PATH := "res://commons/resourses/shaders/SimpleGrid.gdshader"
## Used only where a solid exposes no base_color of its own (grab_cube bakes its colour
## into a scene sub-resource); the real colour is then read back off that material.
const FALLBACK_BASE := Color(0.55, 0.57, 0.62, 1.0)


func _ready() -> void:
	var f: String = str(facture).strip_edges().to_lower()
	facture = f if FACTURES.has(f) else "plate"

	# THE LEGACY PATH. "plate" is the table exactly as authored — no walk, no material, no
	# node touched. Nothing below runs. That is the whole of the additive guarantee.
	if facture == "plate":
		return

	_restyle(self, FALLBACK_BASE)


# ── FACTURE ──────────────────────────────────────────────────────────────────

## Walks the table carrying each solid's own colour down to its mesh. The colour is read
## from the pickable's `base_color` export where it has one, so a red tetrahedron stays
## red and a green dodecahedron stays green under every value — the axis is about what is
## shown, never about which colour.
func _restyle(node: Node, inherited: Color) -> void:
	# The XR highlight ring is an affordance the hands need, not part of the picture.
	if node != self and str(node.name).begins_with("Highlight"):
		return

	var base: Color = inherited
	var bc = node.get("base_color")
	if bc is Color:
		base = bc

	if node is MeshInstance3D:
		_apply(node as MeshInstance3D, base)

	for c in node.get_children():
		_restyle(c, base)


func _apply(mi: MeshInstance3D, base: Color) -> void:
	var active: Material = null
	if mi.mesh != null and mi.mesh.get_surface_count() > 0:
		active = mi.get_active_material(0)

	var solid: Color = Color(base.r, base.g, base.b, 1.0)
	# grab_cube carries no base_color export — its colour lives in a baked SimpleGrid
	# material, so read it back rather than painting the cube the fallback grey.
	if active is ShaderMaterial:
		var mc = (active as ShaderMaterial).get_shader_parameter("modelColor")
		if mc is Color and base == FALLBACK_BASE:
			solid = Color(mc.r, mc.g, mc.b, 1.0)

	match facture:
		"cast":
			var m := StandardMaterial3D.new()
			m.albedo_color = solid
			m.roughness = 0.55
			m.metallic = 0.0
			mi.material_override = m
		"armature":
			var sm: ShaderMaterial = null
			if active is ShaderMaterial:
				sm = (active as ShaderMaterial).duplicate() as ShaderMaterial
			else:
				var sh: Shader = load(GRID_SHADER_PATH)
				if sh == null:
					return
				sm = ShaderMaterial.new()
				sm.shader = sh
				sm.set_shader_parameter("modelColor", solid)
			# show_interior=false makes the fill fully transparent and leaves the
			# wireframe; the fill is not hidden by visibility, so nothing propagates to a
			# child and no subtree disappears with it.
			sm.set_shader_parameter("show_interior", false)
			sm.set_shader_parameter("wireframeColor", solid.lightened(0.30))
			sm.set_shader_parameter("emissionColor", solid.lightened(0.30))
			sm.set_shader_parameter("wireframeOpacity", 1.0)
			sm.set_shader_parameter("width", 2.6)
			sm.set_shader_parameter("emission_strength", 3.2)
			mi.material_override = sm
		_:
			pass

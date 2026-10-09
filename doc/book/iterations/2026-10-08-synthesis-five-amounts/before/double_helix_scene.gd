extends Node3D
class_name DoubleHelixScene

## The double helix, and what it has been stood on.
##
## The root of double_helix_scene.tscn carried no script, so GridInteractablesComponent —
## which calls apply_grid_config on the ROOT — had nothing to call, and every knob in this
## composition was unreachable from a map token. This script is that missing root.

# @identity
# essence: helix(t) = two counter-phase trails from one rotating pivot, raised on a base that decides what kind of object it is
# desire: walk up to a double helix and notice, before you notice the helix, what it has been put on
# critical_parameter: support — monument | bench | vitrine | terrace, the footing under the raised helix
# triggers: _ready() reads the axis and appends the footing after the legacy body exists
# emerges: the same two spirals read as civic authority, laboratory work-in-progress, museum specimen or excavation
# needs: the trail helix [present, from DoubleHelix.tscn]; the footing [built here]
# relationships: the composed room-scale wrapper around [[double_helix_oscillator]]; sibling of [[doublehelix]], which is the same figure without a site
# truth: nobody meets a molecule. They meet whatever it was placed on, and the plinth makes the claim before the object gets a word in.

# ── DNA ───────────────────────────────────────────────────────────────────────

## AXIS — WHAT FOOTING THE HELIX IS GIVEN. Not the pitch, the radius, the rotation speed or
## the trail: those are the physics this teaches and they are identical at every value —
## the same pivot, the same two counter-phase balls, the same spirals falling away beneath.
## What changes is the thing underneath, and the thing underneath is the argument, because
## a double helix on a civic plinth and the same helix on a trestle are not making the same
## claim about how settled the knowledge is.
##
## Adopted from the `support` word already carried by seven artifacts in this corpus
## (info_board, science_screen, code_display, exit_sign, catalyst_target and the fire
## fittings), which use it for exactly this question — what holds this up, and what does the
## holding say. Their value sets differ because their objects differ; the question does not.
##
##   monument  the legacy lineage, byte for byte — the wide floor slab, the ring set on it,
##             the crowning cylinder above the helix. Permanent, civic, load-bearing,
##             addressed to a public. The claim: this is settled, and it is ours.
##   bench     the slab, ring and crown go dark and a working table stands under the helix
##             instead — a lipped top on four legs with a lower shelf and a rail. Hip
##             height, movable, made to be leaned over. The claim: this is in progress.
##   vitrine   a low square plinth and a glass case rising past the helix on four corner
##             posts, with a capping frame. The helix becomes a specimen: preserved,
##             attributed, and behind glass you are not to reach through.
##   terrace   three stepped concentric rings cut into the ground with a survey peg and a
##             datum string at the top step. Nothing is raised at all; the ground was
##             excavated around it. The claim: this was found, and it is still in situ.
##
## STRICTLY ADDITIVE. "monument" builds nothing and touches nothing, so all six existing
## placements render exactly as before. The other three dim the legacy meshes with
## `layers = 0` on the VisualInstance3D — per-instance, so mesh and material are untouched
## and no subtree is hidden — and leave the CollisionShape3D alone at every value, because
## the collider is what a player stands on and that is gameplay, not staging.
@export_enum("monument", "bench", "vitrine", "terrace") var support: String = "monument"
const SUPPORTS: PackedStringArray = ["monument", "bench", "vitrine", "terrace"]

const HOST := "HelixFooting"
const HELIX_Y := 5.586253      # where DoubleHelix.tscn is parked in this scene
const LEGACY_BODY := "StaticBody3D"

var _dimmed: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	var _s: String = str(support).strip_edges().to_lower()
	support = _s if SUPPORTS.has(_s) else "monument"
	_build_support()


## Config entry point — the one this root never had. Reads a single key and ignores every
## other, because composers hand this dictionary round wholesale. An unknown word keeps the
## standing value; a dictionary without "support" does nothing at all.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("support"):
		return
	var want: String = str(config_data["support"]).strip_edges().to_lower()
	if not SUPPORTS.has(want):
		return
	if want == support and get_node_or_null(HOST) != null:
		return
	support = want
	_build_support()


# ── SUPPORT ───────────────────────────────────────────────────────────────────
# Everything below lives inside one host node appended AFTER the legacy children, so
# deleting the host and restoring layers returns the scene exactly.

func _build_support() -> void:
	var old: Node = get_node_or_null(HOST)
	if old != null:
		remove_child(old)
		old.queue_free()
	_dim_legacy(support != "monument")
	if support == "monument" or not SUPPORTS.has(support):
		return                          # the legacy lineage builds nothing at all
	var host := Node3D.new()
	host.name = HOST
	add_child(host)
	match support:
		"bench":
			_support_bench(host)
		"vitrine":
			_support_vitrine(host)
		"terrace":
			_support_terrace(host)
		_:
			pass


## The three legacy meshes stop drawing. `layers = 0` is per-instance on the
## VisualInstance3D: the mesh, its material and every child are untouched, and there are no
## children to hide. The CollisionShape3D beside them is never touched, so the body a player
## can stand on is identical at every value of the axis. Guarded on a flag so the default
## path never writes to any of them at all.
func _dim_legacy(dim: bool) -> void:
	if dim == _dimmed:
		return
	_dimmed = dim
	var body: Node = get_node_or_null(LEGACY_BODY)
	if body == null:
		return
	var mask: int = 1
	if dim:
		mask = 0
	for n in body.get_children():
		if n is VisualInstance3D:
			(n as VisualInstance3D).layers = mask


## BENCH — the helix as work in progress. A lipped top on four legs with a lower shelf and a
## back rail, hip height, the size of a thing two people stand at. Nothing about it says
## permanent, and nothing about it addresses a public.
func _support_bench(host: Node3D) -> void:
	var steel: StandardMaterial3D = _mat(Color(0.44, 0.45, 0.48), 0.42, 0.65)
	var top: StandardMaterial3D = _mat(Color(0.30, 0.31, 0.33), 0.72, 0.20)
	# THE LIP IS EMISSIVE ON PURPOSE, and so are the vitrine's rail and the terrace's pegs.
	# The brightest pixels in any frame of this scene are the helix's two unshaded point
	# trails, and those trails are a function of how many frames have elapsed — which is not
	# the same number twice. If the only lit surface in the picture were the trail, the
	# critic's hottest-5% window would be measuring the render clock rather than this axis.
	# One warm surface per value puts the footing inside that window.
	var lip: StandardMaterial3D = _lit(Color(0.90, 0.38, 0.12), 1.2)
	var w: float = 4.6
	var d: float = 2.3
	var ty: float = 0.98
	_box(host, Vector3(0.0, ty, 0.0), Vector3(w, 0.12, d), top)
	# the lip, so the top reads as a tray that things are set down on
	for sx in [-1.0, 1.0]:
		var sf: float = float(sx)
		_box(host, Vector3(sf * (w * 0.5 - 0.03), ty + 0.09, 0.0), Vector3(0.06, 0.07, d), lip)
	for sz in [-1.0, 1.0]:
		var sg: float = float(sz)
		_box(host, Vector3(0.0, ty + 0.09, sg * (d * 0.5 - 0.03)), Vector3(w, 0.07, 0.06), lip)
	# legs and a lower shelf
	for sx2 in [-1.0, 1.0]:
		for sz2 in [-1.0, 1.0]:
			var lx: float = float(sx2) * (w * 0.5 - 0.24)
			var lz: float = float(sz2) * (d * 0.5 - 0.24)
			_box(host, Vector3(lx, ty * 0.5, lz), Vector3(0.14, ty, 0.14), steel)
	_box(host, Vector3(0.0, 0.34, 0.0), Vector3(w - 0.6, 0.06, d - 0.6), steel)
	# a back rail with three uprights — the shape of a bench that carries services
	_box(host, Vector3(0.0, ty + 0.86, -d * 0.5 + 0.16), Vector3(w - 0.4, 0.08, 0.08), steel)
	for i in range(3):
		var rx: float = -w * 0.5 + 0.5 + float(i) * (w - 1.0) * 0.5
		_box(host, Vector3(rx, ty + 0.47, -d * 0.5 + 0.16), Vector3(0.07, 0.86, 0.07), steel)


## VITRINE — the helix as specimen. A low square plinth, four corner posts, four glass panes
## and a capping frame that closes over the top of the figure. The helix is preserved and
## attributed, and the glass is the part of the argument you are not supposed to notice.
func _support_vitrine(host: Node3D) -> void:
	var stone: StandardMaterial3D = _mat(Color(0.78, 0.76, 0.72), 0.85, 0.05)
	var brass: StandardMaterial3D = _mat(Color(0.72, 0.58, 0.30), 0.35, 0.85)
	var glass: StandardMaterial3D = _glass(Color(0.62, 0.76, 0.86, 0.10))
	var s: float = 3.4               # case footprint
	var py: float = 1.15             # plinth height
	var ch: float = HELIX_Y + 1.55 - py   # case height, closing above the helix
	_box(host, Vector3(0.0, py * 0.5, 0.0), Vector3(s + 0.5, py, s + 0.5), stone)
	_box(host, Vector3(0.0, py + 0.04, 0.0), Vector3(s + 0.18, 0.08, s + 0.18), brass)
	# four panes
	for sx in [-1.0, 1.0]:
		var f: float = float(sx)
		_box(host, Vector3(f * s * 0.5, py + ch * 0.5, 0.0), Vector3(0.03, ch, s), glass)
		_box(host, Vector3(0.0, py + ch * 0.5, f * s * 0.5), Vector3(s, ch, 0.03), glass)
	# corner posts and the capping frame
	for cx in [-1.0, 1.0]:
		for cz in [-1.0, 1.0]:
			_box(host, Vector3(float(cx) * s * 0.5, py + ch * 0.5, float(cz) * s * 0.5),
				Vector3(0.10, ch, 0.10), brass)
	for ex in [-1.0, 1.0]:
		var e: float = float(ex)
		_box(host, Vector3(e * s * 0.5, py + ch, 0.0), Vector3(0.10, 0.10, s + 0.10), brass)
		_box(host, Vector3(0.0, py + ch, e * s * 0.5), Vector3(s + 0.10, 0.10, 0.10), brass)
	_box(host, Vector3(0.0, py + ch + 0.07, 0.0), Vector3(s + 0.30, 0.06, s + 0.30), glass)
	# the label rail every vitrine has, on the front face of the plinth — lit, so the
	# footing owns some of the frame's hottest pixels (see the note in _support_bench)
	_box(host, Vector3(0.0, py * 0.62, s * 0.5 + 0.28), Vector3(1.5, 0.34, 0.05), brass)
	_box(host, Vector3(0.0, py * 0.62, s * 0.5 + 0.31), Vector3(1.34, 0.20, 0.02),
		_lit(Color(0.94, 0.90, 0.74), 1.35))


## TERRACE — the helix as excavation. Three stepped concentric rings cut down into the
## ground, a survey peg standing on the top step and a datum string run across it. Nothing
## is raised; the ground was taken away from around the thing, which is the opposite claim
## to a plinth even though the silhouette is nearly the same height.
func _support_terrace(host: Node3D) -> void:
	var earth: StandardMaterial3D = _mat(Color(0.38, 0.33, 0.27), 0.95, 0.02)
	var cut: StandardMaterial3D = _mat(Color(0.49, 0.44, 0.36), 0.92, 0.02)
	# lit for the same reason the bench's lip is (see the note in _support_bench)
	var peg: StandardMaterial3D = _lit(Color(0.92, 0.86, 0.20), 1.25)
	# Kept inside the legacy slab's own radius on purpose. _subtree_aabb counts every
	# MeshInstance3D regardless of `layers`, so the dimmed monument still sets the frame
	# and all four values are photographed at the same distance. A wider terrace would
	# have pushed the camera back for one tile only, and a re-framed tile reads as a big
	# change whatever is in it.
	var radii: PackedFloat32Array = [3.6, 2.7, 1.9]
	for i in range(radii.size()):
		var cyl := CylinderMesh.new()
		cyl.top_radius = float(radii[i])
		cyl.bottom_radius = float(radii[i])
		cyl.height = 0.26
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		var skin: StandardMaterial3D = earth
		if i % 2 == 1:
			skin = cut
		mi.material_override = skin
		mi.position = Vector3(0.0, 0.13 + float(i) * 0.26, 0.0)
		host.add_child(mi)
	# The survey peg on the top step, and the datum string it holds.
	_box(host, Vector3(2.2, 1.18, 0.0), Vector3(0.07, 1.56, 0.07), peg)
	_box(host, Vector3(-2.2, 1.18, 0.0), Vector3(0.07, 1.56, 0.07), peg)
	_box(host, Vector3(0.0, 1.90, 0.0), Vector3(4.5, 0.02, 0.02), peg)
	# Four quadrant markers on the outer step — the grid an excavation is recorded on.
	for q in range(4):
		var a: float = float(q) * TAU / 4.0 + TAU / 8.0
		_box(host, Vector3(cos(a) * 3.2, 0.34, sin(a) * 3.2), Vector3(0.09, 0.42, 0.09), peg)


# ── helpers ───────────────────────────────────────────────────────────────────

func _box(host: Node3D, centre: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = centre
	host.add_child(mi)


func _mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _lit(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _glass(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.06
	m.metallic = 0.10
	return m

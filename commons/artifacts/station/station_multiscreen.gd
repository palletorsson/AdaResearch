extends Node3D
class_name StationMultiscreen

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the GRID-MODULAR wall-mounted MULTISCREEN of a curation station — a panel_w x panel_h painted-metal frame divided into an R x C lattice of small 2D-in-3D readout cells, each its own captioned face, behind one shared bezel and header strip. Mounts flat on a [[station_wall]] section (front face +Z); origin at the panel centre so it seats on the wall at the placed height.
# desire: to show that several faces are one idea — the panel that holds a convergence; where one station_panel shows a single headline, this shows the four views / the before-after-and-between / the whole family of readings at once, side by side, so a viewer reads them as a single argument with many windows.
# critical_parameter: rows x cols + cell_labels — how many windows the convergence is cut into and what each says; header titles the whole lattice. panel_w/panel_h size the frame to land on the wall grid beside the mullions.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds with new rows/cols/labels.
# emerges: 1x2 = a before/after pair; 2x2 = the classic four-views convergence; 1xN = a filmstrip of stages; NxN = a contact sheet of a whole family. Each cell is a HangarKit.readout (2D-in-3D, never a billboard); the shared bezel + header make the many read as one.
# needs: a backing frame plate [present]; a recessed inner well [present]; a 2D-in-3D header strip [present]; an R x C grid of HangarKit.readout cells with margins [present]; thin mullion separators between cells [present]; an emissive accent line under the header [optional].
# relationships: the many-at-once sibling of [[station_panel]] (which shows ONE face — this shows a lattice); mounts on [[station_wall]] like the panel; uses the same BakedTextAlbedo plates as the [[station_plinth]] captions; placed on the backing wall by [[curation_station]].
# truth: a convergence is several faces of one idea held in a single frame. To divide a surface into windows and caption each is to argue that the parts cohere — the bezel says "these belong together", the grid says "and yet they are distinct".

@export_group("Grid")
## Number of cell rows (top to bottom).
@export var rows: int = 2
## Number of cell columns (left to right).
@export var cols: int = 2

@export_group("Dimensions")
## Overall panel width in metres (the framed lattice spans this on the wall).
@export var panel_w: float = 2.0
## Overall panel height in metres.
@export var panel_h: float = 1.2

@export_group("Content")
## Title for the whole lattice, shown on the header strip across the top.
@export var header: String = "CONVERGENCE"
## One caption per cell, ROW-MAJOR (left-to-right, top-to-bottom). Short strings.
@export var cell_labels: Array = ["VIEW 1", "VIEW 2", "VIEW 3", "VIEW 4"]
## Black text on a matte off-white cell face (the printed-label reading).
@export var text_color: Color = Color(0.10, 0.10, 0.12)

@export_group("Surface")
## A slim emissive accent line just under the header strip (front face).
@export var accent_line: bool = true
## Thin mullion bars drawn between the cells (the lattice rails).
@export var mullions: bool = true

@export_group("Color")
@export var frame_color: Color = Color(0.74, 0.72, 0.68)
@export var well_color: Color = Color(0.62, 0.60, 0.56)
@export var cell_color: Color = Color(0.88, 0.86, 0.80)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)
@export var wear: float = 0.07

const FRAME_T := 0.06        # outer frame border thickness (all sides)
const DEPTH := 0.08          # panel body depth (Z)
const HEADER_FRAC := 0.16    # fraction of panel height the header strip claims
const CELL_GAP := 0.04       # gap between adjacent cells
const MULLION_T := 0.015     # mullion bar half-thickness footprint on the face

var _built := false

func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_rows"): rows = int(str(get_meta("config_rows")))
	if has_meta("config_cols"): cols = int(str(get_meta("config_cols")))
	if has_meta("config_panel_w"): panel_w = float(str(get_meta("config_panel_w")))
	if has_meta("config_panel_h"): panel_h = float(str(get_meta("config_panel_h")))
	if has_meta("config_header"): header = str(get_meta("config_header"))
	if has_meta("config_cell_labels"):
		var raw = get_meta("config_cell_labels")
		if raw is Array:
			cell_labels = []
			for ln in raw:
				cell_labels.append(str(ln))
		elif str(raw).strip_edges() != "":
			# tolerate a comma-separated string from the grid coercer
			cell_labels = []
			for ln in str(raw).split(","):
				cell_labels.append(str(ln).strip_edges())
	if has_meta("config_accent_line"): accent_line = _b(get_meta("config_accent_line"))
	if has_meta("config_mullions"): mullions = _b(get_meta("config_mullions"))
	if has_meta("config_text_color"): text_color = _pc(str(get_meta("config_text_color")), text_color)
	if has_meta("config_frame_color"): frame_color = _pc(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_well_color"): well_color = _pc(str(get_meta("config_well_color")), well_color)
	if has_meta("config_cell_color"): cell_color = _pc(str(get_meta("config_cell_color")), cell_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var r: int = maxi(rows, 1)
	var c: int = maxi(cols, 1)
	var w: float = maxf(panel_w, 0.4)
	var h: float = maxf(panel_h, 0.3)

	# Backing frame plate (light matte) — mounts flat on the wall, front face toward +Z.
	add_child(_box(Vector3(0, 0, 0), Vector3(w, h, DEPTH), HangarKit.rams_body(frame_color, wear)))

	# Recessed inner well behind the cells — a slightly darker, slightly proud plate so the lattice
	# reads as set INTO the frame, not pasted on.
	var well_w: float = w - FRAME_T * 2.0
	var well_h: float = h - FRAME_T * 2.0
	var well_z: float = DEPTH * 0.5
	add_child(_box(Vector3(0, 0, well_z), Vector3(well_w, well_h, 0.02), HangarKit.rams_body(well_color, wear + 0.02)))

	var face_z: float = well_z + 0.02

	# Header strip across the top of the well (titles the whole lattice).
	var header_h: float = well_h * HEADER_FRAC
	var header_cy: float = well_h * 0.5 - header_h * 0.5
	if header.strip_edges() != "":
		var head: MeshInstance3D = BakedText.make_label_mesh(header.to_upper(), accent_color.darkened(0.55),
			Vector2(minf(well_w * 0.9, w), header_h * 0.62), 1400, true)
		if head:
			head.position = Vector3(0, header_cy, face_z + 0.004)
			add_child(head)
	if accent_line:
		add_child(_box(Vector3(0, header_cy - header_h * 0.5 - 0.006, face_z),
			Vector3(well_w * 0.98, 0.018, 0.014), _emi(accent_color, 0.7)))

	# The cell grid fills the well BELOW the header strip.
	var grid_top: float = header_cy - header_h * 0.5 - CELL_GAP
	var grid_bottom: float = -well_h * 0.5 + CELL_GAP * 0.5
	var grid_h: float = maxf(grid_top - grid_bottom, 0.05)
	var grid_left: float = -well_w * 0.5 + CELL_GAP * 0.5
	var grid_right: float = well_w * 0.5 - CELL_GAP * 0.5
	var grid_w: float = maxf(grid_right - grid_left, 0.05)

	# Per-cell OUTER extent (the slot each readout must fit inside, with gaps between).
	var slot_w: float = (grid_w - CELL_GAP * float(c - 1)) / float(c)
	var slot_h: float = (grid_h - CELL_GAP * float(r - 1)) / float(r)
	slot_w = maxf(slot_w, 0.06)
	slot_h = maxf(slot_h, 0.06)

	# readout() grows its bezel OUTSIDE the requested face size by ft = max(face_w, face_h) * 0.06 per
	# side. Back the requested face out of the slot so the WHOLE framed cell (face + bezel) fits the slot.
	# Solve face = slot - 2*ft with ft = max(face_w, face_h)*0.06 ≈ max(slot_w, slot_h)*0.06.
	var ft_guess: float = maxf(slot_w, slot_h) * 0.06
	var face_w: float = maxf(slot_w - ft_guess * 2.0, 0.05)
	var face_h: float = maxf(slot_h - ft_guess * 2.0, 0.04)

	var idx: int = 0
	for ri in range(r):
		for ci in range(c):
			var cx: float = grid_left + slot_w * 0.5 + float(ci) * (slot_w + CELL_GAP)
			var cy: float = grid_top - slot_h * 0.5 - float(ri) * (slot_h + CELL_GAP)
			var label: String = ""
			if idx < cell_labels.size():
				label = str(cell_labels[idx]).strip_edges()
			# Each cell = a HangarKit.readout (its own bezel + matte off-white face + the caption as a
			# single body line), so every window reads as a framed 2D-in-3D screen.
			var lines: Array = [label] if label != "" else []
			var cell: Node3D = HangarKit.readout("", lines, Vector2(face_w, face_h),
				cell_color, text_color, text_color)
			if cell:
				cell.position = Vector3(cx, cy, face_z)
				add_child(cell)
			idx += 1

	# Mullion rails between cells (thin emissive-free trim bars on the well face) — the lattice grid.
	if mullions:
		var rail_mat := HangarKit.worn_metal(frame_color)
		# vertical rails (between columns)
		for ci in range(1, c):
			var rx: float = grid_left + float(ci) * (slot_w + CELL_GAP) - CELL_GAP * 0.5
			add_child(_box(Vector3(rx, (grid_top + grid_bottom) * 0.5, face_z - 0.004),
				Vector3(MULLION_T, grid_h, 0.012), rail_mat))
		# horizontal rails (between rows)
		for ri in range(1, r):
			var ry: float = grid_top - float(ri) * (slot_h + CELL_GAP) + CELL_GAP * 0.5
			add_child(_box(Vector3((grid_left + grid_right) * 0.5, ry, face_z - 0.004),
				Vector3(grid_w, MULLION_T, 0.012), rail_mat))


func _emi(c: Color, energy: float) -> StandardMaterial3D:
	return HangarKit.emissive(c, energy)


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))

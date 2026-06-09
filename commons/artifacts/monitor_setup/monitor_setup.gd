extends Node3D
class_name MonitorSetup

# @identity
# essence: a CONFIGURABLE INFO BOARD — a clamp-pole rig of screens rising from a dark
#   metal desk with a vented tower + keyboard, where EACH screen has its own size,
#   position, angle and CONTENT (title + body + type). The default board tells a small
#   coherent story; an author swaps the content to tell their own. Blade Runner
#   street-vendor energy meets a briefing wall: some screens carry real readable text
#   (info — styled as a CRT TERMINAL: phosphor-green monospace on a near-black tube, with
#   a prompt header, faint scanlines and a blinking cursor), some keep the old neon-poster
#   look (poster), some show a procedural readout (data), and some render a glowing
#   POINT-CLOUD scatter drifting toward a bright central point (points). Cables drape
#   between the screens and the base.
# desire: a lab needs a corner that BROADCASTS A NARRATIVE — not a single nameplate
#   (info_screen does that) but a CLUSTER of competing, authorable signals. A wall where
#   the content is data, so a map/registry/delegate can pour a story into the rig.
# critical_parameter: the `screens` array — the rig is defined by what its screens SAY,
#   what TYPE each is, and how hard they glow (screen_emission). Swap the array, swap the
#   whole story; the rig vocabulary (desk/tower/keyboard/pole/cables) stays constant.
# triggers: _ready() builds the desk/tower/keyboard, the clamp-pole sized to span the
#   configured screens, and one panel per `screens` entry (info=Label3D terminal text,
#   poster=neon texture, data=graph texture, points=MultiMesh scatter field), plus draping
#   cables. _process() blinks the terminal cursors and drifts the point fields.
#   apply_grid_config() reads a whole `screens` array (CONTENT INPUT) + theme/scale/
#   screen_count and rebuilds.
# emerges: the room gains a watcher that can TELL. The player reads a sequence across the
#   panels — a small narrative staged in light. Mediated presence as an authorable stack.
# needs: a floor to stand on (origin at the desk base, rig grows +Y); a viewer roughly on
#   +Z to read the screens; emissive rendering on so the glow lands. An author to supply
#   `screens` content (else the default story shows).
# relationships: cousin to info_screen (one labeled screen vs. a configurable wall of
#   them); sibling to surreal_lab (dense sci-fi clusters); pairs with any briefing/booth map.
# truth: a single screen informs; a CONFIGURED STACK of screens narrates. This rig is the
#   structural form of the BRIEFING WALL — many panels, one story, poured in as data.

## A CONFIGURABLE INFO BOARD built as a cyberpunk screen-rig. A clamp-pole of panels
## rises from a desk with a vented tower + keyboard; EACH panel's size, position, angle
## and CONTENT (title + body + type) is data-driven via the `screens` array, so an author
## can make the board tell a story. Panel types: "info" (Label3D title+body, CRT-terminal
## styled when terminal_style is on), "poster" (procedural neon texture), "data" (procedural
## graph texture), "points" (glowing MultiMesh scatter field). Cables drape to the base.
##
## All procedural. Origin sits at the desk base; the rig grows upward in +Y and the
## panels face roughly +Z. Re-entrant: apply_grid_config() rebuilds from scratch.

# ── DNA: toggles ──────────────────────────────────────────────────────

@export_group("Toggles")
@export var show_cables: bool = true
@export var screen_glow: bool = true
## CRT TERMINAL aesthetic on info screens: near-black phosphor backing, monospace
## phosphor-green/amber/cyan text, a prompt-style header, faint scanlines and a blinking
## cursor. Turn OFF for the old flat-panel info look (light text on accent-tinted dark).
@export var terminal_style: bool = true
## SHADER-DRIVEN CRT GLASS: when on (and terminal_style is on), the info screen's tube
## face uses the crt_terminal.gdshader instead of the STATIC scanline texture — rolling
## scanlines, faint flicker, a phosphor bloom, vignette and edge aberration, all animated
## by the built-in TIME uniform so EVERY screen syncs automatically. The readable text
## stays as Label3D on top (capture-safe). Off → the original static-scanline look. If the
## shader file is missing it degrades silently to the static-scanline fallback.
@export var crt_shader: bool = true
## Master brightness/strength of the CRT glass shader (feeds its `intensity` uniform).
@export_range(0.0, 2.0) var crt_intensity: float = 1.0

@export_group("Glow")
@export_range(0.0, 4.0) var screen_emission: float = 1.3

@export_group("Board")
## Uniform scale applied to the whole rig (desk + pole + every screen offset/size).
@export_range(0.25, 4.0) var board_scale: float = 1.0
## Theme accent tint mixed lightly into bezels/metal; Color.BLACK = no tint.
@export var theme_color: Color = Color(0, 0, 0)

# ── The configurable screen board ─────────────────────────────────────
# Each entry is a Dictionary describing ONE screen:
#   {
#     "title":     String,            # big headline (info type), short
#     "body":      String,            # multi-line body; "\n"-separated lines
#     "type":      "info"|"poster"|"data"|"points",
#                                     # "info" = readable Label3D text (CRT terminal when
#                                     #   terminal_style is on); "poster" = neon texture;
#                                     # "data" = procedural graph; "points" = a glowing
#                                     #   POINT-CLOUD / scatter field (MultiMesh) drifting
#                                     #   toward a brighter central point — a data-viz panel
#                                     #   evoking the project's "point" reduction idea.
#     "size":      Vector2,           # panel face size in metres (w × h)
#     "pos":       Vector3,           # local offset on the rig (metres)
#     "angle_deg": float,             # yaw around Y
#     "pitch_deg": float,             # pitch around X
#     "color":     Color,             # accent / background theme for this panel
#     "mount":     "pole"|"base",     # clamp arm to the pole, or stand on the base
#     # ── markdown content sources (info screens) ──────────────────────
#     "md":        String,            # res:// path to a .md file. If set, the file's
#                                     #   first H1 (or first line) becomes the title and
#                                     #   the next meaningful lines, markdown-stripped to
#                                     #   plain log text, become the body. OVERRIDES
#                                     #   title/body (which still serve as fallback if the
#                                     #   file is missing). See _md_lines() / _md_title().
#     "lines":     int,               # body lines per screen (default 5). With "md" this
#                                     #   is ALSO the PAGE SIZE: how many cleaned body lines
#                                     #   one screen shows of the document.
#     "md_page":   int,               # PAGINATION (default 0). A screen with "md" shows the
#                                     #   document's cleaned body CHUNK for this page —
#                                     #   lines [md_page*lines : (md_page+1)*lines]. Point
#                                     #   several screens at the SAME "md" with md_page
#                                     #   0,1,2,… and the document CONTINUES across them.
#                                     #   Page 0 shows the real H1 title; pages > 0 show a
#                                     #   continuation header "<TITLE> · cont."; a page past
#                                     #   the end shows "<TITLE> · end" + "— end —".
#     "md_dir":    String,            # res:// dir to scan for *.md — builds a LOG FEED
#                                     #   body where each line is "<stem>: <first line>".
#     "md_count":  int,               # how many docs to roll into the md_dir log feed.
#   }
# Missing fields fall back to safe defaults (see _coerce_screen). "md" / "md_dir" are read
# at BUILD time so the board narrates the repo's own words; a missing file degrades to the
# title + "— no data —" rather than crashing.
#
# DEFAULT STORY — "THE BRIEFING WALL READS THE PROJECT": one real document,
# res://doc/ENTRY.md, CONTINUES across the four pole-mounted info screens. Each screen
# points at the SAME "md" with a different "md_page" (0,1,2,3) and shows that page's chunk
# of the document's markdown-stripped body — so the player's eye flows screen→screen and
# reads the doc straight through. Page 0 carries the doc's real title; later pages carry a
# "· cont." continuation header; a page past the end shows an "— end —" marker.
# The screens are laid out top→down / left→right so reading order matches page order:
#   md_page 0 → top-centre        md_page 1 → upper-left
#   md_page 2 → upper-right       md_page 3 → mid-left
# A POINT FIELD (points) scatter screen and a SECURITY-BREACH poster ride the base for
# variety, but the BOARD ITSELF IS THE DOCUMENT. Override the whole array via
# apply_grid_config() or the inspector to spread ANY res:// .md across ANY screens
# (set "md" + "md_page" 0,1,2,… and "lines" as the per-screen page size).
const DEFAULT_DOC: String = "res://doc/ENTRY.md"

# Monospace terminal font (JetBrains Mono) for the CRT look. Preloaded once; assigned to
# every Label3D when terminal_style is on. Falls back to the engine default if absent.
const MONO_FONT_PATH: String = "res://commons/font/JetBrainsMono-Medium.ttf"

# CRT terminal screen-glass shader. Loaded once at build (lazy, guarded by
# ResourceLoader.exists). When crt_shader is on the info tube face uses a ShaderMaterial
# built from this; when the file is missing the build degrades to the static-scanline look.
const CRT_SHADER_PATH: String = "res://commons/ui/shaders/crt_terminal.gdshader"
@export var screens: Array = [
	{
		# PAGE 0 — top-centre. The document's real H1 title + its first body chunk.
		"md": DEFAULT_DOC,
		"md_page": 0,
		"lines": 5,
		"title": "ENTRY",
		"body": "loading document…\nstand by",
		"type": "info",
		"size": Vector2(0.54, 0.36),
		"pos": Vector3(0.02, 1.86, 0.0),
		"angle_deg": 6.0,
		"pitch_deg": -10.0,
		"color": Color(0.05, 0.85, 0.95),
		"mount": "pole",
	},
	{
		# PAGE 1 — upper-left. Continuation: same doc, next chunk.
		"md": DEFAULT_DOC,
		"md_page": 1,
		"lines": 5,
		"title": "ENTRY",
		"body": "…continued",
		"type": "info",
		"size": Vector2(0.44, 0.34),
		"pos": Vector3(-0.4, 1.52, -0.02),
		"angle_deg": 26.0,
		"pitch_deg": -4.0,
		"color": Color(0.6, 0.95, 0.4),
		"mount": "pole",
	},
	{
		# PAGE 2 — upper-right. Continuation: same doc, next chunk.
		"md": DEFAULT_DOC,
		"md_page": 2,
		"lines": 5,
		"title": "ENTRY",
		"body": "…continued",
		"type": "info",
		"size": Vector2(0.44, 0.34),
		"pos": Vector3(0.4, 1.52, -0.02),
		"angle_deg": -24.0,
		"pitch_deg": -4.0,
		"color": Color(0.98, 0.7, 0.1),
		"mount": "pole",
	},
	{
		# PAGE 3 — mid-left. Continuation: same doc, next chunk.
		"md": DEFAULT_DOC,
		"md_page": 3,
		"lines": 5,
		"title": "ENTRY",
		"body": "…continued",
		"type": "info",
		"size": Vector2(0.5, 0.34),
		"pos": Vector3(-0.34, 1.16, 0.02),
		"angle_deg": 18.0,
		"pitch_deg": 2.0,
		"color": Color(0.55, 0.8, 1.0),
		"mount": "pole",
	},
	{
		# POINT FIELD — a glowing scatter drifting toward a brighter central point. Not part
		# of the document; a data-viz panel echoing the project's "point" reduction idea.
		"title": "POINT FIELD",
		"body": "reduction",
		"type": "points",
		"size": Vector2(0.46, 0.28),
		"pos": Vector3(0.4, 1.16, 0.06),
		"angle_deg": -16.0,
		"pitch_deg": 4.0,
		"color": Color(0.35, 1.0, 0.45),
		"mount": "base",
	},
	{
		"title": "SECURITY BREACH",
		"body": "INTRUDER — BLOCK 9\nlockdown engaged",
		"type": "poster",
		"size": Vector2(0.5, 0.32),
		"pos": Vector3(0.72, 1.17, 0.16),
		"angle_deg": -12.0,
		"pitch_deg": 4.0,
		"color": Color(0.95, 0.12, 0.1),
		"mount": "base",
	},
]

# ── Constants ─────────────────────────────────────────────────────────

const TEX_W: int = 256
const TEX_H: int = 180

const DESK_W: float = 1.4
const DESK_D: float = 0.7
const DESK_H: float = 0.08
const DESK_TOP_Y: float = 0.9          # desktop surface height

const POLE_RADIUS: float = 0.035
const POLE_MIN_TOP_Y: float = 2.0      # pole reaches at least ~2m
const POLE_X: float = -0.1
const POLE_Z: float = -0.18

const TEXT_PIXEL_SIZE: float = 0.0012  # Label3D world scale (mirrors info_screen)

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false
var _metal_mat: StandardMaterial3D
var _dark_mat: StandardMaterial3D
var _cable_mat: StandardMaterial3D

# Monospace terminal font, loaded once at build. null = file missing → engine default font
# (terminal colours still apply). See _ensure_mono_font().
var _mono_font: Font = null
var _mono_checked: bool = false

# CRT terminal screen-glass shader, loaded once at build. null = file missing → static
# scanline fallback. See _ensure_crt_shader().
var _crt_shader: Shader = null
var _crt_checked: bool = false

# ── Terminal animation state (driven by _process) ─────────────────────
# Blinking cursors: the bright block at the end of each terminal screen's last line. Toggled
# visible at ~1.5 Hz. Collected here so _process can blink them all cheaply.
var _cursors: Array = []          # Array[MeshInstance3D]
var _cursor_on: bool = true
var _blink_accum: float = 0.0
const BLINK_PERIOD: float = 0.66  # seconds per on/off phase (~1.5 Hz)

# Point-field MultiMeshes: one per "points" screen, with the base local layout cached so we
# can jitter a few points each frame without re-seeding the whole field.
# Each entry: { "mm": MultiMesh, "base": PackedVector3Array, "count": int, "rng_seed": int }
var _point_fields: Array = []
var _points_time: float = 0.0

# Parsed-markdown cache. Keyed by res:// path → a Dictionary:
#   { "title": String, "lines": PackedStringArray (all cleaned body lines) }
# Each .md is read + cleaned ONCE per build; every screen that paginates the same doc
# slices its page from this cache instead of re-reading the file. Cleared on rebuild.
var _md_cache: Dictionary = {}

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_build_all()


func _process(delta: float) -> void:
	# Cheap per-frame terminal life: blink the cursors and gently animate the point fields.
	# Both no-op when their arrays are empty (terminal_style off / no points screens).
	if not _cursors.is_empty():
		_blink_accum += delta
		if _blink_accum >= BLINK_PERIOD:
			_blink_accum -= BLINK_PERIOD
			_cursor_on = not _cursor_on
			for c in _cursors:
				if is_instance_valid(c):
					(c as MeshInstance3D).visible = _cursor_on
	if not _point_fields.is_empty():
		_points_time += delta
		_animate_point_fields()


func apply_grid_config(config_data: Dictionary) -> void:
	# CONTENT INPUT: an author / map / registry / delegate supplies the board here.
	_read_simple_overrides(config_data)
	_read_screens_override(config_data)
	if _built:
		_clear_built_children()
		_built = false
		_build_all()


func _read_simple_overrides(config_data: Dictionary) -> void:
	if config_data.has("show_cables"):
		show_cables = _to_bool(config_data["show_cables"], show_cables)
	if config_data.has("screen_glow"):
		screen_glow = _to_bool(config_data["screen_glow"], screen_glow)
	if config_data.has("screen_emission"):
		screen_emission = _to_float(config_data["screen_emission"], screen_emission)
	# "scale" is the documented author key; "board_scale" also accepted.
	if config_data.has("scale"):
		board_scale = _to_float(config_data["scale"], board_scale)
	if config_data.has("board_scale"):
		board_scale = _to_float(config_data["board_scale"], board_scale)
	if config_data.has("theme"):
		theme_color = _to_color(config_data["theme"], theme_color)
	if config_data.has("theme_color"):
		theme_color = _to_color(config_data["theme_color"], theme_color)


func _read_screens_override(config_data: Dictionary) -> void:
	# Whole-board content input. Accepts an Array of Dictionaries; each Dictionary is
	# coerced defensively so JSON-sourced data (Arrays for Vector2/Vector3) is handled.
	if config_data.has("screens"):
		var raw = config_data["screens"]
		if raw is Array and raw.size() > 0:
			var rebuilt: Array = []
			for entry in raw:
				if entry is Dictionary:
					rebuilt.append(_coerce_screen(entry))
			if rebuilt.size() > 0:
				screens = rebuilt
	# Optional truncation/padding to a requested count.
	if config_data.has("screen_count"):
		var want: int = int(_to_float(config_data["screen_count"], float(screens.size())))
		want = clampi(want, 0, screens.size())
		if want >= 0 and want < screens.size():
			screens = screens.slice(0, want)


# ── Defensive coercion helpers ────────────────────────────────────────

func _to_bool(value, fallback: bool) -> bool:
	if value is bool:
		return value
	var s: String = str(value).strip_edges().to_lower()
	if s == "true" or s == "1" or s == "yes" or s == "on":
		return true
	if s == "false" or s == "0" or s == "no" or s == "off":
		return false
	return fallback


func _to_float(value, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	var s: String = str(value).strip_edges()
	if s.is_valid_float():
		return s.to_float()
	return fallback


func _to_vec2(value, fallback: Vector2) -> Vector2:
	# Accept Vector2, or an Array/PackedArray of [w, h] (JSON path).
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(_to_float(value[0], fallback.x), _to_float(value[1], fallback.y))
	if value is PackedFloat32Array and value.size() >= 2:
		return Vector2(value[0], value[1])
	return fallback


func _to_vec3(value, fallback: Vector3) -> Vector3:
	# Accept Vector3, or an Array/PackedArray of [x, y, z] (JSON path).
	if value is Vector3:
		return value
	if value is Array and value.size() >= 3:
		return Vector3(
			_to_float(value[0], fallback.x),
			_to_float(value[1], fallback.y),
			_to_float(value[2], fallback.z))
	if value is PackedFloat32Array and value.size() >= 3:
		return Vector3(value[0], value[1], value[2])
	return fallback


func _to_color(value, fallback: Color) -> Color:
	# Accept Color, an Array [r,g,b(,a)], or a string "r,g,b" / "#rrggbb".
	if value is Color:
		return value
	if value is Array and value.size() >= 3:
		var a: float = 1.0
		if value.size() >= 4:
			a = _to_float(value[3], 1.0)
		return Color(
			_to_float(value[0], fallback.r),
			_to_float(value[1], fallback.g),
			_to_float(value[2], fallback.b), a)
	if value is String:
		var s: String = (value as String).strip_edges()
		if s.begins_with("#") and s.length() >= 7:
			return Color.html(s)
		var parts: PackedStringArray = s.split(",")
		if parts.size() >= 3:
			return Color(
				_to_float(parts[0], fallback.r),
				_to_float(parts[1], fallback.g),
				_to_float(parts[2], fallback.b))
	return fallback


func _coerce_screen(entry: Dictionary) -> Dictionary:
	# Build a fully-typed, fully-populated screen dict from a (possibly partial,
	# possibly JSON-shaped) author entry.
	var out: Dictionary = {}
	out["title"] = str(entry.get("title", ""))
	out["body"] = str(entry.get("body", ""))
	var t: String = str(entry.get("type", "info")).strip_edges().to_lower()
	if t != "poster" and t != "data" and t != "info" and t != "points":
		t = "info"
	out["type"] = t
	out["size"] = _to_vec2(entry.get("size", null), Vector2(0.45, 0.3))
	out["pos"] = _to_vec3(entry.get("pos", null), Vector3(0.0, 1.5, 0.0))
	out["angle_deg"] = _to_float(entry.get("angle_deg", 0.0), 0.0)
	out["pitch_deg"] = _to_float(entry.get("pitch_deg", 0.0), 0.0)
	out["color"] = _to_color(entry.get("color", null), Color(0.1, 0.8, 0.95))
	var m: String = str(entry.get("mount", "pole")).strip_edges().to_lower()
	if m != "base" and m != "pole":
		m = "pole"
	out["mount"] = m
	# Markdown content sources (carried through so apply_grid_config / inspector entries
	# keep them; resolved later at build time in _resolve_md_content).
	out["md"] = str(entry.get("md", ""))
	out["lines"] = int(_to_float(entry.get("lines", 5.0), 5.0))
	out["md_page"] = int(_to_float(entry.get("md_page", 0.0), 0.0))
	out["md_dir"] = str(entry.get("md_dir", ""))
	out["md_count"] = int(_to_float(entry.get("md_count", 4.0), 4.0))
	return out


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Markdown content sources ──────────────────────────────────────────
# An info screen can source its text from a real .md file ("md") or roll a whole
# directory of docs into a log feed ("md_dir"). Both are resolved at build time and
# OVERRIDE the hand-typed title/body, which remain as graceful fallbacks.

func _resolve_md_content(s: Dictionary) -> void:
	# Mutates s["title"]/s["body"] in place from "md" or "md_dir" when present.
	var dir_path: String = str(s.get("md_dir", "")).strip_edges()
	if dir_path != "":
		var feed: Dictionary = _load_md_dir_feed(dir_path, int(s.get("md_count", 4)))
		if str(feed.get("body", "")) != "":
			# Keep the author's LOG heading if they set one, else use the folder name.
			if str(s.get("title", "")).strip_edges() == "":
				s["title"] = str(feed.get("title", "LOG"))
			s["body"] = str(feed["body"])
		else:
			# Degrade gracefully: keep title, show a no-data line.
			s["body"] = "— no data —"
		return

	var md_path: String = str(s.get("md", "")).strip_edges()
	if md_path == "":
		return  # No markdown source — keep the hand-typed title/body as-is.

	# ── Pagination ──
	# Per-screen page size (also the screen's "lines" field). The document's full cleaned
	# body lives in the cache; this screen shows the chunk for its page.
	var per_page: int = maxi(1, int(s.get("lines", 5)))
	var page: int = maxi(0, int(s.get("md_page", 0)))

	var all_lines: PackedStringArray = _md_lines(md_path)  # cached, cleaned, whole doc
	var doc_title: String = _md_title(md_path)             # cached H1 / first line / stem

	# Slice math: page P covers body lines [P*per_page : (P+1)*per_page].
	var start_line: int = page * per_page
	var end_line: int = start_line + per_page

	# Title per page: page 0 → real title; page > 0 → "<TITLE> · cont.";
	# a page entirely past the end → "<TITLE> · end".
	if page == 0:
		s["title"] = doc_title
	elif start_line >= all_lines.size():
		s["title"] = _trim_width(doc_title + " · end", 40)
	else:
		s["title"] = _trim_width(doc_title + " · cont.", 40)

	if all_lines.size() == 0:
		# File missing / empty / no usable body — title stands, body marks no data.
		s["body"] = "— no data —"
		return

	if start_line >= all_lines.size():
		# Page past the document — clean end marker rather than empty garbage.
		s["body"] = "— end —"
		return

	# Clamp the slice end to the document length (last page may be short).
	if end_line > all_lines.size():
		end_line = all_lines.size()
	var page_lines: PackedStringArray = all_lines.slice(start_line, end_line)
	s["body"] = "\n".join(page_lines)


# All cleaned body lines of a .md file (whole document), cached per path. The body
# EXCLUDES the title line (H1, or the first content line when it was promoted to title)
# so pagination never duplicates the header. Returns an empty array on read failure.
func _md_lines(path: String) -> PackedStringArray:
	_ensure_md_cached(path)
	var entry = _md_cache.get(path, null)
	if entry is Dictionary and entry.has("lines"):
		return entry["lines"]
	return PackedStringArray()


# The document title: first H1, else first content line, else filename stem (upper-cased).
# Cached per path alongside the body lines.
func _md_title(path: String) -> String:
	_ensure_md_cached(path)
	var entry = _md_cache.get(path, null)
	if entry is Dictionary and entry.has("title"):
		return str(entry["title"])
	return _path_stem(path).to_upper()


# Parse a .md file ONCE into {title, lines} and store it in _md_cache. No-op if already
# cached. Reads the whole document; pagination slices the cached array per screen.
func _ensure_md_cached(path: String) -> void:
	if _md_cache.has(path):
		return

	var entry: Dictionary = {"title": _path_stem(path).to_upper(), "lines": PackedStringArray()}

	if not FileAccess.file_exists(path):
		_md_cache[path] = entry
		return
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		_md_cache[path] = entry
		return
	var text: String = f.get_as_text()
	f.close()
	if text.strip_edges() == "":
		_md_cache[path] = entry
		return

	var raw_lines: PackedStringArray = text.replace("\r\n", "\n").replace("\r", "\n").split("\n", true)

	# Pass 1: find the title (first H1, else first non-empty line, else stem).
	# Skip front-matter and code fences so the title is real content.
	var title: String = ""
	var in_fence: bool = false
	var in_front: bool = false
	var first_nonempty: String = ""
	for i in raw_lines.size():
		var trimmed: String = str(raw_lines[i]).strip_edges()
		# Front-matter: a leading "---" block at the very top of the file.
		if trimmed == "---":
			if i == 0:
				in_front = true
				continue
			if in_front:
				in_front = false
				continue
		if in_front:
			continue
		if trimmed.begins_with("```"):
			in_fence = not in_fence
			continue
		if in_fence:
			continue
		if trimmed == "":
			continue
		if first_nonempty == "":
			first_nonempty = trimmed
		if trimmed.begins_with("# "):
			title = _strip_md_inline(trimmed.substr(2)).strip_edges()
			break
	if title == "":
		if first_nonempty != "":
			title = _strip_md_inline(first_nonempty).strip_edges()
		else:
			title = _path_stem(path).to_upper()

	# Pass 2: collect ALL meaningful body lines — markdown-stripped, after the title.
	var body_lines: PackedStringArray = []
	in_fence = false
	in_front = false
	var passed_title: bool = false
	# If there is no H1, the title was drawn from the first content line, so we must
	# skip that exact line when gathering the body to avoid duplicating it.
	var title_is_first_line: bool = (not _has_h1(raw_lines))
	for i in raw_lines.size():
		var t2: String = str(raw_lines[i]).strip_edges()
		if t2 == "---":
			if i == 0:
				in_front = true
				continue
			if in_front:
				in_front = false
				continue
		if in_front:
			continue
		if t2.begins_with("```"):
			in_fence = not in_fence
			continue
		if in_fence:
			continue
		if t2 == "":
			continue
		# Skip the H1 title line itself.
		if t2.begins_with("# ") and not passed_title:
			passed_title = true
			continue
		# Skip the first content line when it was promoted to the title.
		if title_is_first_line and not passed_title:
			passed_title = true
			continue
		var cleaned: String = _clean_md_line(t2)
		if cleaned == "":
			continue
		body_lines.append(cleaned)

	entry["title"] = title
	entry["lines"] = body_lines
	_md_cache[path] = entry


# Scan a directory for *.md and build a log-feed body: one line per doc,
# "<stem>: <first heading or first line>". Returns {title, body}.
func _load_md_dir_feed(dir_path: String, count: int) -> Dictionary:
	var feed: Dictionary = {"title": "LOG", "body": ""}
	var d: DirAccess = DirAccess.open(dir_path)
	if d == null:
		return feed

	var names: PackedStringArray = []
	d.list_dir_begin()
	var entry: String = d.get_next()
	while entry != "":
		if not d.current_is_dir() and entry.to_lower().ends_with(".md"):
			names.append(entry)
		entry = d.get_next()
	d.list_dir_end()
	if names.is_empty():
		return feed
	names.sort()

	var want: int = count
	if want < 1:
		want = 1
	if want > names.size():
		want = names.size()

	# Normalise the directory so we can join file paths cleanly.
	var base: String = dir_path
	if not base.ends_with("/"):
		base += "/"

	var rolled: PackedStringArray = []
	for i in want:
		var fname: String = str(names[i])
		var stem: String = _path_stem(fname)
		var head: String = _first_md_line(base + fname)
		var line: String = stem + ": " + head
		rolled.append(_trim_width(line, 64))

	feed["body"] = "\n".join(rolled)
	return feed


# First meaningful line of a .md file (H1 text if present, else first content line),
# stripped to plain text. Returns "" on any read failure.
func _first_md_line(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var text: String = f.get_as_text()
	f.close()
	var raw_lines: PackedStringArray = text.replace("\r\n", "\n").replace("\r", "\n").split("\n", true)
	var in_fence: bool = false
	var in_front: bool = false
	var fallback: String = ""
	for i in raw_lines.size():
		var ln: String = str(raw_lines[i])
		var t: String = ln.strip_edges()
		if t == "---":
			if i == 0:
				in_front = true
				continue
			if in_front:
				in_front = false
				continue
		if in_front:
			continue
		if t.begins_with("```"):
			in_fence = not in_fence
			continue
		if in_fence:
			continue
		if t == "":
			continue
		if t.begins_with("# "):
			return _strip_md_inline(t.substr(2)).strip_edges()
		if fallback == "":
			fallback = _clean_md_line(t)
	return fallback


# True if any (non-fenced) line is an H1 heading.
func _has_h1(raw_lines: PackedStringArray) -> bool:
	var in_fence: bool = false
	for i in raw_lines.size():
		var t: String = str(raw_lines[i]).strip_edges()
		if t.begins_with("```"):
			in_fence = not in_fence
			continue
		if in_fence:
			continue
		if t.begins_with("# "):
			return true
	return false


# Strip leading block markers (#, ##, >, -, *, "1.") from a line, then clean inline
# markdown and HTML, drop table pipes, and trim to a readable width. "" = skip the line.
func _clean_md_line(line: String) -> String:
	var s: String = line.strip_edges()
	if s == "":
		return ""
	# Drop horizontal rules / leftover fences.
	if s == "---" or s == "***" or s.begins_with("```"):
		return ""
	# Markdown table rows: "| a | b |" or separator "|---|---|" — skip them.
	if s.begins_with("|"):
		return ""
	# Strip leading heading hashes.
	while s.begins_with("#"):
		s = s.substr(1)
	# Strip a leading blockquote marker.
	while s.begins_with(">"):
		s = s.substr(1).strip_edges()
	# Strip a leading list bullet ("- " or "* " or "+ ").
	if s.begins_with("- ") or s.begins_with("* ") or s.begins_with("+ "):
		s = s.substr(2)
	# Strip a leading ordered-list marker like "1." / "12)" (hand-rolled, no regex).
	s = _strip_ordered_marker(s)
	s = _strip_md_inline(s)
	s = s.strip_edges()
	return _trim_width(s, 56)


# Remove inline markdown / HTML from a single line: links → text, **bold**/*em*/`code`
# → inner text, and any <tag> dropped. Hand-rolled (no regex).
func _strip_md_inline(line: String) -> String:
	var s: String = line
	# Links / images: [text](url) → text ; ![alt](url) → alt. Resolve left-to-right.
	s = _flatten_links(s)
	# Emphasis / code markers: drop the markup characters, keep the inner text.
	s = s.replace("**", "")
	s = s.replace("__", "")
	s = s.replace("`", "")
	s = s.replace("~~", "")
	# Lone * and _ used as emphasis — remove them (word chars and content remain).
	s = s.replace("*", "")
	# Strip any HTML tags <...>.
	s = _strip_html_tags(s)
	# Unescape the few common backslash escapes.
	s = s.replace("\\_", "_")
	s = s.replace("\\*", "*")
	s = s.replace("\\#", "#")
	return s


# Convert every [text](url) (and ![alt](url)) to just its visible text. No regex.
func _flatten_links(line: String) -> String:
	var s: String = line
	var out: String = ""
	var i: int = 0
	var n: int = s.length()
	while i < n:
		var ch: String = s[i]
		if ch == "!" and i + 1 < n and s[i + 1] == "[":
			i += 1  # skip the image bang, fall through to the "[" handler next loop
			continue
		if ch == "[":
			var close_b: int = s.find("]", i + 1)
			if close_b != -1 and close_b + 1 < n and s[close_b + 1] == "(":
				var close_p: int = s.find(")", close_b + 2)
				if close_p != -1:
					out += s.substr(i + 1, close_b - i - 1)
					i = close_p + 1
					continue
			# Not a real link — keep the bracket literally.
			out += ch
			i += 1
			continue
		out += ch
		i += 1
	return out


# Drop any <...> HTML tags, keeping the text between them. No regex.
func _strip_html_tags(line: String) -> String:
	if line.find("<") == -1:
		return line
	var out: String = ""
	var i: int = 0
	var n: int = line.length()
	var in_tag: bool = false
	while i < n:
		var ch: String = line[i]
		if ch == "<":
			in_tag = true
		elif ch == ">":
			in_tag = false
		elif not in_tag:
			out += ch
		i += 1
	return out


# Strip a leading ordered-list marker: digits followed by "." or ")" then a space.
# e.g. "1. Foo" → "Foo", "12) Bar" → "Bar". No regex.
func _strip_ordered_marker(line: String) -> String:
	var i: int = 0
	var n: int = line.length()
	while i < n and line[i] >= "0" and line[i] <= "9":
		i += 1
	if i > 0 and i < n and (line[i] == "." or line[i] == ")"):
		var rest: String = line.substr(i + 1)
		if rest.begins_with(" "):
			return rest.strip_edges()
	return line


# Trim a line to a sane width, adding an ellipsis when it was cut.
func _trim_width(line: String, width: int) -> String:
	if line.length() <= width:
		return line
	return line.substr(0, maxi(1, width - 1)).strip_edges() + "…"


# Filename stem (no directory, no ".md" extension).
func _path_stem(path: String) -> String:
	var base: String = path.get_file()
	if base == "":
		base = path
	var dot: int = base.rfind(".")
	if dot > 0:
		base = base.substr(0, dot)
	return base


# ── Build orchestration ───────────────────────────────────────────────

func _build_all() -> void:
	_built = true
	_md_cache.clear()  # fresh parse per build so the board reflects current file state
	_cursors.clear()       # animation refs point at freed nodes after a rebuild — drop them
	_point_fields.clear()
	_ensure_mono_font()
	_ensure_crt_shader()
	_build_shared_materials()
	_build_desk_base()
	_build_tower()
	_build_keyboard()
	_build_device()
	_build_pole()
	_build_screens()
	if show_cables:
		_build_cables()
	if board_scale != 1.0:
		scale = Vector3(board_scale, board_scale, board_scale)


func _build_shared_materials() -> void:
	# Optional theme tint mixed lightly into the metal/bezel so a board can take a hue.
	var metal_base: Color = Color(0.22, 0.23, 0.27)
	var dark_base: Color = Color(0.07, 0.07, 0.09)
	if theme_color != Color(0, 0, 0):
		metal_base = metal_base.lerp(theme_color, 0.18)
		dark_base = dark_base.lerp(theme_color, 0.12)

	_metal_mat = StandardMaterial3D.new()
	_metal_mat.albedo_color = metal_base
	_metal_mat.metallic = 0.85
	_metal_mat.roughness = 0.35

	_dark_mat = StandardMaterial3D.new()
	_dark_mat.albedo_color = dark_base
	_dark_mat.metallic = 0.4
	_dark_mat.roughness = 0.6

	_cable_mat = StandardMaterial3D.new()
	_cable_mat.albedo_color = Color(0.04, 0.04, 0.05)
	_cable_mat.metallic = 0.1
	_cable_mat.roughness = 0.85


# ── Desk base ─────────────────────────────────────────────────────────

func _build_desk_base() -> void:
	# Desktop slab
	var top := MeshInstance3D.new()
	top.name = "DeskTop"
	var tm := BoxMesh.new()
	tm.size = Vector3(DESK_W, DESK_H, DESK_D)
	top.mesh = tm
	top.material_override = _dark_mat
	top.position = Vector3(0.0, DESK_TOP_Y - DESK_H * 0.5, 0.0)
	add_child(top)

	# Two leg slabs (left, right)
	var leg_h: float = DESK_TOP_Y - DESK_H
	var leg_x: float = DESK_W * 0.5 - 0.08
	for i in 2:
		var leg := MeshInstance3D.new()
		leg.name = "DeskLeg_%d" % i
		var lm := BoxMesh.new()
		lm.size = Vector3(0.1, leg_h, DESK_D - 0.1)
		leg.mesh = lm
		leg.material_override = _metal_mat
		var sx: float = leg_x
		if i == 0:
			sx = -leg_x
		leg.position = Vector3(sx, leg_h * 0.5, 0.0)
		add_child(leg)


# ── Computer tower (vented front) ─────────────────────────────────────

func _build_tower() -> void:
	var tower_w: float = 0.26
	var tower_h: float = 0.5
	var tower_d: float = 0.42
	var base_x: float = -DESK_W * 0.5 + tower_w * 0.5 + 0.05
	var base_y: float = DESK_TOP_Y + tower_h * 0.5

	var tower := MeshInstance3D.new()
	tower.name = "Tower"
	var bm := BoxMesh.new()
	bm.size = Vector3(tower_w, tower_h, tower_d)
	tower.mesh = bm
	tower.material_override = _metal_mat
	tower.position = Vector3(base_x, base_y, 0.0)
	add_child(tower)

	# Vent slats on the front face (+Z), drawn as thin dark inset bars
	var vent_mat := StandardMaterial3D.new()
	vent_mat.albedo_color = Color(0.02, 0.02, 0.03)
	vent_mat.roughness = 0.95
	var front_z: float = tower_d * 0.5 + 0.002
	for i in 5:
		var vent := MeshInstance3D.new()
		vent.name = "TowerVent_%d" % i
		var vm := BoxMesh.new()
		vm.size = Vector3(tower_w * 0.62, 0.018, 0.01)
		vent.mesh = vm
		vent.material_override = vent_mat
		var vy: float = base_y + 0.14 - float(i) * 0.04
		vent.position = Vector3(base_x, vy, front_z)
		add_child(vent)

	# Power LED — small emissive dot
	var led := MeshInstance3D.new()
	led.name = "TowerLED"
	var lm := BoxMesh.new()
	lm.size = Vector3(0.02, 0.02, 0.01)
	led.mesh = lm
	led.material_override = _make_emissive_mat(Color(0.2, 1.0, 0.4), 2.0)
	led.position = Vector3(base_x, base_y - 0.18, front_z)
	add_child(led)


# ── Keyboard slab ─────────────────────────────────────────────────────

func _build_keyboard() -> void:
	var kb := MeshInstance3D.new()
	kb.name = "Keyboard"
	var km := BoxMesh.new()
	km.size = Vector3(0.4, 0.02, 0.16)
	kb.mesh = km
	var kb_mat := StandardMaterial3D.new()
	kb_mat.albedo_color = Color(0.12, 0.12, 0.14)
	kb_mat.metallic = 0.3
	kb_mat.roughness = 0.7
	kb.material_override = kb_mat
	kb.position = Vector3(0.18, DESK_TOP_Y + 0.02, DESK_D * 0.5 - 0.14)
	kb.rotation = Vector3(0.0, deg_to_rad(-6.0), 0.0)
	add_child(kb)

	# A faint grid of key bumps suggested with a few small boxes
	var key_mat := StandardMaterial3D.new()
	key_mat.albedo_color = Color(0.18, 0.18, 0.2)
	key_mat.roughness = 0.6
	for r in 2:
		for c in 6:
			var key := MeshInstance3D.new()
			key.name = "Key_%d_%d" % [r, c]
			var keym := BoxMesh.new()
			keym.size = Vector3(0.045, 0.012, 0.04)
			key.mesh = keym
			key.material_override = key_mat
			var kx: float = 0.18 - 0.13 + float(c) * 0.052
			var kz: float = DESK_D * 0.5 - 0.18 + float(r) * 0.05
			key.position = Vector3(kx, DESK_TOP_Y + 0.035, kz)
			add_child(key)


# ── Small glowing device ──────────────────────────────────────────────

func _build_device() -> void:
	var body := MeshInstance3D.new()
	body.name = "Device"
	var dm := BoxMesh.new()
	dm.size = Vector3(0.12, 0.06, 0.1)
	body.mesh = dm
	body.material_override = _dark_mat
	var dev_x: float = DESK_W * 0.5 - 0.16
	var dev_y: float = DESK_TOP_Y + 0.03
	var dev_z: float = -0.05
	body.position = Vector3(dev_x, dev_y, dev_z)
	add_child(body)

	# Emissive readout on top of the device using its own little texture
	var readout := MeshInstance3D.new()
	readout.name = "DeviceReadout"
	var rm := QuadMesh.new()
	rm.size = Vector2(0.09, 0.05)
	readout.mesh = rm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_texture = _make_device_texture()
	rmat.emission_enabled = true
	rmat.emission_texture = rmat.albedo_texture
	rmat.emission_energy_multiplier = _glow_energy() * 1.1
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	readout.material_override = rmat
	readout.rotation = Vector3(deg_to_rad(-90.0), 0.0, 0.0)
	readout.position = Vector3(dev_x, dev_y + 0.031, dev_z)
	add_child(readout)


# ── Vertical clamp-pole + collar rings (sized to span the screens) ─────

func _build_pole() -> void:
	# Pole reaches at least POLE_MIN_TOP_Y, or above the highest pole-mounted screen.
	var top_y: float = POLE_MIN_TOP_Y
	for s in screens:
		if str(s.get("mount", "pole")) != "base":
			var sy: float = _to_vec3(s.get("pos", null), Vector3.ZERO).y
			var half_h: float = _to_vec2(s.get("size", null), Vector2(0.45, 0.3)).y * 0.5
			top_y = maxf(top_y, sy + half_h + 0.1)

	var pole := MeshInstance3D.new()
	pole.name = "Pole"
	var cm := CylinderMesh.new()
	var pole_len: float = top_y - DESK_TOP_Y
	cm.top_radius = POLE_RADIUS
	cm.bottom_radius = POLE_RADIUS
	cm.height = pole_len
	pole.mesh = cm
	pole.material_override = _metal_mat
	pole.position = Vector3(POLE_X, DESK_TOP_Y + pole_len * 0.5, POLE_Z)
	add_child(pole)

	# Collar / clamp rings — one near each pole-mounted screen height, spread along pole.
	var collar_ys: Array = []
	for s in screens:
		if str(s.get("mount", "pole")) != "base":
			collar_ys.append(_to_vec3(s.get("pos", null), Vector3.ZERO).y)
	if collar_ys.is_empty():
		collar_ys = [DESK_TOP_Y + pole_len * 0.4, DESK_TOP_Y + pole_len * 0.8]

	for i in collar_ys.size():
		var collar := MeshInstance3D.new()
		collar.name = "Collar_%d" % i
		var cmesh := CylinderMesh.new()
		cmesh.top_radius = POLE_RADIUS * 2.0
		cmesh.bottom_radius = POLE_RADIUS * 2.0
		cmesh.height = 0.05
		collar.mesh = cmesh
		var collar_mat := StandardMaterial3D.new()
		collar_mat.albedo_color = Color(0.3, 0.31, 0.34)
		collar_mat.metallic = 0.9
		collar_mat.roughness = 0.3
		collar.material_override = collar_mat
		collar.position = Vector3(POLE_X, float(collar_ys[i]), POLE_Z)
		add_child(collar)


# ── Screens: one configurable panel per `screens` entry ────────────────

func _build_screens() -> void:
	for i in screens.size():
		var raw = screens[i]
		if not (raw is Dictionary):
			continue
		# Coerce again at build time so inspector-authored entries (which may carry
		# Arrays) are normalised too. Idempotent for already-typed dicts.
		var s: Dictionary = _coerce_screen(raw)
		_build_one_screen(i, s)


func _build_one_screen(index: int, s: Dictionary) -> void:
	# Resolve any markdown content source into title/body before drawing the panel.
	_resolve_md_content(s)

	var size: Vector2 = s["size"]
	var pos: Vector3 = s["pos"]
	var yaw_deg: float = s["angle_deg"]
	var pitch_deg: float = s["pitch_deg"]
	var accent: Color = s["color"]
	var stype: String = s["type"]
	var mount: String = s["mount"]

	var root := Node3D.new()
	root.name = "Screen_%d" % index
	# Anchor a base-mounted panel relative to the desk top if its y is near zero.
	root.position = pos
	root.rotation = Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0.0)
	add_child(root)

	# Backing panel: thin box + slightly larger bezel behind it.
	var bezel := MeshInstance3D.new()
	bezel.name = "Bezel"
	var bzm := BoxMesh.new()
	bzm.size = Vector3(size.x + 0.05, size.y + 0.05, 0.035)
	bezel.mesh = bzm
	bezel.material_override = _dark_mat
	bezel.position = Vector3(0.0, 0.0, -0.012)
	root.add_child(bezel)

	var back := MeshInstance3D.new()
	back.name = "Backing"
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x + 0.02, size.y + 0.02, 0.02)
	back.mesh = bm
	back.material_override = _make_panel_back_mat(accent, stype)
	root.add_child(back)

	# Content face by type.
	if stype == "poster":
		_build_face_textured(root, size, _make_poster_texture(accent, s["title"]))
	elif stype == "data":
		_build_face_textured(root, size, _make_data_texture(accent))
	elif stype == "points":
		_build_face_points(root, index, size, accent, s["title"])
	else:
		_build_face_info(root, index, size, s["title"], s["body"], accent)

	# Mount hardware: clamp arm to the pole, or a stand neck to the base.
	if mount == "base":
		_build_stand_neck(root, size)
	else:
		_build_clamp_arm(root, pos)


func _build_face_info(root: Node3D, index: int, size: Vector2, title: String, body: String, accent: Color) -> void:
	# CRT TERMINAL look (terminal_style on) or the old flat info panel (off). Terminal mode:
	# near-black phosphor tube, monospace phosphor text, prompt-style header, left-aligned
	# with a tiny margin, scanline overlay + a blinking cursor at the last line's end.
	var term: bool = terminal_style
	var phos: Dictionary = _phosphor_for(accent)

	# Is the animated CRT glass shader active for this face? Only in terminal mode, only
	# when the crt_shader toggle is on AND the shader file actually loaded; otherwise we use
	# the static emissive backing (+ static scanline overlay) exactly as before.
	var use_crt: bool = term and crt_shader and _crt_shader != null

	# Emissive backing colour (the info-board glow) PLUS real readable Label3D text.
	var face := MeshInstance3D.new()
	face.name = "Face"
	var qm := QuadMesh.new()
	qm.size = size
	face.mesh = qm
	# Terminal: dim glowing phosphor tube (very dark). Flat: accent-tinted dark backing.
	var bg: Color = Color(0.04, 0.05, 0.07).lerp(accent, 0.18)
	if term:
		bg = phos["bg"]
	var bg_energy: float = _glow_energy() * (0.35 if term else 0.5)
	if use_crt:
		# Shader-driven glass: rolling scanlines, flicker, bloom, vignette, aberration —
		# animated by TIME so every screen syncs. The Label3D text rides on top (capture-safe).
		face.material_override = _make_crt_glass_material(phos, size)
	else:
		face.material_override = _make_emissive_color_mat(bg, bg_energy)
	face.position = Vector3(0.0, 0.0, 0.013)
	root.add_child(face)

	# Scanline overlay (terminal only): faint dark horizontal rows in front of the tube.
	# Skipped when the CRT shader is active — the shader already rolls its own scanlines.
	if term and not use_crt:
		_add_scanlines(root, size)

	# Text sits just in front of the panel face; billboard OFF so it stays planar.
	var text_root := Node3D.new()
	text_root.name = "Text"
	text_root.position = Vector3(0.0, 0.0, 0.018)
	root.add_child(text_root)

	# Terminal header: a prompt/path line built from the title (short). Flat: the title as-is.
	var header: String = title
	if term and title.strip_edges() != "":
		header = "block9:~$ " + title.strip_edges()

	# Body lines from "\n"-separated body string.
	var lines: PackedStringArray = body.split("\n", false)
	var has_title: bool = header.strip_edges() != ""

	# Font sizing scaled to panel height so text fits varied sizes.
	var title_font: int = maxi(9, int(round(size.y * 128.0)))
	var body_font: int = maxi(7, int(round(size.y * 70.0)))
	var title_step: float = float(title_font) * TEXT_PIXEL_SIZE * 1.55
	var body_step: float = float(body_font) * TEXT_PIXEL_SIZE * 1.4

	# Clamp the body to ONLY the lines that fit the panel height — no overflow into
	# neighbouring screens. Truncate the rest (the screen shows what fits).
	var title_h: float = title_step if has_title else 0.0
	var max_body: int = maxi(1, int(floor((size.y * 0.92 - title_h) / body_step)))
	if lines.size() > max_body:
		lines = lines.slice(0, max_body)

	var total_h: float = 0.0
	if has_title:
		total_h += title_step
	total_h += body_step * float(lines.size())
	var cursor_y: float = total_h * 0.5

	# Terminal: phosphor header + slightly dimmer phosphor body, left-aligned with a margin.
	# Flat: bright accent title + soft near-white body, centred.
	var title_col: Color = accent.lerp(Color(1, 1, 1), 0.25)
	var body_col: Color = Color(0.92, 0.95, 0.98).lerp(accent, 0.15)
	if term:
		title_col = (phos["text"] as Color).lerp(Color(1, 1, 1), 0.15)
		body_col = (phos["text"] as Color) * 0.82
		body_col.a = 1.0
	var h_align: int = HORIZONTAL_ALIGNMENT_LEFT if term else HORIZONTAL_ALIGNMENT_CENTER
	# Terminal: left-justify all lines to a SHARED left edge by giving each Label3D a fixed
	# pixel `width` box (centred on the node at x=0) and aligning LEFT inside it — so a tiny
	# left margin appears and lines don't centre individually. Flat: no width box, centred.
	var text_w_world: float = size.x * 0.88
	var label_width_px: float = text_w_world / TEXT_PIXEL_SIZE  # Label3D width is in pixels

	# Char budgets so each line fills the panel WIDTH without wrapping (char ≈ 0.58·height).
	# Terminal text is left-aligned within a margin box, so it has slightly less usable width.
	var width_frac: float = 0.86 if term else 1.0
	var title_chars: int = maxi(4, int(size.x * width_frac / (float(title_font) * TEXT_PIXEL_SIZE * 0.62)))
	var body_chars: int = maxi(6, int(size.x * width_frac / (float(body_font) * TEXT_PIXEL_SIZE * 0.56)))

	if has_title:
		var head: Label3D = _new_term_label("Title", _fit_text(header, title_chars), title_font, 2, title_col, h_align, term, label_width_px)
		head.position = Vector3(0.0, cursor_y - title_step * 0.5, 0.0)
		text_root.add_child(head)
		cursor_y -= title_step

	# Track the last body line's geometry so the blinking cursor sits at its end.
	var last_line_y: float = cursor_y - body_step * 0.5
	var last_line_chars: int = 0
	for i in lines.size():
		var line: Label3D = _new_term_label("Body%d" % i, _fit_text(str(lines[i]), body_chars), body_font, 1, body_col, h_align, term, label_width_px)
		last_line_y = cursor_y - body_step * 0.5
		line.position = Vector3(0.0, last_line_y, 0.0)
		last_line_chars = line.text.length()
		text_root.add_child(line)
		cursor_y -= body_step

	# Blinking cursor (terminal only): a bright phosphor block just after the last line.
	# The text box's left edge sits at -text_w_world*0.5; the cursor advances from there.
	if term:
		_add_terminal_cursor(text_root, size, body_font, body_step, last_line_y, last_line_chars, -text_w_world * 0.5, phos["text"])


## Build a Label3D with the terminal/flat shared settings. Applies the monospace font when
## terminal_style is on and the font loaded; otherwise the engine default font is used. In
## terminal mode a fixed pixel `width` box + LEFT alignment justify every line to a shared
## left edge (the box is centred on the node); flat mode leaves width unset so it centres.
func _new_term_label(node_name: String, content: String, fsize: int, outline: int, col: Color, h_align: int, term: bool, width_px: float) -> Label3D:
	var lbl := Label3D.new()
	lbl.name = node_name
	lbl.text = content
	lbl.font_size = fsize
	lbl.outline_size = outline
	lbl.pixel_size = TEXT_PIXEL_SIZE
	lbl.modulate = col
	lbl.outline_modulate = Color(0, 0, 0, 0.9)
	lbl.horizontal_alignment = h_align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.no_depth_test = true
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	if term:
		# A fixed width box gives the lines a shared left edge; we already truncate to fit,
		# so wrapping stays off and text never spills past the box.
		lbl.width = width_px
		if _mono_font != null:
			lbl.font = _mono_font
	return lbl


## A small bright phosphor block at the end of the terminal's last line. Registered in
## _cursors so _process can blink it at ~1.5 Hz. Width ≈ one monospace cell.
func _add_terminal_cursor(text_root: Node3D, size: Vector2, body_font: int, body_step: float, line_y: float, line_chars: int, left_margin: float, glow: Color) -> void:
	var cell_w: float = float(body_font) * TEXT_PIXEL_SIZE * 0.56  # ≈ one mono char width
	var cur_w: float = cell_w * 0.85
	var cur_h: float = body_step * 0.62
	var cursor := MeshInstance3D.new()
	cursor.name = "Cursor"
	var qm := QuadMesh.new()
	qm.size = Vector2(cur_w, cur_h)
	cursor.mesh = qm
	cursor.material_override = _make_emissive_color_mat(glow.lerp(Color(1, 1, 1), 0.2), _glow_energy() * 1.2)
	# Sit just after the last line's text (left margin + line width + a small gap), clamped
	# so a long line keeps the cursor inside the panel.
	var line_w: float = float(line_chars) * cell_w
	var cx: float = left_margin + line_w + cell_w * 0.5
	var max_x: float = size.x * 0.5 - cur_w * 0.5
	cx = clampf(cx, left_margin, max_x)
	cursor.position = Vector3(cx, line_y, 0.001)
	cursor.visible = _cursor_on
	text_root.add_child(cursor)
	_cursors.append(cursor)


## A faint scanline overlay: a procedural ImageTexture of alternating dark rows drawn on a
## transparent quad slightly in front of the tube. Subtle — keeps the text legible.
func _add_scanlines(root: Node3D, size: Vector2) -> void:
	var quad := MeshInstance3D.new()
	quad.name = "Scanlines"
	var qm := QuadMesh.new()
	qm.size = size
	quad.mesh = qm
	quad.material_override = _make_scanline_material()
	quad.position = Vector3(0.0, 0.0, 0.0205)  # in front of face (0.013) and text (0.018)
	root.add_child(quad)


func _make_scanline_material() -> StandardMaterial3D:
	# A tall 1×N stripe texture: every other row a low-alpha dark line, rest transparent.
	var rows: int = 64
	var img := Image.create(2, rows, false, Image.FORMAT_RGBA8)
	var dark := Color(0.0, 0.0, 0.0, 0.28)
	var clear := Color(0.0, 0.0, 0.0, 0.0)
	for y in rows:
		var col: Color = dark if (y % 2 == 0) else clear
		img.set_pixel(0, y, col)
		img.set_pixel(1, y, col)
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.no_depth_test = false
	return mat


## Build the animated CRT screen-glass ShaderMaterial for one info tube face. Uses the
## preloaded crt_terminal.gdshader (caller already verified _crt_shader != null). The
## phosphor glow colour comes from the screen's _phosphor_for(accent) tube; scan_density is
## scaled to the panel HEIGHT so taller panels keep a consistent line pitch; intensity rides
## the crt_intensity export folded with the rig's glow energy. TIME inside the shader makes
## every instance of this material animate IN SYNC — no per-node time is set here.
func _make_crt_glass_material(phos: Dictionary, size: Vector2) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _crt_shader
	var glow_col: Color = phos["text"]
	mat.set_shader_parameter("phosphor", glow_col)
	mat.set_shader_parameter("scan_speed", 1.0)
	# ~3.2 lines per cm of panel height → a steady CRT pitch regardless of panel size.
	var density: float = clampf(size.y * 640.0, 80.0, 520.0)
	mat.set_shader_parameter("scan_density", density)
	mat.set_shader_parameter("flicker_amt", 0.06)
	mat.set_shader_parameter("glow", 0.6)
	mat.set_shader_parameter("vignette_amt", 0.5)
	mat.set_shader_parameter("aberration", 0.5)
	# Fold the rig's glow energy into the master intensity, then clamp to the shader's range.
	var energy: float = _glow_energy()
	if energy <= 0.0:
		energy = 1.0  # screen_glow off → keep the glass visible, just unscaled by emission
	var master: float = clampf(crt_intensity * (0.7 + 0.3 * energy), 0.0, 2.0)
	mat.set_shader_parameter("intensity", master)
	return mat


## Truncate `s` to at most `max_chars`, adding an ellipsis if cut, so a line fills the
## panel width without wrapping into a neighbour.
func _fit_text(s: String, max_chars: int) -> String:
	if s.length() <= max_chars:
		return s
	return s.substr(0, maxi(1, max_chars - 1)).strip_edges() + "…"


func _build_face_textured(root: Node3D, size: Vector2, tex: ImageTexture) -> void:
	var face := MeshInstance3D.new()
	face.name = "Face"
	var qm := QuadMesh.new()
	qm.size = size
	face.mesh = qm
	face.material_override = _make_screen_material(tex)
	face.position = Vector3(0.0, 0.0, 0.013)
	root.add_child(face)


# ── "points" type — glowing point-cloud / scatter field (MultiMesh) ────
# A dark tube backing + a field of dozens of tiny emissive quads scattered in the panel
# plane and a shallow volume just in front of it, seeded by a fixed RNG so the layout is
# stable across rebuilds. The points cluster/drift toward a brighter CENTRAL point. A faint
# wireframe frame and a small phosphor title ("POINT FIELD" / "REDUCTION") label it. The
# field is registered in _point_fields so _process can pulse/jitter it cheaply.
func _build_face_points(root: Node3D, index: int, size: Vector2, accent: Color, title: String) -> void:
	# Dark glowing tube backing (matches the terminal look).
	var phos: Dictionary = _phosphor_for(accent)
	var glow: Color = phos["text"]
	var back := MeshInstance3D.new()
	back.name = "Face"
	var qm := QuadMesh.new()
	qm.size = size
	back.mesh = qm
	back.material_override = _make_emissive_color_mat(phos["bg"], _glow_energy() * 0.3)
	back.position = Vector3(0.0, 0.0, 0.013)
	root.add_child(back)

	# Faint wireframe frame: four thin emissive bars around the panel rect.
	_add_points_frame(root, size, glow * 0.6)

	# The point field MultiMesh — tiny emissive quads, dozens of them.
	var count: int = 96
	var rng := RandomNumberGenerator.new()
	var seed_val: int = 13577 + index * 911     # fixed per screen → stable layout
	rng.seed = seed_val

	var mesh := QuadMesh.new()
	var dot: float = clampf(minf(size.x, size.y) * 0.022, 0.004, 0.012)
	mesh.size = Vector2(dot, dot)
	var pmat := StandardMaterial3D.new()
	# Per-instance colour carries each point's brightness (centre bright, rim dim). Unshaded
	# so the colour shows directly; a modest emission keeps every point glowing as phosphor.
	pmat.albedo_color = Color(1, 1, 1)
	pmat.vertex_color_use_as_albedo = true
	pmat.emission_enabled = true
	pmat.emission = glow
	pmat.emission_energy_multiplier = _glow_energy() * 0.9
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = pmat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count

	# Half-extents of the scatter region (a little inside the panel rect), and the shallow
	# depth in front of the face that the volume occupies.
	var hx: float = size.x * 0.42
	var hy: float = size.y * 0.40
	var depth: float = 0.03
	var base_pts := PackedVector3Array()
	base_pts.resize(count)

	for i in count:
		var p: Vector3
		var col: Color
		if i == 0:
			# The bright CENTRAL point the field clusters toward.
			p = Vector3(0.0, 0.0, 0.016 + depth * 0.6)
			col = glow.lerp(Color(1, 1, 1), 0.55)
		else:
			# Scatter biased toward the centre (square the radius factor → denser core).
			var ang: float = rng.randf() * TAU
			var rad: float = pow(rng.randf(), 0.65)
			var px: float = cos(ang) * rad * hx
			var py: float = sin(ang) * rad * hy
			var pz: float = 0.015 + rng.randf() * depth
			p = Vector3(px, py, pz)
			# Brighter near the centre, dimmer at the rim.
			var bright: float = 1.0 - rad * 0.55
			col = glow * clampf(bright, 0.35, 1.0)
			col.a = 1.0
		base_pts[i] = p
		var basis := Basis().scaled(Vector3.ONE if i != 0 else Vector3(1.6, 1.6, 1.6))
		mm.set_instance_transform(i, Transform3D(basis, p))
		mm.set_instance_color(i, col)

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "PointField"
	mmi.multimesh = mm
	root.add_child(mmi)

	_point_fields.append({"mm": mm, "base": base_pts, "count": count, "seed": seed_val})

	# Small phosphor label naming the viz.
	var label_text: String = title.strip_edges()
	if label_text == "":
		label_text = "POINT FIELD"
	var lbl := Label3D.new()
	lbl.name = "PointsLabel"
	lbl.text = label_text
	lbl.font_size = maxi(7, int(round(size.y * 60.0)))
	lbl.outline_size = 1
	lbl.pixel_size = TEXT_PIXEL_SIZE
	lbl.modulate = glow.lerp(Color(1, 1, 1), 0.2)
	lbl.outline_modulate = Color(0, 0, 0, 0.9)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.no_depth_test = true
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	if terminal_style and _mono_font != null:
		lbl.font = _mono_font
	lbl.position = Vector3(0.0, -size.y * 0.5 + size.y * 0.10, 0.02)
	root.add_child(lbl)


# Four thin emissive bars framing the panel rect (a faint wireframe for the scatter).
func _add_points_frame(root: Node3D, size: Vector2, col: Color) -> void:
	var t: float = 0.004
	var mat: StandardMaterial3D = _make_emissive_color_mat(col, _glow_energy() * 0.8)
	var specs: Array = [
		[Vector3(0.0, size.y * 0.5, 0.014), Vector2(size.x, t)],   # top
		[Vector3(0.0, -size.y * 0.5, 0.014), Vector2(size.x, t)],  # bottom
		[Vector3(-size.x * 0.5, 0.0, 0.014), Vector2(t, size.y)],  # left
		[Vector3(size.x * 0.5, 0.0, 0.014), Vector2(t, size.y)],   # right
	]
	for i in specs.size():
		var bar := MeshInstance3D.new()
		bar.name = "Frame%d" % i
		var qm := QuadMesh.new()
		qm.size = specs[i][1]
		bar.mesh = qm
		bar.material_override = mat
		bar.position = specs[i][0]
		root.add_child(bar)


# Gentle per-frame life for every point field: pulse the whole field's scale a touch and
# jitter a handful of points each frame (cheap — only a few instances rewritten). Stable
# because each field re-derives its jitter from its own seed + a slow time phase.
func _animate_point_fields() -> void:
	var pulse: float = 1.0 + 0.06 * sin(_points_time * 2.2)
	for field in _point_fields:
		var mm = field.get("mm", null)
		if not (mm is MultiMesh):
			continue
		var base: PackedVector3Array = field["base"]
		var count: int = int(field["count"])
		# Jitter up to ~10 points this frame, chosen by a rolling window over time.
		var jitter_n: int = mini(10, maxi(0, count - 1))
		var start_idx: int = 1 + (int(_points_time * 8.0) % maxi(1, count - 1))
		for k in jitter_n:
			var i: int = 1 + ((start_idx + k) % maxi(1, count - 1))
			var bp: Vector3 = base[i]
			var ph: float = float(i) * 1.7 + _points_time * 1.5
			var jx: float = sin(ph) * 0.0025
			var jy: float = cos(ph * 1.3) * 0.0025
			var sc: Vector3 = Vector3(pulse, pulse, 1.0)
			var b := Basis().scaled(sc)
			mm.set_instance_transform(i, Transform3D(b, bp + Vector3(jx, jy, 0.0)))
		# Pulse the central point's scale a little more so it breathes.
		var cb := Basis().scaled(Vector3(1.6 * pulse, 1.6 * pulse, 1.0))
		mm.set_instance_transform(0, Transform3D(cb, base[0]))


func _build_clamp_arm(root: Node3D, pos: Vector3) -> void:
	# Short arm reaching back toward the pole line (so it reads as clamped to the pole).
	var arm := MeshInstance3D.new()
	arm.name = "ClampArm"
	var am := BoxMesh.new()
	am.size = Vector3(0.025, 0.025, 0.18)
	arm.mesh = am
	arm.material_override = _metal_mat
	arm.position = Vector3(0.0, 0.0, -0.1)
	root.add_child(arm)


func _build_stand_neck(root: Node3D, size: Vector2) -> void:
	var neck := MeshInstance3D.new()
	neck.name = "MonitorNeck"
	var nm := BoxMesh.new()
	nm.size = Vector3(0.04, 0.18, 0.03)
	neck.mesh = nm
	neck.material_override = _metal_mat
	neck.position = Vector3(0.0, -size.y * 0.5 - 0.09, -0.02)
	root.add_child(neck)


# ── Cables: draping tubes spanning the screens to the base ─────────────

func _build_cables() -> void:
	# One cable from each of the first few pole-mounted screens down to the base,
	# so the drape spans the configured board rather than fixed positions.
	var anchored: int = 0
	for i in screens.size():
		if anchored >= 3:
			break
		var raw = screens[i]
		if not (raw is Dictionary):
			continue
		var mount: String = str(raw.get("mount", "pole")).strip_edges().to_lower()
		if mount == "base":
			continue
		var p: Vector3 = _to_vec3(raw.get("pos", null), Vector3(0.0, 1.5, 0.0))
		# Drape from the screen's lower-back toward the tower / desk surface.
		var from_pt: Vector3 = Vector3(p.x * 0.5, p.y - 0.05, -0.04)
		var target_x: float = -0.45
		if anchored % 2 == 1:
			target_x = 0.45
		var to_pt: Vector3 = Vector3(target_x, DESK_TOP_Y + 0.04, 0.0)
		var radius: float = 0.016
		if anchored == 1:
			radius = 0.013
		_add_cable(from_pt, to_pt, radius)
		anchored += 1

	# Always leave one cable draping to the base if nothing was anchored above.
	if anchored == 0:
		_add_cable(Vector3(-0.08, 1.5, -0.02), Vector3(-0.45, DESK_TOP_Y + 0.05, 0.05), 0.016)


func _add_cable(p_from: Vector3, p_to: Vector3, radius: float) -> void:
	# Draping cable approximated as a chain of short cylinder segments along a
	# sagging arc (a simple downward-bowed quadratic between the two endpoints).
	var root := Node3D.new()
	root.name = "Cable"
	add_child(root)

	var segments: int = 8
	var sag: float = 0.18
	var prev: Vector3 = p_from
	for i in range(1, segments + 1):
		var t: float = float(i) / float(segments)
		var point: Vector3 = p_from.lerp(p_to, t)
		# Parabolic sag: max at t=0.5, zero at the ends
		point.y -= sag * (4.0 * t * (1.0 - t))
		_add_cable_segment(root, prev, point, radius)
		prev = point


func _add_cable_segment(parent: Node3D, a: Vector3, b: Vector3, radius: float) -> void:
	var seg := MeshInstance3D.new()
	seg.name = "Seg"
	var mid: Vector3 = (a + b) * 0.5
	var dir: Vector3 = b - a
	var length: float = dir.length()
	if length < 0.0001:
		return
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = length
	seg.mesh = cm
	seg.material_override = _cable_mat
	seg.position = mid
	# Orient the cylinder (default +Y axis) along dir
	var up := Vector3(0.0, 1.0, 0.0)
	var ndir: Vector3 = dir.normalized()
	var dot: float = up.dot(ndir)
	if dot < -0.9999:
		seg.rotation = Vector3(PI, 0.0, 0.0)
	elif dot < 0.9999:
		var axis: Vector3 = up.cross(ndir).normalized()
		var angle: float = acos(clampf(dot, -1.0, 1.0))
		seg.transform.basis = Basis(axis, angle)
	parent.add_child(seg)


# ── Material helpers ──────────────────────────────────────────────────

func _glow_energy() -> float:
	if screen_glow:
		return screen_emission
	return 0.0


# Load the monospace terminal font once (lazy, cached). Leaves _mono_font null if the file
# is missing — terminal text then uses the engine default font but keeps the phosphor look.
func _ensure_mono_font() -> void:
	if _mono_checked:
		return
	_mono_checked = true
	if ResourceLoader.exists(MONO_FONT_PATH):
		var res = load(MONO_FONT_PATH)
		if res is Font:
			_mono_font = res


# Load the CRT screen-glass shader once (lazy, cached). Leaves _crt_shader null if the file
# is missing — the info tube face then falls back to the static-scanline texture look.
func _ensure_crt_shader() -> void:
	if _crt_checked:
		return
	_crt_checked = true
	if ResourceLoader.exists(CRT_SHADER_PATH):
		var res = load(CRT_SHADER_PATH)
		if res is Shader:
			_crt_shader = res


# ── Terminal phosphor palette ─────────────────────────────────────────
# Map a screen's accent `color` to a CRT phosphor variant. The accent's HUE picks the tube:
# greens → phosphor GREEN (default), warm reds/oranges/yellows → AMBER, blues/cyans → CYAN.
# Returns { "text": bright phosphor text colour, "bg": near-black glowing tube colour }.
func _phosphor_for(accent: Color) -> Dictionary:
	var green: Color = Color(0.35, 1.0, 0.45)
	var amber: Color = Color(1.0, 0.72, 0.22)
	var cyan: Color = Color(0.3, 0.95, 1.0)
	var text: Color = green
	var bg: Color = Color(0.02, 0.045, 0.03)        # dark green-black tube by default
	# Use hue only when the accent is colourful enough to read as a deliberate choice.
	var h: float = accent.h
	var s: float = accent.s
	if s > 0.18:
		if h >= 0.5 and h <= 0.72:
			# Blue/cyan band → cyan phosphor on a dark blue-black tube.
			text = cyan
			bg = Color(0.02, 0.035, 0.05)
		elif h < 0.12 or h > 0.92 or (h >= 0.06 and h <= 0.18):
			# Reds / oranges / yellows → amber phosphor on a dark amber-black tube.
			text = amber
			bg = Color(0.05, 0.03, 0.012)
		# else: greens (and everything else) keep the default green phosphor.
	return {"text": text, "bg": bg}


func _make_emissive_mat(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.roughness = 0.6
	return mat


func _make_emissive_color_mat(color: Color, energy: float) -> StandardMaterial3D:
	# Flat emissive colour (no texture) for info-panel backings.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _make_panel_back_mat(accent: Color, stype: String) -> StandardMaterial3D:
	# Thin backing box tinted by the panel accent so the rig carries colour even from behind.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.06, 0.08).lerp(accent, 0.2)
	mat.metallic = 0.3
	mat.roughness = 0.6
	return mat


func _make_screen_material(tex: ImageTexture) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission_energy_multiplier = _glow_energy()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


# ── Procedural screen textures ────────────────────────────────────────
# Drawing helpers operate on an Image. Faux text = small filled bars.

func _new_image(bg: Color) -> Image:
	var img := Image.create(TEX_W, TEX_H, false, Image.FORMAT_RGBA8)
	img.fill(bg)
	return img


func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var x0: int = clampi(x, 0, TEX_W)
	var y0: int = clampi(y, 0, TEX_H)
	var x1: int = clampi(x + w, 0, TEX_W)
	var y1: int = clampi(y + h, 0, TEX_H)
	for py in range(y0, y1):
		for px in range(x0, x1):
			img.set_pixel(px, py, color)


# A row of short bars to read as a line of text.
func _text_bars(img: Image, x: int, y: int, count: int, bar_w: int, bar_h: int, gap: int, color: Color) -> void:
	for i in count:
		var bx: int = x + i * (bar_w + gap)
		# Vary bar width a touch so it reads as words, not a comb
		var w: int = bar_w
		if i % 3 == 0:
			w = bar_w + 2
		if i % 5 == 4:
			w = maxi(2, bar_w - 2)
		_fill_rect(img, bx, y, w, bar_h, color)


func _radial_burst(img: Image, cx: int, cy: int, inner: Color, outer: Color) -> void:
	var max_d: float = sqrt(float(TEX_W * TEX_W + TEX_H * TEX_H)) * 0.5
	for py in TEX_H:
		for px in TEX_W:
			var dx: float = float(px - cx)
			var dy: float = float(py - cy)
			var d: float = sqrt(dx * dx + dy * dy) / max_d
			var t: float = clampf(d, 0.0, 1.0)
			img.set_pixel(px, py, inner.lerp(outer, t))


# ── "poster" type — the old neon-poster look, now accent-tinted ────────
# Reproduces the original SECURITY-BREACH style poster (radial burst + hooded
# blob + warning bars), themed by the panel's accent colour so any poster screen
# keeps that cool cyberpunk look.
func _make_poster_texture(accent: Color, _title: String) -> ImageTexture:
	var deep: Color = accent.darkened(0.7)
	var img := _new_image(deep)
	var hot: Color = accent.lerp(Color(1, 1, 1), 0.25)
	_radial_burst(img, TEX_W / 2, TEX_H / 2 + 10, hot, deep)
	var dark := Color(0.02, 0.0, 0.02)
	# Hooded figure: hood arc (block) + body
	_fill_rect(img, 100, 44, 56, 44, dark)       # hood top
	_fill_rect(img, 92, 80, 72, 64, dark)        # cloak body
	# Dark face void inside hood
	_fill_rect(img, 114, 60, 28, 24, Color(0.0, 0.0, 0.0))
	# Warning bar across the top
	_fill_rect(img, 0, 6, TEX_W, 22, Color(0.0, 0.0, 0.0, 0.85))
	_text_bars(img, 14, 11, 14, 11, 12, 3, hot)
	# Bottom scan bar
	_fill_rect(img, 0, TEX_H - 14, TEX_W, 10, Color(0.0, 0.0, 0.0, 0.7))
	_text_bars(img, 12, TEX_H - 12, 12, 10, 6, 4, hot)
	return ImageTexture.create_from_image(img)


# ── "data" type — procedural graph/readout (bars + baseline) ───────────
func _make_data_texture(accent: Color) -> ImageTexture:
	var img := _new_image(Color(0.02, 0.04, 0.06))
	var line: Color = accent.lerp(Color(1, 1, 1), 0.2)
	# Baseline
	_fill_rect(img, 8, TEX_H - 40, TEX_W - 16, 2, line * 0.5)
	# A jagged "signal" as a row of vertical bars of varied height
	var heights := [30, 70, 45, 90, 55, 110, 60, 80, 40, 95, 50, 75]
	for i in heights.size():
		var bx: int = 14 + i * 19
		var bh: int = int(heights[i])
		_fill_rect(img, bx, TEX_H - 40 - bh, 10, bh, line)
	# A few horizontal gridlines for a readout feel
	for g in 3:
		var gy: int = 30 + g * 30
		_fill_rect(img, 8, gy, TEX_W - 16, 1, line * 0.3)
	# Status text bars top
	_text_bars(img, 12, 14, 8, 12, 9, 5, line)
	return ImageTexture.create_from_image(img)


# (small device readout — tiny graph + status bars, kept for the desk device)
func _make_device_texture() -> ImageTexture:
	var img := _new_image(Color(0.02, 0.04, 0.06))
	var green := Color(0.2, 1.0, 0.5)
	# Baseline
	_fill_rect(img, 8, TEX_H - 40, TEX_W - 16, 2, green * 0.5)
	# A jagged "signal" as a row of vertical bars of varied height
	var heights := [30, 70, 45, 90, 55, 110, 60, 80, 40, 95, 50, 75]
	for i in heights.size():
		var bx: int = 14 + i * 19
		var bh: int = int(heights[i])
		_fill_rect(img, bx, TEX_H - 40 - bh, 10, bh, green)
	# Status text bars top
	_text_bars(img, 12, 14, 8, 12, 9, 5, green)
	return ImageTexture.create_from_image(img)

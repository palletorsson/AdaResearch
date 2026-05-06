## biome_paint_tokens.gd — Parser for the `biome_paint` map layer.
##
## The biome_paint layer sits alongside structure / utilities / interactables
## in map_data.json and lets authors paint per-cell hints for where biome
## density should emphasize, in addition to the global per-sequence
## `soft_stages.json` defaults.
##
## Token language:
##   " " or ""    →  unpainted; cell inherits stage default (no deposit)
##   "-"          →  sterile (carve presence to 0 here — v1 just skips)
##   "f1".."f5"   →  flower, intensity 1..5
##   "t1".."t5"   →  tree
##   "u1".."u5"   →  fungus (u, since f is flower)
##   "c1".."c5"   →  creature
##   "m1".."m5"   →  moss/mixed flora (flower + fungus blend)
##   "x1".."x5"   →  cross-kingdom mix (all four kingdoms at half strength)
##
## Intensity n maps to strength n / 5.0 (so 5 = 1.0, 3 = 0.6, etc.).
##
## Returned shape per token:
##   {
##     "deposits": [
##       { "kingdom": <int 0..3>, "strength": <float 0..1> },
##       ...
##     ],
##     "sterile":  <bool>,
##     "valid":    <bool>,
##   }
## Empty / unpainted cells return { "deposits": [], "sterile": false, "valid": true }.
## Malformed tokens return { "deposits": [], "sterile": false, "valid": false }.

class_name BiomePaintTokens

# Match the kingdoms used by PresenceGrid:
#   0 = tree (R), 1 = creature (G), 2 = flower (B), 3 = fungus (A)
const KINGDOM_TREE: int = 0
const KINGDOM_CREATURE: int = 1
const KINGDOM_FLOWER: int = 2
const KINGDOM_FUNGUS: int = 3

const _KIND_TO_KINGDOM: Dictionary = {
	"t": KINGDOM_TREE,
	"c": KINGDOM_CREATURE,
	"f": KINGDOM_FLOWER,
	"u": KINGDOM_FUNGUS,
}

## Parse a single cell token.
## Always returns a Dictionary so the caller doesn't have to null-check.
static func parse(raw: Variant) -> Dictionary:
	var empty := {"deposits": [], "sterile": false, "valid": true}
	if raw == null:
		return empty
	var s := String(raw).strip_edges()
	if s.is_empty() or s == " ":
		return empty
	if s == "-":
		return {"deposits": [], "sterile": true, "valid": true}

	# Tokens are <prefix><digit>, prefix in [t c f u m x], digit 1..5.
	if s.length() < 2:
		return {"deposits": [], "sterile": false, "valid": false}
	var prefix := s.substr(0, 1)
	var n_str := s.substr(1)
	if not n_str.is_valid_int():
		return {"deposits": [], "sterile": false, "valid": false}
	var n := int(n_str)
	if n < 1 or n > 5:
		return {"deposits": [], "sterile": false, "valid": false}
	var strength: float = float(n) / 5.0

	var deposits: Array = []
	if _KIND_TO_KINGDOM.has(prefix):
		deposits.append({"kingdom": _KIND_TO_KINGDOM[prefix], "strength": strength})
	elif prefix == "m":
		# Moss / mixed flora — flower + fungus at 70% each.
		var s_mix: float = strength * 0.7
		deposits.append({"kingdom": KINGDOM_FLOWER, "strength": s_mix})
		deposits.append({"kingdom": KINGDOM_FUNGUS, "strength": s_mix})
	elif prefix == "x":
		# Cross-kingdom — all four at half strength.
		var s_x: float = strength * 0.5
		for k in [KINGDOM_TREE, KINGDOM_CREATURE, KINGDOM_FLOWER, KINGDOM_FUNGUS]:
			deposits.append({"kingdom": k, "strength": s_x})
	else:
		return {"deposits": [], "sterile": false, "valid": false}

	return {"deposits": deposits, "sterile": false, "valid": true}


## Iterate a 2D biome_paint layer and yield (cell_x, cell_z, deposit) entries.
## `tiles` is a 2D Array of strings as it appears in map_data.json.
## Returns Array of Dictionaries:
##   { "x": int, "z": int, "kingdom": int, "strength": float, "sterile": bool, "raw": String }
static func iter_painted_cells(tiles: Array) -> Array:
	var out: Array = []
	if not (tiles is Array):
		return out
	for z in tiles.size():
		var row = tiles[z]
		if not (row is Array):
			continue
		for x in row.size():
			var raw_token = row[x]
			var info := parse(raw_token)
			if not info["valid"]:
				continue
			if info["sterile"]:
				out.append({
					"x": int(x), "z": int(z),
					"sterile": true, "kingdom": -1, "strength": 0.0,
					"raw": String(raw_token),
				})
				continue
			for dep in info["deposits"]:
				out.append({
					"x": int(x), "z": int(z),
					"sterile": false,
					"kingdom": int(dep["kingdom"]),
					"strength": float(dep["strength"]),
					"raw": String(raw_token),
				})
	return out

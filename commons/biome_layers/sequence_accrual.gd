extends RefCounted
class_name SequenceAccrual

## SequenceAccrual — a map's biome builds on the maps before it in its sequence.
##
## Each map saves only its OWN painted layers (its delta) into its map_data.json's
## top-level `paint_layers[]`. At LOAD time, a map's effective paint layers are the
## union, in sequence order, of every earlier map's layers + its own. So the biome
## visibly thickens as you walk a sequence — without duplicating data (each map is
## still just its own delta on disk). This is render-time accrual, composed fresh
## every load. See doc/PAINT_LAYERS.md § Sequence accrual.
##
## Maps in a sequence have DIFFERENT grid sizes, so nothing copies cell-for-cell:
## procedural layers (noise/curve/plane/random) re-evaluate on each map's own grid,
## and brush masks bilinear-resample to it (DistributionField._read_brush). Accrual
## is layer-RECIPE level, not painted-pixel level.
##
## Additive + safe: with no EcosystemManager, no sequence, or a first-in-sequence
## map, this returns the map's own layers unchanged.

const MAPS_DIR := "res://commons/maps/"

# Session cache of each map's own paint_layers, keyed by map name. A late map in a
# long sequence accrues from dozens of earlier maps; without this every map load
# (and every live brush rebuild) re-opened + re-parsed all of them on the main
# thread. Invalidated per-map on save (invalidate) — see the brush save paths.
static var _paint_cache: Dictionary = {}


## Drop a map's cached paint_layers (call after writing its map_data.json so the
## next accrual re-reads the fresh layers). No arg clears the whole cache.
static func invalidate(map_name: String = "") -> void:
	if map_name == "":
		_paint_cache.clear()
	else:
		_paint_cache.erase(map_name)


## The effective paint layers for `map_name`: every earlier map's layers (sequence
## order) followed by `own_layers` (own last). Same-element layers ACCUMULATE; the
## consumer (DistributionField.placements_for) dedupes per cell and caps the
## per-element total, so accrual thickens the distribution without unbounded count.
## `eco` is the EcosystemManager autoload (may be null → returns own_layers).
static func accrued_layers(eco, map_name: String, own_layers: Array) -> Array:
	if eco == null or not eco.has_method("get_sequence_for_map") or not eco.has_method("get_sequence_maps"):
		return own_layers
	var seq: String = str(eco.get_sequence_for_map(map_name))
	if seq == "":
		return own_layers
	var maps: Array = eco.get_sequence_maps(seq)
	var idx: int = maps.find(map_name)
	if idx <= 0:   # not found, or first map → nothing to build on
		return own_layers

	var preceding: Array = []   # one Array[layer] per earlier map, in order
	for i in idx:
		var earlier: String = str(maps[i])
		if earlier == map_name:
			continue
		var layers: Array = _load_paint_layers(earlier)
		if not layers.is_empty():
			# Tag provenance so editors/debug can show "inherited from <map>".
			# Consumers (DistributionField, ground_substrate) ignore unknown keys.
			var tagged: Array = []
			for l in layers:
				if l is Dictionary:
					var d: Dictionary = (l as Dictionary).duplicate(true)
					d["_accrued_from"] = earlier
					tagged.append(d)
			preceding.append(tagged)
	return compose(preceding, own_layers)


## Pure merge (no IO): flatten the per-earlier-map layer lists in order, then
## append the map's own layers last. Kept separate so it is unit-testable.
static func compose(preceding_lists: Array, own_layers: Array) -> Array:
	var out: Array = []
	for layers in preceding_lists:
		if layers is Array:
			out.append_array(layers)
	if own_layers is Array:
		out.append_array(own_layers)
	return out


## Read a map's own top-level paint_layers[] from disk (cached). [] if missing.
static func _load_paint_layers(map_name: String) -> Array:
	if _paint_cache.has(map_name):
		return _paint_cache[map_name]
	var result: Array = []
	var path := MAPS_DIR + map_name + "/map_data.json"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			var text := f.get_as_text()
			f.close()
			var json := JSON.new()
			if json.parse(text) == OK and json.data is Dictionary:
				var pl = (json.data as Dictionary).get("paint_layers", [])
				if pl is Array:
					result = pl
	_paint_cache[map_name] = result
	return result

class_name BarArrayCartridge
extends RefCounted

## Base class for BarArray algorithm cartridges.
## The array is PackedFloat32Array of normalized values (0.0–1.0).
## Subclass this and override the methods below.

## --- Override these ---

## Return the algorithm's display name.
func get_name() -> String:
	return "Unknown"

## Category for grouping (sorting, signal, mathematical, data_structure).
func get_category() -> String:
	return "sorting"

## Color for a bar at given index/value. Override for custom palettes.
func get_bar_color(index: int, value: float, total: int) -> Color:
	# Default: height-mapped warm gradient (blue-low to amber-high)
	return Color(value * 0.9 + 0.1, 0.4 + value * 0.3, 1.0 - value * 0.6)

## Emission energy for a bar. Higher = brighter glow.
func get_bar_emission(index: int, value: float, total: int) -> float:
	return 0.3

## Called once. Return the starting array of float values (0.0–1.0).
func initialize(size: int) -> PackedFloat32Array:
	var arr = PackedFloat32Array()
	arr.resize(size)
	for i in range(size):
		arr[i] = float(i + 1) / float(size)
	# Fisher-Yates shuffle
	for i in range(size - 1, 0, -1):
		var j = randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
	return arr

## Advance one step. Return a result dictionary:
## {
##   "array": PackedFloat32Array,     — the (possibly modified) array
##   "comparisons": Array[Array],     — pairs [[i,j], ...] being compared this step
##   "swaps": Array[Array],           — pairs [[i,j], ...] that were swapped
##   "highlights": Dictionary,        — {index: Color} for custom highlights
##   "done": bool,                    — true when algorithm is finished
##   "description": String            — optional text ("Comparing 3 and 7")
## }
func step(arr: PackedFloat32Array) -> Dictionary:
	return {"array": arr, "comparisons": [], "swaps": [], "highlights": {}, "done": true, "description": ""}

## Called when player touches bar at index. Return modified array.
func on_bar_touch(arr: PackedFloat32Array, index: int) -> PackedFloat32Array:
	return arr

## Is the algorithm finished? Default checks sorted ascending.
func is_complete(arr: PackedFloat32Array) -> bool:
	for i in range(arr.size() - 1):
		if arr[i] > arr[i + 1]:
			return false
	return true

## Preferred array size (0 = use substrate default).
func get_preferred_size() -> int:
	return 0

## Preferred step interval in seconds (0 = use substrate default).
func get_preferred_interval() -> float:
	return 0.0

## How many steps to pre-compute on init.
func get_warmup_steps() -> int:
	return 0

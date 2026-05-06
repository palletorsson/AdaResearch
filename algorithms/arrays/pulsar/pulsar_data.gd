# pulsar_data.gd - Pulsar B1919+21 Radio Wave Data Generator
# The first pulsar discovered (1967) - its data became the iconic Joy Division album cover
#
# Each row = one pulse (one rotation of the neutron star)
# Each column = radio intensity at that time point
# Stacked rows = 2D array showing how the pulse varies over time
class_name PulsarData

# =============================================================================
# PULSAR DATA GENERATION
# =============================================================================

## Generate simplified pulsar data matching the characteristic B1919+21 shape
## Returns 2D array: [rows][cols] where each value is 0.0-1.0 intensity
static func get_pulsar_data(num_rows: int = 80, num_cols: int = 50) -> Array:
	var data: Array = []
	var rng = RandomNumberGenerator.new()
	rng.seed = 1919  # Deterministic - always same "pulsar"

	for row in range(num_rows):
		var pulse: Array = []
		var row_factor = float(row) / num_rows

		for col in range(num_cols):
			var col_factor = float(col) / num_cols

			# Base noise (radio static)
			var noise = rng.randf() * 0.08

			# Main pulse - centered, with slight drift
			var center = num_cols * 0.5 + sin(row * 0.15) * (num_cols * 0.08)
			var width = 3.0 + row_factor * 2.0  # Width increases slightly with each pulse
			var dist = abs(col - center)

			# Gaussian-like main pulse
			var main_pulse = exp(-dist * dist / (2.0 * width * width)) * 0.85

			# Secondary pulse (dispersion tail) - arrives later, weaker
			var tail_center = center + width * 2.5
			var tail_width = width * 1.5
			var tail_dist = abs(col - tail_center)
			var tail_pulse = 0.0
			if col > center:
				tail_pulse = exp(-tail_dist * tail_dist / (2.0 * tail_width * tail_width)) * 0.35

			# Occasional bright pulses (scintillation)
			var scintillation = 0.0
			if rng.randf() > 0.92 and dist < width * 1.5:
				scintillation = rng.randf() * 0.2

			# Pre-cursor (weak signal before main pulse)
			var precursor = 0.0
			var pre_center = center - width * 3.0
			if col < center and abs(col - pre_center) < width:
				precursor = exp(-pow(col - pre_center, 2) / (2.0 * width * width)) * 0.15

			var intensity = noise + main_pulse + tail_pulse + scintillation + precursor
			intensity = clampf(intensity, 0.0, 1.0)

			pulse.append(intensity)
		data.append(pulse)

	return data

## Convert pulsar data to binary (1s and 0s) based on threshold
static func get_binary_pulsar_data(threshold: float = 0.25, num_rows: int = 80, num_cols: int = 50) -> Array:
	var raw = get_pulsar_data(num_rows, num_cols)
	var binary: Array = []

	for row in raw:
		var binary_row: Array = []
		for val in row:
			binary_row.append(1 if val > threshold else 0)
		binary.append(binary_row)

	return binary

## Get a smaller sample of pulsar data for display purposes
static func get_pulsar_sample(rows: int = 8, cols: int = 16) -> Array:
	var full_data = get_pulsar_data(80, 50)
	var sample: Array = []

	var row_step = max(1, 80 / rows)
	var col_step = max(1, 50 / cols)

	for r in range(rows):
		var row_data: Array = []
		var src_row = mini(r * row_step, 79)
		for c in range(cols):
			var src_col = mini(c * col_step, 49)
			row_data.append(full_data[src_row][src_col])
		sample.append(row_data)

	return sample

## Get binary sample for simple display
static func get_binary_pulsar_sample(rows: int = 8, cols: int = 16, threshold: float = 0.25) -> Array:
	var sample = get_pulsar_sample(rows, cols)
	var binary: Array = []

	for row in sample:
		var binary_row: Array = []
		for val in row:
			binary_row.append(1 if val > threshold else 0)
		binary.append(binary_row)

	return binary

# =============================================================================
# EDUCATIONAL INFO
# =============================================================================

static func get_pulsar_info() -> Dictionary:
	return {
		"name": "PSR B1919+21",
		"discovered": "1967",
		"discoverer": "Jocelyn Bell Burnell",
		"location": "Cambridge, UK",
		"period": "1.337 seconds",
		"distance": "2283 light years",
		"cultural_note": "The stacked pulse visualization became the cover of Joy Division's 'Unknown Pleasures' (1979)",
		"array_connection": "Each pulse is an array of amplitude values. 80 pulses stacked = 2D array. The visualization IS the data structure."
	}

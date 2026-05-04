# PresenceGrid.gd — Pheromone memory of organism presence
#
# A 2D RGBA texture where each channel tracks a kingdom's presence:
#   R = tree (green-shift), G = creature (trails), B = flower (pollen), A = fungus (mycelium)
#
# Each frame: decay → diffusion → deposit from organisms.
# The ground shader reads this texture to express the landscape.
#
# Inspired by PhysarumGrid but with 4 independent channels and
# DNA-driven deposit intensity.
#
# Usage:
#   var grid := PresenceGrid.new(128, Vector2(50, 50))
#   grid.deposit(world_pos, kingdom, strength, radius)
#   grid.process(delta)
#   var texture: ImageTexture = grid.get_texture()

class_name PresenceGrid
extends RefCounted

# ─────────────────────────────────────────────────────────────
#  Configuration
# ─────────────────────────────────────────────────────────────

## Grid resolution (pixels per axis).
var resolution: int = 128

## World size this grid covers (meters).
var world_size: Vector2 = Vector2(50.0, 50.0)

## World origin offset (grid center in world space).
var world_offset: Vector2 = Vector2.ZERO

## Decay rate per second (0.98 = fades over ~3 seconds).
var decay_rate: float = 0.98

## Diffusion strength per step (0.0-1.0, how much spreads to neighbors).
var diffusion_strength: float = 0.25

## Maximum presence value per channel.
var max_presence: float = 1.0

## Process interval (seconds between grid updates).
var process_interval: float = 0.1


# ─────────────────────────────────────────────────────────────
#  State
# ─────────────────────────────────────────────────────────────

## The presence data as a flat array of Color values.
var _data: Array[Color] = []

## Scratch buffer for diffusion (avoids allocation per frame).
var _scratch: Array[Color] = []

## The GPU-readable texture (updated periodically).
var _texture: ImageTexture = null

## Timer for throttled processing.
var _timer: float = 0.0


# ═══════════════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════════════

func _init(res: int = 128, world_sz: Vector2 = Vector2(50.0, 50.0)) -> void:
	resolution = res
	world_size = world_sz
	var total: int = resolution * resolution
	_data.resize(total)
	_scratch.resize(total)
	var black := Color(0, 0, 0, 0)
	for i in total:
		_data[i] = black
		_scratch[i] = black
	_rebuild_texture()


# ═══════════════════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════════════════

## Call each frame. Throttles actual processing to process_interval.
func process(delta: float) -> void:
	_timer += delta
	if _timer < process_interval:
		return
	_timer -= process_interval

	_decay()
	_diffuse()
	_rebuild_texture()


# ═══════════════════════════════════════════════════════════════
# DEPOSIT — Organisms mark their presence
# ═══════════════════════════════════════════════════════════════

## Deposit presence at a world position for a specific kingdom.
## kingdom: 0=tree(R), 1=creature(G), 2=flower(B), 3=fungus(A)
func deposit(world_pos: Vector3, kingdom: int, strength: float, radius: float = 2.0) -> void:
	var grid_pos: Vector2i = _world_to_grid(Vector2(world_pos.x, world_pos.z))
	var grid_radius: int = ceili(radius / (world_size.x / float(resolution)))

	for dy in range(-grid_radius, grid_radius + 1):
		for dx in range(-grid_radius, grid_radius + 1):
			var gx: int = grid_pos.x + dx
			var gy: int = grid_pos.y + dy
			if gx < 0 or gx >= resolution or gy < 0 or gy >= resolution:
				continue

			# Circular falloff
			var dist: float = Vector2(float(dx), float(dy)).length()
			if dist > float(grid_radius):
				continue
			var falloff: float = 1.0 - (dist / float(grid_radius))
			falloff *= falloff  # Quadratic falloff

			var idx: int = gy * resolution + gx
			var c: Color = _data[idx]

			match kingdom:
				0: c.r = minf(c.r + strength * falloff, max_presence)  # Tree
				1: c.g = minf(c.g + strength * falloff, max_presence)  # Creature
				2: c.b = minf(c.b + strength * falloff, max_presence)  # Flower
				3: c.a = minf(c.a + strength * falloff, max_presence)  # Fungus

			_data[idx] = c


## Deposit from a CritterEntity (convenience).
func deposit_from_entity(entity_pos: Vector3, dna_kingdom: int,
		scent_strength: float, entity_scale: float) -> void:
	var strength: float = scent_strength * entity_scale * 0.3
	var radius: float = entity_scale * 2.0
	deposit(entity_pos, dna_kingdom, strength, radius)


## Carve presence at a world position — sterilises a region.
##
## The opposite of `deposit`. Multiplies every channel at affected cells
## by (1 - strength * falloff), so strength=1 fully clears at the centre
## and tapers to no effect at the radius. Used by the biome_paint layer's
## "-" token (and any future dynamic sterilisation effect).
##
## Falloff is quadratic, same shape as deposit, so a paint cell that
## carves and a paint cell that deposits cancel cleanly when overlapped.
func carve(world_pos: Vector3, strength: float, radius: float = 2.0) -> void:
	var grid_pos: Vector2i = _world_to_grid(Vector2(world_pos.x, world_pos.z))
	var grid_radius: int = ceili(radius / (world_size.x / float(resolution)))
	if grid_radius <= 0:
		grid_radius = 1
	for dy in range(-grid_radius, grid_radius + 1):
		for dx in range(-grid_radius, grid_radius + 1):
			var gx: int = grid_pos.x + dx
			var gy: int = grid_pos.y + dy
			if gx < 0 or gx >= resolution or gy < 0 or gy >= resolution:
				continue
			var dist: float = Vector2(float(dx), float(dy)).length()
			if dist > float(grid_radius):
				continue
			var falloff: float = 1.0 - (dist / float(grid_radius))
			falloff *= falloff
			var keep: float = 1.0 - clampf(strength * falloff, 0.0, 1.0)
			var idx: int = gy * resolution + gx
			var c: Color = _data[idx]
			c.r *= keep
			c.g *= keep
			c.b *= keep
			c.a *= keep
			_data[idx] = c


# ═══════════════════════════════════════════════════════════════
# DECAY — Presence fades over time
# ═══════════════════════════════════════════════════════════════

func _decay() -> void:
	for i in _data.size():
		var c: Color = _data[i]
		c.r *= decay_rate
		c.g *= decay_rate
		c.b *= decay_rate
		c.a *= decay_rate
		# Floor tiny values to zero
		if c.r < 0.005: c.r = 0.0
		if c.g < 0.005: c.g = 0.0
		if c.b < 0.005: c.b = 0.0
		if c.a < 0.005: c.a = 0.0
		_data[i] = c


# ═══════════════════════════════════════════════════════════════
# DIFFUSION — Presence spreads to neighbors
# ═══════════════════════════════════════════════════════════════

func _diffuse() -> void:
	var s: float = diffusion_strength
	var inv_s: float = 1.0 - s

	for y in resolution:
		for x in resolution:
			var idx: int = y * resolution + x
			var center: Color = _data[idx]

			# 4-tap neighbor average
			var sum := Color(0, 0, 0, 0)
			var count: int = 0
			if x > 0:
				sum += _data[idx - 1]; count += 1
			if x < resolution - 1:
				sum += _data[idx + 1]; count += 1
			if y > 0:
				sum += _data[idx - resolution]; count += 1
			if y < resolution - 1:
				sum += _data[idx + resolution]; count += 1

			if count > 0:
				var avg := Color(
					sum.r / float(count),
					sum.g / float(count),
					sum.b / float(count),
					sum.a / float(count)
				)
				_scratch[idx] = Color(
					center.r * inv_s + avg.r * s,
					center.g * inv_s + avg.g * s,
					center.b * inv_s + avg.b * s,
					center.a * inv_s + avg.a * s
				)
			else:
				_scratch[idx] = center

	# Swap buffers
	var tmp: Array[Color] = _data
	_data = _scratch
	_scratch = tmp


# ═══════════════════════════════════════════════════════════════
# TEXTURE OUTPUT
# ═══════════════════════════════════════════════════════════════

## Get the presence texture for shader binding.
func get_texture() -> ImageTexture:
	return _texture


## Rebuild the ImageTexture from current data.
func _rebuild_texture() -> void:
	var img := Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
	for y in resolution:
		for x in resolution:
			var idx: int = y * resolution + x
			img.set_pixel(x, y, _data[idx])

	if _texture == null:
		_texture = ImageTexture.create_from_image(img)
	else:
		_texture.update(img)


# ═══════════════════════════════════════════════════════════════
# QUERIES
# ═══════════════════════════════════════════════════════════════

## Get presence at a world position.
func get_presence(world_pos: Vector3) -> Color:
	var gp: Vector2i = _world_to_grid(Vector2(world_pos.x, world_pos.z))
	if gp.x < 0 or gp.x >= resolution or gp.y < 0 or gp.y >= resolution:
		return Color(0, 0, 0, 0)
	return _data[gp.y * resolution + gp.x]


## Get total presence intensity at a position (sum of all channels).
func get_total_presence(world_pos: Vector3) -> float:
	var c: Color = get_presence(world_pos)
	return c.r + c.g + c.b + c.a


## Get dominant kingdom at a position (0-3, or -1 if no presence).
func get_dominant_kingdom(world_pos: Vector3) -> int:
	var c: Color = get_presence(world_pos)
	var vals: Array[float] = [c.r, c.g, c.b, c.a]
	var best: int = -1
	var best_val: float = 0.01  # Minimum threshold
	for i in 4:
		if vals[i] > best_val:
			best_val = vals[i]
			best = i
	return best


# ═══════════════════════════════════════════════════════════════
# COORDINATE CONVERSION
# ═══════════════════════════════════════════════════════════════

func _world_to_grid(world_xz: Vector2) -> Vector2i:
	var normalized: Vector2 = (world_xz - world_offset + world_size * 0.5) / world_size
	return Vector2i(
		clampi(roundi(normalized.x * float(resolution)), 0, resolution - 1),
		clampi(roundi(normalized.y * float(resolution)), 0, resolution - 1)
	)

@tool
extends MeshInstance3D

# === EXPORTS ===
@export var MATERIAL: Material
@export var RESOLUTION: int = 50:
	set(value):
		RESOLUTION = value
		if is_inside_tree():
			generate()

@export var ISO_LEVEL := 0.0:
	set(value):
		ISO_LEVEL = value
		if is_inside_tree():
			generate()

@export var NOISE: FastNoiseLite
@export var FLAT_SHADED := false
@export var TERRAIN_TERRACE: int = 1
@export var TERRAIN_HEIGHT: float = 15.0:
	set(value):
		TERRAIN_HEIGHT = value
		if is_inside_tree():
			generate()
@export var USE_HEIGHTMAP_MODE: bool = true:
	set(value):
		USE_HEIGHTMAP_MODE = value
		if is_inside_tree():
			generate()
@export var PLANE_HEIGHT_OFFSET: float = 0.3:
	set(value):
		PLANE_HEIGHT_OFFSET = value
		if is_inside_tree():
			generate()

# === HOLE-FREE ENHANCEMENTS ===
@export_group("Hole-Free Settings")
@export var USE_ROBUST_INTERPOLATION: bool = true:
	set(value):
		USE_ROBUST_INTERPOLATION = value
		if is_inside_tree():
			generate()

@export var PREVENT_DEGENERATE_TRIANGLES: bool = true:
	set(value):
		PREVENT_DEGENERATE_TRIANGLES = value
		if is_inside_tree():
			generate()

@export var GENERATE: bool:
	set(value):
		var time = Time.get_ticks_msec()
		generate()
		var elapsed = (Time.get_ticks_msec()-time)/1000.0
		print("Terrain generated in: " + str(elapsed) + "s")

# === TRIANGULATION TABLE ===
const TRIANGULATIONS = [
	[],
	[0, 8, 3],
	[0, 1, 9],
	[1, 8, 3, 9, 8, 1],
	[1, 2, 10],
	[0, 8, 3, 1, 2, 10],
	[9, 2, 10, 0, 2, 9],
	[2, 8, 3, 2, 10, 8, 10, 9, 8],
	[3, 11, 2],
	[0, 11, 2, 8, 11, 0],
	[1, 9, 0, 2, 3, 11],
	[1, 11, 2, 1, 9, 11, 9, 8, 11],
	[3, 10, 1, 11, 10, 3],
	[0, 10, 1, 0, 8, 10, 8, 11, 10],
	[3, 9, 0, 3, 11, 9, 11, 10, 9],
	[9, 8, 10, 10, 8, 11],
	[4, 7, 8],
	[4, 3, 0, 7, 3, 4],
	[0, 1, 9, 8, 4, 7],
	[4, 1, 9, 4, 7, 1, 7, 3, 1],
	[1, 2, 10, 8, 4, 7],
	[3, 4, 7, 3, 0, 4, 1, 2, 10],
	[9, 2, 10, 9, 0, 2, 8, 4, 7],
	[2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4],
	[8, 4, 7, 3, 11, 2],
	[11, 4, 7, 11, 2, 4, 2, 0, 4],
	[9, 0, 1, 8, 4, 7, 2, 3, 11],
	[4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1],
	[3, 10, 1, 3, 11, 10, 7, 8, 4],
	[1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4],
	[4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3],
	[4, 7, 11, 4, 11, 9, 9, 11, 10],
	[9, 5, 4],
	[9, 5, 4, 0, 8, 3],
	[0, 5, 4, 1, 5, 0],
	[8, 5, 4, 8, 3, 5, 3, 1, 5],
	[1, 2, 10, 9, 5, 4],
	[3, 0, 8, 1, 2, 10, 4, 9, 5],
	[5, 2, 10, 5, 4, 2, 4, 0, 2],
	[2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8],
	[9, 5, 4, 2, 3, 11],
	[0, 11, 2, 0, 8, 11, 4, 9, 5],
	[0, 5, 4, 0, 1, 5, 2, 3, 11],
	[2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5],
	[10, 3, 11, 10, 1, 3, 9, 5, 4],
	[4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10],
	[5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3],
	[5, 4, 8, 5, 8, 10, 10, 8, 11],
	[9, 7, 8, 5, 7, 9],
	[9, 3, 0, 9, 5, 3, 5, 7, 3],
	[0, 7, 8, 0, 1, 7, 1, 5, 7],
	[1, 5, 3, 3, 5, 7],
	[9, 7, 8, 9, 5, 7, 10, 1, 2],
	[10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3],
	[8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2],
	[2, 10, 5, 2, 5, 3, 3, 5, 7],
	[7, 9, 5, 7, 8, 9, 3, 11, 2],
	[9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11],
	[2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7],
	[11, 2, 1, 11, 1, 7, 7, 1, 5],
	[9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11],
	[5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0],
	[11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0],
	[11, 10, 5, 7, 11, 5],
	[10, 6, 5],
	[0, 8, 3, 5, 10, 6],
	[9, 0, 1, 5, 10, 6],
	[1, 8, 3, 1, 9, 8, 5, 10, 6],
	[1, 6, 5, 2, 6, 1],
	[1, 6, 5, 1, 2, 6, 3, 0, 8],
	[9, 6, 5, 9, 0, 6, 0, 2, 6],
	[5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8],
	[2, 3, 11, 10, 6, 5],
	[11, 0, 8, 11, 2, 0, 10, 6, 5],
	[0, 1, 9, 2, 3, 11, 5, 10, 6],
	[5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11],
	[6, 3, 11, 6, 5, 3, 5, 1, 3],
	[0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6],
	[3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9],
	[6, 5, 9, 6, 9, 11, 11, 9, 8],
	[5, 10, 6, 4, 7, 8],
	[4, 3, 0, 4, 7, 3, 6, 5, 10],
	[1, 9, 0, 5, 10, 6, 8, 4, 7],
	[10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4],
	[6, 1, 2, 6, 5, 1, 4, 7, 8],
	[1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7],
	[8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6],
	[7, 3, 2, 7, 2, 4, 4, 2, 6, 4, 6, 5, 4, 5, 9],
	[3, 11, 2, 7, 8, 4, 10, 6, 5],
	[5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11],
	[0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6],
	[9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6],
	[8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6],
	[5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11],
	[0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7],
	[6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9],
	[10, 4, 9, 6, 4, 10],
	[4, 10, 6, 4, 9, 10, 0, 8, 3],
	[10, 0, 1, 10, 6, 0, 6, 4, 0],
	[8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10],
	[1, 4, 9, 1, 2, 4, 2, 6, 4],
	[3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4],
	[0, 2, 4, 4, 2, 6],
	[8, 3, 2, 8, 2, 4, 4, 2, 6],
	[10, 4, 9, 10, 6, 4, 11, 2, 3],
	[0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6],
	[3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10],
	[6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1],
	[9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3],
	[8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1],
	[3, 11, 6, 3, 6, 0, 0, 6, 4],
	[6, 4, 8, 11, 6, 8],
	[7, 10, 6, 7, 8, 10, 8, 9, 10],
	[0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10],
	[10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0],
	[10, 6, 7, 10, 7, 1, 1, 7, 3],
	[1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7],
	[2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9],
	[7, 8, 0, 7, 0, 6, 6, 0, 2],
	[7, 3, 2, 6, 7, 2],
	[2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7],
	[2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7],
	[1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11],
	[11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1],
	[8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6],
	[0, 9, 1, 11, 6, 7],
	[7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0],
	[7, 11, 6],
	[7, 6, 11],
	[3, 0, 8, 11, 7, 6],
	[0, 1, 9, 11, 7, 6],
	[8, 1, 9, 8, 3, 1, 11, 7, 6],
	[10, 1, 2, 6, 11, 7],
	[1, 2, 10, 3, 0, 8, 6, 11, 7],
	[2, 9, 0, 2, 10, 9, 6, 11, 7],
	[6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8],
	[7, 2, 3, 6, 2, 7],
	[7, 0, 8, 7, 6, 0, 6, 2, 0],
	[2, 7, 6, 2, 3, 7, 0, 1, 9],
	[1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6],
	[10, 7, 6, 10, 1, 7, 1, 3, 7],
	[10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8],
	[0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7],
	[7, 6, 10, 7, 10, 8, 8, 10, 9],
	[6, 8, 4, 11, 8, 6],
	[3, 6, 11, 3, 0, 6, 0, 4, 6],
	[8, 6, 11, 8, 4, 6, 9, 0, 1],
	[9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6],
	[6, 8, 4, 6, 11, 8, 2, 10, 1],
	[1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6],
	[4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9],
	[10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3],
	[8, 2, 3, 8, 4, 2, 4, 6, 2],
	[0, 4, 2, 4, 6, 2],
	[1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8],
	[1, 9, 4, 1, 4, 2, 2, 4, 6],
	[8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1],
	[10, 1, 0, 10, 0, 6, 6, 0, 4],
	[4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3],
	[10, 9, 4, 6, 10, 4],
	[4, 9, 5, 7, 6, 11],
	[0, 8, 3, 4, 9, 5, 11, 7, 6],
	[5, 0, 1, 5, 4, 0, 7, 6, 11],
	[11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5],
	[9, 5, 4, 10, 1, 2, 7, 6, 11],
	[6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5],
	[7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2],
	[3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6],
	[7, 2, 3, 7, 6, 2, 5, 4, 9],
	[9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7],
	[3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0],
	[6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8],
	[9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7],
	[1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4],
	[4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10],
	[7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10],
	[6, 9, 5, 6, 11, 9, 11, 8, 9],
	[3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5],
	[0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11],
	[6, 11, 3, 6, 3, 5, 5, 3, 1],
	[1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6],
	[0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10],
	[11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5],
	[6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3],
	[5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2],
	[9, 5, 6, 9, 6, 0, 0, 6, 2],
	[1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8],
	[1, 5, 6, 2, 1, 6],
	[1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6],
	[10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0],
	[0, 3, 8, 5, 6, 10],
	[10, 5, 6],
	[11, 5, 10, 7, 5, 11],
	[11, 5, 10, 11, 7, 5, 8, 3, 0],
	[5, 11, 7, 5, 10, 11, 1, 9, 0],
	[10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1],
	[11, 1, 2, 11, 7, 1, 7, 5, 1],
	[0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11],
	[9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7],
	[7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2],
	[2, 5, 10, 2, 3, 5, 3, 7, 5],
	[8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5],
	[9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2],
	[9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2],
	[1, 3, 5, 3, 7, 5],
	[0, 8, 7, 0, 7, 1, 1, 7, 5],
	[9, 0, 3, 9, 3, 5, 5, 3, 7],
	[9, 8, 7, 5, 9, 7],
	[5, 8, 4, 5, 10, 8, 10, 11, 8],
	[5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0],
	[0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5],
	[10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4],
	[2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8],
	[0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11],
	[0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5],
	[9, 4, 5, 2, 11, 3],
	[2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4],
	[5, 10, 2, 5, 2, 4, 4, 2, 0],
	[3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9],
	[5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2],
	[8, 4, 5, 8, 5, 3, 3, 5, 1],
	[0, 4, 5, 1, 0, 5],
	[8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5],
	[9, 4, 5],
	[4, 11, 7, 4, 9, 11, 9, 10, 11],
	[0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11],
	[1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11],
	[8, 3, 1, 8, 1, 4, 1, 10, 4, 7, 4, 11, 10, 11, 4],
	[4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2],
	[9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3],
	[11, 7, 4, 11, 4, 2, 2, 4, 0],
	[11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4],
	[2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9],
	[9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7],
	[3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10],
	[1, 10, 2, 8, 7, 4],
	[4, 9, 1, 4, 1, 7, 7, 1, 3],
	[4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1],
	[4, 0, 3, 7, 4, 3],
	[4, 8, 7],
	[9, 10, 8, 10, 11, 8],
	[3, 0, 9, 3, 9, 11, 11, 9, 10],
	[0, 1, 10, 0, 10, 8, 8, 10, 11],
	[3, 1, 10, 11, 3, 10],
	[1, 2, 11, 1, 11, 9, 9, 11, 8],
	[3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9],
	[0, 2, 11, 8, 0, 11],
	[3, 2, 11],
	[2, 3, 8, 2, 8, 10, 10, 8, 9],
	[9, 10, 2, 0, 9, 2],
	[2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8],
	[1, 10, 2],
	[1, 3, 8, 9, 1, 8],
	[0, 9, 1],
	[0, 3, 8],
	[]
]

# === HOLE-FREE VOXEL GRID ===
class VoxelGrid:
	var data: PackedFloat32Array
	var resolution: int
	
	func _init(resolution: int):
		self.resolution = resolution
		# HOLE-FREE: Extend grid by 1 for proper boundary handling
		var extended_size = (resolution + 2)
		self.data.resize(extended_size * extended_size * extended_size)
		self.data.fill(1.0)  # Default to solid for boundaries
	
	func read(x: int, y: int, z: int) -> float:
		# HOLE-FREE: Add boundary checks and consistent indexing
		var extended_res = resolution + 2
		if x < 0 or y < 0 or z < 0 or x >= extended_res or y >= extended_res or z >= extended_res:
			return 1.0  # Return solid for out-of-bounds
		return self.data[x + extended_res * (y + extended_res * z)]
	
	func write(x: int, y: int, z: int, value: float):
		var extended_res = resolution + 2
		if x < 0 or y < 0 or z < 0 or x >= extended_res or y >= extended_res or z >= extended_res:
			return  # Ignore out-of-bounds writes
		# HOLE-FREE: Clamp values to valid range
		self.data[x + extended_res * (y + extended_res * z)] = clamp(value, -1.0, 1.0)

# === CONSTANTS ===
const POINTS = [
	Vector3i(0, 0, 0), Vector3i(0, 0, 1), Vector3i(1, 0, 1), Vector3i(1, 0, 0),
	Vector3i(0, 1, 0), Vector3i(0, 1, 1), Vector3i(1, 1, 1), Vector3i(1, 1, 0),
]

const EDGES = [
	Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 0),
	Vector2i(4, 5), Vector2i(5, 6), Vector2i(6, 7), Vector2i(7, 4),
	Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7),
]

# === HOLE-FREE TERRAIN GENERATION ===
func generate():
	if not NOISE:
		print("⚠️ No noise assigned - creating default noise")
		NOISE = FastNoiseLite.new()
		NOISE.frequency = 0.1
	
	var voxel_grid = VoxelGrid.new(RESOLUTION)
	
	# HOLE-FREE: Generate terrain with proper boundary handling
	# Use offset of 1 to account for extended grid
	for x in range(RESOLUTION + 2):
		for y in range(RESOLUTION + 2):
			for z in range(RESOLUTION + 2):
				# Convert to world coordinates
				var world_x = x - 1  # Offset for extended grid
				var world_y = y - 1
				var world_z = z - 1
				
				var value: float
				if x == 0 or y == 0 or z == 0 or x == RESOLUTION + 1 or y == RESOLUTION + 1 or z == RESOLUTION + 1:
					# HOLE-FREE: Boundary voxels use consistent calculation
					value = calculate_terrain_value(world_x, world_y, world_z)
				else:
					# Interior voxels
					value = calculate_terrain_value(world_x, world_y, world_z)
				
				voxel_grid.write(x, y, z, value)
	
	# HOLE-FREE: March with proper boundary handling
	current_vertices.clear()  # Reset vertices array
	var triangle_count = 0
	var processed_cubes = 0
	
	# Process cubes from 1 to RESOLUTION (in extended grid coordinates)
	for x in range(1, RESOLUTION + 1):
		for y in range(1, RESOLUTION + 1):
			for z in range(1, RESOLUTION + 1):
				processed_cubes += 1
				var cube_triangles = march_cube_robust(x, y, z, voxel_grid)
				triangle_count += cube_triangles
				
	print("🌍 Generated %d triangles from %d cubes" % [triangle_count, processed_cubes])
	
	# Create mesh
	create_mesh_from_vertices(current_vertices)

func calculate_terrain_value(x: int, y: int, z: int) -> float:
	"""Calculate terrain value - now supports both heightmap and volumetric modes"""
	
	if USE_HEIGHTMAP_MODE:
		# 🎯 HEIGHTMAP MODE: 2.5D terrain like traditional games
		# Get ground height at this X,Z position using 2D noise
		var world_pos = Vector3(x, y, z)
		var ground_height = NOISE.get_noise_2d(world_pos.x, world_pos.z) * TERRAIN_HEIGHT
		
		# Add base offset to keep terrain above origin
		ground_height += TERRAIN_HEIGHT * 0.5
		
		# Calculate distance to surface
		var distance_to_surface = world_pos.y - ground_height
		
		# Create smooth transition zone for better marching cubes results
		if distance_to_surface <= -2.0:
			return 1.0  # Deep underground - solid
		elif distance_to_surface >= 2.0:
			return -1.0  # High in air - empty  
		else:
			# Smooth transition zone (-1 to +1 range)
			return -distance_to_surface * 0.5
			
	else:
		# 🌋 VOLUMETRIC MODE: 3D cave-like structures (original behavior)
		var noise_value = NOISE.get_noise_3d(x, y, z)
		var height_factor = (y + y % TERRAIN_TERRACE) / float(RESOLUTION) + PLANE_HEIGHT_OFFSET
		var terrain_value = noise_value + height_factor
		return clamp(terrain_value, -1.0, 1.0)

func march_cube_robust(x: int, y: int, z: int, voxel_grid: VoxelGrid) -> int:
	"""HOLE-FREE marching cubes implementation"""
	var tri = get_triangulation(x, y, z, voxel_grid)
	var triangle_count = 0
	
	# Process triangles in groups of 3
	for i in range(0, tri.size(), 3):
		if i + 2 >= tri.size():
			break
			
		var edge1 = tri[i]
		var edge2 = tri[i + 1]
		var edge3 = tri[i + 2]
		
		if edge1 < 0 or edge2 < 0 or edge3 < 0:
			break  # End of triangulation
		
		# Get triangle vertices
		var v1 = get_vertex_position(x, y, z, edge1, voxel_grid)
		var v2 = get_vertex_position(x, y, z, edge2, voxel_grid)
		var v3 = get_vertex_position(x, y, z, edge3, voxel_grid)
		
		# HOLE-FREE: Validate triangle
		if is_valid_triangle(v1, v2, v3):
			add_triangle_to_mesh(v1, v2, v3)
			triangle_count += 1
	
	return triangle_count

func get_vertex_position(x: int, y: int, z: int, edge_index: int, voxel_grid: VoxelGrid) -> Vector3:
	"""Get interpolated vertex position on edge"""
	var point_indices = EDGES[edge_index]
	var p0 = POINTS[point_indices.x]
	var p1 = POINTS[point_indices.y]
	var pos_a = Vector3(x + p0.x, y + p0.y, z + p0.z)
	var pos_b = Vector3(x + p1.x, y + p1.y, z + p1.z)
	
	if USE_ROBUST_INTERPOLATION:
		return calculate_robust_interpolation(pos_a, pos_b, voxel_grid)
	else:
		return calculate_simple_interpolation(pos_a, pos_b, voxel_grid)

func calculate_robust_interpolation(a: Vector3, b: Vector3, voxel_grid: VoxelGrid) -> Vector3:
	"""HOLE-FREE interpolation with edge case handling"""
	var val_a = voxel_grid.read(int(a.x), int(a.y), int(a.z))
	var val_b = voxel_grid.read(int(b.x), int(b.y), int(b.z))
	
	# Ensure values are in valid range
	val_a = clamp(val_a, -1.0, 1.0)
	val_b = clamp(val_b, -1.0, 1.0)
	
	var density_diff = abs(val_b - val_a)
	
	# Handle edge cases that cause holes
	if density_diff < 0.001:
		return (a + b) * 0.5  # Nearly identical values
	
	if abs(val_a - ISO_LEVEL) < 0.001:
		return a  # Exact threshold at point A
	if abs(val_b - ISO_LEVEL) < 0.001:
		return b  # Exact threshold at point B
	
	# Standard interpolation with safety checks
	var t = (ISO_LEVEL - val_a) / (val_b - val_a)
	t = clamp(t, 0.0, 1.0)
	
	# Additional safety for extreme cases
	if val_a >= ISO_LEVEL and val_b >= ISO_LEVEL:
		return (a + b) * 0.5  # Both solid
	elif val_a < ISO_LEVEL and val_b < ISO_LEVEL:
		return (a + b) * 0.5  # Both air
	
	return a + t * (b - a)

func calculate_simple_interpolation(a: Vector3, b: Vector3, voxel_grid: VoxelGrid) -> Vector3:
	"""Original interpolation for comparison"""
	var val_a = voxel_grid.read(int(a.x), int(a.y), int(a.z))
	var val_b = voxel_grid.read(int(b.x), int(b.y), int(b.z))
	
	if abs(val_b - val_a) < 0.000001:
		return (a + b) * 0.5  # Prevent division by zero
	
	var t = (ISO_LEVEL - val_a) / (val_b - val_a)
	t = clamp(t, 0.0, 1.0)
	return a + t * (b - a)

func is_valid_triangle(v1: Vector3, v2: Vector3, v3: Vector3) -> bool:
	"""HOLE-FREE: Validate triangle to prevent degenerates"""
	if not PREVENT_DEGENERATE_TRIANGLES:
		return true
	
	# Check for degenerate triangles (vertices too close)
	var min_distance = 0.000001
	if (v1.distance_squared_to(v2) < min_distance or
		v2.distance_squared_to(v3) < min_distance or
		v3.distance_squared_to(v1) < min_distance):
		return false
	
	# Check for valid normal
	var edge1 = v2 - v1
	var edge2 = v3 - v1
	var normal = edge1.cross(edge2)
	
	return normal.length_squared() > min_distance

# Global variables for mesh building
var current_vertices: PackedVector3Array = []

func add_triangle_to_mesh(v1: Vector3, v2: Vector3, v3: Vector3):
	"""Add triangle to mesh arrays"""
	current_vertices.append(v1)
	current_vertices.append(v2)
	current_vertices.append(v3)

func create_mesh_from_vertices(vertices: PackedVector3Array):
	"""Create final mesh from vertices"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	if FLAT_SHADED:
		surface_tool.set_smooth_group(-1)
	
	for vert in current_vertices:
		surface_tool.add_vertex(vert)
	
	surface_tool.generate_normals()
	surface_tool.index()
	
	if MATERIAL:
		surface_tool.set_material(MATERIAL)
	
	mesh = surface_tool.commit()
	
	print("✅ Mesh created with %d vertices" % current_vertices.size())
	current_vertices.clear()

func get_triangulation(x: int, y: int, z: int, voxel_grid: VoxelGrid) -> Array:
	"""Get triangulation with HOLE-FREE boundary handling"""
	var idx = 0b00000000
	
	# HOLE-FREE: Use consistent coordinate system
	var coords = [
		Vector3i(x, y, z),
		Vector3i(x, y, z+1),
		Vector3i(x+1, y, z+1),
		Vector3i(x+1, y, z),
		Vector3i(x, y+1, z),
		Vector3i(x, y+1, z+1),
		Vector3i(x+1, y+1, z+1),
		Vector3i(x+1, y+1, z)
	]
	
	for i in range(8):
		var coord = coords[i]
		var value = voxel_grid.read(coord.x, coord.y, coord.z)
		if value < ISO_LEVEL:
			idx |= (1 << i)
	
	if idx >= 0 and idx < TRIANGULATIONS.size():
		return TRIANGULATIONS[idx]
	else:
		return [] 

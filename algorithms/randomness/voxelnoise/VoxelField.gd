# VoxelField.gd
extends Node
class_name VoxelField

@export var seed: int = 1337
@export var scale: float = 1.0          # world meters per voxel step
@export var iso: float = -0.3            # isosurface value

var noise := FastNoiseLite.new()

func _ready():
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.08

func field(p: Vector3) -> float:
	# Example: layered noise + a soft sphere — replace with your own
	var n = 0.7 * noise.get_noise_3d(p.x, p.y, p.z)
	n += 0.3 * noise.get_noise_3d(p.x*2.3, p.y*2.3, p.z*2.3)
	var sphere = 1.0 - p.length()/20.0
	return n + 0.5*sphere

func grad(p: Vector3, e: float = 0.5) -> Vector3:
	# central differences
	return Vector3(
		field(p + Vector3(e,0,0)) - field(p - Vector3(e,0,0)),
		field(p + Vector3(0,e,0)) - field(p - Vector3(0,e,0)),
		field(p + Vector3(0,0,e)) - field(p - Vector3(0,0,e))
	) / (2.0*e)

func interesting_score(center: Vector3) -> float:
	# One simple, effective heuristic:
	# - strong gradient near isosurface -> sharp features
	# - high absolute Laplacian (2nd derivative trace) -> curvature/ridges
	var g = grad(center)
	var gnorm = g.length()
	var e := 0.75
	var lap = field(center + Vector3(e,0,0)) + field(center - Vector3(e,0,0)) + field(center + Vector3(0,e,0)) + field(center - Vector3(0,e,0)) + field(center + Vector3(0,0,e)) + field(center - Vector3(0,0,e)) - 6.0*field(center)
	lap = abs(lap)
	# emphasize locations where F ~ iso
	var near_iso = 1.0 / (0.25 + pow(abs(field(center) - iso), 2.0))
	return (0.6*gnorm + 0.4*lap) * near_iso

func find_interesting_rois(search_aabb: AABB, coarse: int, keep: int) -> Array:
	"""Find regions of interest within the search AABB using a coarse grid"""
	print("VoxelField: Searching for ROIs in ", search_aabb, " with coarse=", coarse, " keep=", keep)
	var rois = []
	var step = search_aabb.size / coarse
	print("VoxelField: Step size = ", step)
	
	# Sample the field on a coarse grid
	for x in range(coarse):
		for y in range(coarse):
			for z in range(coarse):
				var pos = search_aabb.position + Vector3(x, y, z) * step
				var score = interesting_score(pos)
				
				# Create ROI data
				var roi = {
					"cell": AABB(pos, step),
					"score": score,
					"center": pos + step * 0.5
				}
				rois.append(roi)
	
	print("VoxelField: Generated ", rois.size(), " ROIs, sample scores: ")
	for i in range(min(5, rois.size())):
		print("  Sample ROI ", i, ": score=", rois[i].score, " field=", field(rois[i].center))
	
	# Sort by score (highest first) and keep only the top 'keep' ROIs
	rois.sort_custom(func(a, b): return a.score > b.score)
	
	print("VoxelField: Top scores after sorting:")
	for i in range(min(keep, rois.size())):
		print("  ROI ", i, ": score=", rois[i].score)
	
	# Return only the top ROIs
	var result = []
	for i in range(min(keep, rois.size())):
		result.append(rois[i])
	
	return result

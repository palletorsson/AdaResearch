extends "res://algorithms/randomness/entropy_jar/entropy_jar.gd"
## Prepared still specimens reuse the interactive jar's actual layout and measure.
## The original pick-up-and-shake jar remains in Random_Entropy.
func _ready() -> void:
	jar_radius=0.13;jar_height=0.34;particle_radius=0.012;pedestal_height=0.68
	particle_seed=435
	super._ready()
	_jar_body.enabled=false
	_jar_body.get_node("JarLid").hide()
	set_physics_process(false)

func _create_pedestal() -> void:pass
func _create_dock() -> void:pass
func _create_labels() -> void:pass
func _create_vr_controls() -> void:pass
func _update_display() -> void:pass

func radial_entropy() -> float:
	var bins: Array=[[0,0],[0,0]]
	var threshold: float=(jar_radius-jar_wall_thickness-particle_radius)*0.6
	for colour in 2:
		for particle in (_particles_a if colour==0 else _particles_b):
			var p: Vector3=particle.position
			bins[int(Vector2(p.x,p.z).length()>=threshold)][colour]+=1
	var result:=0.0
	for counts in bins:
		var total: float=counts[0]+counts[1]
		if total>0:
			for n in counts:
				if n>0:
					var probability: float=n/total
					result-=total/80.0*probability*log(probability)/log(2.0)
	return result

func positions() -> Array:
	var result: Array=[]
	for group in [_particles_a,_particles_b]:
		for particle in group:result.append(particle.position)
	return result

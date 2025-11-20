extends Node

var text = '''[center][font_size=28][b]Flocking (Boids)[/b][/font_size][/center]
[center][i]Decentralized Coordination, Emergent Choreography[/i][/center]

**Flocking creates coordinated group motion from three simple rules.**

**Craig Reynolds (1986)** - simulated bird flocks ("boids") with local rules.

[hr]

[b]Three Rules[/b]

**1. Separation** - avoid crowding neighbors
**2. Alignment** - steer toward average heading of neighbors
**3. Cohesion** - steer toward average position of neighbors

[color=yellow][b]Code:[/b][/color]
[code]
func separate(boid, neighbors):
    var steer = Vector3.ZERO
    for n in neighbors:
        if n.position.distance_to(boid.position) < separation_radius:
            steer += (boid.position - n.position).normalized()
    return steer

func align(boid, neighbors):
    var avg_velocity = Vector3.ZERO
    for n in neighbors:
        avg_velocity += n.velocity
    avg_velocity /= neighbors.size()
    return (avg_velocity - boid.velocity).normalized()

func cohere(boid, neighbors):
    var center = Vector3.ZERO
    for n in neighbors:
        center += n.position
    center /= neighbors.size()
    return (center - boid.position).normalized()

# Update boid
var separation = separate(boid, neighbors) * w_separation
var alignment = align(boid, neighbors) * w_alignment
var cohesion = cohere(boid, neighbors) * w_cohesion

boid.acceleration = separation + alignment + cohesion
boid.velocity += boid.acceleration
boid.position += boid.velocity
[/code]

**No leader.** Each boid follows local rules. **Emergent coordination.**

[hr]

[b]Queer Flocking[/b]

**Flocking is decentralized queer sociality:**
- **No central authority** (no alpha, no leader)
- **Local awareness** (only nearby boids matter)
- **Balance proximity + autonomy** (cohere but don't collide)

**Queer communities flock:**
- **Separation** = boundaries (personal space, consent)
- **Alignment** = shared values (political alignment without uniformity)
- **Cohesion** = staying together (collective survival)

**Emergent choreography** - complex group behavior from simple individual rules.

[hr]

[color=cyan][b]Summary:[/b][/color]
Flocking: three rules (separation, alignment, cohesion). No leader, local awareness only. Emergent coordination. Queer flocking: decentralized sociality, balancing autonomy + community, collective survival through local rules. Choreography without choreographer.

'''

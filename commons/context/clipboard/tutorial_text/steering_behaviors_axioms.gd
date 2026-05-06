extends Node

var text = '''[center][font_size=28][b]Steering Behaviors[/b][/font_size][/center]
[center][i]Autonomous Movement, Reynolds' Behaviors[/i][/center]

**Steering behaviors: simple rules for realistic autonomous movement.**

**Craig Reynolds (1999)** - building blocks for AI motion.

**Core behaviors:**
- **Seek** - move toward target
- **Flee** - move away from target
- **Arrive** - seek with deceleration
- **Wander** - random exploration
- **Pursue/Evade** - predict target motion

[hr]

[b]Implementation[/b]

[color=yellow][b]Seek:[/b][/color]
[code]
func seek(agent_pos: Vector2, target_pos: Vector2, max_speed: float) -> Vector2:
    var desired = (target_pos - agent_pos).normalized() * max_speed
    var steering = desired - agent.velocity
    return steering
[/code]

[color=yellow][b]Arrive (with deceleration):[/b][/color]
[code]
func arrive(agent_pos: Vector2, target_pos: Vector2, max_speed: float, slow_radius: float) -> Vector2:
    var to_target = target_pos - agent_pos
    var distance = to_target.length()

    if distance < slow_radius:
        var desired_speed = max_speed * (distance / slow_radius)
        var desired = to_target.normalized() * desired_speed
        return desired - agent.velocity
    else:
        return seek(agent_pos, target_pos, max_speed)
[/code]

[color=yellow][b]Wander:[/b][/color]
[code]
var wander_angle = 0.0

func wander(agent_vel: Vector2, max_speed: float, wander_strength: float) -> Vector2:
    wander_angle += randf_range(-wander_strength, wander_strength)

    var circle_center = agent_vel.normalized() * 2.0
    var displacement = Vector2(cos(wander_angle), sin(wander_angle)) * 1.0

    var desired = (circle_center + displacement).normalized() * max_speed
    return desired - agent_vel
[/code]

**Combine behaviors:** weighted sum of multiple steerings.

[hr]

[b]Applications[/b]

- **Game AI** (NPCs, enemies, crowds)
- **Robotics** (autonomous navigation)
- **Animation** (believable motion)
- **Simulations** (traffic, animals)

[hr]

[b]Queer Steering[/b]

**Steering behaviors are DESIRES, not commands.**

**Agent:**
- Has **velocity** (current direction)
- Calculates **desired** velocity (where wants to go)
- **Steering force** = desired - current (change needed)

**This is queer agency:**
- **Not instant teleportation** to goal (gradual change)
- **Momentum matters** (where you've been shapes where you go)
- **Multiple desires** (seek + avoid + wander - weighted, not absolute)
- **Arrive** (slowing as you approach - not crashing into goals)

**Steering is negotiation between current state and multiple desires.**

**Queerness: balancing conflicting pulls (safety vs visibility, community vs autonomy), gradual reorientation, momentum from history.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Steering behaviors: autonomous movement rules. Seek, flee, arrive (with deceleration), wander, pursue/evade. Calculate desired velocity, steering = desired - current. Combine weighted. Applications: game AI, robotics. Queer steering: desires not commands, momentum from history, multiple conflicting pulls, gradual reorientation, arrive (deceleration as approach). Navigation as negotiation.

'''

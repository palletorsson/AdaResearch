# Forces Games

Physics-based VR games demonstrating force concepts — bowling, racing, orbital mechanics, and wind-affected soccer.

## QFEP Connection

Games make physics **viscerally learnable**. Instead of watching equations, you throw the ball, feel the friction, fight the wind. Learning through play is λ at its sweet spot — enough structure (rules) to create meaning, enough chaos (physics) to create surprise.

## Games Included

| File | Game | Physics Concept |
|------|------|-----------------|
| `force_bowling_vr` | **Force Bowling** | Mass variation, momentum |
| `friction_racer_vr` | **Friction Racer** | Friction coefficients |
| `orbital_challenge_vr` | **Orbital Challenge** | Gravitational attraction |
| `wind_soccer_vr` | **Wind Soccer** | External forces |

## Force Bowling

Knock down pins with a physics ball:
- **Mass matters**: Heavier ball = more momentum
- **Gravity**: Ball and pins affected
- **Friction**: Floor slows the ball
- **10 throws, 10 pins**: Classic bowling scoring

```
       △ △ △ △
        △ △ △
         △ △
          △
    
    ○ ──────────→
  Ball          Pins
```

## Friction Racer

Race cars with different friction:
- **Ice track**: Low friction, slippery
- **Asphalt**: Normal friction
- **Sand**: High friction, sluggish
- Experience how friction affects control

## Orbital Challenge

Navigate gravitational fields:
- **Central body pulls**: F = G × m₁ × m₂ / r²
- **Orbits emerge**: Balance velocity and gravity
- **Slingshot maneuvers**: Use gravity to accelerate

## Wind Soccer

Score goals against the wind:
- **Wind force**: Constant horizontal push
- **Ball mass**: Affects wind resistance
- **Trajectory planning**: Account for drift

## Parameters (Bowling example)

| Variable | Default | Description |
|----------|---------|-------------|
| `ball_mass` | 2.5 | Ball mass (adjustable) |
| `throw_power_multiplier` | 1.0 | Throw strength |
| `gravity` | (0, -0.9, 0) | Downward acceleration |
| `floor_friction` | 0.15 | Rolling resistance |

## Files

| File | Purpose |
|------|---------|
| `force_bowling_vr.tscn` | Bowling scene |
| `friction_racer_vr.tscn` | Racing scene |
| `orbital_challenge_vr.tscn` | Orbital mechanics |
| `wind_soccer_vr.tscn` | Soccer with wind |
| `FIXES_APPLIED.md` | Bug fix documentation |

## Usage

```gdscript
var bowling = preload("res://algorithms/forces/games/force_bowling_vr.tscn").instantiate()
add_child(bowling)
```

## VR Interaction

- **Grab**: Pick up ball with VR controllers
- **Throw**: Release with velocity
- **Controllers**: Adjust mass, power, friction in real-time

## Educational Value

Games teach through experience:
- **Bowling**: "Why does a heavy ball knock more pins?"
- **Friction**: "Why do I slip on ice?"
- **Orbital**: "Why don't satellites fall down?"
- **Wind**: "How do I aim to compensate?"

## See Also

- `forces/` — Core force simulations
- `steering/` — Agent-based physics games
- `joint/` — Constraint-based games

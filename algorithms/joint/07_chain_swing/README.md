# Chain Swing

Multi-link chain connected by pin joints — a swing set demonstrating compound pendulum physics.

## QFEP Connection

A chain is **distributed constraint** — each link has full rotational freedom (pin joint), but together they form a coordinated system. The chain doesn't move randomly; it swings with characteristic modes. Many local freedoms (E) produce global patterns (F) through physical coupling.

## Structure

```
    ╔════════════╗  ← Top beam (static)
        │
        ○  ← Pin joint (anchor)
        │
       [═]  ← Link (rigid body)
        │
        ○  ← Pin joint
        │
       [═]  ← Link (rigid body)
        │
        ○  ← Pin joint
        │
    ╔═══════╗  ← Seat (rigid body)
```

## Components

| Part | Type | Purpose |
|------|------|---------|
| Frame (L/R) | StaticBody3D | Support structure |
| Top beam | StaticBody3D | Horizontal support |
| Anchor | StaticBody3D | Joint attachment point |
| Links | RigidBody3D | Chain segments |
| Seat | RigidBody3D | Swing seat |

## Joints

All joints are `PinJoint3D`:
- **Anchor → Top link**: Attaches chain to frame
- **Link → Link**: Connects chain segments
- **Bottom link → Seat**: Attaches seat to chain

## Physics

Chain swing differs from simple pendulum:
- **Multiple modes**: Can swing, twist, wobble
- **Energy transfer**: Between links
- **Damping**: Angular and linear damping on links

## Files

| File | Purpose |
|------|---------|
| `chain_swing.gd` | Demo implementation |
| `*.tscn` | Scene file |

## Usage

```gdscript
var swing = preload("res://algorithms/joint/07_chain_swing/chain_swing.tscn").instantiate()
add_child(swing)
# Swing starts with initial nudge
```

## VR Experience

Watch the swing move. Notice how the chain links rotate independently but coordinate into a swinging motion. Push the seat and observe the wave propagating up the chain. The physics feels natural because chains follow these exact rules.

## See Also

- `02_double_pendulum/` — Chaotic compound pendulum
- `shared/` — Base class documentation
- `physicssimulation/springsystem/` — Spring-connected masses

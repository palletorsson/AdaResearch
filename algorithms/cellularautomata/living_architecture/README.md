# Living Architecture

Buildings that breathe, decay, and regrow.

## QFEP Connection

Living architecture embodies **φΔE(S,t)** — the rate of entropy change over time. The bridge decays under your weight (entropy increase) and regrows when left alone (self-organization). Architecture becomes ecology, structure becomes process.

## The Decaying Bridge

A bridge that responds to presence:
- **Decay**: Cells near the player lose health
- **Regrow**: Cells far from player slowly heal
- **Death threshold**: Fully decayed cells become transparent/passable

This creates a cat-and-mouse with the architecture — stand still and the ground disappears beneath you.

## Parameters

```gdscript
@export var length: int = 20           # Bridge length (cells)
@export var width: int = 4             # Bridge width (cells)
@export var cell_size: float = 1.0     # Cell dimensions
@export var decay_speed: float = 0.1   # Health lost per tick near player
@export var regrow_speed: float = 2.0  # Health regained per tick when distant
@export var decay_radius: float = 2.0  # Distance at which decay occurs

# Colors
@export var color_healthy: Color = Color(0.2, 0.8, 0.2)  # Green
@export var color_decayed: Color = Color(0.2, 0.2, 0.2)  # Gray
@export var color_dead: Color = Color(0.0, 0.0, 0.0, 0.0) # Invisible
```

## Cellular Automata Rules

Each cell has health (0.0 to 1.0):
- If player within `decay_radius`: health -= `decay_speed`
- If player distant: health += `regrow_speed` (slower)
- Health < 0: cell dies (collision disabled)
- Health > 0: cell alive (collision enabled)

Color interpolates from healthy → decayed → dead.

## VR Experience

Walk across the living bridge. Feel the ground soften beneath your feet. Keep moving or fall through. This is architecture that demands attention.

## Files

- `decaying_bridge.gd` — Bridge simulation
- `decaying_bridge.tscn` — Scene setup

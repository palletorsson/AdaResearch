# MorphoBody

A body that grows limbs through reaction-diffusion morphogenesis — Turing patterns determining where appendages emerge.

## QFEP Connection

Morphogenesis is **QFEP in biology** — two chemicals (activator/inhibitor) create stable patterns through their interaction. Alan Turing discovered this in 1952: the same math explains leopard spots, zebra stripes, and limb positioning. Order (body plan) emerges from chemical chaos.

## How It Works

```
┌─────────────────────────────────────┐
│                                     │
│     Reaction-Diffusion Grid (32³)   │
│                                     │
│       ┌───┐                         │
│       │ B │ ← High B concentration  │
│       └───┘   triggers bud growth   │
│                                     │
│    ╭──────────╮                     │
│    │  TORSO   │                     │
│    ╰──────────╯                     │
│       │   │                         │
│       │   │  ← Limbs grow from buds │
│       ▼   ▼                         │
│                                     │
└─────────────────────────────────────┘
```

1. **Gray-Scott reaction-diffusion** runs in 3D grid
2. **Bud detection**: When chemical B exceeds threshold, spawn limb bud
3. **Limb growth**: Buds extend outward over time
4. **Result**: Organic, self-organized body plan

## Gray-Scott Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `feed` | 0.037 | Chemical A feed rate |
| `kill` | 0.065 | Chemical B kill rate |
| `diff_a` | 1.0 | Diffusion rate of A |
| `diff_b` | 0.5 | Diffusion rate of B |
| `dt` | 1.0 | Time step |

These values produce spot patterns — the classic morphogen configuration.

## Growth Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `grid_n` | 32 | Reaction-diffusion grid resolution |
| `steps_per_frame` | 3 | RD iterations per frame |
| `bud_threshold` | 0.28 | B concentration to trigger limb |
| `max_buds` | 4 | Maximum limb count |
| `torso_radius` | (0.5, 0.8, 0.4) | Central body size |
| `limb_max_len` | 0.9 | Maximum limb length |
| `limb_radius` | 0.06 | Limb thickness |
| `growth_speed` | 0.35 | Limb extension rate |

## Files

| File | Purpose |
|------|---------|
| `morphobody.tscn` | Scene |
| `morphobody.gd` | RD simulation and limb growth |

## Usage

```gdscript
var body = preload("res://algorithms/computationalbiology/morphobody/morphobody.tscn").instantiate()
body.max_buds = 6  # More limbs
body.feed = 0.04   # Different pattern
add_child(body)
```

## Biological Background

Turing's morphogenesis theory (1952) explains:
- **Why zebras have stripes**: Activator-inhibitor waves
- **Why fingers are spaced**: Reaction-diffusion in limb buds
- **Why leopards have spots**: Same math, different parameters

The body doesn't "know" where limbs should go — the pattern emerges from chemistry.

## VR Experience

Watch the body grow its own limbs in real-time. The torso appears first, then chemical patterns form, then limbs sprout where concentrations peak. Each run produces a different creature — same rules, different random seed, different body.

## See Also

- `cellularautomata/` — Other pattern formation
- `emergentsystems/ecosystemsimulation2/` — Full ecosystem with morphology
- `computationalbiology/` — Other biological simulations

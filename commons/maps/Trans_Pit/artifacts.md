# Trans Pit — Artifacts
*Transformation: What Stays the Same When Everything Changes · F_order · 2 artifacts*

> Three transformations, three ways to die. A corridor where pushing stones shove you over fire pits. An arena with revolving walls sweeping toward the edge. A room where the center grows and forces you out. Translation displaces, rotation sweeps, scale pressures. The pit below is the same in every case — only the geometry of your removal changes.

The map, read through what it holds — its artifacts in the order you meet them:

## Pusher Block
![Pusher Block](/scene-catalog/pusher_block.png)

A red cube that translates back and forth along one axis, physically pushing the player into pits. Uses AnimatableBody3D for proper physics collision. The translation transformation made dangerous.

`pusher_block`

## Grower Block
![Grower Block](/scene-catalog/grower_block.png)

A cube that pulses between tiny and huge, physically pushing the player as it grows. When small you can pass, when large it fills the corridor and squeezes you into the pit. Color shifts from green (safe) to red (danger).

`grower_block`

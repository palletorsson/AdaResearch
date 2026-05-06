extends Node

var text = '''
[center][b]Karl Sims Style Evolution[/b][/center]
[center][i]Two-legged walkers learn to move[/i][/center]

[hr]
[b]What Happens[/b]
- Random genomes set hip swing amplitude/frequency/phase.
- Walkers run for GENERATION_DURATION seconds.
- Fitness = forward progress + travel distance + slight height bonus.
- Best genomes breed; others are replaced.

[hr]
[b]Inspector Controls[/b]
- random_seed: deterministic evolution.
- enable_random_restart: inject fresh genomes each generation.
- enable_debug_prints: log fitness to console.

[hr]
[b]Try This[/b]
1. Toggle random restart to keep exploration fresh.
2. Edit constants in the script (torque, duration) to change behaviour.
3. Pause and inspect hinge joints to see motor limits.

[hr]
[i]Tip[/i]
The demo runs continuously; watch several generations for emergent gaits.
'''

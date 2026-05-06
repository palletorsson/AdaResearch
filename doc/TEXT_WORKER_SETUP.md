# Distributed Text Worker Setup

This repo now has a local Claude Code worker that can split text-editing across three machines without overlapping work.

Files involved:

- `tools/claude_cli_rewriter.py`: core worker
- `tools/run_text_worker.ps1`: Windows wrapper
- `tools/run_text_worker.sh`: macOS/Linux wrapper

## Recommended topology

Use `git`, not a shared writable folder.

Why:

- each machine keeps its own Claude quota and session state
- edits are isolated until you commit
- merge conflicts stay manageable if each machine gets a different shard

## One-time setup on each machine

1. Clone the same repo revision on all three machines.
2. Install Python 3.
3. Install Claude Code and confirm `claude` works in a terminal.
4. Pull the commit that includes the worker scripts.
5. Confirm the queue loads:

Windows:

```powershell
python tools\claude_cli_rewriter.py --file critical.md --dry-run --limit 3
```

Mac:

```bash
python3 tools/claude_cli_rewriter.py --file critical.md --dry-run --limit 3
```

If `python` is not available on macOS, replace it with `python3` in the shell wrapper below.

## Three-machine shard plan

Use striped shards instead of start/end ranges. That way the split stays stable even if the queue changes slightly.

- Main PC: `--shard-index 0 --shard-count 3`
- Windows PC: `--shard-index 1 --shard-count 3`
- Mac: `--shard-index 2 --shard-count 3`

Preview each shard:

Windows:

```powershell
.\tools\run_text_worker.ps1 -File critical.md -ShardIndex 1 -ShardCount 3 -DryRun -ListMaps
```

Mac:

```bash
chmod +x tools/run_text_worker.sh
./tools/run_text_worker.sh --file critical.md --shard-index 2 --shard-count 3 --dry-run --list-maps
```

## Run the workers

Windows PC:

```powershell
.\tools\run_text_worker.ps1 -File critical.md -ShardIndex 1 -ShardCount 3
```

Mac:

```bash
chmod +x tools/run_text_worker.sh
./tools/run_text_worker.sh --file critical.md --shard-index 2 --shard-count 3
```

Main PC:

```powershell
.\tools\run_text_worker.ps1 -File critical.md -ShardIndex 0 -ShardCount 3
```

Useful variants:

- change file role: `-File technical.md` or `--file technical.md`
- dry-run only: `-DryRun` or `--dry-run`
- list selected maps only: `-ListMaps` or `--list-maps`
- use contiguous slice instead: `-Start 0 -End 9` or `--start 0 --end 9`

## Current `critical.md` shard assignments

Shard 0:

- `Primitives_Polythedra`
- `WaveFunctions_Intro`
- `Noise_One`
- `Fractal_CrossSequence`
- `SoftBodies_Soft_Body_Deformation`
- `SwarmIntelligence_Boids_Algorithm`
- `ML_Gradient_Landscape`
- `ML_Sequence_Memory`
- `Brouwer_Intuitionism`
- `SpeculativeComputation_Rhizome_Network`
- `GT_Network_Analysis`

Shard 1:

- `Trans_Introduction`
- `Random_Definition`
- `CA_AgentsCircuits`
- `LSystems_Growth`
- `SoftBodies_Cloth_Physics`
- `SwarmIntelligence_Agent_Based_Modeling_ABM`
- `ML_Classification`
- `ML_Generative`
- `Crisis_Synthesis`
- `GT_Foundations`
- `GT_Spanning_Trees`

Shard 2:

- `Trans_RotationSpectacle`
- `Random_Space`
- `Fractal_Recursion`
- `LSystems_Grammars_And_Curves`
- `Topology_Entropy_Morphogenesis`
- `SwarmIntelligence_Particle_Swarm_Optimization`
- `ML_Perception`
- `ML_Synthesis`
- `QFEP_Sandbox`
- `GT_Pathfinding`

## Safe workflow

1. `git pull`
2. Run your shard
3. Inspect `git diff`
4. Commit on that machine
5. Push
6. Merge sequentially back on the main machine

Do not have two machines write the same shard at once.

## Notes

- The worker writes directly into `commons/maps/.../<file>`.
- It restores the original file if a regeneration attempt does not beat the prior composite score.
- `tools/claude_cli_rewriter_log.json` records what each machine processed.

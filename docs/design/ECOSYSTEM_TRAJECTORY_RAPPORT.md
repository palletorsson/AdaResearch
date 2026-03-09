# Ecosystem Trajectory Rapport

## Where We Are, What's Missing, and How to Get to the Endgame

---

## Executive Summary

Ada Research has a fully designed 19-stage ecosystem progression. Three managers (EcosystemManager, HazardManager, CatalystCapabilityManager) track world state, creature relationships, and player capabilities across the entire curriculum spine. The **control plane** (data, signals, save/load) is complete and functional. The **data plane** (visual consumers, audio wiring, creature behavior, terrain generation) is almost entirely disconnected. The endgame exists as narrative content and config data but not as playable experience.

The gap is clear: we have the skeleton of a living world but none of the flesh. This rapport maps the integration path from current state to a coherent, playable ecosystem trajectory ending in an open landscape.

---

## The Three-Manager Triad (What Works)

All three managers live as autoload singletons. They read from `soft_stages.json` (19 stages) and listen to `MapProgressionManager.sequence_completed`.

### EcosystemManager
- Tracks: allow_flags, vegetation_density, terrain_mode, nature_kingdoms, ambient_preset, LOD
- Emits: `allow_flags_changed`, `vegetation_config_changed`, `terrain_mode_changed`, `nature_kingdoms_changed`, `ecosystem_stage_advanced`
- Status: **Fully functional.** Nobody listens to it.

### HazardManager
- Tracks: per-creature personality (foe/wary/neutral/curious/friend), spawn permissions, max concurrent, spawner behavior
- Emits: `hazard_personality_changed`, `hazard_befriended`
- Status: **Fully functional.** Creatures ignore personality. ProximitySpawner doesn't call request_spawn_permission().

### CatalystCapabilityManager
- Tracks: capacity level (L1-L6), hand_verbs, movement_abilities, catalyst_modes, bracelet
- Emits: `capability_changed`, `capacity_level_changed`
- Status: **Fully functional.** No interaction system queries it for gating.

---

## The 19-Stage Arc (What's Designed)

### Phase 1: Order (Stages 1-5)
Sterile lab. Flat terrain. Grey palette. Player observes and touches. Hazards dormant. No vegetation.

### Phase 2: Oscillation (Stages 4, 6)
Color arrives. Flowers appear. Hazards activate. Perception shifts.

### Phase 3: Entropy (Stages 7-9)
Randomness, noise, cellular automata. Fungus kingdom. Terrain breaks from flat to noise to growth. Ecology emerges. Spawners become aggressive.

### Phase 4: Edge of Chaos (Stages 10-12)
Fractals, L-systems, procedural generation. Creature kingdom appears. Self-generating terrain. Vegetation density 0.6-0.8.

### Phase 5: Integration (Stages 13-15)
Soft bodies, swarm intelligence, machine learning. First creature befriending (miura_crawler -> friend). Flight unlocked. Density 0.85-0.95.

### Phase 6: Synthesis / Endgame (Stages 16-19)
Foundations crisis introduces contradiction. QFEP Laboratory makes the formula interactive. Post-crisis applies limits. Graph theory makes ALL remaining creatures friends. Density 1.0.

---

## The Endgame Gap

### What exists:
- Sequence definitions for stages 16-19 (foundationscrisis, qfeplaboratory, postfoundationscrisis, graphtheory)
- Narrative content (blurb.md, intent.md) for most endgame maps
- Config data in soft_stages.json for all endgame stages
- Lab evolution manifest documenting post-crisis Lab states
- Crisis_Synthesis map_data.json (the one fully built endgame map)

### What does NOT exist:
- **No open landscape / world-beyond-the-Lab scene.** The game is entirely indoor.
- **No door/portal to an exterior world.** After completing everything, the player is in the same Lab.
- **No sequel hook.** Progression simply stops.
- **No visual world transformation.** The Lab looks the same at stage 19 as stage 1.
- **No ambient audio progression.** 10 preset names designed, 0 wired.
- **No terrain generation responding to ecosystem state.**
- **No vegetation spawning from density/kingdom data.**
- **No creature behavior changes from personality.**

---

## The Integration Path: 8 Steps to a Living World

### Step 1: Wire Ambient Audio (Small, High Impact)
Create 10 ambient preset JSON files matching the soft_stages names. Connect EcosystemManager's `_current_ambient_preset` to AmbientSoundController. When a stage advances, crossfade to the new ambient. This is the cheapest way to make progression feel alive.

**Files to modify:** AmbientSoundController.gd, EcosystemManager.gd
**Files to create:** 10 audio preset JSONs (empty_lab, perception_shift, environmental_entropy, ecology_emerges, recursive_world, living_matter, collective_creatures, adaptive_world, contradictory_world, tunable_becoming)

### Step 2: Wire Hazard Personality to Creature Behavior
HazardCreatureBase already has PATROL/CHASE/ATTACK states. Add personality-aware behavior: friends don't attack, curious creatures approach but don't damage, wary creatures flee. Read personality from HazardManager on spawn.

**Files to modify:** HazardCreatureBase.gd, ProximitySpawner.gd

### Step 3: Connect Nature System to EcosystemManager
The nature_system/ has flower, tree, fungus, creature morphology generators. Connect them to EcosystemManager's `is_kingdom_allowed()` and vegetation_density. Spawn flora/fauna procedurally per map based on current ecosystem state.

**Files to modify:** nature_spawner.gd (or create new)
**Query:** `EcosystemManager.get_vegetation_density()`, `is_kingdom_allowed("flower")`, etc.

### Step 4: Implement Terrain Mode Switching
Create a terrain generator that responds to `terrain_mode_changed`. Four modes: flat (plane), noise (Perlin heightmap), growth (cellular automata terrain), self_generating (WFC/procgen terrain).

**Files to create:** EcosystemTerrainGenerator.gd
**Signal:** Listen to `EcosystemManager.terrain_mode_changed`

### Step 5: Gate Player Abilities
Connect XR locomotion providers to `CatalystCapabilityManager.is_movement_available()`. Climb only unlocks at stage 8, flight at stage 14. Gate hand_verbs through the same system.

**Files to modify:** Locomotion providers, interaction scripts

### Step 6: Build Missing Endgame Maps
Create map_data.json grids for the foundationscrisis (6 maps), qfeplaboratory (6 maps), and graphtheory (8 maps) sequences. These are the playable content.

### Step 7: Create the Open Landscape Scene
This is the culmination. After completing graphtheory (stage 19), a door in the Lab opens to an exterior scene. The landscape is:
- Generated from the full ecosystem state (density 1.0, all kingdoms, self-generating terrain)
- Populated with all befriended creatures (they wander peacefully)
- Ambient: `tunable_becoming` with all layers active
- Both hostile and promising: the terrain is wild, procedurally grown, not curated
- A clear horizon line: the promise that there's more to explore
- Interactive: the player has flight, all verbs, full QFEP parameter control
- A single artifact at the center: the QFEP formula as a physical object the player can hold

**Files to create:** OpenLandscape.tscn, open_landscape.gd, map_data.json

### Step 8: The Sequel Hook
The open landscape has a second door on the far horizon. Walking toward it triggers a final beat: the world zooms out, revealing the Lab was inside a larger structure. The camera pulls back to show the QFEP formula floating in space with all its terms glowing. Fade to title card: "Ada Research: Volume Two."

---

## Presenting Ecosystem During Gameplay

The ecosystem should be visible to the player at every stage, not just at the end. Here's how each phase surfaces:

| Phase | What the Player Sees |
|-------|---------------------|
| Order (1-5) | Bare Lab. Grey. Static. The only living thing is the miura_crawler, dormant in the corner. |
| Oscillation (4, 6) | Flowers appear on surfaces. Color bleeds into the world. A creature watches from a distance. |
| Entropy (7-9) | Mushrooms grow on walls. The floor undulates with noise. Creatures chase. The Lab feels alive and slightly dangerous. |
| Edge of Chaos (10-12) | Fractal ferns cover every surface. L-system trees branch through corridors. The world generates itself. New creatures emerge. |
| Integration (13-15) | Soft matter deforms underfoot. Flocks of creatures swirl through rooms. The miura_crawler follows the player like a companion. Flight. |
| Synthesis (16-19) | Paradox terrain. The Lab walls dissolve. Creatures are friends. The QFEP formula floats in the air. The door to the landscape opens. |

---

## Priority Order

1. **Ambient audio** (Step 1) — 2-3 hours. Instant emotional payoff.
2. **Hazard personality** (Step 2) — 3-4 hours. The foe-to-friend arc becomes real.
3. **Nature spawning** (Step 3) — 4-6 hours. The world visibly grows.
4. **Endgame maps** (Step 6) — 8-12 hours. Playable content.
5. **Terrain switching** (Step 4) — 4-6 hours. Ground transforms.
6. **Ability gating** (Step 5) — 2-3 hours. Progression has teeth.
7. **Open landscape** (Step 7) — 8-12 hours. The culminating moment.
8. **Sequel hook** (Step 8) — 2-4 hours. The promise.

**Total estimated work: 35-50 hours for a complete, integrated ecosystem trajectory from sterile lab to open world.**

---

## Conclusion

The architecture is sound. The data is comprehensive. The 19-stage progression from order to synthesis is well-designed and philosophically coherent. What's missing is the wiring — connecting the managers that track state to the systems that render state. Once that wiring is in place, the player will experience a world that genuinely emerges around them, creatures that transform from threats to companions, and a Lab that dissolves into an open landscape where everything they've learned becomes a living, breathing world.

The endgame isn't just a reward. It's proof that the QFEP formula works: from order (F), through entropy (E), at the edge of chaos (lambda), the world that emerges (phi * DeltaE) is both hostile and promising. That's the game's thesis made physical.

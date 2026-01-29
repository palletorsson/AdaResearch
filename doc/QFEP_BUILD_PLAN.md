# QFEP Maps Build Plan

**STATUS: ✅ ALL ARTIFACTS BUILT**

Last updated: Session complete

## Status Summary

### ✅ ALREADY BUILT & WORKING
| Artifact | Scene Path | Notes |
|----------|------------|-------|
| `lambda_slider` | `res://commons/interfaces/qfep/lambda_slider.tscn` | Just improved grabbability |
| `phi_slider` | `res://commons/interfaces/qfep/phi_slider.tscn` | Just improved grabbability |
| `qfep_formula_3d` | `res://commons/interfaces/qfep/formula_display/qfep_formula_3d.tscn` | ✅ |
| `qfep_reactor` | `res://commons/interfaces/qfep/qfep_reactor.tscn` | ✅ |
| `qfep_oscilloscope` | `res://commons/interfaces/qfep/qfep_oscilloscope.tscn` | ✅ |
| `entropy_meter` | `res://commons/interfaces/qfep/entropy_meter.tscn` | ✅ |
| `edge_detector` | `res://commons/interfaces/qfep/edge_detector.tscn` | ✅ |
| `phase_cube` | `res://commons/interfaces/qfep/phase_cube.tscn` | ✅ |
| `reactive_particle_field` | `res://commons/interfaces/qfep/reactive_particle_field.tscn` | ✅ |
| `dark_sphere` | `res://commons/primitives/sphere/dark_sphere.tscn` | ✅ Already exists |
| `crystalcluster` | `res://commons/primitives/crystalcluster/crystalcluster.tscn` | Can use for `crystal_cluster` |

### ✅ DEFINED IN REGISTRY (should work via GridArtifactRegistry)
These use `grab_sphere_point_with_color.tscn` with color params:
| Artifact | Color | Notes |
|----------|-------|-------|
| `grab_sphere_F` | `#4080FF` (blue) | Order/pattern drive |
| `grab_sphere_E` | `#FF6060` (red) | Entropy/freedom |
| `grab_sphere_lambda` | `#40FF80` (green) | Entropy drive parameter |
| `grab_sphere_phi` | `#FF80FF` (magenta) | Rate sensitivity |

### 🔧 EXISTING BUT CAN REUSE/ALIAS
| Map Reference | Use Existing | Notes |
|---------------|--------------|-------|
| `crystal_cluster` | `crystalcluster` | Same thing, add alias |
| `reactive_particles` | `reactive_particle_field` | Same thing, add alias |
| `snap_cube_puzzle` | `snap_tetrahedron_puzzle` | Use existing snap puzzle |
| `snap_tetra_puzzle` | `snap_tetrahedron_puzzle` | Already exists |

---

## 🛠️ NEEDS TO BE BUILT

### Priority 1: QFEP_Introduction (Entry Point)
**All term spheres are defined** - just verify `grab_sphere_point_with_color.tscn` supports the color param from registry.

### Priority 2: QFEP_F_Term (Order)
| Artifact | Description | Approach |
|----------|-------------|----------|
| ~~`snap_cube_puzzle`~~ | Pattern completion | Use existing `snap_tetrahedron_puzzle` |
| ~~`snap_tetra_puzzle`~~ | Pattern completion | Already exists |
| ~~`crystal_cluster`~~ | Ordered crystals | Use existing `crystalcluster` |
| ~~`dark_sphere`~~ | The trap of pure order | Already exists |

**Status: DONE** - just need aliases in registry

### Priority 3: QFEP_E_Term (Entropy)
| Artifact | Description | Approach |
|----------|-------------|----------|
| `random_cubes` | Chaotic cube arrangement | Simple: spawn cubes with random positions/rotations |
| `particle_chaos` | Chaotic particle field | GPUParticles3D with high spread, random velocity |

**Effort: LOW** - 2 simple procedural objects

### Priority 4: QFEP_Lambda_Spectrum (The Corridor)
| Artifact | Description | Approach |
|----------|-------------|----------|
| `crystal_formation` | λ=0 zone | Use `crystalcluster` with blue tint |
| `ordered_grid` | Low λ zone | Array of aligned cubes |
| `edge_particles` | λ≈0.4 zone | `reactive_particle_field` at edge settings |
| `complexity_pattern` | Edge zone | Turing pattern shader or cellular automata |
| `dissolving_form` | High λ zone | Mesh with dissolve shader |
| `chaos_particles` | λ=1 zone | GPUParticles3D with maximum chaos |

**Effort: MEDIUM** - some can reuse existing, some need new

### Priority 5: QFEP_Phi_Term (Change Sensitivity)
| Artifact | Description | Approach |
|----------|-------------|----------|
| `rigid_sculpture` | Conservative side | Static geometric form, frozen |
| `fluid_form` | Embrace side | Animated morph/flow mesh |
| `preserved_pattern` | φ<0 | Static pattern that resists change |
| `transforming_pattern` | φ>0 | Continuously morphing pattern |

**Effort: MEDIUM** - need animation/morph systems

### Priority 6: QFEP_Edge_Of_Chaos (The Sweet Spot)
| Artifact | Description | Approach |
|----------|-------------|----------|
| `turing_pattern` | Reaction-diffusion | Existing `reaction_diffusion` algorithm? |
| `edge_core` | Central visualization | Enhanced `qfep_reactor` or new orb |
| `emergence_zone` | Where complexity lives | `reactive_particle_field` tuned to edge |

**Effort: MEDIUM** - can leverage existing reaction-diffusion work

### Priority 7: QFEP_Sandbox (Full Control)
| Artifact | Description | Approach |
|----------|-------------|----------|
| ~~`reactive_particles`~~ | Responds to sliders | Use `reactive_particle_field` |

**Status: DONE** - just alias

---

## Build Order Recommendation

### Phase 1: Registry Aliases (15 min)
Add aliases to `qfep.json` for existing artifacts:
- `crystal_cluster` → `crystalcluster`
- `reactive_particles` → `reactive_particle_field`
- `snap_cube_puzzle` → `snap_tetrahedron_puzzle`

### Phase 2: Simple Procedural Objects (1-2 hours)
1. `random_cubes` - spawn cubes with random transforms
2. `particle_chaos` - GPUParticles3D preset
3. `ordered_grid` - aligned cube array
4. `chaos_particles` - high-entropy particle preset

### Phase 3: Lambda Spectrum Visuals (2-3 hours)
1. `crystal_formation` - crystalcluster with λ=0 styling
2. `dissolving_form` - mesh with dissolve shader
3. `edge_particles` - reactive_particle_field tuned to λ≈0.4

### Phase 4: Phi Term Contrasts (2-3 hours)
1. `rigid_sculpture` - static form
2. `fluid_form` - animated morph
3. `preserved_pattern` / `transforming_pattern` - pattern pair

### Phase 5: Edge of Chaos Experience (2-3 hours)
1. `turing_pattern` - reaction-diffusion visualization
2. `edge_core` - central reactive orb
3. `emergence_zone` - particle field at edge settings

---

## Files to Modify

1. `res://commons/artifacts/registry/qfep.json` - Add aliases and new entries
2. `res://commons/interfaces/qfep/` - New artifact scripts
3. Potentially `res://algorithms/patterngeneration/reactiondiffusion/` - Turing patterns

---

## Questions to Resolve

1. Does `grab_sphere_point_with_color.tscn` properly read `default_params.color` from registry?
2. Should Lambda Spectrum objects respond dynamically to player Z position?
3. Do we want audio feedback tied to λ and φ values?

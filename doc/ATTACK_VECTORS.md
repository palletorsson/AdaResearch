# Attack Vectors — Quality Dimensions for Improvement

Not categories. Not substrates. These are specific quality axes that cut across ALL artifacts. An artifact might need 3 of these simultaneously. Each vector is: what to detect, what to fix, how to verify.

Pick a vector. Find every artifact that needs it. Fix them all. Move to the next vector.

---

## 1. Slider Precision
**Detect:** Code has `slider_horizontal` but: no `slider_moved` signal connected, no value label, range too wide/narrow, slider not reachable at VR standing height.
**Fix:** Connect signal, add Label3D showing current value, tune range to meaningful parameter bounds, position at 1.0-1.4m height.
**Verify:** Move slider end-to-end. Does the visualization change smoothly? Can you read the value? Can you reach it without bending?

## 2. Button Feedback
**Detect:** Code has `push_button` but: no visual press state, no confirmation of action, no sound.
**Fix:** Add press animation (scale or color flash), add Label3D confirming action ("Step 42", "Reset"), add click sound.
**Verify:** Press the button. Did you FEEL it worked? Could someone watching know you pressed it?

## 3. Grabbable Response
**Detect:** Code has `XRToolsPickable` but: no highlight on approach, no haptic on grab, object too small or too large to grip naturally, no visual change while held.
**Fix:** Add glow-on-hover (emission ramp), add haptic pulse on grab, scale to hand-comfortable size (0.05-0.3m), change state while held (living paper runs while grabbed).
**Verify:** Reach toward it. Did it invite you? Grab it. Did it feel right? Hold it. Does something happen?

## 4. Label Readability
**Detect:** Any `Label3D` in code. Check: font_size < 16 (too small for VR), no billboard mode (faces wrong direction), positioned behind or above eyeline, white-on-white or dark-on-dark.
**Fix:** font_size >= 20 for primary readouts, billboard = BILLBOARD_ENABLED, position at 1.2-1.8m height, high contrast (white on dark bg, or amber on dark).
**Verify:** Stand at arm's length. Can you read every label without squinting or turning your head?

## 5. Material Expressiveness
**Detect:** Default StandardMaterial3D with no emission, roughness=0.5, metallic=0. Flat gray.
**Fix:** Apply the energy hierarchy: frame=0.5, bodies=1.0-1.5, protagonist=2.0, markers=2.5+. Color by role. Metallic 0.3, roughness 0.4 for active objects.
**Verify:** Screenshot on dark background. Can you instantly tell what's the main thing, what's structure, what's annotation?

## 6. Trail & History
**Detect:** Artifact has `_process()` with moving objects but no trail. The algorithm unfolds over time but a screenshot shows nothing.
**Fix:** ImmediateMesh trail on the most expressive position (foot, tip, edge, center). 200 points, mover color at 30% alpha, UNSHADED.
**Verify:** Screenshot after 3 seconds. Does the trail SHOW the algorithm? Is the trail the most informative element in the image?

## 7. Animation Clarity
**Detect:** Has `_process()` animation but: too fast to follow, too slow to notice, no way to pause/step, multiple things moving at once with no visual hierarchy.
**Fix:** Tune speed to human-readable pace. Add step mode if appropriate. Use color/size/glow to create hierarchy — one thing moves first, your eye follows.
**Verify:** Watch for 5 seconds. Can you describe what's happening to someone who isn't looking?

## 8. VR Scale
**Detect:** Objects smaller than 0.05m radius (invisible at arm's length) or larger than 10m (overwhelming, can't see the whole thing).
**Fix:** Minimum visible sphere: 0.06m radius. Maximum single-view artifact: ~5m. Larger installations need walkthrough design, not stand-and-look.
**Verify:** Stand at default spawn distance. Can you see everything you need to see without turning around?

## 9. Sound Design
**Detect:** Almost everything is silent. 1 of 114 randomness artifacts has audio.
**Fix:** Three tiers: (a) Event sounds — click, pop, thud on state change. (b) Ambient tone — low drone for running simulations. (c) Spatial audio — sound positioned at the source in 3D.
**Verify:** Close your eyes. Can you tell the artifact is running? Can you tell WHERE it is?

## 10. Color Communication
**Detect:** All objects same color, or colors don't map to anything meaningful.
**Fix:** Color encodes role (mover=cyan, frame=gray, constraint=orange) OR parameter (low=blue, high=red) OR state (active=bright, settled=dim). Never both. Pick one system per artifact.
**Verify:** Point at any colored element. Can you say what the color MEANS?

## 11. Joint & Constraint Visibility
**Detect:** Physics joints (PinJoint3D, HingeJoint3D, etc.) are invisible by default. Player sees boxes floating near each other with no visible connection.
**Fix:** Glowing marker spheres at joint positions (orange, r=0.12, energy=2.5). Optionally: axis indicators showing which DOF are free vs locked.
**Verify:** Screenshot. Can you see WHERE the constraint is and WHAT it constrains?

## 12. Process Legibility
**Detect:** A simulation runs but you can't tell what step it's on, whether it's converging, or what the critical parameter currently is.
**Fix:** Label3D showing iteration count, current value of critical parameter, convergence metric. Update every frame.
**Verify:** Glance at the readout. Do you know what's happening without reading the code?

## 13. Mesh Quality
**Detect:** Custom ArrayMesh with wrong normals, back-face culled flat quads, z-fighting with ground, LOD issues.
**Fix:** CULL_DISABLED for flat custom quads. Normals consistent. Z-offset for overlapping surfaces. Reasonable polygon count for 90fps.
**Verify:** Rotate around the artifact. Any flickering, disappearing faces, or visual artifacts?

## 14. Controller Mapping
**Detect:** Artifact claims interaction but: no input action connected, uses keyboard-only controls (ui_left/ui_right), or VR controller mapping conflicts with movement system.
**Fix:** Map to VR-appropriate inputs. Check against the hidden dependencies clause (AX=flight, trigger=grab). Use `XRToolsInteractableArea` for point-and-click.
**Verify:** In VR, can you interact without accidentally flying or teleporting?

## 15. Capture Quality
**Detect:** Screenshot is empty, too far, too close, wrong camera, or doesn't tell the story.
**Fix:** Load capture-debug flow. Disable artifact cameras. Use zoom sweep. Wait for trails.
**Verify:** Does the screenshot work as a catalog image? Would you click on it?

---

## How to Use Attack Vectors

1. **Pick a vector** (e.g., "Slider Precision")
2. **Scan all artifacts** for the detection pattern (grep for `slider_horizontal`)
3. **Count**: how many have sliders? how many are broken?
4. **Fix one** — develop the pattern
5. **Batch the rest** — parallel agents with the pattern
6. **Verify all** — screenshot comparison before/after
7. **Move to next vector**

## Detection Scripts

```bash
# Find all artifacts with sliders
grep -rl "slider_horizontal" algorithms/ --include="*.gd" | wc -l

# Find all artifacts with buttons
grep -rl "push_button" algorithms/ --include="*.gd" | wc -l

# Find all artifacts with Label3D
grep -rl "Label3D" algorithms/ --include="*.gd" | wc -l

# Find all artifacts with no emission (flat materials)
grep -rL "emission_enabled" algorithms/ --include="*.gd" | wc -l

# Find all artifacts with physics joints
grep -rl "Joint3D" algorithms/ --include="*.gd" | wc -l

# Find all artifacts with trails
grep -rl "ImmediateMesh" algorithms/ --include="*.gd" | wc -l
```

## Vector Priority (estimated impact)

| Vector | Artifacts affected | Effort | Impact |
|---|---|---|---|
| Material Expressiveness | ~1200 (most have flat materials) | Low | High — biggest visual upgrade |
| Trail & History | ~400 (have _process, no trail) | Medium | High — screenshots go from nothing to informative |
| Label Readability | ~300 (have labels, many unreadable) | Low | Medium — VR quality of life |
| Capture Quality | ~1400 (most screenshots missing or bad) | Low | High — catalog usability |
| Slider Precision | ~80 (have sliders) | Medium | Medium — interaction quality |
| Button Feedback | ~60 (have buttons) | Medium | Medium — interaction quality |
| Sound Design | ~1650 (almost all silent) | High | High — VR immersion |
| VR Scale | ~100 (too small or too big) | Low | Medium — visibility |

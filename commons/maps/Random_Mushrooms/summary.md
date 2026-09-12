# Random_Mushrooms - Map Summary

## Overview
A six-metre raised bed of mushrooms in the middle of the hall and a specimen table at its north edge. The bed is an arrangement made from draws — six templates, eighty candidates gated by a noise threshold, a facing and a size for each accepted one, a ring and two clusters placed on purpose — and the table shows the six templates, prints the population's counts, rings every copy of one template or one kind in the bed, and regrows the population from a named seed. Question: which parts of this population were allowed to vary?

## Spatial Layout
- **Dimensions**: 13 × 13 cells; the interior x 1–10 at floor level, a one-metre platform strip along x 11 (rows 3–9)
- **Doors**: north at x 5–7 (row 0), south at (6,12); the teleporter at (8,12), floored in the museum by `museum.floor_cells`
- **The bed**: x 3.5–9.5, z 4.5–10.5, its ground lifted 0.18 m clear of the floor and boarded
- **The table**: 1.5 × 0.5 × 0.9 m, its face at z ≈ 3.1, facing the north door; the visitor's spot at (6.5, 2.3)
- **The walk**: north door → west margin (x 1–3.5) → south margin (z 10.5–12) → south door

## Key Elements

### Interactables
- **mushrooms** (6,7), `mushrooms:180#stand:specimen#size:6` — the primary: the bed and its table
- **reaction_diffusion_intro** (9,11) — the book pearl's hero line: a Gray-Scott field, spots from two rates
- **bubbles_random** (10,4), **bubble_particles** (10,9) — bubbles in the east nook
- **random_number_book_page_collection** (10,7) — the RAND Corporation's 1955 digits, cascading
- **dark_sphere** (10,2) — the anchor, north-east

### The table's controls
- **SHOW** — the next template; a magenta ring and a pin on every copy of it in the bed, and a ring on its disc
- **KIND** — scattered (blue) · rings (green) · clusters (violet) · rejected candidates (grey) · back to the template
- **SIZE** — the size rule off under the same seed (every mushroom at 1), and on again
- **REGROW** — the same population again, ground and all
- **NEW SEED** — another population, another ground

### The plate (six lines)
seed and REGROW's policy · candidates, accepted, rejected · rings (placed), clusters (placed), templates · the SHOW or KIND line with its count · the size rule or SIZE off · glow, lit of the cap, mushrooms

## Learning Sequence
1. From the north door, the table first: six specimens on discs, the plate, the panel
2. Pick two related mushrooms in the bed; SHOW until their template is named and ringed; they differ in facing and size only
3. REGROW: the same population returns; SIZE: the same population at one size; NEW SEED: another
4. KIND rejected: grey marks where candidates were refused by the noise threshold
5. KIND rings: the circle was an instruction with a centre, a radius and a count; clusters have a rule of their own
6. Round the west margin and along the south to the door; the bubbles, the digits and the reaction-diffusion field in the east and south

## Museum
`wall_height 3`, `gate_depth_rows 0`, `artifact_placement map`, `sculpture_clear_rects [[3,1,10,12]]`, `floor_cells [[8,12]]`. The dealt lane neither slides nor shrinks the map's bodies; dealt plinths stay out of cells 3–9 × 1–11.

## Connection to Sequence
- **Follows**: Random_Gaussian — many draws under one law
- **Precedes**: Random_Game — a draw that decides an outcome
- **Theme**: an arrangement is the sum of several kinds of draw, and each can be read separately

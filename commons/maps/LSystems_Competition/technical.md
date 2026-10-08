# Competition — rewriting after a shared-state update

Architecture distinguished records from constructed access. This hall adds a mutable environment and a schedule. The primary is the registered ForestCompetition scene in algorithms/lsystems/Ecosystem; the opt-in CompetitionLesson uses a second, manually advanced instance of the same script as its model. Ordinary placements retain the five-strategy forest. The original forest remains visible behind the lesson in this hall.

## What STEP computes

The controlled pair has roots (-0.175,0,0) and (0.175,0,0), identical F axioms, the existing WIDE_DENSE rule F → F[+F]F[-F][F], diameter 0.02, health 1 and multiplier 1. These are explicit comparison conditions; the original wide strategy uses multiplier 0.9. Both use the original consumption, allometry, competition, rewriting and turtle methods. No random draw enters this pair setup.

The field is 20×20 with 0.35 m cells across 7 m. Every cell starts at 0.6. The sampling radius in cells is clamp(ceil(crown_radius / CELL_SIZE)+1,1,4); it defines a square, not a root disk. Initial crown_radius = 0.1 + sqrt(0.02)*1.5 ≈ 0.3121, giving radius 2 and 25 cells. Root grid addresses are (9,10) and (10,10). Twenty sampled cells overlap. Uptake sums the per-cell amounts, without normalizing by sample count.

At multiplier 1, the first attempt takes 25×0.6×0.15 = 2.25. The second takes (20×0.51 + 5×0.6)×0.15 = 1.98. Swapping the first index exchanges those readings. The first complete pair leaves the same field under the reversed order: both consume the same fractions at their addresses, but the allocation differs. Further generations can change the sampling radius and diameter, so that simple equality must not be assumed indefinitely.

_grow_step wraps its index, checks generation < cap and health > 0.1, consumes soil, updates diameter, conditionally rewrites, updates crowding health and interprets the selected tree. It then records that tree's health and advances the index. last_growth_event reports the selected index, uptake, reason and generations before/after; it does not change the kernel's calculation. An empty collection is now a safe no-op.

The diameter increment is 0.005 × uptake × season multiplier × growth multiplier × health. Spring uses 1.2; summer 1; autumn 0.3; winter 0. The visual length parameter is 0.3 + dbh^0.67×8 and the turtle's base segment length is 0.08×that parameter/2. This is an authored allometric scaling scheme, not a measured botanical height.

The rewrite gate requires uptake > 0.05 and non-winter. Winter still consumes when the outer generation/health gate admits an attempt. At the pair's cap of 3, further attempts skip consumption as well as growth. Health below or equal to 0.1 is another gate. _growing can become false at either limit; that is not evidence of ecological equilibrium.

## Separate clocks and representations

The front model never advances itself per frame. STEP is one tree attempt. ORDER flips the first index and resets both trees and soil, retaining the selected season. SEASON toggles spring/winter and resets, retaining first index. RESET restores spring, A first. SOIL performs 60 fixed 1/60 s calls to diffusion and replenishment, with no attempt or season advance. RULE shows the actual gate. History is bounded to 80 events; the pair cap bounds branch growth.

Diffusion uses a new buffer and averages valid four-neighbours, with a clamped interpolation coefficient. The edge has fewer neighbours; do not claim exact total conservation from this averaging. Replenishment interpolates each cell towards nutrient_supply at rate 0.1×season multiplier×delta. Its seasonal multipliers are 1.5, 1, 0.5 and 0.2. A replenished field does not imply a new branch until STEP runs.

The floor diagram shows all 400 values with one mesh; tile height and colour encode resource value. Coloured outlines show each next sampling square. The branch displays are translated apart and magnified 4×, with explicit labels; root coordinates, consumption and crowding are unchanged. Plinths are solid, the diagram is not terrain. The museum floor supports walking across it.

The original forest retains its five grammar strategies, random starts, four controllers and automatic seasons. Its field presentation refreshes at 10 Hz while state still advances each frame. The label now says that soil continues after growth stops. The pre-growth empty tree mesh no longer opens an empty surface. Configuration before _ready is safe. Two former voids remain in the map under flush collision covers; the old teleporter hole is supporting floor. The coral is raised onto a plinth. No coral algorithm changed.

## What the forest does not compute

Crowding is a root-distance threshold plus estimated crown overlap weighted by the other tree's biomass. It reduces health, with a small recovery term and a 0.05 lower clamp. It is not branch collision detection. There is no light field, phototropism, branch pruning, moving roots, death, nutrient transfer between trees, or marine-current competition. The retained coral generates form independently. Old texts that described those operations are archived with the pre-change map.

Next: inspect the genetic tree sculptor in LSystems_Living. Its parameter-to-form mapping asks a different question from a resource gate. Desktop test results belong to the review receipt; headset reach, comfort and Quest performance remain pending.

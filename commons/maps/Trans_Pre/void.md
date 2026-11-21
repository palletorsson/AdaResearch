# Trans_Pre — What survives its movement?

*Floor 13 · Care Unit Model B's working chapter (`void.md`, building on `final.md` and `tutorial.md`)*

---

## 1. Before colour, only timing

Everything on Floor 13 is still black, white, and charcoal grey. Colour does not arrive until Floor 28; smooth sine waves do not arrive until Floor 62. Here every change runs on straight linear interpolation (`lerp`) and a steady turn rate multiplied by elapsed seconds (`delta`). Whatever pulls the body closer, warns it back, or invites a hand to open it has to do so through **motion alone**.

In Melencolia on the floor above, the solids stayed still while my camera moved. Stepping off the landing into Floor 13, the floor itself stays fixed while the objects begin to act.

## 2. Three families, five linear passes

Across Shaft A, the Motion Vocabulary Arena lines up three families — **Coins** on the South elevated scaffold, **Bombs** down in the sunken central basin, and **Packages** along the North elevated scaffold — each repeated five times from West to East:

1. **Static** — holds its coordinates, orientation, and size. Even unmoving, a coin can still be collected and a package can still be opened.
2. **Translate** — moves steadily between two endpoints along one axis via `lerp`. Orientation and size remain invariant.
3. **Rotate** — turns at a constant rate around one axis (`rotation_speed * delta`) while position and size remain fixed.
4. **Scale** — expands and contracts uniformly around its own centre while staying anchored in place.
5. **Archetype** — combines all three into the familiar hovering, spinning, breathing pickup or pulsing hazard.

*Wait for reach.* — Compare the five monochrome coins side by side: stillness, vertical lift, spin, uniform pulse, and all three joined together. None of them changes shape or colour, yet the body reads each pass differently before a single label is read.

On the North wall, Alan Warburton's *Fairytales of Motion* (2019) names what is already happening in the room: the motion codes invented to make cartoon objects readable hardened into motion-capture libraries, gait analytics, and behavioural profiling. Isolating the operations one by one strips away their magic and shows the three lines of arithmetic underneath.

## 3. Random domestic objects against standardized threats

East of the arena, around Shaft B, the floor stays static while the objects move through a short monochrome gauntlet. The coins invite an approach; three active linear-sweep bombs pace across the corridor; three monochrome gift packages wait along the route and on the NE detour.

*Open the gift.* — Opening a monochrome package does not hand over a special weapon. It drops a random ordinary object from the tower's own shelf — a brick, a die, a tin can, a bowling pin, a doorstop, a gem.

*Dodge the sweep.* — Any of those ordinary objects can be grabbed and thrown into a pacing bomb to detonate it (with the same full-screen flash, camera tremor / controller impact, and blinking charge warning that hits Model B on contact), or the visitor can bypass the sweep on the detour. Standardized threats do not require standardized counters.

## 4. What carries downward to Floor 14

Here on Floor 13, **objects** translate, rotate, and scale while the concrete hall refuses to move. Translation preserves size and facing; rotation preserves distances; uniform scale preserves proportion. On Floor 14 (`Trans_Introduction`), those exact three operations leave the tabletop and take over the architecture itself — moving the bridge beneath Model B's feet across Shaft B, turning the central span, and scaling the landing down into Shaft A.

---

*Verified controlled comparison receipt: `doc/book/iterations/2026-11-21-trans-pre-motion-comparison/checks.json` (`01-coin-family-t00.png` → `02-coin-family-t06.png` → `03-coin-family-t12.png`, plus live Dual Breadcrumb HUD `04-f13-dual-breadcrumb-hud.png`).*

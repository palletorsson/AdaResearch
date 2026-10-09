# Vectors_Act4a_KineticForces — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## Why it reads whole

The triage rated it GOOD: seven of eight placed stations have their code in
the tutorial, and the `sub:` cells already give the walk order the intent
thought was missing (south to north: intro → work → drag → projectile →
centripetal / gravity → the reflection). The text follows that walk and lets
the room's own truth beats be the section headings.

## Exactness decisions

- **Every quoted function is probed** (`probe_act4a_tutorial.gd`, eight
  checks): a square push does zero work; `push_split` conserves the push while
  the useful part shrinks as the handle rises; drag never reverses; the reach
  under drag is finite at v0/b and never passed; `slides` flips exactly at
  tan θ = μ (with the wedge's μ 0.28, holds at 15°, goes at 16°); centripetal
  is square to the tangent and quadruples when speed doubles; the barycenter
  balances m1 d1 = m2 d2 and sits closer to the heavier; mutual gravity is
  equal, opposite and inverse-square.
- **Numbers from the artifacts, not the intent**: the pad hands you 6 m/s
  forward and 7 up (`forward_force`, `up_force`); the ring is 3.4 m; the
  corridor is three zones of 3 m; the orbit pair are 3.6 m apart; Sisyphus's
  handle is 32° and the shove 60 N; the wedge's μ is 0.28.
- **`force_pad` had only its subtitle in the tutorial** (the triage's one
  gap). The text gives it the arc from Act III ("you met the arc in the last
  hall as a thing you aimed; here you are the thing launched") rather than
  inventing code for it.
- **The carousel is the room's best physical proof**: its description says the
  chains lean at exactly tan φ = ω²r/g because they must pull IN, and "nothing
  pulls outward." The text says the outward feeling is the body wanting to go
  straight and the chain refusing.
- `wedge_slide` was rescued into this room by the first forces fold and is
  already in the tutorial's `slope_components` / `slides`; the text places it
  at the far end as "the smallest fall there is."

## Open

- `prop_carousel` stands at r25, by the entrance, while `centrifuge_ring`
  stands at r8; the text treats them together under Turn. If the walk should
  meet the hero beside its twin, the carousel wants moving north.

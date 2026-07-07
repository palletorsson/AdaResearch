# Vectors Act4b Oscillation — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 7 artifacts*

> The forces that return what they are given. A hall of clocks and balances: a spring tower that gives less and ticks faster as you stiffen it, a pendulum that slows as its string lengthens, a cradle that hands one ball's momentum through a still middle and out the other side, a well where each bounce is a fraction of the last. Then balance — slide a weight along a beam until a small load far out holds a big one near in, and watch Calder's mobile drift, every arm answered by a real weight. These forces keep time and keep faith, because the pull back is always proportional to how far you have been pulled.

The map, read through what it holds — its artifacts in the order you meet them:

## Pendulum Hall (walk-in)
![Pendulum Hall (walk-in)](/scene-catalog/pendulum_hall.png)

The body-scale, walk-in twin of pendulum_swing: a real, large pendulum (default L = 4.6 m) hung from a 6 m gantry, swinging live at its true period T = 2π√(L/g) = ~4.3 s. The restoring force mg sin θ hauls the bob back through bottom-dead-centre; a glowing arc on the floor records the swept path; the weight / tension / restoring vectors ride the bob at the scale of your own body. Stand in the hall and watch the giant bob pass. The large half of the 'intimate toy -> walk-in installation' pair (clusters with pendulum_swing).

`pendulum_hall`

## Spring Tower (walk-in Hooke)
![Spring Tower (walk-in Hooke)](/scene-catalog/spring_tower.png)

The body-scale, walk-in twin of spring_bob: a heavy mass bobs on a giant coil at its real period T = 2π√(m/k); the coil stretches and compresses while the spring force (−kx) and the weight trade places at body scale. F = −kx, the signature of everything that keeps time. Stand beside the tower and watch it tick.

`spring_tower`

## Weather Vane (wind ∝ v²)
![Weather Vane (wind ∝ v²)](/scene-catalog/weather_vane.png)

Wind made playable - F_drag = ½ρv²C_dA. A ToyConsole: the WIND slider sets the speed; a weather vane swings to point downwind while a flag streams off the pole and the drag vector grows with the SQUARE of the speed - double the wind, quadruple the push, the flag snapping from a lazy ripple to horizontal. The clean toy the old wind-tunnel / windmill examples never became.

`weather_vane`

## Calder Mobile (balanced, real weights)
![Calder Mobile (balanced, real weights)](/scene-catalog/calder_mobile.png)

A large hanging Calder mobile that is actually balanced. Every arm obeys the lever law τ = w·d: the two children of each rod are weighed, then the pivot is placed so w_left·d_left = w_right·d_right - the heavier shape rides the shorter arm - and the whole thing hangs level from a single ceiling point. Leaf masses are real: each flat painted disc is sheet aluminium, mass = π r²·t·ρ (t = 3 mm, ρ = 2700 kg/m³). Calder's primaries - red, yellow, blue, black, white. A plaque states the real total mass and the balance principle. Improves on the project's earlier calder_mobile_primaries, which was only a palette totem, not a balanced mobile.

`calder_mobile`

## Lever (τ = F·d)
![Lever (τ = F·d)](/scene-catalog/lever_balance.png)

The law of the lever made playable - τ = F·d, balanced when F₁d₁ = F₂d₂. A ToyConsole: the LOAD slider slides the right weight along the arm, changing its TORQUE (force times distance) not its weight; the beam tips toward the bigger torque and sits level only when the two are equal. A lever trades force for distance. The clean toy the old balance-puzzle / scale examples never became.

`lever_balance`

## Momentum Cradle (p = mv conserved)
![Momentum Cradle (p = mv conserved)](/scene-catalog/momentum_cradle.png)

Momentum conservation made playable - Newton's cradle, rebuilt as a console. Lift an end ball and the blow travels through the still middle balls untouched and kicks the far ball out to the same height: one in, one out, p = mv conserved. lift 0..1 sets the swing amplitude.

`momentum_cradle`

## Bounce Well (restitution)
![Bounce Well (restitution)](/scene-catalog/bounce_well.png)

Restitution made playable - a console toy for the embodied vectors-forces arc (the clean rebuild of the bouncing-ball sim). A ball dropped into a well bounces, each bounce returning to e times the last height; frozen stroboscopically the arcs shrink geometrically. restitution 0..1 from a dead thud to a perpetual bounce.

`bounce_well`

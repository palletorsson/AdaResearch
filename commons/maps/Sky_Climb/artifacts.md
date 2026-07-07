# Sky Climb — Artifacts
*Vectors & Forces: From Direction to Dynamics · oscillation · 5 artifacts*

> A tower of empty air with launch pads for floors. Step on the first pad and it throws you upward; catch the next one at the top of your arc and it throws you higher. Between the pads, Calder mobiles hang and turn — primary-coloured arms drifting in balance, sculpture you rise past rather than walk around. At the top, a return launcher drops you back to the start to climb again. A launch is a velocity you are given; gravity writes the rest. Here the rest is the whole climb.

The map, read through what it holds — its artifacts in the order you meet them:

## Calder Mobile (project primitives)
![Calder Mobile (project primitives)](/scene-catalog/calder_object_mobile.png)

The balanced Calder mobile (τ = w·d at every arm) but hung with the project's own ordinary objects - point, sphere, pyramid, arch - as the weights instead of painted discs. Each primitive carries a plausible mass and the arms balance those masses by the lever law, so the foundational shapes of the curriculum drift in equilibrium. A plaque states the total mass. Same CalderMobile script with use_objects = true.

`calder_object_mobile`

## Force Pad
![Force Pad](/scene-catalog/force_pad.png)

1x1 m glowing launch pad. An Area3D on the player_body layer fires on contact, setting the player CharacterBody3D's velocity to forward+up. Pulsing surface, forward chevrons, live launch-vector arrow. DNA: forward_force (6), up_force (7), cooldown_time.

`force_pad`

## Calder Mobile (balanced, real weights)
![Calder Mobile (balanced, real weights)](/scene-catalog/calder_mobile.png)

A large hanging Calder mobile that is actually balanced. Every arm obeys the lever law τ = w·d: the two children of each rod are weighed, then the pivot is placed so w_left·d_left = w_right·d_right - the heavier shape rides the shorter arm - and the whole thing hangs level from a single ceiling point. Leaf masses are real: each flat painted disc is sheet aluminium, mass = π r²·t·ρ (t = 3 mm, ρ = 2700 kg/m³). Calder's primaries - red, yellow, blue, black, white. A plaque states the real total mass and the balance principle. Improves on the project's earlier calder_mobile_primaries, which was only a palette totem, not a balanced mobile.

`calder_mobile`

## calder_mobile_primaries

`calder_mobile_primaries`

## Return Launcher (the way home)
![Return Launcher (the way home)](/scene-catalog/return_launcher.png)

The catapult made sci-fi and made personal: instead of flinging a stone toward +Z it flings YOU on a ballistic arc back to where you started. Stand on the glowing launch ring and an energy arm snaps over; a velocity is solved on the spot - v0 = (home - here)/t - ½g·t - so that t seconds later you land exactly on your spawn. It can't throw the wrong way, because it always aims at the beginning (captured the first frame it sees the player). The final throw of a fly-up course. Fires the player's CharacterBody3D via an Area3D on the player layer, like force_pad.

`return_launcher`

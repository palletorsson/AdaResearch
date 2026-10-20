# The Void: one game, two input methods

19 October 2026. Requirement: desktop and VR share the game rules, progression,
objects, layouts and outcomes. Input adapters translate mouse/keyboard and
tracked-controller actions into the same interactions.

Fixed three concrete differences:

- Desktop's C shortcut created a different projectile and bypassed the earned
  catalyst. It now supplies virtual hand poses to the existing shared ability.
  Formation, unlock, cooldown, held-object exclusion, wall collision and healing
  consequences all use the same implementation.
- Desktop had no museum pointer/pickup adapter. It now uses the existing mouse
  pointer, with actual XRTools pick-up/let-go for XRTools objects. The carried
  point's light, coordinate feedback and trigger react through their existing
  signals. Death releases held objects and clears input state in both modes.
- Desktop walked at 3.5 m/s while the museum rig used 3.0. Speed, jump, traction,
  drag and pointer reach now have one definition. Desktop applies world gravity
  on the jump frame, as XRTools does.

Both modes continue to load the same rooms.json. No editor placements or
tutorial/reflection texts were changed for this repair.

| Action | Desktop | VR |
| --- | --- | --- |
| Move / look | WASD / mouse | Museum sticks / headset |
| Jump | Space | Right A |
| Pick up / release | Right click; wheel changes carry distance | Grip |
| Use held object / pointer | Left click | Trigger |
| Form earned catalyst | Hold C with empty hands | Bring empty hands together |
| Send catalyst | Left click while formed | Trigger while formed |
| Retry checkpoint | R | Right B |

Restart The Void to load the changes. Earning the catalyst remains required in
both modes; tests grant it only to isolated fixture instances, never the user's
saved progression.

## Verification

`python tools/test_void_shared_play.py` runs Godot 4.6 against copied production
sources. Mouse cases deliver native input events using the window backend;
headless Godot cannot capture the mouse. XR cases use actual XRTools nodes with
synthetic trackers. This is not a physical headset test or an audit of every
artifact in the museum.

| Suite | Passed assertions |
| --- | ---: |
| Desktop / XR parity: movement, input, catalyst, switch, lit point, recovery | 47 |
| Creature behaviour, collisions and health | 28 |
| Actual Cube floor spider, both input paths and streaming | 14 |
| Fall damage, death and checkpoint recovery | 42 |
| Safe corner landings | 16 |
| Shared museum rig, sticks and light switch | 18 |
| Avatar, jump, held-tool priority and catalyst | 20 |
| Total | 185 |

Measured over 60 physics frames: desktop travelled 2.9500065 m, XR 2.9500070 m
(including acceleration). Jump peaks: desktop 1.0415524 m, XR 1.0415525 m.
Logs contain existing resource UID and teardown warnings; the runner rejects
script errors, engine errors, nonzero exits and failed assertions.

Game health is shared: ordinary one-floor hard landing costs 10 out of 100;
spider bite costs 20 with a three-second cooldown; a calmed spider restores 10
every two seconds while nearby with clear sight. Deeper falls retain fatal
recovery, and marked corner pads remain safe.

Implementation: `commons/void/desktop_hand.gd`, `player_rules.gd`, `walker.gd`,
`game.gd`, `floor_stream.gd`. Input adapters must not grow alternate health,
enemy, progression or projectile rules in future changes.

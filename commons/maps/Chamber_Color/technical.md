# A value arrives at a receiver

This chamber follows Color_Walls: material appearance, colour coordinates and bodily access already have separate implementations. The closing encounter tests what happens when one chromatic message invokes several responses.

## Input and placement

`becoming_catalyst` at grid (4,8) opts into `#lesson:chromatic`. `chromatic_study.gd` builds a standing FIRE COLOUR console and support. The catalyst body is explicitly unpickable in this installation. Its button invokes the existing `mode_chromatic.gd` factory, aims at the practice target in the same embedded grid and enforces the native 0.25-second cooldown. It waits while the target is absent. No wrist lease or progression unlock is granted by firing the bench.

The target at (4,10), root height 0.7 m, uses a cube shape, frame, grid mark and three-hit threshold. Its position brings the contact within splash range of nearby floor cube centres. The recovered structure and utilities are preserved. A sculpture clearance rectangle protects the encounter from museum decoration.

## Projectile and reception

The native mode chooses a uniform random hue, saturation 0.85 and value 1.0. Speed is 15 m/s and lifetime 3.5 seconds. The emission hue changes during flight but `color_primary` stays fixed. Collision mask 2 addresses hit receivers; a bare layer-1 grid wall alone does not trigger this shot's impact.

The base projectile dispatches the target callback once. The chromatic subclass then applies its grid effect. A duplicate callback in the subclass was removed: it had counted one contact twice. Target collision disabling is deferred outside the physics-query flush.

The grid effect compares the impact with current rendered instance centres transformed through GridMultiMesh's global transform. This accounts for museum offsets and previous visual edits. Centres strictly closer than 1.5 metres receive hue offset `distance * 0.15`, saturation 0.8 and value 0.95. Their render transforms shrink by a random factor from 0.75 to 0.92, rotate and shift slightly. Two temporary small cube meshes per affected instance fly outward and vanish. They are decorative effects, not recursively growing structures.

Only MultiMesh colour and transform data change. The grid collision bodies and source map JSON do not. Repeated shots can accumulate visual changes during the live hall. No saved-edit or cross-hall persistence contract is supplied by this mode.

## Return and checks

Three distinct hits make the target shrink away and disable its collision. After four seconds it resets its hit counter, re-enables collision and returns with an elastic scale animation. This does not restore grid instances. The `hits` token key is now recognised as numeric configuration instead of tutorial rotation shorthand.

`commons/testing/probe_chamber_colour.gd` exercises actual button signals and physical projectile contacts in the real museum, comparing colour, render transforms and unchanged grid collision transforms. It also tests cooldown, disappearance, waiting, return and control areas after museum disarming. Tracked hands and headset comfort remain untested.

The transport cube carried you without needing to turn. Here, a surface stays attached to its middle. Follow one end. Where does the other end go?

<!-- @rotation_wall_crossings -->

The green blade turns around y. Its centre stays over the gap while its ends sweep towards the grid. At ninety degrees it pauses. Walk across the length that has arrived in your direction of travel.

The orange blade turns around x. Look at its middle. It has no hinge at the bank. One end descends as the other rises, like a large paddle wheel.

The far landing is three grid cubes higher. During the pause, the blade makes a slope you can climb. But a slope that keeps turning does not keep offering itself as a floor. Through vertical, your feet lose their agreement with it.

Step onto the small level platform beside the orange blade's lower end. Stay there as the turn begins.

You rise, move forward, and arrive beside the higher grid. The blade's centre has stayed where it was. Your head has stayed upright. Which part turned, and which part was kept from turning?

The platform follows an arc while its surface stays level. Its sideways mounting lets the blade pass through vertical without sweeping through your body. Keeping a standing surface under you is another rule in this mechanism. Rotation does not supply it for free.

For the orange ride, the position calculation can be written:

```gdscript
var radial := Vector3(0, -1.5, -3.5)
var orbit := Basis(Vector3.RIGHT, PI * progress) * radial
var endpoint := Vector3(0, 1.5, 0) + orbit
```

`progress` runs from zero to one: half a revolution. The point goes from the lower near bank to the higher far bank; its x coordinate stays fixed. The platform adds its sideways mounting offset and shares each small displacement with a supported rider. Stepping off or jumping releases that support.

At the blue blade, z is the axis. Board from the left. This platform carries you sideways along x and up. Look down the hall while it moves. Rotation around z has no displacement along z to give you. The passage asks you to face another bank.

Both rides pause for twelve seconds, then take twelve for the half-turn. After the high pause they retrace the upper arc. Staying aboard brings you back above the basin. The grid wedges and still aisles offer other returns.

The blades remain 8.4 metres long and 2.4 wide. A centre, an axis and a length describe their turn. A standing surface, a body and a receiving bank make it a passage.

<!-- @ -->

Beyond the blades, the orientations stay still. Your movement will bring you into their differences.

<!-- @rotation_array_compare -->

Four bands each contain two columns and six rows of cubes. Begin at zero. Choose a column and walk forward along z.

Eighteen degrees. Thirty-six. Fifty-four.

The centres keep the same spacing; the angle increases with each row. Follow an outlined edge when surfaces seem continuous. It still belongs to one cube.

Try another band. Where do you climb, descend, stop? Find the row beside you, then inspect it from the still aisle.

X makes rises and falls across your route. Z makes ridges along it. Y turns square footprints while keeping their tops horizontal. The fourth band combines x, then y, then z. At intermediate rows, its edges leave the planes of the grid.

```gdscript
var degrees := float(cube.get_meta("row")) * row_angle_step
cube.basis = rotation_for_band(band, degrees)
```

The row supplies the angle; the band supplies the axis or combination. For XYZ:

```gdscript
return Basis(Vector3.BACK, radians) * Basis(Vector3.UP, radians) * Basis(Vector3.RIGHT, -radians)
```

The rightmost matrix acts first: x, then y, then z. In the previous hall, the same upward and sideways displacements could exchange order and still reach the same destination. Turns about different axes need not finish in the same orientation when their order is reversed. This band fixes its order in the code.

These angles are assigned by position, not accumulated while you wait.

The cubes have not been cut or joined. Their internal distances survive the turn; the connections available to your walk need not.

Watch the cyan bodies begin: each is 0.44 metres wide. Pink bodies follow from the same places, now 1.20 metres wide. Their height, speed, gravity and forward instruction stay the same. Rings keep the first endpoints. Readouts record distance, stopping and sideways displacement. REPLAY begins both passes again.

You might expect wider to mean worse. Watch z before deciding. Here the narrow body catches on a ridge; the wider one can slide sideways and continue. Its changed route matters as much as its arrival.

The capsules neither jump nor choose a detour. The collision solver supplies their slides. You can walk through them without pushing them, and try your own movement. A stopped trial belongs to this body and these rules. It has not exhausted the space.

<!-- @ -->

The final row reaches ninety degrees. A cube can recover an axis-aligned outline there. The way to that flat-looking end still passes through everything before it. More rotation does not promise more obstruction.

Walk on into the last court. Let the repeated turns surround you.

<!-- @boolean_tunnel -->

Look through the first hollow cube. Four more stand beyond it. Walk inside and follow a corner with your eye.

Each segment adds eighteen degrees.

```gdscript
angle_deg = i * rotation_per_segment
```

Five segments occupy fifteen metres. They stand still; your walk unfolds their differences. Turn back and the sequence unwinds.

Subtracting an inner box made each cube hollow. The turns arrange those openings around a continuous floor.

Which edge did you take for a horizon?

<!-- @carousel_cake -->

Step out beside the turning stacks. Follow a stripe on a low layer, then near the top. Stand still. Their relations keep changing.

```gdscript
var layer_speed: float = base_rotation_speed * pow(rotation_speed_multiplier, float(i))
var angle: float = _rotation_angle * layer_speed
```

The lowest layer turns at half a radian per second; each successive layer turns 1.2 times as fast. In the tunnel, eighteen degrees separated neighbours. Here a rate changes the angle through time.

Eight layers make each of the five profiles: a brim, a column, a taper, a pinched spindle, a flare. They share heights and speeds. Walk between them and compare the room each leaves around itself.

Your body has supplied a measure throughout this hall: what could carry it, obstruct it, surround it. The next hall changes the size of the surroundings while your body stays the same. What will fit then?

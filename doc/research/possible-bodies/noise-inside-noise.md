# Borrow an address

[Noise 6 Wall](noise-six-wall.html) → **Noise Inside Noise** → [Noise Space 10](/necklace/thread?map=Noise_Space_10&role=primary)

[Two primary works and their book passages](/necklace/thread?map=Noise_Inside_Noise&role=primary) · [Sequence progress](/research/waves-chance-noise/index.html#Noise_Inside_Noise)

Step into the noise sphere. Colour curves above your head and returns towards the floor behind you. Inside, two smaller spheres and an instrument let you follow what changes in the surrounding field. **Where did the difference enter?**

![Standing inside the noise sphere, with the comparison instrument and two smaller spheres in front of the visitor](noise-inside-noise-inside-warp.png)

In the previous room we added weighted answers. Here we change the address at which an answer is sought. The enclosing sphere, the smaller bodies, the images and the coordinate grid give us different places to follow that operation.

## The sphere is where we stand

The ten-metre sphere encloses the visitor, with a continuous circular floor and two opposing side openings. The controls are inside. WARP changes the enclosing field as well as the small comparison; the enclosing wall, ceiling and floor stay fixed.

![Looking upwards from inside the sphere, with noise covering the ceiling](noise-inside-noise-inside-ceiling.png)

The enclosure uses the same warped samples and projection as the smaller body. Its colour gain is .65 and it is drawn without lighting, so the pattern stays visible from within. Scale and lighting differ; the sampling rule is shared.

![Looking towards a real opening from within the enclosing sphere](noise-inside-noise-inside-door.png)

## Start by returning to zero

Choose zero in the recorded comparison below. The two images agree. Then raise the warp amount while following the yellow point. The pink ring names the address from which the right-hand image borrows its value. Next sample selects another witness without changing the images.

<!-- samples -->

These are the actual 96 × 96 images and numerical readings produced in Godot. Each image samples the same square, from −4 to 4 in both coordinates; positive z is upwards. The markers indicate exact query coordinates, which need not coincide with an image's sample centres. At zero the pink ring surrounds the yellow point. With a warp, a visible displacement opens between them.

```gdscript
func address_at(p: Vector2, amount: float) -> Vector2:
    return p + amount * displacement_at(p)

func value_at(p: Vector2, amount: float) -> float:
    var q: Vector2 = address_at(p, amount)
    return base.get_noise_2d(q.x, q.y)
```

The answer from `q` returns to the original place `p` in the image. Two fixed Perlin fields supply the displacement vector; a fixed Value field supplies the answer. Changing the amount changes neither seed nor colour range. The study stays still between actions, so there is no counter to stop and no earlier moment to recover.

## Give the value another job

Now keep the warp at 0.8 and switch between the two recorded sphere views. SKIN applies colour to round geometry. RELIEF also lets the signed value change each vertex's radius. The flat images keep their values through the switch.

<!-- relief -->

The radius of each small sphere is `0.94 + 0.16 × value` metres in RELIEF. This separates two decisions: where the field is sampled, and what receives the result. Turning the warp to zero makes both relief meshes agree again. The small surfaces have no collision. The enclosing sphere has fixed collision and stays round through RELIEF, giving the visitor a steady floor and openings from which to compare those changes.

## A body still needs a mapping

The spheres use direction x and z, multiplied by three, as their field coordinates. Direction y is omitted. Upper and lower points can ask at the same address. Their apparent continuity depends on this particular projection, the mesh vertices and interpolation between them.

The little instrument keeps the coordinate change visible beside the colour images: an original cyan grid, a displaced pink grid, and the selected link between addresses. A curved line in that drawing does not by itself prove a topological tear. It lets us ask a closer question about this mapping.

![The low instrument housing with its paired images, coordinate witness and numerical readout](noise-inside-noise-instrument.png)

**WARP** selects 0, 0.35, 0.8 or 1.4. **SAMPLE** chooses one of five witnesses. **RELIEF** changes how the values shape the two bodies. **ZERO** returns to direct sampling. All four operate through the actual desktop pointer. The supported, tilted case keeps the numerical record beside the material it describes.

## Keep the other time in the room

![The retained dark orb beside the new study](noise-inside-noise-orb.png)

The dark orb keeps its independent sine-driven pulse. It remains a second primary work in the book. An address can change, a value can gain another use, and a material can keep time. The hall gives those differences separate places to become observable.

## Reconnect the hall

![Overhead view of the enclosing sphere within the museum](noise-inside-noise-plan.png)

Both original artifacts remain. The large legacy sphere scene and its shader remain available in other placements; this hall selects an optional coordinate study with a newly declared sampler. It is not a claim that the old dome shader already performed domain warping.

Every original structure cell and utility remains, including the raised exit landing and adjacent wall. The spherical enclosure adds a circular floor over the earlier study's platform and connects to the museum's side passages. One new ground row from the earlier pass wraps around the exit wall. The book sequence already included this hall, but the active museum skipped it; the reviewed row was restored after Noise 6 Wall.

**52 rendered museum checks passed.** The desktop body enters the enclosure and walks out through the opposite opening. Collision rays find the surrounding wall and ceiling, while both doorways stay clear. The instrument's standing position is inside the sphere. The enclosing colour field agrees with the sampler after its declared gain and 8-bit vertex-colour encoding.

The original comparisons also pass: at zero all 9,216 paired image samples agree; every nonzero preset changes them while preserving the baseline. SKIN keeps matching small-sphere geometry; RELIEF follows the actual samples at all 8,514 output vertices while the enclosure stays fixed. All four pointer controls, the independent legacy instance and the museum route pass.

Headset reach, comfort, legibility and Quest performance await the later headset session. These web controls inspect recorded states, so the comparison can be reviewed remotely.

<!-- book -->

Next to develop: **Noise Space 10**. We can carry the distinction between coordinate, value, surface and collision into the question of where a body can go. Its museum connection remains part of that next pass.

[Chapter](noise-inside-noise-final.md) · [Tutorial](noise-inside-noise-tutorial.md) · [Technical account](noise-inside-noise-technical.md) · [Critical account](noise-inside-noise-critical.md) · [Captured evidence](noise-inside-noise-evidence.json) · [Run receipt](noise-inside-noise-run.json)

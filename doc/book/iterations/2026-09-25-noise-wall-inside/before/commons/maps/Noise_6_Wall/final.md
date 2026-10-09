# The room wears the sum

<!-- @shader_noise_space -->

There is a room inside the hall. Pink gathers in its corners. The little sphere inside seems to have borrowed something from the walls, although its clouds pull around a different body. Step through one door and look towards the other. The floor carries you while something softer appears to move through it.

What would have to change for those folds to carry your feet?

Keep that question while you return to the panel. Four small windows show the same coordinates with one, two, four and six cloud terms. Press FREEZE. The room holds the moment of the press. Its colours and the small windows stop changing together. We can stay with a difference long enough to inspect it.

Press DRESS, then enter again. Grey has taken the place of pink. Something of the cloud remains, but its depth and atmosphere have changed. Follow the wall towards the door. The opening is still there. Your feet meet the same floor.

We have changed what the surface offers the eye. The wall's vertices and the shapes your body collides with have stayed put. This distinction is useful precisely because the surface can be so persuasive. You might still walk differently towards a dark patch, or hesitate before something that looks deep. What the player can physically cross and what the player imagines crossing need not arrive together.

At the panel, compare the first grey window with the second. A smaller variation has entered the same region. The four- and six-term windows add finer disturbances. LAYERS carries each of those cumulative choices into the room; the four windows keep their separate counts so you can look back.

Here is the loop doing that work:

```glsl
    for (int i = 0; i < layers; i++) {
        vec2 animated_pos = pos * frequency;
        animated_pos.x += sin(t * 0.3 + pos.y * 0.5) * 0.3;
        animated_pos.y += cos(t * 0.2 + pos.x * 0.3) * 0.2;

        value += amplitude * abs(noise2d(animated_pos));
        amplitude *= 0.5;
        frequency *= 2.0;
    }
```

`value` begins at zero, `amplitude` at 0.5 and `frequency` at 1. Each turn reaches further through the field over the same surface, then gives its answer half the weight of the previous turn. The familiar sine and cosine move the sampling coordinates. FREEZE has held their time, too.

Stay with `abs` for a moment. A negative answer returns as a positive magnitude. Positive and negative values of equal size can now contribute the same amount. In the previous room, a threshold decided whether a cell received a block. Here another operation gives differences another destination: both signs can help dress a surface. This is a new two-dimensional shader field; we are carrying a way of thinking forward, rather than transferring the voxel room's stored samples.

The plate lists accumulated weights: 0.5, 0.75, 0.9375, 0.9844. The sixth term weighs only one thirty-second as much as the first. It still has somewhere to act. Look for a region where a small addition changes the edge you were following.

More terms can also make the grey window brighter. Every weighted magnitude is nonnegative. At a fixed coordinate and time, adding one cannot reduce the sum. But the weights alone do not tell us a pixel's brightness: each term brings a sampled value, and the display puts the result through another rule.

```glsl
        float bare = clamp(cloud_noise(uv * cloud_scale, time * time_scale) * term_gain, 0.0, 1.0);
```

The comparison uses a gain of two, and the shader clamps anything above one. Any two sums of 0.5 or more would become the same white, although when the four windows were measured at one held moment, even their brightest pixel reached only about half-white. Grey is already an interpretation, with its own capacity to lose a difference. There is no final undressed picture waiting underneath every other picture.

Try BASIS while the moment stays held. Perlin, Value, Cellular and Simplex offer different constructions to the same accumulation. These are the implementations in this shader, with their own scaling constants. Watch what happens to a contour you had begun to recognise. Returning to Perlin restores this construction at the held coordinates. There is no seed button here; the shader's hash uses fixed constants.

Press DRESS again. The pink returns around the same held cloud sum. The finished material adds a second, four-term turbulence calculation:

```glsl
        float cloud_pattern = (cloud_base + cloud_detail * 0.4) * cloud_density;
        cloud_pattern = smoothstep(0.2, 0.8, cloud_pattern);
```

Colour mixing, edge and corner shading, roughness and small changes to the lighting normal follow. LAYERS changes the cloud sum; that separate detail loop still has four terms. A one-term cloud can therefore wear a detailed finish. The button's number names one part of a construction.

Take this knowledge inside. The material has crossed from a small square to an enclosure and a sphere. Can you follow one cloud around a corner?

Each wall piece starts its own UV coordinates. The sphere wraps a different coordinate chart around itself. The same calculation can stretch, repeat or meet a seam when another surface receives it. The room is surrounded by a shared procedure, but it is not an unbroken sample of a world-space cloud.

The seam is an invitation to look at how the room has dressed. A surface can make a box feel intimate, strange or excessive without first earning another geometry. Its pleasure need not be dismissed when we find the instruction that produces it. Now we can change that instruction with a more particular desire.

<!-- @dark_sphere -->

Outside, the dark orb continues to pulse. The room is held; this body is not. Stand between the two and watch the difference in their times.

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
_sphere_material.emission_energy_multiplier = lerpf(pulse_min * _emit_mul, pulse_max * _emit_mul, pulse_t)
```

The orb receives a sine as a changing emission strength. It belongs to the hall without belonging to the panel's clock. A control has a reach, and discovering its edge tells us something about the world's construction.

Press FREEZE once more to let the room continue from its held moment. The orb did not wait. We leave with several times still running, and a surface whose apparent depth has not become a foothold.

<!-- @ -->

In Noise Inside Noise, we will ask what happens when a field changes the coordinates at which another field is read. Here we added answers. Next we follow what happens to the asking.

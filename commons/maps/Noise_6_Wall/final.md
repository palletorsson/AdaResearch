# Six scales, and the one you are looking at

Which layer of a surface are you attending to?

<!-- @shader_noise_space -->

The hall is named for a wall of cloud, and the first honest thing to say is that you are not standing inside one. The artifact this room is built from makes an enclosure eighteen metres wide, twenty-seven deep and thirteen and a half high. The hall you are in is thirteen cells across with three-metre walls. Its walls stand outside these walls; its ceiling is above this ceiling. Walk the map on its own and the cloud is around you. Here, it is beside you.

So the room gives you the next best thing, which may be the better thing. At the entrance there is a board with four square patches on it. They look like four different textures and they are not. They are one field, at one seed, in one coordinate frame, at one contrast, under one clock, and they differ in exactly one respect: how many terms of the sum are being added.

```glsl
    for (int i = 0; i < layers; i++) {
        vec2 animated_pos = pos * frequency;
        value += amplitude * abs(noise2d(animated_pos));
        amplitude *= 0.5;
        frequency *= 2.0;
    }
```

The first patch is one term. Broad, soft, slow: a field with nothing small in it anywhere. The second adds a term at half the amplitude and twice the frequency. The third has four, the fourth has six, and the sixth term is a thirty-second of the amplitude of the first at thirty-two times its frequency — detail you can see and could not possibly navigate by.

The left patch is darker than the right one, and the plate tells you why rather than hiding it:

    layers   1        2        4        6
    weight   0.500    0.750    0.9375   0.9844

That is the sum of the amplitudes, and it is the whole of the brightness difference. Nothing has been renormalised to make the four look equal, because a comparison that quietly rescales its own terms cannot show you what the terms were. All four are shown at the same display gain, and the plate says that too.

Look along the four and watch what arrives at each step. Detail does not replace what was there: the broad masses in the first patch are still exactly where they were in the fourth, because each term is added to the ones before it and never touches them. That is the thing worth carrying out of this room. Inside a six-layer surface you cannot say which scale you are attending to — and you are not failing to look properly. You are looking at a sum, and a sum has no layers in it any more. It has a value at every point and no memory of where that value came from. The board can show you the terms only because it kept them apart on purpose.

LAYERS takes the room's own materials down to the same count, one, two, four, six and round again, so the number on the plate and the number in the walls are never two different claims.

FREEZE stops everything that moves: the shader's own clock, the colour cycling and the density breathing, on the room and on all four patches at once. It is worth pressing before you compare anything, because two patches sampled at two moments are not a comparison.

BASIS is a different question and the plate keeps it separate. It changes the generator underneath — simplex, perlin, value, cellular — while the number of layers stays where you left it. Six walls and six octaves are not the same six, and a room that let those slide together would be teaching a coincidence.

<!-- @ -->

Noise Perlin Simplex follows, and takes the basis question on its own terms: two generators, fairly compared, with nothing else allowed to differ.

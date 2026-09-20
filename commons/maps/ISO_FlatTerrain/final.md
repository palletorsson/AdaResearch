# Look beneath the height

<!-- @mc_flat_landscape -->

How many times can the ground be above the same place?

The turquoise landscape begins with hills. Walk around its edge. A gold line passes vertically through it; the small marks show where that line meets the generated surface. The desk reports one crossing. Choose another COLUMN. The height varies, but each tested column still has one answer.

Press HOLD. The earlier surface remains behind the live specimen. Now press INTERIOR once, then again. Look beneath the upper profile before reading the number. Something can disappear from the top view while becoming visible from the side. A fold may give the same vertical line more than one meeting with the boundary.

The first field begins with a familiar description:

```glsl
float terrainDensity = (surfaceHeight - worldPos.y) / 30.0;
float density = terrainDensity - caveNoise * params.caveStrength;
```

Here `surfaceHeight` depends on horizontal position. With cave strength zero, the second line leaves the first alone. Rise through a column and the density decreases steadily; at level zero it crosses at the assigned height. The hills can be rough or smooth. This description still gives each horizontal position only one height. It cannot independently specify a floor, an air gap and a ceiling there.

INTERIOR keeps that height function, sample domain and threshold unchanged. It changes the weight of a three-dimensional cave field: zero, 0.3, 0.4, then 0.8. Because that contribution varies with height too, the final field need no longer decrease steadily as you rise. A column can leave solid, enter air, and meet solid again.

Try the strongest setting. The marked column is chosen from a fixed set of 25 by 25 test positions, with the most crossings shown first after a rebuild. COLUMN moves through that set. These are intersections with the extracted triangles. They are evidence at particular positions, rather than a complete account of the continuous field or the whole landscape.

The cave term can also lower the upper surface. Holding the height function steady does not hold the final skyline steady: both terms contribute to the boundary. Compare with your held copy. Which difference did you notice first—the changed silhouette, or the space beneath it?

The earlier noise rooms gave us variation we could recognise as terrain. Here we ask what that variation is allowed to describe. Adding more detail to a height function cannot give it a second answer at the same position. Changing the description can. Even then, an enclosed pocket may offer no entrance. A visual opening may be too small for a body. This miniature's column counter does not decide either question for us.

<!-- @mc_overhang_landscape -->

The amber landscape starts from a height field too. Press TERMS and watch it acquire contributions one at a time: overhang, cave, arch, then outcrop. Keep the turquoise specimen as it is while you examine the amber one from the side.

Its description gathers several tendencies:

```glsl
density = baseTerrain - overhangDensity - caveStrength
        - archStrength + outcropStrength;
```

Each contribution has its own spatial mask and noise calculation. The two specimens share an extractor, but they are not a matched pair differing by one switch. The left experiment varies the weight of one interior field. The right experiment adds different terms to a composition. Distinguish those questions before comparing the results.

The names suggest things to look for. Does the setting called “arched” give you an arch you can recognise here? Where does it fail to do so? A word on the desk names an intention; the field, sampling and selected domain make the actual surface. The gap between those accounts is part of the encounter.

RESET returns both reference fields and keeps the held surface. Neither specimen is rescaled or lifted to improve its fit as the values change. Some differences are small. Come closer, change your viewpoint, or keep the question open. More terms need not produce more usable space.

<!-- @ -->

The original CPU terrain and rhizome specimen remain further into the hall, offering other ways to return to this question. Our next stop is Portal Landscape: once an opening appears, where can it take us?

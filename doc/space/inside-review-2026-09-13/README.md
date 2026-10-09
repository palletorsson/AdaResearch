# Noise Inside Noise — the visitor inside the sphere

Current review: `/research/possible-bodies/noise-inside-noise.html`. User correction on 13 September: the noise sphere must enclose the visitor. Next development target remains Noise_Space_10; this correction does not advance to another hall.

## 2026-09-13 — the sphere encloses the visitor

The user corrected the previous presentation: we should be inside the noise sphere. The optional study now adds a 5 m-radius sphere, centred at local (0,1.5,.2), with a circular floor at y=.06 and two opposing openings from floor to y=2.5. The comparison instrument, smaller pair and orb are inside. The enclosing surface uses the same warped field and direction-x/z projection, with unshaded colour gain .65. WARP changes the field surrounding the visitor. RELIEF changes the smaller pair only; the enclosing support and collision stay fixed.

Accepted run: PID 4868, 2026-09-13T15:11:53+02:00 to 2026-09-13T15:12:22+02:00, 52 checks, no failures. Both openings pass head-height rays, the wall and ceiling stop rays from inside, and the desktop body enters one opening and leaves through the other. The actual control approach lies inside the sphere. All 37,248 encoded vertex colours match the shared sample and declared gain, with zero error after 8-bit encoding. The original 42 comparisons continue to pass. Source fingerprints and original saved necklace hand unchanged. No map cells or utilities changed in this correction.

The chapter now opens with entering the sphere. Supporting prose, primary description, review images and plan reflect that encounter. Previous tabletop-only work is archived under doc/space/inside-enclosure-2026-09-13. The enclosing mesh is cut at the circular floor; it is a spherical room with a level walking surface, not a closed sphere that traps the player. Headset comfort, reach, legibility and Quest performance remain deferred.


## What remains

The two original map tokens are noisesphere and dark_sphere; both remain primary and have book passages. The noisesphere token still selects stand:warp. The smaller pair, images and coordinate witness remain as its comparison instrument. The original scene resource and legacy shader are unchanged, and unconfigured placements retain their old dome. The orb retains its independent time. All original map structure cells and utilities remain, along with the previous pass's added boundary and ground passages.

The enclosing wall has 37,248 triangle vertices. Exact angular divisions include the two door boundaries; missing faces make real openings in both the visible mesh and the concave collider. Backface collision and two-sided rendering allow the inner surface to be seen and touched. The 2.5 m-high openings are approximately 2.28 m wide at floor level. A cylinder of radius approximately 4.788 m, height .06 m, reaches the spherical intersection with the floor. The top of the enclosing sphere is y=6.5 m. Its colours come from the same Value field read through two Perlin displacement components as the existing study. The enclosure does not have another clock or independently changing seed.

## Evidence and its limits

Runner and exact accepted hashes: `ada_run/inside-review-2026-09-13/run.json`. The existing runner now also fingerprints enclosing_sphere.gd. It uses its own saved-hand snapshot and an owned offscreen rendered process with XR disabled. No other Godot process was present in the prelaunch inventory. The final run exited normally with 52 checks passed.

The enclosure is tested through its actual mesh and collider, not only stored state: colour encoding, fixed vertex positions through WARP and RELIEF, rays through both openings, rays into the wall and ceiling, and a real desktop body crossing the room. The traversal ends at local (-6.499562, .000474, .800208), beyond the opposite spherical boundary, on the existing museum approach. The previous apron and exit-route tests also pass.

The first colour comparison measured a maximum raw float difference of .00392133. ArrayMesh stores colours as 8-bit channels. Comparing the encoded expected channels gives zero difference across every vertex; the verifier checks the exact encoding rather than broadly loosening its tolerance. This readback does not claim the lit screenshots equal raw field samples.

New captures at a 1.6 m camera height: inside-zero and inside-warp share a camera and differ only in strength (0 versus .8); inside-ceiling looks upward; inside-door shows an opening from within. The older named skin_0..3, relief, instrument, readout, orb and plan images are regenerated with the enclosure present. The overhead view now shows the enclosing shell, which hides the instrument from above. There are no headset or performance claims.

## Records and publication

The before/ and previous-run/ directories in `doc/space/inside-enclosure-2026-09-13` preserve the preceding sources, chapter and accepted 42-check run. previous-review/ preserves its documentation and publication receipts. Current verification and publication receipts remain in `doc/space/inside-review-2026-09-13` so the existing review URL and build workflow stay stable. Older notes there about the initial restoration are historical.

The book's three code excerpts remain exact passages from warp_study.gd. Book order is noisesphere then dark_sphere. The enclosing sampler has the same x/z projection, but a different mesh tessellation, display gain and lighting mode; the prose makes those differences explicit. Its fixed floor and openings let the visitor compare the changing field from within it.

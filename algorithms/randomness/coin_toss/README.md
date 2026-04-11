# Coin Toss

A VR-interactive coin toss experiment. Grab coins from a tray on a pedestal, flick or throw them, and watch them land heads or tails on a felt landing pad. A running display tracks the heads-to-tails ratio, which converges toward 0.5 over many tosses -- the law of large numbers made physical.

## Concept Taught

**Bernoulli trials and the law of large numbers.** The coin toss is the simplest random experiment in probability: a single binary outcome with equal probability (p = 0.5). This artifact turns that abstraction into a physical, embodied experience. Each toss is a Bernoulli trial. The display shows the cumulative ratio of heads to tails, and students watch it fluctuate wildly at first (after 3 tosses, 100% heads is common) then stabilize toward 50% as the sample size grows. The history ribbon shows the sequence of individual outcomes, making patterns (and the lack thereof) visible. The QFEP connection is probability as symmetry: the coin has no reason to prefer one face, so p = 0.5 is the expression of perfect physical symmetry.

## How It Works

1. A pedestal and circular tray are built procedurally. Eight coins are stacked in the tray.
2. Each coin is an XRTools pickable RigidBody3D with two half-cylinders (gold heads, silver tails), collision shape, and "H"/"T" labels on each face.
3. When a coin is picked up, its state resets. When dropped, it is marked as "thrown."
4. Each frame, thrown coins are monitored for settling: linear velocity below 0.03 and angular velocity below 0.2 for 0.6 seconds.
5. Once settled, the coin's result is read by computing the dot product of its local +Y axis with world UP. Positive = heads (gold side up), negative = tails (silver side up). A near-zero dot means the coin landed on its edge -- an extremely rare event that is not counted.
6. Statistics are updated: total flips, heads count, tails count, running ratio, and a scrolling history of the last 30 results.
7. Coins that fall too far below the scene are cleaned up automatically.
8. VR controls provide REFILL (respawn coins in tray) and CLEAR (reset statistics) buttons.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `coin_radius` | float | 0.025 | Radius of each coin |
| `coin_thickness` | float | 0.003 | Thickness of each coin |
| `coin_mass` | float | 0.03 | Mass of each coin |
| `coin_bounce` | float | 0.35 | Bounce coefficient |
| `color_heads` | Color | gold | Color of the heads side |
| `color_tails` | Color | silver | Color of the tails side |
| `tray_radius` | float | 0.12 | Radius of the coin tray |
| `tray_height` | float | 0.02 | Height of the tray rim |
| `pedestal_height` | float | 0.9 | Height of the pedestal column |
| `pad_radius` | float | 0.2 | Radius of the landing pad |
| `pad_color` | Color | green | Color of the felt landing pad |

## Features

- XRTools pickable coins with freeze-on-grab, release-to-throw physics
- Two-tone coin construction: gold heads with "H" label, silver tails with "T" label
- Highlight ring for VR hover/selection feedback
- Physics-based result detection via basis dot product with world UP
- Edge landing detection (extremely rare, not counted)
- Running ratio display converging toward 0.5
- Scrolling history ribbon of last 30 results
- Detailed statistics: flip count, heads, tails, ratio to four decimal places
- REFILL button respawns coins in the tray
- CLEAR button resets all statistics
- Automatic cleanup of coins that fall out of the scene
- Felt landing pad with high friction, low bounce physics material

## Files

| File | Purpose |
|------|---------|
| `coin_toss.gd` | Complete coin toss experiment -- coin creation, physics, result detection, statistics, VR controls |

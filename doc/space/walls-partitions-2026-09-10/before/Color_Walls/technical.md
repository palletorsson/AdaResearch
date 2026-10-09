# Colour becomes an office — implementation

The office opts in with `#layout:cubicles` in `algorithms/color/color_mixing/color_constellation_office.gd`. Four cubicles on each side of the central aisle each contain a desk, monitor and chair. The installation occupies approximately 9.6 by 13.8 m.

Each pane has a matching static box collider. All partitions are orthogonal. The two short entrance panels leave a 1.2 m opening; the central aisle remains clear. The glass uses a transparent `StandardMaterial3D` with alpha 0.26. Looking through several panes invokes the renderer's transparency/compositing rules; this does not simulate wavelength-dependent absorption through real glass.

The existing `mixture` experiment belongs to the default installation. The furnished cubicle layout is a distinct configuration. The colour-space navigator and gradient interpolator remain separate artifacts: a colour's coordinates, interpolation between values, and layered views through glass are related questions with different implementations.

The former tutorial is archived under `doc/space/color-recovery-2026-09-09/before/commons/maps/Color_Walls`.

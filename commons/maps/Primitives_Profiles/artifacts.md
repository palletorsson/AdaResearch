# Primitives Profiles — selected artifact

`glyph_profile_gallery` uses `commons/artifacts/glyph_profile_gallery/glyph_profile_gallery.tscn`. The museum arrangement adapts the six frame recipes in the existing [glyph-form atlas](../../../doc/book/studies/glyph-form-atlas/atlas.gd).

| Source | Supplied construction | Retained limitation |
| --- | --- | --- |
| O | Straight depth at bodily scale | Lower stroke forms a sill. |
| O | Narrowing, flaring and turning sections | Lower opening remains; no vessel bottom. |
| B | Rising and turning sections | Two wells remain separate. |
| C | An open circular route | An apparent enclosure is not automatically a handle. |
| I | A closed circular route | The path introduces the opening. |
| : | Two dots following shared frames | The bodies remain disconnected. |

[profile_sweep.gd](../../../doc/book/studies/glyph-form-atlas/profile_sweep.gd) supplies glyph triangulation, boundaries, side walls and caps. Tested source checks have a bounded scope; the standalone atlas's free camera has no collision. The museum uses its own host, whose traversal needs separate verification.

See [map_data.json](map_data.json) for placement. Neither the source study nor the museum display promises arbitrary character morphing or general path generation.

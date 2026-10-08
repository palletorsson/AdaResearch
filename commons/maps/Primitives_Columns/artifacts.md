# Primitives Columns — selected artifact

`resolution_colonnade_museum` uses `commons/artifacts/resolution_colonnade/resolution_colonnade_museum.tscn`. Its source builds twenty-five columns: an equal-profile, equal-height first row with fixed profile sampling, followed by four varied rows.

The shared [totem builder](../../artifacts/resolution_colonnade/resolution_totem.gd) supplies five authored profiles, separate height and width inputs, radial divisions and subdivisions per curved section. It builds ArrayMesh surfaces; a profile subdivision is not a decorative collar.

The original [standalone gallery](../../artifacts/resolution_colonnade/gallery.gd) remains a separate source arrangement. The [reduced learner renderer](../../../doc/book/studies/ada-xr-starter/studies/primitive_column/column_surface.gd) instead joins a list of radii with straight intervals and has no collider.

See [map_data.json](map_data.json) for museum placement. Source geometry and placement do not by themselves verify reach, traversal or headset comfort.

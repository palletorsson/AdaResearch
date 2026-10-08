# Shared construction

Artifact: commons/artifacts/facade_room_cast/facade_room_cast.tscn. Standalone desktop scene: study.tscn in the same directory (F6; WASD and mouse; keys 1 entrance, 2 interior, 3 positive).

Both results start with an 8 x 5 x 7 stock B. The same _interior() builds V: a room box, spherical alcove, doorway, window, stepped reveal, and subtractive skirting/rail impressions. The room is B minus V; the positive is B intersect V. Clipping excludes the cutter extensions outside the stock. One definition preserves the correspondence. The finished shared floor has its top at y=0.

The existing OpeningParts and CorniceParts factories supply frames and cornice. Only the local window pane and local door backing/panels/handle are removed so they do not cover the true openings. Existing facade scripts and map placements are unchanged. This is a scaled/adapted fragment, not a full-preset reproduction.

The isolated probe checks a 1.8 m tall / 0.30 m radius capsule on the selected interior/return/perimeter routes and tests the positive's refusal of entry. Ray-parity samples test the partition of stock by the two generated meshes, alongside landmarks and matching void trees. This sampling supports the construction claim; it is not a proof of every triangle. Runtime details and native images are in doc/book/iterations/2026-09-24-facade-room-and-cast/. No tracked-headset, Quest performance or full museum-loader claim.

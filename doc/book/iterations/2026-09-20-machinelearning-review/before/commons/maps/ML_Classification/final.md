# A boundary that moves with its centre

Why can a point change groups even though the point itself has not moved?

<!-- @enhanced_kmeans -->

Pick a point near the boundary between two coloured groups and follow its colour as the display updates. Keep its position in view while watching the centres nearby. Predict which centre it will belong to after the next assignment.

The points are repeatedly assigned to their nearest centre. Each centre then moves to the mean position of the points assigned to it. Moving a centre changes where the next boundary will fall, so a stationary point can acquire a different group membership. Assignment and centre movement take turns reshaping one another.

Follow a centre during an update and identify the points that are pulling its mean towards one side. A single centre summarises the assigned positions without preserving their whole arrangement. Two differently shaped groups could share a mean, so the centre is already a compression of the data. When the next assignment uses that centre, it acts on the summary. This is one reason to keep watching the points rather than allowing the moving centres to become your only evidence.

This is k-means clustering. The number of centres is chosen in advance; the procedure searches for an arrangement of those centres using distance. The default display starts with four centres, while the generated sample contains three broad blobs and some noise. It is a useful reason to look closely instead of assuming the chosen number reveals the data’s natural categories.

The room sits in a classification sequence, but this encounter does not learn named classes from labelled examples. It groups observations by geometry. Calling a cluster a diagnosis, a personality or a social identity would add an interpretation that the distance calculation did not supply.

Watch a point on the edge of a blob after most colours appear settled. A hard colour boundary reports one assignment and conceals how nearly the alternatives competed. The displayed total distance is also a particular readout; do not confuse it with a complete explanation of why every individual assignment is appropriate.

Imagine replacing the separated blobs with two nested rings. Nearest-centre regions would divide space according to a different geometry from the rings’ apparent membership. That is a proposed alternative dataset for the room: a way to make the representation’s limits visible, rather than simply declaring that clustering is biased.

<!-- @ -->

The neural-network room introduces learned connections between layers. It will still need an account of what its training examples and error measure ask it to preserve.

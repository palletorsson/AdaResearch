# A boundary that moves with its centre

Why can a point change groups even though the point itself has not moved?

In Gradient Landscape we chose a line and a measure of its error. Here the parameters are centres, and an observation's distance to them helps decide which group will claim it.

<!-- @enhanced_kmeans -->

Begin with BLOBS. Press STEP to give the points their first colours, then choose one to watch near the boundary between two groups. Keep its position in view while watching the centres nearby. Predict which centre will claim it at the next step. PAUSE / RUN lets the updates continue; RESET returns this sample and its centres to their beginning.

The points are repeatedly assigned to their nearest centre. Each centre then moves to the mean position of the points assigned to it. Moving a centre changes where the next boundary will fall, so a stationary point can acquire a different group membership. Assignment and centre movement take turns reshaping one another.

Follow a centre during an update and identify the points that are pulling its mean towards one side. A single centre summarises the assigned positions without preserving their whole arrangement. Two differently shaped groups could share a mean, so the centre is already a compression of the data. When the next assignment uses that centre, it acts on the summary. This is one reason to keep watching the points rather than allowing the moving centres to become your only evidence.

This is k-means clustering. The number of centres is chosen in advance; the procedure searches for an arrangement of those centres using distance. The default display starts with four centres, while the generated sample contains three broad blobs and some noise. It is a useful reason to look closely instead of assuming the chosen number reveals the data’s natural categories.

The room is called Classification, but this encounter does not learn named classes from labelled examples. It groups observations by geometry. Calling a cluster a diagnosis, a personality or a social identity would add an interpretation that the distance calculation did not supply.

Two other works in this hall use labelled examples. The SVM seeks a separating boundary with a margin and highlights observations that influence it through its fitted coefficients. This is a numerical training procedure; the gold points do not certify a perfect separator. The forest trains trees on resampled data and combines their votes. Both received class labels; the moving centres did not. Their different procedures give us a reason to ask where the answers entered, before admiring the clarity of the boundary.

Watch a point on the edge of a blob after most colours appear settled. A hard colour boundary reports one assignment and conceals how nearly the alternatives competed. The exhibit's total distance adds ordinary distances before the centres move. The tutorial table instead shows the sum of squared distances for the assignments currently displayed—the quantity its mean update reduces. Neither number tells us whether a group has a useful name or whether an individual assignment should carry a consequence.

Press DATASET to replace the blobs with RINGS. Four centres remain. Before stepping, follow a ring with your eye; then watch where its colour breaks. The grouping follows distance to a centre, which need not follow the form you were tracing.

Press DATASET again for BLOCK, a sample with no planted clusters. The procedure still gives it four groups. Does the confidence of the colour change when there was no group for it to discover? Return to BLOBS and the earlier sample returns. We have changed what the procedure encounters while keeping its demand for four centres. The boundary belongs to that meeting.

<!-- @ -->

At the tutorial table the familiar black sphere returns as one centre you can move. Choose a centre, lift it, and put it somewhere else. The observations stay where they were. Their colours clear until you ask for a new assignment; the interface admits that your intervention has interrupted the answer. Another button moves each centre to its group's mean. You can pause between these operations and see which kind of change you caused.

A point exactly between two centres is given to the lower index. A centre with no assigned points stays where it was. These small decisions are easy to lose inside a finished colour field. They matter whenever we want to know how this particular division came about. The mean can be useful without exhausting the group it summarizes; a boundary can be exact under a rule without becoming an account of what its members are.

The neural-network room introduces learned connections between layers. It will still need an account of what its training examples and error measure ask it to preserve.

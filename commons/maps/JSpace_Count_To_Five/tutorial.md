# Tutorial — JSpace_Count_To_Five

## Claim
A model's hidden layer has a geometry, and geometry can be walked. This floor is a real chart of this book's semantic space — with its distortion measured and posted, not hidden.

## Idea
Take the seventeen feature-words from the count-to-five interpretability image. Embed each in the LSA space built from the book's own corpus (artifact cards + walked pages + tutorials + blogs, 3,936 documents). Compute all pairwise cosine distances. Press them into 2D with MDS. The result is the chamber's floor plan: each word a pillar at its measured coordinate, activation (document frequency) as height and glow.

The projection from 128 dimensions to a walkable floor must lie a little. Kruskal stress-1 says how much: **0.27**, on the plaque. A chart that reports its stress is a map; one that hides it is a myth.

## Code
```python
V = normalize(svd.transform(vec.transform(words)))   # LSA vectors
D = 1.0 - V @ V.T                                    # cosine distance
P = MDS(n_components=2, dissimilarity="precomputed").fit_transform(D)
stress1 = sqrt(((D - pdist(P))**2).sum() / (D**2).sum())   # the honesty number
```

## Try
1. Stand between two pillars and estimate their distance with your legs — then read their doc counts. Near pillars co-occur in the book; far ones don't.
2. Find the pillars that refuse to light. Look straight at one and hold your gaze — introspection features fire under attention.
3. Walk the rim. The dark pillars out there are words the book has never said. Which one surprises you?
4. Leave by stepping one–two–three–four–five, in order. Step wrong and the floor corrects you.

# Audio Analysis

Track quality analysis and improvement suggestions using a 10-point rubric.

## Files

- `TrackAnalyzer.gd` — 3-layer evaluation: composition, production, and game-readiness. Performs frequency band analysis (sub, bass, mid, presence, air) with genre-specific ideal balances.
- `TrackImprover.gd` — Generates improvement suggestions based on analysis results.
- `TrackScorecard.gd` — Visualization and scoring output from analysis.

## Usage

Used by the catalog tools (`catalog/SongDevTools.gd`) to evaluate generated tracks and suggest parameter adjustments before export.

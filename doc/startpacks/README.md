# Development Start Packs

Saved starting points for common AdaResearch development intents.

Each pack has:
- `*.md` for human reading
- `*.json` for AI/tool consumption
- `index.json` as the manifest
- `category` and `tags` metadata for filtering and grouping

Generate or refresh:

```powershell
python tools/dev_start.py grid --write
python tools/dev_start.py "nature system" --write
python tools/dev_start.py --saved
python tools/dev_start.py --refresh-saved grid
python tools/dev_start.py --refresh-all-saved
python tools/dev_start.py --refresh-curated
```

Useful patterns:

```powershell
python tools/dev_start.py "interactive button" --slug lab-button-prototype --write
python tools/dev_start.py flowers --json
```

Current curated packs:
- `grid`
- `nature-system`
- `flowers`
- `folding`
- `interaction-controls`
- `science-screen`
- `artifact-registry`
- `sequence-map-pipeline`

The generator pulls from:
- repo files
- `doc/` and `docs/`
- checked-in session handoffs and summaries
- encyclopedia source files
- optional local `grounded_wiki_engine` cache for grounded chat-derived claims and turns

Use these packs as updateable starting points, not immutable truth.
When the repo changes materially, regenerate them.
The encyclopedia `/startpacks` page can now filter saved packs by category, tag,
and free-text search over title/topic/slug.

---
name: continue
description: Pick the hottest item from the heat map and work on it. Just say "continue" to keep the project moving forward.
---

# Continue — One Command to Keep Working

## When to Use
When the user says: "continue", "keep going", "what's next", "work on what matters"

## How It Works

1. **Read the heat map** at `doc/HEAT_MAP.json`
2. **Pick the hottest item** (highest temperature)
3. **Load LOD context** for that item: `python tools/lod_query.py <item>`
4. **Do the work** — fix, build, capture, whatever the action says
5. **Update the heat map** — mark item as done, regenerate
6. **Report** — one paragraph: what you did, what changed, what's next

## Heat Map Temperatures

| Temp | Meaning | Example |
|------|---------|---------|
| 100 | Compile error | GDScript won't parse |
| 90 | Blocked | Can't demo, can't test |
| 80 | Active work | Recently touched, momentum |
| 70 | Missing safety | No collider, no spawn |
| 60 | Quality gap | Pattern doesn't match photo |
| 50 | Missing content | Sequence has no maps |
| 40 | Missing capture | No screenshot for gallery |
| 30 | Polish | Code cleanup, docs |

## Regenerate Heat Map

```bash
python tools/heat_map_generator.py
```

Or if that doesn't exist, the heat map was last generated inline. The key sources:
- `git log -10` → what's recently active
- `doc/FOCUS_VECTOR.json` → what's blocked
- Missing captures → what's not verified
- Compile errors → what's broken

## The Flow

```
User: "continue"
Claude: [reads heat map] → "VR floor height is blocked (90°). Fixing..."
        [does the work]
        [updates heat map]
        "Fixed y_offset. Floor now at ground level. Next hottest: flight mode (90°)."

User: "continue"
Claude: [reads heat map] → "Flight mode button conflict (90°). Fixing..."
        ...

User: "no, work on meander instead"
Claude: [boosts meander temperature to 100] → works on meander
```

## Rules
- Always pick the HOTTEST item unless user redirects
- If stuck after 2 attempts, lower that item's temperature and move to next
- After completing an item, set its temperature to 0
- If heat map is empty, regenerate it
- Always report in ONE paragraph, not a wall of text

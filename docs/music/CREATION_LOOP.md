# Creation Loop Architecture

A cyclic workflow for developing procedural music with research-backed quality.

```
    ┌─────────────────────────────────────────────────────────────┐
    │                                                             │
    ▼                                                             │
┌───────────┐      ┌───────────┐      ┌───────────┐      ┌───────────┐
│           │      │           │      │ BRILLIANT │      │           │
│ RESEARCHER│─────▶│  TEACHER  │─────▶│  STUDENT  │─────▶│ EVALUATOR │
│           │      │           │      │           │      │           │
└───────────┘      └───────────┘      └───────────┘      └───────────┘
     ▲                                                        │
     │                                                        │
     └────────────────────────────────────────────────────────┘
                         feedback loop
```

---

## Roles

### 1. 🔬 RESEARCHER
**Goal:** Discover what makes a genre/style work

**Inputs:**
- Genre name or reference tracks
- Existing knowledge gaps

**Activities:**
- Study reference tracks (BPM, key, structure)
- Analyze production techniques
- Document sound design principles
- Identify signature elements
- Find historical context

**Outputs:**
- Genre research document (→ `SONG_IDENTITIES.md`)
- Track suggestions with analysis
- Sound design specifications
- Chord progressions & patterns

**Quality Criteria:**
- Specific, actionable parameters (not vague descriptions)
- Multiple reference tracks analyzed
- Technical specs (Hz, ms, ratios) when possible

---

### 2. 📚 TEACHER
**Goal:** Translate research into implementable knowledge

**Inputs:**
- Research documents
- Existing synth capabilities
- Platform constraints (Godot/GDScript)

**Activities:**
- Create song identity JSON configs
- Write GDScript code examples
- Define parameter ranges and defaults
- Map words → synth parameters
- Create arrangement templates

**Outputs:**
- Song config files (→ `songs/*.json`)
- Synth code snippets (→ `SYNTH_RESEARCH.md`)
- Word-to-parameter mappings
- Section/structure templates

**Quality Criteria:**
- All values are valid for the synth engine
- Code compiles and runs
- Parameters have sensible ranges
- Clear documentation

---

### 3. 🎓 BRILLIANT STUDENT
**Goal:** Create something new using learned knowledge

**Inputs:**
- Song config (identity, parameters, sound design)
- Word descriptors
- Arrangement structure

**Activities:**
- Generate audio using AudioSynthesizer
- Apply parameter variations
- Experiment within constraints
- Make creative decisions
- Push boundaries of the style

**Outputs:**
- Generated audio stream
- Actual parameter values used
- Section transitions
- Any novel combinations discovered

**Quality Criteria:**
- Sounds like the target genre
- Has musical coherence
- Demonstrates understanding, not just copying
- Shows creativity within constraints

---

### 4. 📊 EVALUATOR
**Goal:** Assess quality and identify improvements

**Inputs:**
- Generated audio
- Original research/specs
- TrackScorecard metrics

**Activities:**
- Compare to reference tracks
- Run TrackScorecard analysis
- Check genre authenticity
- Identify what works/doesn't
- Score on multiple dimensions

**Outputs:**
- Quality scores (0-10)
- Specific improvement suggestions
- Parameter adjustment recommendations
- New research questions

**Evaluation Dimensions:**
| Dimension | Question |
|-----------|----------|
| **Authenticity** | Does it sound like the genre? |
| **Coherence** | Do elements work together? |
| **Interest** | Is it engaging over time? |
| **Technical** | Clean mix? Proper levels? |
| **Innovation** | Any novel elements? |

**Quality Criteria:**
- Objective metrics when possible
- Specific, actionable feedback
- Balanced (both strengths and weaknesses)

---

## The Loop

### Iteration 0: Bootstrap
```
RESEARCHER → TEACHER → STUDENT → EVALUATOR
   │                                  │
   └──────── initial research ────────┘
```

1. **Researcher** studies the genre deeply
2. **Teacher** creates first song config
3. **Student** generates first attempt
4. **Evaluator** identifies major gaps

### Iteration N: Refinement
```
     ┌─── specific questions ───┐
     │                          ▼
EVALUATOR ──────────────▶ RESEARCHER
     │                          │
     │                          ▼
     │                      TEACHER
     │                          │
     │                          ▼
     └──────────────────▶ STUDENT
                               │
                               ▼
                          EVALUATOR
```

1. **Evaluator** identifies specific weaknesses
2. **Researcher** investigates those specific areas
3. **Teacher** updates configs/code
4. **Student** generates new version
5. **Evaluator** compares to previous

### Convergence Criteria
The loop ends when:
- Authenticity score > 8/10
- No major issues identified
- Diminishing returns on iterations
- Or: intentional creative divergence

---

## Artifacts Per Iteration

| Role | Creates | Location |
|------|---------|----------|
| Researcher | Genre analysis | `docs/music/SONG_IDENTITIES.md` |
| Researcher | Track suggestions | `docs/SYNTH_RESEARCH.md` |
| Teacher | Song config | `songs/{genre}.json` |
| Teacher | Code examples | `SYNTH_RESEARCH.md` |
| Student | Audio output | Runtime / export |
| Evaluator | Scorecard | `TrackScorecard` UI |
| Evaluator | Feedback | → Next iteration input |

---

## Archive Integration

When an iteration is "good enough":

1. **Archive current version**
   ```
   songs/{genre}.json → songs/archive/{genre}_v{N}_{date}.json
   ```

2. **Update ARCHIVE_INDEX.json**
   - Record what changed
   - Record evaluation scores
   - Record key learnings

3. **Clear for next iteration**
   - Overview shows only unarchived (work-in-progress)
   - Archive preserves history

---

## Example: Creating "French Touch" Style

### Iteration 0
```
RESEARCHER:
  - Studies Daft Punk, Stardust, Cassius
  - Documents: filter sweeps, disco samples, phaser, sidechain
  - Finds: 120-125 BPM, minor keys, 4-bar filter cycles

TEACHER:
  - Creates french_touch.json
  - Adds filter_bass sound design
  - Defines sidechain parameters

STUDENT:
  - Generates 2-minute track
  - Uses specified parameters

EVALUATOR:
  - "Filter sweep too fast"
  - "Kick lacks punch"
  - "Good groove feel"
  - Score: 6/10
```

### Iteration 1
```
RESEARCHER:
  - Studies filter sweep timing specifically
  - Finds: 8-16 bar sweeps, not 4
  - Analyzes kick EQ in reference tracks

TEACHER:
  - Updates filter_sweep.cycle_bars: 8-16
  - Adds kick.low_boost parameter

STUDENT:
  - Regenerates with new parameters

EVALUATOR:
  - "Much better sweep timing"
  - "Kick improved but needs more click"
  - Score: 7.5/10
```

### Iteration 2
```
RESEARCHER:
  - Studies kick transients in French touch
  - Finds: layered kick (sub + click)

TEACHER:
  - Adds kick.click_layer parameter
  - Adjusts kick.sub_freq

STUDENT:
  - Regenerates

EVALUATOR:
  - "Sounds authentic now"
  - "Ready for archive"
  - Score: 8.5/10
  
→ ARCHIVE as v1
```

---

## Implementation Notes

### For SongDevTools Integration

The UI already supports this workflow:

| Role | UI Element |
|------|------------|
| Researcher | SYNTH_RESEARCH.md, SONG_IDENTITIES.md |
| Teacher | Song config JSONs, Sound Editor tab |
| Student | AudioSynthesizer generation |
| Evaluator | TrackScorecard, Archive compare |

### Automation Opportunities

1. **Auto-research:** Web search for genre characteristics
2. **Auto-teach:** Generate config from research doc
3. **Auto-evaluate:** TrackScorecard metrics
4. **Auto-iterate:** Adjust parameters based on scores

### Human-in-the-Loop

Critical decision points requiring human judgment:
- "Is this authentic enough?"
- "Is this creatively interesting?"
- "Should we diverge from genre conventions?"
- "Archive this version?"

---

## Quality Metrics

### TrackScorecard Integration

```gdscript
# After generation, evaluate:
var results = _scorecard.analyze(audio_data, bpm)

# Key metrics:
results.spectral_balance    # Frequency distribution
results.dynamic_range       # Loudness variation
results.rhythmic_consistency # Beat stability
results.estimated_lambda    # Complexity measure
results.overall_score       # Combined 0-10
```

### Genre-Specific Checks

| Genre | Must Have | Must Avoid |
|-------|-----------|------------|
| French Touch | Filter sweeps, sidechain | Dry sounds, no groove |
| Detroit Techno | 909 drums, cold pads | Too busy, too warm |
| Burial | Crackle, 2-step, reverb | Clean/polished, 4/4 |
| Kraftwerk | Precision, motorik | Swing, organic feel |

---

*Schema version: 1.0*
*Created: 2025-01-30*

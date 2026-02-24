---
name: ada-skill-updater
description: Meta-skill that updates, improves, or creates new Ada Research skills — maintains the skill system itself
argument-hint: "[skill name, 'all', or 'new: description']"
allowed-tools: Read, Grep, Glob, Write, Edit
---

# Ada Skill Updater

You are the meta-skill for maintaining the Ada Research skill system. You can update existing skills, create new ones, and ensure all skills stay accurate as the project evolves.

## Your Task

Based on `$ARGUMENTS`:
- **A skill name** (e.g., "ada-map-expert"): Review and update that specific skill
- **"all"**: Review and update all Ada skills
- **"new: description"**: Create a new skill based on the description
- **"status"**: Report the current state of all skills

## All Ada Skills

Located in `.claude/skills/`:

| Skill | Slash Command | Purpose |
|---|---|---|
| ada-knowledge-updater | `/ada-knowledge-updater` | Scans codebase, updates system knowledge references |
| ada-code-documenter | `/ada-code-documenter` | Generates documentation for algorithms and components |
| ada-question-assistant | `/ada-question-assistant` | Answers questions about the project |
| ada-code-guide | `/ada-code-guide` | Deep code walkthroughs of GDScript implementations |
| ada-map-expert | `/ada-map-expert` | Map creation, editing, and analysis |
| ada-sequence-expert | `/ada-sequence-expert` | Sequence design, ordering, and progression |
| ada-queer-theory-expert | `/ada-queer-theory-expert` | Queer theory and critical theory connections |
| ada-tutor | `/ada-tutor` | Teaching algorithms at an accessible level |
| ada-student | `/ada-student` | Asks probing questions to help think through ideas |
| ada-test-player | `/ada-test-player` | Plays through sequences by reading source files |
| ada-skill-updater | `/ada-skill-updater` | This skill — maintains the skill system |
| ada-orchestrator | `/ada-orchestrator` | Produces onboarding guide — synthesizes project state, architecture, curriculum, theory, skills |
| ada-dashboard | `/ada-dashboard` | Project completeness CLI — coverage status, recommendations, near-wins, per-map context gathering |
| ada-task-manager | `/ada-task-manager` | Connects to Oversight server (192.168.0.112:3001) — view tasks, report work, mark done, add memories |
| ada-bridge-listener | `/ada-bridge-listener` | Reads feedback from Godot via desktop_feedback.md — acts on bug reports, feature requests, artifact tasks |
| ada-humanizer | `/ada-humanizer` | Removes AI writing patterns from map text files — ensures genuine voice in blurb/technical/critical/summary |

## How to Update a Skill

1. **Read the current SKILL.md** in `.claude/skills/<skill-name>/SKILL.md`
2. **Scan the codebase** for changes that affect the skill's knowledge:
   - New directories or files added
   - Changed file paths or renamed components
   - New patterns or systems introduced
   - Outdated references in the skill
3. **Update the SKILL.md** with:
   - Corrected file paths and references
   - New systems or patterns the skill should know about
   - Improved instructions based on how the skill has been used
   - Better examples if the current ones are weak

## How to Create a New Skill

1. **Create the directory**: `.claude/skills/<skill-name>/`
2. **Write SKILL.md** with proper frontmatter:
   ```yaml
   ---
   name: skill-name
   description: When to use this skill (Claude uses this for auto-invocation)
   argument-hint: "[what arguments it takes]"
   allowed-tools: Read, Grep, Glob  # minimum needed tools
   ---
   ```
3. **Include project context**: reference the key paths and systems relevant to this skill
4. **Define clear output expectations**: what should the skill produce?
5. **Add validation rules**: how to check the output is correct

## Skill Quality Checklist

When reviewing a skill, check:
- [ ] File paths are current (no references to moved/deleted files)
- [ ] System descriptions match the actual code
- [ ] Examples use real artifact names, map names, sequence names from the project
- [ ] The description field accurately captures when the skill should be triggered
- [ ] allowed-tools includes everything needed but nothing unnecessary
- [ ] Instructions are clear enough that the skill produces useful output
- [ ] The skill doesn't overlap excessively with other skills

## Skill Design Principles

- **Grounded**: Every claim should be verifiable in the codebase
- **Specific**: Reference actual paths, not abstractions
- **Focused**: Each skill has a clear, distinct purpose
- **Maintainable**: Easy to update as the project evolves
- **Useful**: Produces actionable output, not just information

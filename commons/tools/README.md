# Tools — Developer Bridges and Dashboards

In-engine developer tools and external bridge scripts for AI-assisted workflows.

## Files

| File | Description |
|------|-------------|
| `ClaudeBridge.gd` | VR wrist console + Claude Code bridge — polls outbox.json, displays messages on left hand, voice recording via push-to-talk |
| `ClaudeCodePanel.gd` | In-editor Claude Code panel integration |
| `OversightVoiceBridge.gd` | Voice-to-text bridge for oversight task narration |
| `claude_bridge_poll.py` | Python polling helper for the Claude bridge inbox |
| `project_dashboard_cli.ps1` | **Primary CLI** — project status, coverage gaps, recommendations (`-Mode status`) |
| `audit_md_coverage.ps1` | Audits markdown documentation coverage across the project |
| `spine_status.ps1` | Quick spine/sequence completion status |
| `transcribe_voice.py` | Whisper-based voice transcription for VR recordings |

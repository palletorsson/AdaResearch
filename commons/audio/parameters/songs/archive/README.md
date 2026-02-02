# Song Archive

This folder contains archived versions of song configurations.

## Structure

- `ARCHIVE_INDEX.json` — Manifest of all archived versions with metadata
- `{song_name}_v{version}_{date}.json` — Individual archived song files

## Usage

### Archiving a Song
Songs are archived when significant changes are made to preserve the previous version.
Each archive entry includes:
- Version number
- Timestamp
- Description of what changed
- The complete song configuration at that point

### Restoring a Song
To restore an archived version:
1. Find the version in `ARCHIVE_INDEX.json`
2. Copy the archived file to the parent `songs/` folder
3. Rename to remove version/date suffix

## Archive Naming Convention

```
{song_name}_v{version}_{YYYY-MM-DD}.json
```

Examples:
- `ambient_works_v1_2025-01-30.json`
- `detroit_techno_v2_2025-02-15.json`

## Index Schema

```json
{
    "archives": [
        {
            "song": "ambient_works",
            "version": 1,
            "date": "2025-01-30",
            "filename": "ambient_works_v1_2025-01-30.json",
            "description": "Initial identity-based configuration",
            "changes": ["Added sound_design block", "Added chord_progressions"]
        }
    ]
}
```

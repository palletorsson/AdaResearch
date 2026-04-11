# Artifact Placeholder

Stand-in node displayed when an artifact's scene file is missing or cannot be loaded. Shows a Label3D with the artifact's lookup name and the reason it could not be resolved.

## How It Works

On ready, the placeholder reads its `artifact_lookup_name` and `placeholder_reason` from node metadata. It then formats a text label combining the prefix, lookup name, and optional reason string, displaying it on the existing Label3D child node.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `label_prefix` | String | "MISSING" |

## Features

- Displays the artifact lookup name and failure reason as 3D text
- Reads context from node metadata (`artifact_lookup_name`, `placeholder_reason`)
- Used automatically by ArtifactCatalogDataProvider when scenes are unresolvable

## Files

- `ArtifactPlaceholder.gd` -- Placeholder label logic
- `ArtifactPlaceholder.tscn` -- Scene file with Label3D

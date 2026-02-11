# GDScript Warnings Report

Generated: 2026-02-11

## Summary

Godot's GDScript linter detected warnings for:
- **SHADOWED_VARIABLE_BASE_CLASS** — Local variables shadowing Node3D properties
- **UNUSED_VARIABLE** — Declared but unused variables

---

## Shadowed Variables (High Priority)

These local variables shadow built-in `Node3D` properties (`position`, `rotation`, `scale`).

### LabManager.gd:185-186
```gdscript
var position = definition.get("position", [0, 0, 0])  # shadows Node3D.position
var rotation = definition.get("rotation", [0, 0, 0])  # shadows Node3D.rotation
```

**Fix:** Rename to `pos_array` and `rot_array`:
```gdscript
var pos_array = definition.get("position", [0, 0, 0])
var rot_array = definition.get("rotation", [0, 0, 0])
artifact_instance.position = Vector3(pos_array[0], pos_array[1], pos_array[2])
artifact_instance.rotation_degrees = Vector3(rot_array[0], rot_array[1], rot_array[2])
```

### Files with `var position` shadowing (~170 instances)

| Category | Files | Notes |
|----------|-------|-------|
| Inner classes | ~50 files | `var position: Vector3` in class definitions — OK, different scope |
| Local loop vars | ~40 files | `var position = Vector3(...)` in for loops |
| Function params | ~30 files | Shadowing in local scope |
| Grid components | 8 instances | GridInteractablesComponent, GridUtilitiesComponent, etc. |
| Axiom files | ~20 files | Tutorial/info displays |

### Files with `var rotation` shadowing (~35 instances)

Key files:
- `LabManager.gd:186`
- `GridInteractablesComponent.gd:315`
- `GridSpawnComponent.gd:152`
- Multiple VR examples

### Files with `var scale` shadowing (~100+ instances)

Primarily in:
- Audio synthesizer code (AudioSynthesizer.gd has 20+ instances)
- Shader parameter code
- Visualization code

---

## Unused Variables

### CustomSoundGenerator.gd:1784
```gdscript
var chord_voicing = params.get("chord_voicing", "jazz_7th")  # declared but never used
```

**Fix:** Either use the variable or prefix with underscore:
```gdscript
var _chord_voicing = params.get("chord_voicing", "jazz_7th")
```

---

## Quick Fixes

### 1. LabManager.gd (most visible warning)

```gdscript
# Before
func _apply_artifact_transform(artifact_instance: Node3D, definition: Dictionary):
	var position = definition.get("position", [0, 0, 0])
	var rotation = definition.get("rotation", [0, 0, 0])
	var scale_def = definition.get("scale", [1, 1, 1])
	
	artifact_instance.position = Vector3(position[0], position[1], position[2])
	artifact_instance.rotation_degrees = Vector3(rotation[0], rotation[1], rotation[2])
	artifact_instance.scale = Vector3(scale_def[0], scale_def[1], scale_def[2])

# After
func _apply_artifact_transform(artifact_instance: Node3D, definition: Dictionary):
	var pos_def = definition.get("position", [0, 0, 0])
	var rot_def = definition.get("rotation", [0, 0, 0])
	var scale_def = definition.get("scale", [1, 1, 1])
	
	artifact_instance.position = Vector3(pos_def[0], pos_def[1], pos_def[2])
	artifact_instance.rotation_degrees = Vector3(rot_def[0], rot_def[1], rot_def[2])
	artifact_instance.scale = Vector3(scale_def[0], scale_def[1], scale_def[2])
```

### 2. CustomSoundGenerator.gd:1784

```gdscript
# Before
var chord_voicing = params.get("chord_voicing", "jazz_7th")

# After (if unused intentionally)
var _chord_voicing = params.get("chord_voicing", "jazz_7th")

# Or remove entirely if truly unused
```

---

## Batch Fix Commands

To find all instances for review:

```powershell
# Find all shadowed position variables
Get-ChildItem -Recurse -Filter "*.gd" | 
  Where-Object { $_.FullName -notmatch "\.godot|android" } | 
  Select-String -Pattern "var position\s*[=:]" |
  Group-Object Path |
  Select-Object Count, Name

# Find all shadowed rotation variables
Get-ChildItem -Recurse -Filter "*.gd" | 
  Where-Object { $_.FullName -notmatch "\.godot|android" } | 
  Select-String -Pattern "var rotation\s*[=:]"
```

---

## Notes

1. **Inner class properties are OK** — `var position: Vector3` inside a class definition doesn't shadow the parent's property
2. **Loop variables are sometimes OK** — if the function doesn't need `self.position`
3. **Most critical:** Manager/component code where confusion is likely

## Recommended Priority

1. ✅ Fix `LabManager.gd` (visible in editor output)
2. ✅ Fix `CustomSoundGenerator.gd` unused variable
3. 🔄 Review Grid components (GridInteractablesComponent, GridUtilitiesComponent)
4. ⏳ Low priority: Inner class definitions (technically fine, just warnings)

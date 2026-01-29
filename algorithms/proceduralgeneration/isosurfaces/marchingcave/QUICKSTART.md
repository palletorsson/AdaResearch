# Quick Start Guide 🚀

## Load These Scenes Directly

Just open any of these scenes in Godot to see them in action!

### 1. 🏔️ Original Cave (External View)
```
res://algorithms/proceduralgeneration/marchingcave/Scenes/marchingcubes_cave.tscn
```
**What you'll see**: A dense cave network from outside, with atmospheric torch lighting

---

### 2. 🌄 Flat Landscape with Caves
```
res://algorithms/proceduralgeneration/marchingcave/Scenes/marchingcubes_flat_landscape.tscn
```
**What you'll see**: Rolling hills with occasional underground cave pockets, bright outdoor lighting

**NEW!** ⭐

---

### 3. 🎭 Torus Sculpture (Art Installation)
```
res://algorithms/proceduralgeneration/marchingcave/Scenes/marchingcubes_torus_sculpture.tscn
```
**What you'll see**: An organic twisted donut-shaped sculpture with gallery spotlights

**NEW!** ⭐

---

### 4. 🕯️ Inside Cave (First-Person)
```
res://algorithms/proceduralgeneration/marchingcave/Scenes/marchingcubes_inside_cave.tscn
```
**What you'll see**: You start INSIDE a cave with a torch, volumetric fog, dramatic lighting

**NEW!** ⭐

---

## First Time Setup

1. **Open Godot 4.x**
2. **Load any scene above**
3. **Wait 2-5 seconds** for compute shader to generate mesh
4. **Press F6** (Play Scene) to see it live

---

## If You See "Fallback Mesh"

Some systems don't support compute shaders. You'll see:
- **Flat Landscape**: Simple grid with hills ✅ Still looks good!
- **Torus**: Basic torus mesh ✅ Still a donut!
- **Cave**: Procedural tunnel ✅ Still playable!

This is **normal and okay** - the fallbacks are designed to look good too!

---

## Quick Tweaks

Select the main `Terrain` or `TorusSculpture` node in the scene tree and adjust:

### More/Fewer Caves (Landscape)
- **Inspector → iso_level**
- `-0.2` = LOTS of caves
- `0.2` = Very few caves

### Different Random Shape
- **Inspector → noise_offset**
- Change `X`, `Y`, or `Z` to any number
- Instant new landscape!

### Bigger/Smaller Area
- **Inspector → chunk_scale**
- `200` = Small, detailed
- `500` = Huge, spread out

---

## Camera Controls in Play Mode

When you press **F6** (Play Scene):

- **Right-click + Mouse**: Look around
- **WASD**: Move (if scene has movement script)
- **Mouse wheel**: Zoom in/out (camera scenes only)
- **ESC**: Exit play mode

---

## Which Scene Should I Try First?

### For Beauty
→ **Torus Sculpture** (most visually striking)

### For Exploration
→ **Inside Cave** (immersive first-person)

### For Open World
→ **Flat Landscape** (terrain with caves)

### For Understanding
→ **Original Cave** (see the classic implementation)

---

## Next Steps

1. **Read `VARIANTS_README.md`** for full technical details
2. **Edit the shaders** in `Compute/` folder to customize shapes
3. **Tweak lighting** in each scene for different moods
4. **Create your own variant** following the guide in VARIANTS_README.md

---

## Performance Tips

If running slow:
1. Lower `chunk_scale` to 150-200
2. Close other programs
3. Run in Release mode instead of Debug
4. Use fallback mesh (set `use_fallback = true` in script)

---

## Common Questions

**Q: Why does generation take a few seconds?**
A: The compute shader is calculating millions of voxels and generating complex geometry. This is normal!

**Q: Can I move the camera in the editor?**
A: Yes! Select the Camera3D node and move it around in the 3D viewport.

**Q: Can I add my own materials?**
A: Absolutely! The mesh uses `TerrainMat.tres` - duplicate it and customize!

**Q: Can I export this to VR?**
A: Yes! These scenes work great in VR. Add XR camera and controllers.

**Q: Why is my torus different from the screenshot?**
A: The `noise_offset` creates variation. Change it to match, or embrace your unique sculpture!

---

## Troubleshooting

### Nothing appears
- Wait 5-10 seconds for compute shader
- Check console for errors
- Try setting `use_fallback = true`

### Crashes on load
- Your GPU might not support compute shaders
- Enable `use_fallback = true` before loading

### Weird shapes
- This is procedural - variation is expected!
- Adjust `noise_offset` for different results
- Lower `noise_scale` for smoother shapes

---

## Have Fun! 🎉

These scenes are meant to be **explored and modified**. Don't be afraid to:
- Change numbers
- Move lights around
- Edit shaders
- Break things (you can always reload!)

The best way to learn is to **experiment**! 🧪

---

## License

MIT License - See `MITLicenseForMarchingCubes.txt`

Free to use in your projects! 💚


# ⚠️ GENERATE TILES FIRST! ⚠️

## You're seeing a checker pattern grid because tiles don't exist yet!

---

## 🚀 DO THIS NOW (Takes 10 seconds)

### 1️⃣ Open the Tile Generator
```
File → Open Script: wfc_rooms.gd
```
Or navigate to:
```
algorithms/proceduralgeneration/wfcRooms/wfc_rooms.gd
```

### 2️⃣ Run It
```
File → Run
```
Or press: **`Ctrl + Shift + X`**

### 3️⃣ Wait for Success Message
Look in the **Output** panel for:
```
✅ Done! Copy the tile set you want into wfc_rooms.gd
Saved: res://RoomTiles_Aligned.tscn
```

### 4️⃣ Reload and Play
```
1. Close wfc_dungeon_generator.tscn
2. Reopen it
3. Press F6 (Play Scene)
4. 🎉 See your dungeon!
```

---

## 📺 What You'll See After

**Before (Now):** Checker pattern grid
```
□ ■ □ ■ □ ■
■ □ ■ □ ■ □
□ ■ □ ■ □ ■
```

**After:** 3D dungeon with rooms and hallways!
```
┌───┬───┐   ┌───┐
│   │   ├───┤   │
├───┤   │   └───┤
│   └───┘       │
└───────────────┘
```

---

## 🔍 Troubleshooting

### "I don't see wfc_rooms.gd"
- **Path:** `algorithms/proceduralgeneration/wfcRooms/wfc_rooms.gd`
- **In FileSystem panel:** Navigate to the folder above
- **Right-click** → Open in Script Editor

### "Nothing happens when I run it"
- Check the **Output** panel (bottom of screen)
- Look for error messages
- Make sure you're running wfc_rooms.gd, not wfc_solver.gd

### "I got an error"
- Make sure you're in the **Script Editor** (not Scene view)
- The file should say `@tool extends EditorScript` at the top
- Try closing and reopening Godot

### "I ran it but still see checker pattern"
- **Reload the scene:** Close wfc_dungeon_generator.tscn and reopen
- **Or:** Press `Ctrl+R` to reload current scene
- Check FileSystem for `RoomTiles_Aligned.tscn`

---

## ❓ Why Do I Need to Do This?

The WFC dungeon generator needs **tile templates** to work with. Think of it like:

1. **wfc_rooms.gd** = Creates the puzzle pieces (tiles)
2. **wfc_solver.gd** = Puts the puzzle together (dungeon)
3. **wfc_dungeon_generator.tscn** = Shows you the result

You only run step 1 **once** (or when you want different tiles).

---

## 🎨 Want Different Tiles?

After generating the default tiles, you can customize:

1. Open `tile_template_examples.gd`
2. Run it to see 7 different tile sets
3. Copy one you like into `wfc_rooms.gd`
4. Re-run `wfc_rooms.gd`
5. Reload scene

---

## 📋 Quick Reference

| Action | What to Do |
|--------|-----------|
| **Generate tiles** | Run wfc_rooms.gd (Ctrl+Shift+X) |
| **View dungeon** | Play wfc_dungeon_generator.tscn (F6) |
| **New layout** | Change `generation_seed` in Inspector |
| **Bigger dungeon** | Change `grid_width`/`grid_height` |
| **Different tiles** | Edit wfc_rooms.gd, re-run |

---

## ✅ Success Checklist

- [ ] Opened wfc_rooms.gd in Script Editor
- [ ] Ran it (Ctrl+Shift+X)
- [ ] Saw "Saved: res://RoomTiles_Aligned.tscn" in Output
- [ ] Reloaded wfc_dungeon_generator.tscn
- [ ] Pressed F6 and saw dungeon (not checker pattern)

---

**Still stuck?** See `START_HERE.md` or `README.md` for more help!


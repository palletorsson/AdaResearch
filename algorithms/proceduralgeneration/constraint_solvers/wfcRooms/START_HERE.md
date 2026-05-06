# WFC Rooms - Start Here! 👋

## Why You See Nothing

The WFC dungeon generator needs **tile templates** to work. You haven't generated them yet!

---

## 🚀 Quick Fix (2 Steps)

### Step 1: Generate Tiles
```
1. Open wfc_rooms.gd in the Script Editor
2. Click "File" → "Run" (or press Ctrl+Shift+X)
3. Wait 2 seconds
4. This creates RoomTiles_Aligned.tscn
```

### Step 2: View Result
```
1. Open wfc_dungeon_generator.tscn again (or reload it)
2. Press F6 to play
3. Now you'll see a procedural dungeon!
```

---

## What Just Happened?

### wfc_rooms.gd (Tile Generator)
- **EditorScript** that runs once
- Creates 18 different room tiles
- Saves them to `algorithms/proceduralgeneration/wfcRooms/RoomTiles_Aligned.tscn`
- Each tile has walls, doors, or openings

### wfc_dungeon_generator.tscn (Dungeon Generator)
- **Runtime scene** that uses the tiles
- Reads tiles from `algorithms/proceduralgeneration/wfcRooms/RoomTiles_Aligned.tscn`
- Uses Wave Function Collapse algorithm
- Generates a 12x12 dungeon grid

---

## 📋 Complete Workflow

```
1. Run wfc_rooms.gd
   ↓ Creates tiles
   
2. Open wfc_dungeon_generator.tscn
   ↓ Uses those tiles
   
3. Press F6
   ↓ Generates dungeon
   
4. Success! 🎉
```

---

## 🎨 If You See a Checker Pattern

That's the **fallback grid** - it means tiles aren't generated yet.

Follow Step 1 above to fix it!

---

## 🔧 Customization

After generating tiles, you can:

**Adjust Grid Size**
- Select root node in wfc_dungeon_generator.tscn
- Change `grid_width` and `grid_height` in Inspector
- Bigger = larger dungeon

**Different Layout**
- Change `generation_seed` in Inspector
- Different number = different dungeon
- Same number = same dungeon every time

**Custom Tiles**
- Open `tile_template_examples.gd`
- Copy one of the 7 example tile sets
- Paste into `wfc_rooms.gd`
- Re-run wfc_rooms.gd

---

## 📁 File Reference

| File | Purpose | When to Use |
|------|---------|-------------|
| `wfc_rooms.gd` | **Generate tiles** | Run once before anything else |
| `wfc_dungeon_generator.tscn` | **See dungeon** | Play after tiles exist |
| `tile_template_examples.gd` | **Get ideas** | Copy templates from here |
| `RoomTiles_Aligned.tscn` | **The tiles** | Created by wfc_rooms.gd |

---

## ❓ Still Not Working?

### Check 1: Did wfc_rooms.gd run successfully?
- Look for "Saved: res://RoomTiles_Aligned.tscn" in Output
- Check FileSystem panel for RoomTiles_Aligned.tscn

### Check 2: Is the path correct?
- wfc_dungeon_generator.tscn should have:
- `tiles_scene_path = "res://algorithms/proceduralgeneration/wfcRooms/RoomTiles_Aligned.tscn"`

### Check 3: Reload the scene
- Close and reopen wfc_dungeon_generator.tscn
- Or press Ctrl+R to reload

---

## 🎓 Understanding the System

```
wfc_rooms.gd
    ↓ Generates
RoomTiles_Aligned.tscn (18 tiles)
    ↓ Used by
wfc_solver.gd
    ↓ Creates
Procedural Dungeon (12x12 rooms)
```

---

## 🎯 Next Steps

1. ✅ Generate tiles (wfc_rooms.gd)
2. ✅ View dungeon (wfc_dungeon_generator.tscn)
3. 📖 Read README.md for full documentation
4. 🎨 Try different tile templates
5. 🔧 Customize parameters
6. 🎮 Use in your game!

---

## 💡 Pro Tip

Save yourself time - **bookmark this workflow**:

```bash
# Every time you want to change tiles:
1. Edit wfc_rooms.gd tile array
2. Run wfc_rooms.gd (Ctrl+Shift+X)
3. Reload wfc_dungeon_generator.tscn
4. Play (F6)
```

---

Need more help? See:
- `QUICKSTART.md` - Quick reference
- `README.md` - Full documentation
- `WFC_GUIDE.md` - Customization guide

Happy dungeon generating! 🏰✨


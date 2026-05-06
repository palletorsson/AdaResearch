# 🐟 BLOBFISH PARTICLE SWARM

**Particles that move together like a jiggly blob creature!**

---

## 🎬 HOW TO SEE IT

**Open in Godot:**
```
res://algorithms/particles/example_particle_body.tscn
```

**Press F6** to run!

---

## 🐠 WHAT IT DOES

The particles behave like a **blobfish** using flocking algorithms:

1. **Cohesion** - Stay together as a group
2. **Separation** - Don't overlap (personal space)
3. **Alignment** - Move in same direction
4. **Wiggle** - Organic, jiggly motion
5. **Swimming** - Moves through space like a fish
6. **Buoyancy** - Slight upward drift

**Result:** A living, breathing, swimming blob creature! 🐟

---

## 🎮 CONTROLS

### **Nudge the Blob:**
- `W` - Nudge forward
- `A` - Nudge left
- `D` - Nudge right
- `Q` - Nudge up
- `E` - Nudge down
- `Space` - Random swim direction

### **Adjust Speed:**
- `↑` - Swim faster
- `↓` - Swim slower

### **Adjust Wiggle:**
- `←` - Less jiggly
- `→` - More jiggly

### **Change Appearance:**
- `1-6` - Connection modes
- `S` - Toggle surface/lines
- `+/-` - More/fewer connections

---

## 🌊 WHAT YOU'LL SEE

**Initial spawn:**
- 25 particles appear
- They cluster together
- Lines/surface connects them

**After a few seconds:**
- Blob starts swimming
- Organic wiggling motion
- Changes direction every 3 seconds
- Looks alive!

**With surface mode (S):**
- Semi-transparent purple skin
- Jiggly blob creature
- Like a jellyfish or blobfish!

---

## 🎨 RECOMMENDED SETTINGS

**Best visual (press these keys):**
1. Press `2` - NEAREST connections
2. Press `S` - Surface mode ON
3. Press `→` a few times - More wiggle
4. Watch it swim! 🐟

**Energy creature:**
1. Press `2` - NEAREST connections
2. Press `S` - Surface mode OFF (lines only)
3. Press `+` a few times - Dense web
4. Looks like energy being!

**Outline creature:**
1. Press `3` - OUTER_HULL
2. Press `S` - Surface mode ON
3. See the blob's boundary swim!

---

## 🔧 HOW IT WORKS

### **Flocking Behavior:**

The blob uses **Craig Reynolds' Boids algorithm**:

```
For each particle:
  1. Cohesion: Move toward blob center
  2. Separation: Avoid crowding neighbors
  3. Alignment: Match neighbors' velocity
  4. Swim: Follow overall direction
  5. Wiggle: Add organic motion
  6. Buoyancy: Float upward slightly
```

### **Organic Motion:**

```gdscript
wiggle = sin(time + position) * amplitude
```

Creates natural, wave-like movement!

---

## 💡 CREATIVE IDEAS

**1. Blobfish Pet**
- Follows player
- Reacts to touch
- Changes color based on mood

**2. Energy Shield**
- Surrounds player
- Deflects projectiles
- Pulses when hit

**3. Alien Creature**
- Swims through environment
- Avoids obstacles
- Hunts/flees

**4. Procedural Animation**
- No keyframes needed
- Fully physics-based
- Adapts to environment

---

## ⚙️ PARAMETERS

Edit `blobfish_swarm.gd` or adjust in inspector:

```gdscript
blob_radius = 0.4           # Size of blob
swim_speed = 0.3            # How fast it moves
wiggle_frequency = 2.0      # Wiggle speed
wiggle_amplitude = 0.15     # Wiggle amount
cohesion_strength = 1.5     # Stay together
separation_strength = 0.8   # Personal space
buoyancy = 0.2              # Upward drift
```

---

## 🎯 EXPERIMENTS

### **Experiment 1: Fast Wiggler**
```
↑↑↑ (faster swim)
→→→ (more wiggle)
Result: Energetic blob!
```

### **Experiment 2: Slow Drifter**
```
↓↓↓ (slower swim)
←←← (less wiggle)
Result: Calm, floating blob
```

### **Experiment 3: Dense Creature**
```
Press 2 (NEAREST)
Press + + + + (many connections)
Press S (surface ON)
Result: Solid, organic creature
```

---

## 🐟 BLOBFISH FACTS

The code mimics real blobfish behavior:
- ✅ Gelatinous body (surface mode)
- ✅ Slow swimming (adjustable speed)
- ✅ Buoyancy (slight upward drift)
- ✅ Jiggly movement (wiggle)
- ✅ Cohesive form (flocking)

---

## 📁 FILES

- `core/blobfish_swarm.gd` - Flocking behavior (180 lines)
- `core/particle_body.gd` - Body visualization
- `algorithms/particles/example_particle_body.gd` - Demo
- `algorithms/particles/example_particle_body.tscn` - Scene ⭐

---

**Open the scene and watch your blob swim!** 🐟✨

**Path:** `res://algorithms/particles/example_particle_body.tscn`

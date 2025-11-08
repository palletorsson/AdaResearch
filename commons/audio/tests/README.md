# 🎵 Audio Test Scenes

Test scenes for previewing and experimenting with the audio system!

---

## 📋 Available Test Scenes

### 1. Trap Sequencer (`test_trap_sequencer.tscn`)
Test the basic trap beats sequencer with preset patterns.
- **Focus**: Trap beat patterns only
- **Controls**: Pattern switching, BPM, swing
- **Best for**: Quick trap beat preview

### 2. Sound Suite Sequencer (`test_sound_suite_sequencer.tscn`)
Test the full sound suite system with multiple sound suites and individual control.
- **Focus**: Multiple sound suites (trap, tech noir, etc.)
- **Controls**: Suite switching, pattern selection, individual sound parameter control
- **Best for**: Experimenting with different sound suites and custom parameters

---

## 🚀 How to Run (Both Scenes):

### Option 1: Run Scene Directly (Easiest)
1. Open Godot
2. In **FileSystem** tab, navigate to `commons/audio/tests/`
3. Find `test_trap_sequencer.tscn`
4. **Right-click** → **Run Scene** (or press **F6** when scene is open)
5. **Listen to the beats!** 🔥

### Option 2: Set as Main Scene
1. Open `test_trap_sequencer.tscn`
2. Click **Scene** → **Set as Main Scene**
3. Press **F5** to run
4. Enjoy!

---

## 🎛️ Controls:

### Pattern Selection (Press Number Keys)
- **1** - Minimal Trap (sparse, chill - 85 BPM)
- **2** - Hard Trap (aggressive, hard-hitting)
- **3** - Drill (UK drill style - 140 BPM)
- **4** - Triplet Trap (bouncy triplet groove)
- **5** - Ambient Sparse (very minimal)

### Playback Control
- **SPACE** - Play/Stop

### Real-Time Adjustments
- **UP Arrow** - Increase BPM (+5)
- **DOWN Arrow** - Decrease BPM (-5)
- **RIGHT Arrow** - More swing (+0.05)
- **LEFT Arrow** - Less swing (-0.05)

---

## 🎼 What You'll Hear:

### Pattern 1: Minimal Trap (Default)
```
Kick:    X...........X.....
Snare:   ....X.......X.....
HH Cls:  ..X...X...X...X...
HH Opn:  ...............X..
```
Perfect for chill/ambient vibes

### Pattern 2: Hard Trap
```
Kick:    X.....X.X.X.......
Snare:   ....X.......X.....
Clap:    ....X.......X.....
HH Cls:  ..X...X...X...X...
```
Aggressive and punchy

### Pattern 3: Drill
```
32-step pattern with:
- Rolling hi-hats
- Skippy kick pattern
- Sparse snares
- 808 rim accents
```
UK drill energy @ 140 BPM

### Pattern 4: Triplet Trap
```
24-step triplet pattern
Bouncy, swung groove
```

### Pattern 5: Ambient Sparse
```
Kick:    X...............
HH Cls:  ....X...........
Rim:     .........X......
```
Minimal percussion for ambient scenes

---

## 🔧 Troubleshooting:

### No Sound?
1. **Check Console** - Look for error messages
2. **Verify SoundBank** - Make sure `SoundBankSingleton.gd` is registered as AutoLoad:
   - Go to **Project → Project Settings → AutoLoad**
   - Check if `SoundBank` is there
   - If not, add it:
     - Path: `res://commons/audio/SoundBankSingleton.gd`
     - Name: `SoundBank`
     - Enable: ✅

3. **Check Audio Output** - Make sure Godot audio isn't muted

### Console Shows Warnings?
- If you see **"SoundBank singleton not found"**:
  - Follow step 2 above to add SoundBank as AutoLoad
  - Restart the scene

### Pattern Sounds Wrong?
- Try changing patterns (press 1-5)
- Adjust BPM (UP/DOWN arrows)
- Reset swing to 0 (press LEFT arrow multiple times)

---

## 🎚️ Example Session:

```
1. Press F6 to run scene
   → Minimal trap starts playing @ 85 BPM

2. Press "2" to switch to hard trap
   → More aggressive pattern

3. Press UP arrow 10 times
   → BPM increases to 135 BPM (double-time feel)

4. Press RIGHT arrow 4 times
   → Swing increases to 0.35 (bouncy groove)

5. Press "3" for drill pattern
   → UK drill vibes @ 135 BPM

6. Press SPACE to stop
   → Sequencer pauses

7. Press SPACE again
   → Sequencer resumes
```

---

## 🎵 Next Steps:

Once you've previewed patterns here, integrate them into your maps:

### Add to map_sequences.json:
```json
{
  "sequences": {
    "your_sequence": {
      "trap_sequencer": {
        "enabled": true,
        "pattern": "minimal_trap",
        "bpm": 85.0,
        "swing": 0.15,
        "master_volume": -8.0
      }
    }
  }
}
```

---

## 📝 Notes:

- **First time running**: May take a moment to generate sounds
- **Pattern changes**: Happen smoothly without stopping playback
- **BPM range**: 40-200 BPM (clamped automatically)
- **Swing range**: 0.0-1.0 (0 = straight, 1 = max swing)

---

**Enjoy your trap beats!** 🔥💥

For full documentation, see: `commons/audio/TRAP_AUTOMATION_GUIDE.md`

---
---

# 🎨 Sound Suite Sequencer Test Scene

Advanced test scene for exploring multiple sound suites with individual parameter control!

## 🚀 How to Run:

1. Open Godot
2. Navigate to `commons/audio/tests/`
3. Find `test_sound_suite_sequencer.tscn`
4. **Right-click** → **Run Scene** (F6)
5. **Experiment with different sound suites!** 🎨

---

## 🎛️ Controls:

### Suite Selection
- **1** - Trap Beats (drums)
- **2** - Tech Noir (ambient/atmospheric)

### Pattern Selection (Trap Beats)
- **Q** - Minimal trap (sparse, chill)
- **W** - Hard trap (aggressive)
- **E** - Four-on-floor (classic)

### Pattern Selection (Tech Noir)
- **Q** - Ambient sparse (minimal atmosphere)
- **W** - Atmospheric layers (dense soundscape)

### Playback Control
- **SPACE** - Play/Stop
- **UP/DOWN** - BPM ±5
- **LEFT/RIGHT** - Swing ±0.05

### Sound Parameter Control (Trap Beats)
- **K** - Kick pitch +5
- **J** - Kick pitch -5
- **S** - Snare decay +0.1
- **A** - Snare decay -0.1
- **H** - Hihat tone +1000 Hz
- **G** - Hihat tone -1000 Hz

---

## 🎨 What You Can Do:

### 1. Switch Between Sound Suites

Start with trap beats, then switch to tech noir to hear completely different sounds:

```
1. Press "1" for Trap Beats
   → Drums and percussion

2. Press "2" for Tech Noir
   → Ambient atmosphere and drones

3. Press "Q" to load a pattern
   → Different pattern per suite!
```

### 2. Control Individual Sounds

Customize the sound of each instrument in real-time:

```
1. Press "1" for Trap Beats
2. Press "K" multiple times
   → Kick pitch goes up (deeper to higher)

3. Press "S" multiple times
   → Snare decay increases (short snap to long ring)

4. Press "H" multiple times
   → Hihat gets brighter
```

### 3. Create Dynamic Soundscapes (Tech Noir)

```
1. Press "2" for Tech Noir suite
2. Press "W" for atmospheric layers
3. Adjust BPM to 60 (press DOWN many times)
   → Sparse, cinematic atmosphere
```

### 4. Experiment with Swing and BPM

```
1. Start with minimal trap (press "1" then "Q")
2. Increase BPM to 140 (press UP many times)
   → Double-time feel

3. Add swing to 0.5 (press RIGHT 10 times)
   → Bouncy, triplet groove

4. Now it sounds like trap at high energy!
```

---

## 🎼 Example Session:

```
1. Press F6 to run scene
   → Starts with trap beats @ 85 BPM

2. Press "K" 5 times
   → Kick pitch increases (sounds higher)

3. Press "W"
   → Switch to hard trap pattern (more aggressive)

4. Press UP 10 times
   → BPM now 135 (faster, more energetic)

5. Press "2"
   → Switch to Tech Noir suite
   → Same pattern, completely different sounds!

6. Press "Q"
   → Load ambient sparse pattern
   → Slow, atmospheric drones

7. Press DOWN 10 times
   → BPM 85 again (slow atmosphere)

8. Experiment with switching back and forth!
```

---

## 🔧 Key Features:

### Multi-Suite Support
- Switch between trap beats, tech noir, and future suites
- Each suite has completely different sounds
- Same patterns work across suites

### Individual Sound Control
- Every sound has customizable parameters
- Changes apply in real-time (next trigger)
- Parameters persist when switching patterns

### Pattern System
- Built-in preset patterns per suite
- Patterns adapt to current suite
- Custom patterns can be loaded

### Real-Time Control
- BPM, swing, variation
- Per-track mute and volume
- Suite and pattern hot-swapping

---

## 🎵 Next Steps:

### Integrate Into Your Maps

```json
{
  "audio": {
    "sequencer": {
      "type": "SoundSuiteSequencer",
      "suite": "trap_beats",
      "pattern": "minimal_trap",
      "bpm": 85.0,
      "swing": 0.15,
      "sound_params": {
        "kick": {"pitch": 55.0, "decay": 1.2},
        "snare": {"decay": 0.3}
      }
    }
  }
}
```

### Dynamic Suite Switching

```gdscript
# Switch suite based on game state
func _on_area_entered(area):
    if area.name == "BattleZone":
        sequencer.change_suite("trap_beats")
        sequencer.set_bpm(140.0)
    elif area.name == "CityZone":
        sequencer.change_suite("tech_noir")
        sequencer.set_bpm(60.0)
```

---

## 📝 Notes:

- **Parameter changes** apply to the next triggered sound
- **Suite switching** can happen during playback (no gap)
- **Pattern length** automatically adjusts per pattern
- **BPM range**: 40-200 (auto-clamped)
- **Swing range**: 0.0-1.0

---

**For full documentation, see:** `commons/audio/SOUND_SUITE_SEQUENCER.md`

**Happy experimenting!** 🎨🔥

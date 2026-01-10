**Shader Noise**
GPU Randomness and Hash Functions

**CPU noise is slow.** GPU noise is parallel - thousands of samples per frame.

**Shader noise = procedural generation on the graphics card.**

---

## Why GPU Noise?

**Advantages:**
- **Massively parallel** - Every pixel computed simultaneously
- **Real-time** - Procedural textures without RAM storage
- **Infinite resolution** - No texture memory limits
- **Dynamic** - Animate noise with time parameter

**Challenges:**
- **No random()** - GPUs are deterministic
- **Hash functions** - Pseudo-random from coordinates
- **Limited precision** - Floating-point artifacts

---

Hash Function (Deterministic
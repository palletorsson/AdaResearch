# PARTICLE RESOURCES - AUTOLOAD SETUP INSTRUCTIONS

**Issue:** Static methods not working in Godot  
**Solution:** Use Godot's Autoload (Singleton) system  
**Date:** 2025-12-01T13:36:00Z

---

## 🔧 SETUP REQUIRED

ParticleResources needs to be added as an **Autoload** in Godot project settings.

### **Steps to Fix:**

1. **Open Godot Editor**

2. **Go to Project Settings**
   - Menu: `Project` → `Project Settings`

3. **Navigate to Autoload Tab**
   - Click on the `Autoload` tab

4. **Add ParticleResources**
   - Path: `res://core/particle_resources.gd`
   - Node Name: `ParticleResources`
   - Click `Add`

5. **Save and Reload**
   - Close Project Settings
   - Reload the project (or restart Godot)

---

## ✅ VERIFICATION

After adding as autoload, you should be able to call:

```gdscript
ParticleResources.get_sphere_mesh()
ParticleResources.get_particle_material()
```

The autoload makes it globally accessible as a singleton.

---

## 🎯 ALTERNATIVE: Use Instance Pattern

If you don't want to use autoload, we can change the code to use an instance pattern instead.

Let me know which approach you prefer!

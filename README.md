# AdaResearch



## Get started: 
= Setting Up XR in Godot =

== 1. Install Godot ==
* Download and install the latest version of Godot from the [https://godotengine.org/ official website].

== 2. Create a New Project ==
* Launch Godot and create a new project.
* In the Project Settings, navigate to the '''Rendering > XR''' section.
* Enable '''XR Features''' to ensure XR support is active.

== 3. Set Up the XR Scene ==
* Add an '''XROrigin3D''' node to your scene; this serves as the reference point for all XR tracking.
* As children of the XROrigin3D node, add:
  * An '''XRCamera3D''' node to represent the player's viewpoint.
  * Two '''XRController3D''' nodes for the left and right hand controllers.
* Position these nodes appropriately to match typical user ergonomics.

== 4. Install Godot XR Tools ==
* Download the latest release of Godot XR Tools from the [https://github.com/GodotVR/godot-xr-tools/releases GitHub releases page].
* Extract the contents and place the '''godot-xr-tools''' folder into the '''addons''' directory of your project.
* In the Godot editor, go to '''Project > Project Settings > Plugins''' and enable the Godot XR Tools plugin.

== 5. Initialize XR in Your Project ==
* Attach a script to your main scene node (e.g., XROrigin3D) with the following code:

  <syntaxhighlight lang="gdscript">
  extends Node3D

  func _ready():
      var xr_interface = XRServer.find_interface("OpenXR")
      if xr_interface and xr_interface.initialize():
          get_viewport().use_xr = true
          DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
      else:
          print("OpenXR not initialized. Please check your headset connection.")
  </syntaxhighlight>

* This script initializes the OpenXR interface and configures the viewport for XR rendering.

== 6. Install Godot Jolt (Optional for Physics) ==
* If your XR project requires advanced physics, consider installing the Godot Jolt plugin.
* Download it from the [https://godotengine.org/asset-library/asset/1918 Godot Asset Library] and follow the installation instructions provided.

== 7. Test Your Setup ==
* Connect your XR hardware and run the project to ensure everything is functioning correctly.
* Use the Godot editor's output console to monitor for any initialization messages or errors.

For a visual walkthrough and additional guidance, you might find this tutorial helpful:

[https://www.youtube.com/watch?v=BrNZs4XzU0w Getting Started With XR in Godot 4.3 Tutorial]

By following these steps, you should have a functional XR setup in Godot, ready for further development.

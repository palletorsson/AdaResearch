using Sandbox;
using System;

/// <summary>
/// Minimal locomotion for the Ada VR test scene.
///
/// VR (headset connected): left stick = smooth locomotion relative to gaze,
/// right stick = snap turn. The VRAnchor on this GameObject moves the playspace.
/// Desktop (no headset): WASD + hold right mouse to look — so the scene can be
/// checked without a headset.
///
/// Both modes ground-clamp with a downward trace onto the grid columns.
/// </summary>
public sealed class AdaVRPlayer : Component
{
	[Property] public float MoveSpeedMeters { get; set; } = 2.5f;
	[Property] public float SnapTurnDegrees { get; set; } = 30f;

	private CameraComponent _camera;
	private bool _snapReady = true;
	private float _pitch;

	protected override void OnStart()
	{
		_camera = Components.GetInChildrenOrSelf<CameraComponent>();

		// simple hand visuals — small tinted cubes on the tracked hand objects
		if ( Game.IsRunningInVR )
		{
			MakeHandVisual( "Left Hand", new Color( 0.3f, 0.8f, 0.9f ) );
			MakeHandVisual( "Right Hand", new Color( 0.9f, 0.5f, 0.3f ) );
		}
	}

	private void MakeHandVisual( string handName, Color tint )
	{
		var hand = GameObject.Children.Find( c => c.Name == handName );
		if ( hand == null ) return;

		var box = Model.Load( "models/dev/box.vmdl" );
		var boxSize = box?.Bounds.Size ?? new Vector3( 50f );
		if ( boxSize.x < 0.01f ) boxSize = new Vector3( 50f );

		var visual = new GameObject( true, $"{handName} Visual" );
		visual.Parent = hand;
		visual.LocalPosition = Vector3.Zero;
		var size = 0.08f * AdaMapBuilder.MetersToUnits;
		visual.LocalScale = new Vector3( size / boxSize.x, size / boxSize.y, size / boxSize.z );

		var renderer = visual.Components.Create<ModelRenderer>();
		renderer.Model = box;
		renderer.Tint = tint;
	}

	protected override void OnUpdate()
	{
		if ( Game.IsRunningInVR )
			UpdateVR();
		else
			UpdateDesktop();

		GroundClamp();
	}

	private void UpdateVR()
	{
		var speed = MoveSpeedMeters * AdaMapBuilder.MetersToUnits;

		// left stick: smooth locomotion relative to where the head is looking
		var joy = Input.VR.LeftHand.Joystick.Value;
		if ( joy.Length > 0.05f )
		{
			var headRot = _camera?.WorldRotation ?? WorldRotation;
			var fwd = headRot.Forward.WithZ( 0 ).Normal;
			var right = headRot.Right.WithZ( 0 ).Normal;
			WorldPosition += (fwd * joy.y + right * joy.x) * speed * Time.Delta;
		}

		// right stick: snap turn around the head position
		var turn = Input.VR.RightHand.Joystick.Value.x;
		if ( MathF.Abs( turn ) > 0.6f && _snapReady )
		{
			_snapReady = false;
			var pivot = _camera?.WorldPosition ?? WorldPosition;
			var rot = Rotation.FromYaw( -MathF.Sign( turn ) * SnapTurnDegrees );
			var offset = WorldPosition - pivot;
			WorldPosition = pivot + rot * offset;
			WorldRotation = rot * WorldRotation;
		}
		else if ( MathF.Abs( turn ) < 0.2f )
		{
			_snapReady = true;
		}
	}

	private void UpdateDesktop()
	{
		var speed = MoveSpeedMeters * AdaMapBuilder.MetersToUnits;

		if ( Input.Down( "attack2" ) ) // hold right mouse to look
		{
			var look = Input.AnalogLook;
			WorldRotation = Rotation.FromYaw( WorldRotation.Yaw() + look.yaw );
			_pitch = Math.Clamp( _pitch + look.pitch, -85f, 85f );
			if ( _camera != null )
				_camera.LocalRotation = Rotation.FromPitch( _pitch );
		}

		var move = Input.AnalogMove; // x = forward, y = left
		if ( move.Length > 0.01f )
		{
			var fwd = WorldRotation.Forward.WithZ( 0 ).Normal;
			var left = WorldRotation.Left.WithZ( 0 ).Normal;
			WorldPosition += (fwd * move.x + left * move.y) * speed * Time.Delta;
		}
	}

	private void GroundClamp()
	{
		var eye = 0.2f * AdaMapBuilder.MetersToUnits;
		var from = WorldPosition + Vector3.Up * 1.2f * AdaMapBuilder.MetersToUnits;
		var to = WorldPosition - Vector3.Up * 3f * AdaMapBuilder.MetersToUnits;

		var tr = Scene.Trace.Ray( from, to ).IgnoreGameObjectHierarchy( GameObject ).Run();
		if ( tr.Hit )
		{
			var targetZ = tr.HitPosition.z + (Game.IsRunningInVR ? 0f : eye * 8f); // desktop camera sits on the anchor
			WorldPosition = WorldPosition.WithZ( MathX.Lerp( WorldPosition.z, targetZ, Time.Delta * 10f ) );
		}
	}
}

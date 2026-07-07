using Sandbox;
using System;

/// <summary>
/// s&box port of the three Tutorial_Start artifacts: rotating_cube,
/// oscillation_cube, rotation_oscillation_cube. Unknown artifacts render as a
/// static Placeholder so any Ada map loads without erroring.
/// </summary>
public sealed class AdaAnimatedCube : Component
{
	public enum MotionMode { Placeholder, Rotate, Oscillate, Both }

	[Property] public MotionMode Mode { get; set; } = MotionMode.Rotate;
	[Property] public float DegreesPerSecond { get; set; } = 45f;
	[Property] public float OscillationMeters { get; set; } = 0.15f;
	[Property] public float OscillationHz { get; set; } = 0.5f;

	private Vector3 _basePosition;

	protected override void OnStart()
	{
		_basePosition = LocalPosition;
	}

	protected override void OnUpdate()
	{
		if ( Mode is MotionMode.Rotate or MotionMode.Both )
			LocalRotation *= Rotation.FromYaw( DegreesPerSecond * Time.Delta );

		if ( Mode is MotionMode.Oscillate or MotionMode.Both )
		{
			var amp = OscillationMeters * AdaMapBuilder.MetersToUnits;
			var z = MathF.Sin( Time.Now * OscillationHz * MathF.Tau ) * amp;
			LocalPosition = _basePosition + Vector3.Up * z;
		}
	}
}

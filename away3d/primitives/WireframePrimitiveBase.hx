package away3d.primitives;

import away3d.bounds.BoundingVolumeBase;
import away3d.entities.SegmentSet;
import away3d.errors.AbstractMethodError;
import away3d.materials.ColorMaterial;
import away3d.primitives.data.Segment;

import openfl.geom.Vector3D;

class WireframePrimitiveBase extends SegmentSet
{
	public var color(get, set):Int;
	public var thickness(get, set):Float;
	
	private var _geomDirty:Bool = true;
	private var _colorMaterial:ColorMaterial;
	private var _thickness:Float;
	
	public function new(color:Int = 0xffffff, thickness:Float = 1)
	{
		if (thickness <= 0)
			thickness = 1;
		_colorMaterial = new ColorMaterial(color);
		_thickness = thickness;
		mouseEnabled = mouseChildren = false;
		super(_colorMaterial, false);
	}
	
	private function get_color():Int
	{
		return _colorMaterial.color;
	}
	
	private function set_color(value:Int):Int
	{
		_colorMaterial.color = value;
		return value;
	}
	
	private function get_thickness():Float
	{
		return _thickness;
	}
	
	private function set_thickness(value:Float):Float
	{
		_thickness = value;
		for (segment in _segments) {
			segment.thickness = value;
		}
		return value;
	}
	
	override public function removeAllSegments():Void
	{
		super.removeAllSegments();
	}
	
	override private function get_bounds():BoundingVolumeBase
	{
		if (_geomDirty)
			updateGeometry();
		return super.bounds;
	}
	
	private function buildGeometry():Void
	{
		throw new AbstractMethodError();
	}
	
	private function invalidateGeometry():Void
	{
		_geomDirty = true;
		invalidateBounds();
	}
	
	private function updateGeometry():Void
	{
		buildGeometry();
		_geomDirty = false;
	}
	
	private function updateOrAddSegment(index:Int, v0:Vector3D, v1:Vector3D):Void
	{
		var segment:Segment;
		var s:Vector3D, e:Vector3D;

		if ((segment = getSegment(index)) != null) {
			segment.start.copyFrom(v0);
			segment.end.copyFrom(v1);
			segment._halfThickness = _thickness * 0.5;
			updateSegment(segment);
		} else
			addSegment(new LineSegment(v0.clone(), v1.clone(), _thickness));
	}
	
	override private function updateMouseChildren():Void
	{
		_ancestorsAllowMouseEnabled = false;
	}
}
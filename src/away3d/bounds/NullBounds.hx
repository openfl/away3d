package away3d.bounds;

	import away3d.core.base.*;
	import away3d.core.math.Plane3D;
	import away3d.core.math.PlaneClassification;
	import away3d.primitives.*;
	
	import flash.geom.Vector3D;
	import away3d.geom.Matrix3D;

	
	/**
	 * NullBounds represents a debug bounding "volume" that is either considered always in, or always out of the frustum.
	 * NullBounds is useful for entities that are always considered in the frustum, such as directional lights or skyboxes.
	 */
	class NullBounds extends BoundingVolumeBase
	{
		var _alwaysIn:Bool;
		var _renderable:WireframePrimitiveBase;
		
		public function new(alwaysIn:Bool = true, renderable:WireframePrimitiveBase = null)
		{
			super();
			_alwaysIn = alwaysIn;
			_renderable = renderable;
			_max.x = _max.y = _max.z = Math.POSITIVE_INFINITY;
			_min.x = _min.y = _min.z = _alwaysIn? Math.NEGATIVE_INFINITY : Math.POSITIVE_INFINITY;
		}
		
		override public function clone():BoundingVolumeBase
		{
			return new NullBounds(_alwaysIn);
		}
		
		override private function createBoundingRenderable():WireframePrimitiveBase
		{
			if (_renderable!=null) return _renderable;
			return new WireframeSphere(100, 16, 12, 0xffffff, 0.5);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function isInFrustum(planes:Array<Plane3D>, numPlanes:Int):Bool
		{
			//planes = planes;
			//numPlanes = numPlanes;
			return _alwaysIn;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function fromGeometry(geometry:Geometry):Void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		override public function fromSphere(center:Vector3D, radius:Float):Void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		override public function fromExtremes(minX:Float, minY:Float, minZ:Float, maxX:Float, maxY:Float, maxZ:Float):Void
		{
		}
		
		override public function classifyToPlane(plane:Plane3D):Int
		{
			//plane = plane;
			return PlaneClassification.INTERSECT;
		}
		
		override public function transformFrom(bounds:BoundingVolumeBase, matrix:Matrix3D):Void
		{
			//matrix = matrix;
			_alwaysIn = cast(bounds, NullBounds)._alwaysIn;
		}
	}


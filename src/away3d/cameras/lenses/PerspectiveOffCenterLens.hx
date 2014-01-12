package away3d.cameras.lenses;

	import away3d.core.math.*;
	
	import flash.geom.Vector3D;
	
	/**
	 * The PerspectiveLens object provides a projection matrix that projects 3D geometry with perspective distortion.
	 */
	class PerspectiveOffCenterLens extends LensBase
	{
		var _minAngleX:Float;
		var _minLengthX:Float;
		var _tanMinX:Float;
		var _maxAngleX:Float;
		var _maxLengthX:Float;
		var _tanMaxX:Float;
		var _minAngleY:Float;
		var _minLengthY:Float;
		var _tanMinY:Float;
		var _maxAngleY:Float;
		var _maxLengthY:Float;
		var _tanMaxY:Float;
		
		/**
		 * Creates a new PerspectiveLens object.
		 *
		 * @param fieldOfView The vertical field of view of the projection.
		 */
		public function new(minAngleX:Float = -40, maxAngleX:Float = 40, minAngleY:Float = -40, maxAngleY:Float = 40)
		{
			super();
			
			this.minAngleX = minAngleX;
			this.maxAngleX = maxAngleX;
			this.minAngleY = minAngleY;
			this.maxAngleY = maxAngleY;
		}
		
		public var minAngleX(get, set) : Float;
		
		public function get_minAngleX() : Float
		{
			return _minAngleX;
		}
		
		public function set_minAngleX(value:Float) : Float
		{
			_minAngleX = value;
			
			_tanMinX = Math.tan(_minAngleX*Math.PI/180);
			
			invalidateMatrix();
		}
		
		public var maxAngleX(get, set) : Float;
		
		public function get_maxAngleX() : Float
		{
			return _maxAngleX;
		}
		
		public function set_maxAngleX(value:Float) : Float
		{
			_maxAngleX = value;
			
			_tanMaxX = Math.tan(_maxAngleX*Math.PI/180);
			
			invalidateMatrix();
		}
		
		public var minAngleY(get, set) : Float;
		
		public function get_minAngleY() : Float
		{
			return _minAngleY;
		}
		
		public function set_minAngleY(value:Float) : Float
		{
			_minAngleY = value;
			
			_tanMinY = Math.tan(_minAngleY*Math.PI/180);
			
			invalidateMatrix();
		}
		
		public var maxAngleY(get, set) : Float;
		
		public function get_maxAngleY() : Float
		{
			return _maxAngleY;
		}
		
		public function set_maxAngleY(value:Float) : Float
		{
			_maxAngleY = value;
			
			_tanMaxY = Math.tan(_maxAngleY*Math.PI/180);
			
			invalidateMatrix();
		}
		
		/**
		 * Calculates the scene position relative to the camera of the given normalized coordinates in screen space.
		 *
		 * @param nX The normalised x coordinate in screen space, -1 corresponds to the left edge of the viewport, 1 to the right.
		 * @param nY The normalised y coordinate in screen space, -1 corresponds to the top edge of the viewport, 1 to the bottom.
		 * @param sZ The z coordinate in screen space, representing the distance into the screen.
		 * @return The scene position relative to the camera of the given screen coordinates.
		 */
		override public function unproject(nX:Float, nY:Float, sZ:Float):Vector3D
		{
			var v:Vector3D = new Vector3D(nX, -nY, sZ, 1.0);
			
			v.x *= sZ;
			v.y *= sZ;
			
			v = unprojectionMatrix.transformVector(v);
			
			//z is unaffected by transform
			v.z = sZ;
			
			return v;
		}
		
		override public function clone():LensBase
		{
			var clone:PerspectiveOffCenterLens = new PerspectiveOffCenterLens(_minAngleX, _maxAngleX, _minAngleY, _maxAngleY);
			clone._near = _near;
			clone._far = _far;
			clone._aspectRatio = _aspectRatio;
			return clone;
		}
		
		/**
		 * @inheritDoc
		 */
		override private function updateMatrix():Void
		{
			var raw:Array<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
			
			_minLengthX = _near*_tanMinX;
			_maxLengthX = _near*_tanMaxX;
			_minLengthY = _near*_tanMinY;
			_maxLengthY = _near*_tanMaxY;
			
			var minLengthFracX:Float = -_minLengthX/(_maxLengthX - _minLengthX);
			var minLengthFracY:Float = -_minLengthY/(_maxLengthY - _minLengthY);
			
			var left:Float, right:Float, top:Float, bottom:Float;
			
			// assume scissored frustum
			var center:Float = -_minLengthX*(_scissorRect.x + _scissorRect.width*minLengthFracX)/(_scissorRect.width*minLengthFracX);
			var middle:Float = _minLengthY*(_scissorRect.y + _scissorRect.height*minLengthFracY)/(_scissorRect.height*minLengthFracY);
			
			left = center - (_maxLengthX - _minLengthX)*(_viewPort.width/_scissorRect.width);
			right = center;
			top = middle;
			bottom = middle + (_maxLengthY - _minLengthY)*(_viewPort.height/_scissorRect.height);
			
			raw[uint(0)] = 2*_near/(right - left);
			raw[uint(5)] = 2*_near/(bottom - top);
			raw[uint(8)] = (right + left)/(right - left);
			raw[uint(9)] = (bottom + top)/(bottom - top);
			raw[uint(10)] = (_far + _near)/(_far - _near);
			raw[uint(11)] = 1;
			raw[uint(1)] = raw[uint(2)] = raw[uint(3)] = raw[uint(4)] =
				raw[uint(6)] = raw[uint(7)] = raw[uint(12)] = raw[uint(13)] = raw[uint(15)] = 0;
			raw[uint(14)] = -2*_far*_near/(_far - _near);
			
			_matrix.copyRawDataFrom(raw);
			
			_minLengthX = _far*_tanMinX;
			_maxLengthX = _far*_tanMaxX;
			_minLengthY = _far*_tanMinY;
			_maxLengthY = _far*_tanMaxY;
			
			_frustumCorners[0] = _frustumCorners[9] = left;
			_frustumCorners[3] = _frustumCorners[6] = right;
			_frustumCorners[1] = _frustumCorners[4] = top;
			_frustumCorners[7] = _frustumCorners[10] = bottom;
			
			_frustumCorners[12] = _frustumCorners[21] = _minLengthX;
			_frustumCorners[15] = _frustumCorners[18] = _maxLengthX;
			_frustumCorners[13] = _frustumCorners[16] = _minLengthY;
			_frustumCorners[19] = _frustumCorners[22] = _maxLengthY;
			
			_frustumCorners[2] = _frustumCorners[5] = _frustumCorners[8] = _frustumCorners[11] = _near;
			_frustumCorners[14] = _frustumCorners[17] = _frustumCorners[20] = _frustumCorners[23] = _far;
			
			_matrixInvalid = false;
		}
	}


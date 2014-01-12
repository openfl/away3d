package away3d.lights.shadowmaps;

	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.FreeMatrixLens;
	import away3d.cameras.lenses.LensBase;
	import away3d.containers.Scene3D;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.render.DepthRenderer;
	
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import away3d.geom.Matrix3D;
	import flash.geom.Rectangle;
	
	//use namespace arcane;
	
	class CascadeShadowMapper extends DirectionalShadowMapper implements IEventDispatcher
	{
		var _scissorRects:Array<Rectangle>;
		var _scissorRectsInvalid:Bool = true;
		var _splitRatios:Array<Float>;
		
		var _numCascades:Int;
		var _depthCameras:Array<Camera3D>;
		var _depthLenses:Array<FreeMatrixLens>;
		
		var _texOffsetsX:Array<Float>;
		var _texOffsetsY:Array<Float>;
		
		var _changeDispatcher:EventDispatcher;
		var _nearPlaneDistances:Array<Float>;
		
		public function new(numCascades:UInt = 3)
		{
			super();
			if (numCascades < 1 || numCascades > 4)
				throw new Error("numCascades must be an integer between 1 and 4");
			_numCascades = numCascades;
			_changeDispatcher = new EventDispatcher(this);
			init();
		}
		
		public function getSplitRatio(index:UInt):Float
		{
			return _splitRatios[index];
		}
		
		public function setSplitRatio(index:UInt, value:Float):Void
		{
			if (value < 0)
				value = 0;
			else if (value > 1)
				value = 1;
			
			if (index >= _numCascades)
				throw new Error("index must be smaller than the number of cascades!");
			
			_splitRatios[index] = value;
		}
		
		public function getDepthProjections(partition:UInt):Matrix3D
		{
			return _depthCameras[partition].viewProjection;
		}
		
		private function init():Void
		{
			_splitRatios = new Array<Float>(_numCascades, true);
			_nearPlaneDistances = new Array<Float>(_numCascades, true);
			
			var s:Float = 1;
			// For loop conversion - 			for (var i:Int = _numCascades - 1; i >= 0; --i)
			var i:Int;
			for (i in _numCascades - 1...0) {
				_splitRatios[i] = s;
				s *= .4;
			}
			
			_texOffsetsX = new <Number>[-1, 1, -1, 1];
			_texOffsetsY = new <Number>[1, 1, -1, -1];
			_scissorRects = new Array<Rectangle>();
			_depthLenses = new Array<FreeMatrixLens>();
			_depthCameras = new Array<Camera3D>();
			
			// For loop conversion - 						for (i = 0; i < _numCascades; ++i)
			
			for (i in 0..._numCascades) {
				_depthLenses[i] = new FreeMatrixLens();
				_depthCameras[i] = new Camera3D(_depthLenses[i]);
			}
		}
		
		// will not be allowed
		public var depthMapSize(null, set) : Void;
		override public function set_depthMapSize(value:UInt) : Void
		{
			if (value == _depthMapSize)
				return;
			super.depthMapSize = value;
			invalidateScissorRects();
		}
		
		private function invalidateScissorRects():Void
		{
			_scissorRectsInvalid = true;
		}
		
		public var numCascades(get, set) : Int;
		
		public function get_numCascades() : Int
		{
			return _numCascades;
		}
		
		public function set_numCascades(value:Int) : Int
		{
			if (value == _numCascades)
				return;
			if (value < 1 || value > 4)
				throw new Error("numCascades must be an integer between 1 and 4");
			_numCascades = value;
			invalidateScissorRects();
			init();
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		override private function drawDepthMap(target:TextureBase, scene:Scene3D, renderer:DepthRenderer):Void
		{
			if (_scissorRectsInvalid)
				updateScissorRects();
			
			_casterCollector.cullPlanes = _cullPlanes;
			_casterCollector.camera = _overallDepthCamera;
			_casterCollector.clear();
			scene.traversePartitions(_casterCollector);
			
			renderer.renderCascades(_casterCollector, target, _numCascades, _scissorRects, _depthCameras);
			
			_casterCollector.cleanUp();
		}
		
		private function updateScissorRects():Void
		{
			var half:Float = _depthMapSize*.5;
			
			_scissorRects[0] = new Rectangle(0, 0, half, half);
			_scissorRects[1] = new Rectangle(half, 0, half, half);
			_scissorRects[2] = new Rectangle(0, half, half, half);
			_scissorRects[3] = new Rectangle(half, half, half, half);
			
			_scissorRectsInvalid = false;
		}
		
		override private function updateDepthProjection(viewCamera:Camera3D):Void
		{
			var matrix:Matrix3D;
			var lens:LensBase = viewCamera.lens;
			var lensNear:Float = lens.near;
			var lensRange:Float = lens.far - lensNear;
			
			updateProjectionFromFrustumCorners(viewCamera, viewCamera.lens.frustumCorners, _matrix);
			_matrix.appendScale(.96, .96, 1);
			_overallDepthLens.matrix = _matrix;
			updateCullPlanes(viewCamera);
			
			// For loop conversion - 						for (var i:Int = 0; i < _numCascades; ++i)
			
			var i:Int;
			
			for (i in 0..._numCascades) {
				matrix = _depthLenses[i].matrix;
				
				_nearPlaneDistances[i] = lensNear + _splitRatios[i]*lensRange;
				_depthCameras[i].transform = _overallDepthCamera.transform;
				
				updateProjectionPartition(matrix, _splitRatios[i], _texOffsetsX[i], _texOffsetsY[i]);
				
				_depthLenses[i].matrix = matrix;
			}
		}
		
		private function updateProjectionPartition(matrix:Matrix3D, splitRatio:Float, texOffsetX:Float, texOffsetY:Float):Void
		{
			var raw:Array<Float> = Matrix3DUtils.RAW_DATA_CONTAINER;
			var xN:Float, yN:Float, zN:Float;
			var xF:Float, yF:Float, zF:Float;
			var minX:Float = Number.POSITIVE_INFINITY, minY:Float = Number.POSITIVE_INFINITY, minZ:Float;
			var maxX:Float = Number.NEGATIVE_INFINITY, maxY:Float = Number.NEGATIVE_INFINITY, maxZ:Float = Number.NEGATIVE_INFINITY;
			var i:UInt = 0;
			
			while (i < 12) {
				xN = _localFrustum[i];
				yN = _localFrustum[uint(i + 1)];
				zN = _localFrustum[uint(i + 2)];
				xF = xN + (_localFrustum[uint(i + 12)] - xN)*splitRatio;
				yF = yN + (_localFrustum[uint(i + 13)] - yN)*splitRatio;
				zF = zN + (_localFrustum[uint(i + 14)] - zN)*splitRatio;
				if (xN < minX)
					minX = xN;
				if (xN > maxX)
					maxX = xN;
				if (yN < minY)
					minY = yN;
				if (yN > maxY)
					maxY = yN;
				if (zN > maxZ)
					maxZ = zN;
				if (xF < minX)
					minX = xF;
				if (xF > maxX)
					maxX = xF;
				if (yF < minY)
					minY = yF;
				if (yF > maxY)
					maxY = yF;
				if (zF > maxZ)
					maxZ = zF;
				i += 3;
			}
			
			minZ = 1;
			
			var w:Float = (maxX - minX);
			var h:Float = (maxY - minY);
			var d:Float = 1/(maxZ - minZ);
			
			if (minX < 0)
				minX -= _snap; // because int() rounds up for < 0
			if (minY < 0)
				minY -= _snap;
			minX = int(minX/_snap)*_snap;
			minY = int(minY/_snap)*_snap;
			
			var snap2:Float = 2*_snap;
			w = int(w/snap2 + 1)*snap2;
			h = int(h/snap2 + 1)*snap2;
			
			maxX = minX + w;
			maxY = minY + h;
			
			w = 1/w;
			h = 1/h;
			
			raw[0] = 2*w;
			raw[5] = 2*h;
			raw[10] = d;
			raw[12] = -(maxX + minX)*w;
			raw[13] = -(maxY + minY)*h;
			raw[14] = -minZ*d;
			raw[15] = 1;
			raw[1] = raw[2] = raw[3] = raw[4] = raw[6] = raw[7] = raw[8] = raw[9] = raw[11] = 0;
			
			matrix.copyRawDataFrom(raw);
			matrix.appendScale(.96, .96, 1);
			matrix.appendTranslation(texOffsetX, texOffsetY, 0);
			matrix.appendScale(.5, .5, 1);
		}
		
		public function addEventListener(type:String, listener:xxx->yyy, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
		{
			_changeDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function removeEventListener(type:String, listener:xxx->yyy, useCapture:Bool = false):Void
		{
			_changeDispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function dispatchEvent(event:Event):Bool
		{
			return _changeDispatcher.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Bool
		{
			return _changeDispatcher.hasEventListener(type);
		}
		
		public function willTrigger(type:String):Bool
		{
			return _changeDispatcher.willTrigger(type);
		}
		
		public var nearPlaneDistances(get, null) : Array<Float>;		
		public function get_nearPlaneDistances() : Array<Float>
		{
			return _nearPlaneDistances;
		}
	}


package away3d.extrusions;

	
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.entities.Mesh;
	import away3d.paths.IPath;
	
	import away3d.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	[Deprecated]
	class PathDuplicator
	{
		var _transform:Matrix3D;
		var _upAxis:Vector3D = new Vector3D(0, 1, 0);
		var _path:IPath;
		var _scene:Scene3D;
		var _meshes:Array<Mesh>;
		var _clones:Array<Mesh>;
		var _repeat:UInt;
		var _alignToPath:Bool;
		var _randomRotationY:Bool;
		var _segmentSpread:Bool = false;
		var _mIndex:UInt;
		var _count:UInt;
		var _container:ObjectContainer3D;
		
		/**
		 * Creates a new <code>PathDuplicator</code>
		 * Class replicates and distribute one or more mesh(es) along a path. The offsets are defined by the position of the object. 0,0,0 would place the center of the mesh exactly on Path.
		 *
		 * @param    path                [optional]    A Path object. The _path definition. either Cubic or Quadratic path
		 * @param    meshes                [optional]    Vector.&lt;Mesh&gt;. One or more meshes to repeat along the path.
		 * @param    scene                [optional]    Scene3D. The scene where to addchild the meshes if no ObjectContainer3D is provided.
		 * @param    repeat                [optional]    uint. How many times a mesh is cloned per PathSegment. Default is 1.
		 * @param    alignToPath            [optional]    Boolean. If the alignment of the clones must follow the path. Default is true.
		 * @param    segmentSpread        [optional]    Boolean. If more than one Mesh is passed, it defines if the clones alternate themselves per PathSegment or each repeat. Default is false.
		 * @param container                [optional]    ObjectContainer3D. If an ObjectContainer3D is provided, the meshes are addChilded to it instead of directly into the scene. The container is NOT addChilded to the scene by default.
		 * @param    randomRotationY    [optional]    Boolean. If the clones must have a random rotationY added to them.
		 *
		 */
		function PathDuplicator(path:IPath = null, meshes:Array<Mesh> = null, scene:Scene3D = null, repeat:UInt = 1, alignToPath:Bool = true, segmentSpread:Bool = true, container:ObjectContainer3D = null, randomRotationY:Bool = false)
		{
			_path = path;
			_meshes = meshes;
			_scene = scene;
			_repeat = repeat;
			_alignToPath = alignToPath;
			_segmentSpread = segmentSpread;
			_randomRotationY = randomRotationY;
			_container = container;
		}
		
		/**
		 * The up axis to which duplicated objects' Y axis will be oriented.
		 */
		public var upAxis(get, set) : Vector3D;
		public function get_upAxis() : Vector3D
		{
			return _upAxis;
		}
		
		public function set_upAxis(value:Vector3D) : Vector3D
		{
			_upAxis = value;
		}
		
		/**
		 * If a container is provided, the meshes are addChilded to it instead of directly into the scene. The container is NOT addChilded to the scene.
		 */
		public function set_container(cont:ObjectContainer3D) : Void
		{
			_container = cont;
		}
		
		public var container(get, set) : Void;
		
		public function get_container() : Void
		{
			return _container;
		}
		
		/**
		 * Defines the resolution between each PathSegments. Default 1, is also minimum.
		 */
		public function set_repeat(val:UInt) : Void
		{
			_repeat = (val < 1)? 1 : val;
		}
		
		public var repeat(get, set) : Void;
		
		public function get_repeat() : Void
		{
			return _repeat;
		}
		
		/**
		 * Defines if the profile point array should be orientated on path or not. Default true.
		 */
		public function set_alignToPath(b:Bool) : Void
		{
			_alignToPath = b;
		}
		
		public var alignToPath(get, set) : Void;
		
		public function get_alignToPath() : Void
		{
			return _alignToPath;
		}
		
		/**
		 * Defines if a clone gets a random rotationY to break visual repetitions, usefull in case of vegetation for instance.
		 */
		public function set_randomRotationY(b:Bool) : Void
		{
			_randomRotationY = b;
		}
		
		public var randomRotationY(get, set) : Void;
		
		public function get_randomRotationY() : Void
		{
			return _randomRotationY;
		}
		
		/**
		 * returns a vector with all meshes cloned since last time build method was called. Returns null if build hasn't be called yet.
		 * Another option to retreive the generated meshes is to pass an ObjectContainer3D to the class
		 */
		public var clones(get, null) : Array<Mesh>;
		public function get_clones() : Array<Mesh>
		{
			return _clones;
		}
		
		/**
		 * Sets and defines the Path object. See extrusions.utils package. Required for this class.
		 */
		public function set_path(p:IPath) : Void
		{
			_path = p;
		}
		
		public var path(get, set) : Void;
		
		public function get_path() : Void
		{
			return _path;
		}
		
		/**
		 * Defines an optional Vector.&lt;Mesh&gt;. One or more meshes to repeat along the path.
		 * When the last in the vector is reached, the first in the array will be used, this process go on and on until the last segment.
		 *
		 * @param    ms    A Array<Mesh>. One or more meshes to repeat along the path. Required for this class.
		 */
		public function set_meshes(ms:Array<Mesh>) : Void
		{
			_meshes = ms;
		}
		
		public var meshes(get, set) : Void;
		
		public function get_meshes() : Void.<Mesh>
		{
			return _meshes;
		}
		
		public function clearData(destroyCachedMeshes:Bool):Void
		{
			if (destroyCachedMeshes) {
				var i:UInt = 0;
				if (meshes) {
					// For loop conversion - 					for (i = 0; i < meshes.length; ++i)
					for (i in 0...meshes.length)
						meshes[i] = null;
				}
				if (_clones) {
					for (i; i < _clones.length; ++i)
						_clones[i] = null;
				}
			}
			_meshes = _clones = null;
		}
		
		/**
		 * defines if the meshes[index] is repeated per segments or duplicated after each others. default = false.
		 */
		public function set_segmentSpread(b:Bool) : Void
		{
			_segmentSpread = b;
		}
		
		public var segmentSpread(get, set) : Void;
		
		public function get_segmentSpread() : Void
		{
			return _segmentSpread;
		}
		
		/**
		 * Triggers the generation
		 */
		public function build():Void
		{
			if (!_path || !_meshes || meshes.length == 0)
				throw new Error("PathDuplicator error: Missing Path or Meshes data.");
			if (!_scene && !_container)
				throw new Error("PathDuplicator error: Missing Scene3D or ObjectContainer3D.");
			
			_mIndex = _meshes.length - 1;
			_count = 0;
			_clones = new Array<Mesh>();
			
			var segments:Array<Array<Vector3D>> = _path.getPointsOnCurvePerSegment(_repeat);
			var tmppt:Vector3D = new Vector3D();
			
			var i:UInt = 0;
			var j:UInt;
			var nextpt:Vector3D;
			var m:Mesh;
			var tPosi:Vector3D;
			
			// For loop conversion - 						for (i = 0; i < segments.length; ++i)
			
			for (i in 0...segments.length) {
				
				if (!_segmentSpread)
					_mIndex = (_mIndex + 1 != _meshes.length)? _mIndex + 1 : 0;
				
				// For loop conversion - 								for (j = 0; j < segments[i].length; ++j)
				
				for (j in 0...segments[i].length) {
					
					if (_segmentSpread)
						_mIndex = (_mIndex + 1 != _meshes.length)? _mIndex + 1 : 0;
					
					m = _meshes[_mIndex];
					tPosi = m.position;
					
					if (_alignToPath) {
						_transform = new Matrix3D();
						
						if (i == segments.length - 1 && j == segments[i].length - 1) {
							nextpt = segments[i][j - 1];
							orientateAt(segments[i][j], nextpt);
						} else {
							nextpt = (j < segments[i].length - 1)? segments[i][j + 1] : segments[i + 1][0];
							orientateAt(nextpt, segments[i][j]);
						}
					}
					
					if (_alignToPath) {
						tmppt.x = tPosi.x*_transform.rawData[0] + tPosi.y*_transform.rawData[4] + tPosi.z*_transform.rawData[8] + _transform.rawData[12];
						tmppt.y = tPosi.x*_transform.rawData[1] + tPosi.y*_transform.rawData[5] + tPosi.z*_transform.rawData[9] + _transform.rawData[13];
						tmppt.z = tPosi.x*_transform.rawData[2] + tPosi.y*_transform.rawData[6] + tPosi.z*_transform.rawData[10] + _transform.rawData[14];
						
						tmppt.x += segments[i][j].x;
						tmppt.y += segments[i][j].y;
						tmppt.z += segments[i][j].z;
					} else
						tmppt = new Vector3D(tPosi.x + segments[i][j].x, tPosi.y + segments[i][j].y, tPosi.z + segments[i][j].z);
					
					generate(m, tmppt);
				}
			}
			
			segments = null;
		}
		
		private function orientateAt(target:Vector3D, position:Vector3D):Void
		{
			var xAxis:Vector3D;
			var yAxis:Vector3D;
			var zAxis:Vector3D = target.subtract(position);
			zAxis.normalize();
			
			if (zAxis.length > 0.1) {
				xAxis = _upAxis.crossProduct(zAxis);
				xAxis.normalize();
				
				yAxis = xAxis.crossProduct(zAxis);
				yAxis.normalize();
				
				var rawData:Array<Float> = _transform.rawData;
				
				rawData[0] = xAxis.x;
				rawData[1] = xAxis.y;
				rawData[2] = xAxis.z;
				
				rawData[4] = -yAxis.x;
				rawData[5] = -yAxis.y;
				rawData[6] = -yAxis.z;
				
				rawData[8] = zAxis.x;
				rawData[9] = zAxis.y;
				rawData[10] = zAxis.z;
				
				_transform.rawData = rawData;
			}
		}
		
		private function generate(m:Mesh, position:Vector3D):Void
		{
			var clone:Mesh = m.clone() as Mesh;
			
			if (_alignToPath)
				clone.transform = _transform;
			else
				clone.position = position;
			
			clone.name = (m.name != null)? m.name + "_" + _count : "clone_" + _count;
			_count++;
			
			if (_randomRotationY)
				clone.rotationY = Math.random()*360;
			
			if (_container)
				_container.addChild(clone);
			else
				_scene.addChild(clone);
			
			_clones.push(clone);
		}
	
	}


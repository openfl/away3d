package away3d.core.partition;

	//import away3d.arcane;
	
	//use namespace arcane;
	
	class Octree extends Partition3D
	{
		public function new(maxDepth:Int, size:Float)
		{
			super(new OctreeNode(maxDepth, size));
		}
	}


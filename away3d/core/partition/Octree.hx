package away3d.core.partition;

class Octree extends Partition3D
{

	public function new(maxDepth:Int, size:Float)
	{
		super(new OctreeNode(maxDepth, size));
	}
}
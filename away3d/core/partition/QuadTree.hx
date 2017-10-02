package away3d.core.partition;

class QuadTree extends Partition3D
{
	public function new(maxDepth:Int, size:Float, height:Float = 1000000)
	{
		super(new QuadTreeNode(maxDepth, size, height));
	}
}
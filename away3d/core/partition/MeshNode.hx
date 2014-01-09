package away3d.core.partition;

	import away3d.core.base.SubMesh;
	import away3d.core.traverse.PartitionTraverser;
	import away3d.entities.Mesh;
	
	/**
	 * MeshNode is a space partitioning leaf node that contains a Mesh object.
	 */
	class MeshNode extends EntityNode
	{
		var _mesh:Mesh;
		
		/**
		 * Creates a new MeshNode object.
		 * @param mesh The mesh to be contained in the node.
		 */
		public function new(mesh:Mesh)
		{
			super(mesh);
			_mesh = mesh; // also keep a stronger typed reference
		}
		
		/**
		 * The mesh object contained in the partition node.
		 */
		public var mesh(get, null) : Mesh;
		public function get_mesh() : Mesh
		{
			return _mesh;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser:PartitionTraverser):Void
		{
			if (traverser.enterNode(this)) {
				super.acceptTraverser(traverser);
				var subs:Array<SubMesh> = _mesh.subMeshes;
				var i:UInt = 0;
				var len:UInt = subs.length;
				while (i < len)
					traverser.applyRenderable(subs[i++]);
			}
		}
	
	}


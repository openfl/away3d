package away3d.debug.data;

	import away3d.entities.SegmentSet;
	import away3d.primitives.LineSegment;
	
	import flash.geom.Vector3D;
	
	class TridentLines extends SegmentSet
	{
		public function new(vectors:Array<Array<Vector3D>>, colors:Array<UInt>):Void
		{
			super();
			build(vectors, colors);
		}
		
		private function build(vectors:Array<Array<Vector3D>>, colors:Array<UInt>):Void
		{
			var letter:Array<Vector3D>;
			var v0:Vector3D;
			var v1:Vector3D;
			var color:UInt;
			var j:UInt;
			
			// For loop conversion - 						for (var i:UInt = 0; i < vectors.length; ++i)
			
			var i:UInt = 0;
			
			for (i in 0...vectors.length) {
				color = colors[i];
				letter = vectors[i];
				
				// For loop conversion - 								for (j = 0; j < letter.length; j += 2)
				
				for (j in 0...letter.length) {
					v0 = letter[j];
					v1 = letter[j + 1];
					addSegment(new LineSegment(v0, v1, color, color, 1));
				}
			}
		}
	
	}
}


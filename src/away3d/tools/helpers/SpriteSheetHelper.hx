package away3d.tools.helpers;

	import away3d.animators.data.SpriteSheetAnimationFrame;
	import away3d.animators.nodes.SpriteSheetClipNode;
	import away3d.textures.BitmapTexture;
	import away3d.textures.Texture2DBase;
	import away3d.tools.utils.TextureUtils;
	
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/**
	 * SpriteSheetHelper, a class to ease sprite sheet animation data generation
	 */
	class SpriteSheetHelper
	{
		function SpriteSheetHelper()
		{
		}
		
		/**
		 * Generates and returns one or more "sprite sheets" BitmapTexture from a given movieClip
		 *
		 * @param sourceMC                MovieClip: A movieclip with timeline animation
		 * @param cols                    uint: Howmany cells along the u axis.
		 * @param rows                    uint: Howmany cells along the v axis.
		 * @param width                uint: The result bitmapData(s) width.
		 * @param height                uint: The result bitmapData(s) height.
		 * @param transparent                Boolean: if the bitmapData(s) must be transparent.
		 * @param backgroundColor            uint: the bitmapData(s) background color if not transparent.
		 *
		 * @return Vector.&lt;Texture2DBase&gt;    The generated Texture2DBase vector for the SpriteSheetMaterial.
		 */
		public function generateFromMovieClip(sourceMC:MovieClip, cols:UInt, rows:UInt, width:UInt, height:UInt, transparent:Bool = false, backgroundColor:UInt = 0):Array<Texture2DBase>
		{
			var spriteSheets:Array<Texture2DBase> = new Array<Texture2DBase>();
			var framesCount:UInt = sourceMC.totalFrames;
			var i:UInt = framesCount;
			var w:UInt = width;
			var h:UInt = height;
			
			if (!TextureUtils.isPowerOfTwo(w))
				w = TextureUtils.getBestPowerOf2(w);
			if (!TextureUtils.isPowerOfTwo(h))
				h = TextureUtils.getBestPowerOf2(h);
			
			var spriteSheet:BitmapData;
			var destCellW:Float = Math.round(h/cols);
			var destCellH:Float = Math.round(w/rows);
			//var cellRect:Rectangle = new Rectangle(0, 0, destCellW, destCellH);
			
			var mcFrameW:UInt = sourceMC.width;
			var mcFrameH:UInt = sourceMC.height;
			
			var sclw:Float = destCellW/mcFrameW;
			var sclh:Float = destCellH/mcFrameH;
			var t:Matrix = new Matrix();
			t.scale(sclw, sclh);
			
			var tmpCache:BitmapData = new BitmapData(mcFrameW*sclw, mcFrameH*sclh, transparent, transparent? 0x00FFFFFF : backgroundColor);
			
			var u:UInt, v:UInt;
			var cellsPerMap:UInt = cols*rows;
			var maps:UInt = framesCount/cellsPerMap;
			if (maps < framesCount/cellsPerMap)
				maps++;
			
			var pastePoint:Point = new Point();
			var frameNum:UInt = 0;
			var bitmapTexture:BitmapTexture;
			
			while (maps--) {
				
				u = v = 0;
				spriteSheet = new BitmapData(w, h, transparent, transparent? 0x00FFFFFF : backgroundColor);
				
				// For loop conversion - 								for (i = 0; i < cellsPerMap; i++)
				
				for (i in 0...cellsPerMap) {
					frameNum++;
					if (frameNum <= framesCount) {
						pastePoint.x = Math.round(destCellW*u);
						pastePoint.y = Math.round(destCellH*v);
						sourceMC.gotoAndStop(frameNum);
						tmpCache.draw(sourceMC, t, null, "normal", tmpCache.rect, true);
						spriteSheet.copyPixels(tmpCache, tmpCache.rect, pastePoint);
						
						if (transparent)
							tmpCache.fillRect(tmpCache.rect, 0x00FFFFFF);
						
						u++;
						if (u == cols) {
							u = 0;
							v++;
						}
						
					} else
						break;
					
				}
				
				bitmapTexture = new BitmapTexture(spriteSheet);
				spriteSheets.push(bitmapTexture);
			}
			
			tmpCache.dispose();
			
			return spriteSheets;
		}
		
		/**
		 * Returns a SpriteSheetClipNode to pass to animator from animation id , cols and rows.
		 * @param animID                String:The name of the animation
		 * @param cols                    uint: Howmany cells along the u axis.
		 * @param rows                    uint: Howmany cells along the v axis.
		 * @param mapCount                uint: If the same animation is spread over more bitmapDatas. Howmany bimapDatas. Default is 1.
		 * @param from                    uint: The offset start if the animation first frame isn't in first cell top left on the map. zero based. Default is 0.
		 * @param to                    uint: The last cell if the animation last frame cell isn't located down right on the map. zero based. Default is 0.
		 *
		 * @return SpriteSheetClipNode        SpriteSheetClipNode: The SpriteSheetClipNode filled with the data
		 */
		public function generateSpriteSheetClipNode(animID:String, cols:UInt, rows:UInt, mapCount:UInt = 1, from:UInt = 0, to:UInt = 0):SpriteSheetClipNode
		{
			var spriteSheetClipNode:SpriteSheetClipNode = new SpriteSheetClipNode();
			spriteSheetClipNode.name = animID;
			
			var u:UInt, v:UInt;
			var framesCount:UInt = cols*rows;
			
			if (mapCount < 1)
				mapCount = 1;
			if (to == 0 || to < from || to > framesCount*mapCount)
				to = cols*rows*mapCount;
			
			if (from > to)
				throw new Error("Param 'from' must be lower than the 'to' param.");
			
			var scaleV:Float = 1/rows;
			var scaleU:Float = 1/cols;
			
			var frame:SpriteSheetAnimationFrame;
			
			var i:UInt, j:UInt;
			var animFrames:UInt = 0;
			
			// For loop conversion - 						for (i = 0; i < mapCount; ++i)
			
			for (i in 0...mapCount) {
				u = v = 0;
				
				// For loop conversion - 								for (j = 0; j < framesCount; ++j)
				
				for (j in 0...framesCount) {
					
					if (animFrames >= from && animFrames < to) {
						
						frame = new SpriteSheetAnimationFrame();
						frame.offsetU = scaleU*u;
						frame.offsetV = scaleV*v;
						frame.scaleU = scaleU;
						frame.scaleV = scaleV;
						frame.mapID = i;
						
						spriteSheetClipNode.addFrame(frame, 16);
					}
					
					if (animFrames == to)
						return spriteSheetClipNode;
					
					animFrames++;
					
					u++;
					if (u == cols) {
						u = 0;
						v++;
					}
				}
			}
			
			return spriteSheetClipNode;
		}
	}


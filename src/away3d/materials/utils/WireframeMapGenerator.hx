/**
 * WireframeMapGenerator is a utility class to generate a wireframe texture for uniquely mapped meshes.
 */
package away3d.materials.utils;


import flash.Vector;
import away3d.core.base.ISubGeometry;
import away3d.entities.Mesh;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.display.TriangleCulling;

class WireframeMapGenerator {

/**
	 * Create a wireframe map with a texture fill.
	 * @param mesh The Mesh object for which to create the wireframe texture.
	 * @param bitmapData The BitmapData to use as the fill texture.
	 * @param lineColor The wireframe's line colour.
	 * @param lineThickness The wireframe's line thickness.
	 */
    static public function generateTexturedMap(mesh:Mesh, bitmapData:BitmapData, lineColor:Int = 0xffffff, lineThickness:Float = 2):BitmapData {
        bitmapData = bitmapData.clone();
        var i:Int = 0;
        while (i < mesh.subMeshes.length) {
            drawLines(lineColor, lineThickness, bitmapData, mesh.subMeshes[i].subGeometry);
            ++i;
        }
        return bitmapData;
    }

/**
	 * Create a wireframe map with a solid colour fill.
	 * @param mesh The Mesh object for which to create the wireframe texture.
	 * @param lineColor The wireframe's line colour.
	 * @param lineThickness The wireframe's line thickness.
	 * @param fillColor The colour of the wireframe fill.
	 * @param fillAlpha The alpha of the wireframe fill.
	 * @param width The texture's width.
	 * @param height The texture's height.
	 * @return A BitmapData containing the texture underneath the wireframe.
	 */

    static public function generateSolidMap(mesh:Mesh, lineColor:Int = 0xffffff, lineThickness:Float = 2, fillColor:Int = 0, fillAlpha:Float = 0, width:Int = 512, height:Int = 512):BitmapData {
        var bitmapData:BitmapData;
        if (fillAlpha > 1) fillAlpha = 1
        else if (fillAlpha < 0) fillAlpha = 0;
        bitmapData = new BitmapData(width, height, fillAlpha == (1) ? false : true, Std.int(fillAlpha) << 24 | Std.int(fillColor & 0xffffff));
        var i:Int = 0;
        while (i < mesh.subMeshes.length) {
            drawLines(lineColor, lineThickness, bitmapData, mesh.subMeshes[i].subGeometry);
            ++i;
        }
        return bitmapData;
    }

/**
	 * Draws the actual lines.
	 */

    static private function drawLines(lineColor:Int, lineThickness:Float, bitmapData:BitmapData, subGeom:ISubGeometry):Void {
        var sprite:Sprite = new Sprite();
        var g:Graphics = sprite.graphics;
        var uvs:Vector<Float> = subGeom.UVData;
        var i:Int = 0;
        var len:Int = uvs.length;
        var w:Float = bitmapData.width;
        var h:Float = bitmapData.height;
        var texSpaceUV:Vector<Float> = new Vector<Float>(len, true);
        var indices:Vector<UInt> = subGeom.indexData;
        var indexClone:Vector<Int>;
        do {
            texSpaceUV[i] = uvs[i] * w;
            ++i;
            texSpaceUV[i] = uvs[i] * h;
        }
        while ((++i < len));
        len = indices.length;
        indexClone = new Vector<Int>(len, true);
        i = 0;
// awesome, just to convert from uint to int vector -_-
        do {
            indexClone[i] = indices[i];
        }
        while ((++i < len));
        g.lineStyle(lineThickness, lineColor);
        g.drawTriangles(texSpaceUV, indexClone, null, TriangleCulling.NONE);
        bitmapData.draw(sprite);
        g.clear();
    }

}


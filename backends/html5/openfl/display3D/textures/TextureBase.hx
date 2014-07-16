/****
* 
****/

package openfl.display3D.textures;

import openfl.gl.GL;
import openfl.gl.GLTexture;
import openfl.gl.GLFramebuffer;
import openfl.events.EventDispatcher;

class TextureBase extends EventDispatcher 
{
	public var width : Int;
    public var height : Int;
    public var glTexture:GLTexture;
    public var frameBuffer:GLFramebuffer;

    public function new(glTexture:GLTexture, width : Int=0, height : Int=0) 
    {
        super();
        this.width = width;
        this.height = height;
        this.glTexture = glTexture;
    }

    public function dispose():Void 
    {
        GL.deleteTexture(glTexture);
    }
}

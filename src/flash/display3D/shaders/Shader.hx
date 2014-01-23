/****
* 
****/

package flash.display3D.shaders;

#if flash
typedef Shader = flash.utils.ByteArray;
#elseif (cpp || neko || js)
typedef Shader = openfl.gl.GLShader;
 #end

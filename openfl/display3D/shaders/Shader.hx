/****
* 
****/

package openfl.display3D.shaders;

#if flash
typedef Shader = openfl.utils.ByteArray;
#elseif (cpp || neko || js)
typedef Shader = openfl.gl.GLShader;
 #end

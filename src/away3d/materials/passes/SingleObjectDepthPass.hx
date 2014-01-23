/**
 * The SingleObjectDepthPass provides a material pass that renders a single object to a depth map from the point
 * of view from a light.
 */
package away3d.materials.passes;


import flash.Vector;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.lights.LightBase;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.geom.Matrix3D;
import haxe.ds.ObjectMap;

class SingleObjectDepthPass extends MaterialPassBase {

    private var _textures:Vector<ObjectMap<IRenderable, Texture>>;
    private var _projections:ObjectMap<IRenderable, Matrix3D>;
    private var _textureSize:Int;
    private var _polyOffset:Vector<Float>;
    private var _enc:Vector<Float>;
    private var _projectionTexturesInvalid:Bool;
/**
	 * Creates a new SingleObjectDepthPass object.
	 * @param textureSize The size of the depth map texture to render to.
	 * @param polyOffset The amount by which the rendered object will be inflated, to prevent depth map rounding errors.
	 *
	 * todo: provide custom vertex code to assembler
	 */

    public function new(textureSize:Int = 512, polyOffset:Float = 15) {
        _projectionTexturesInvalid = true;
        super(true);
        _textureSize = textureSize;
        _numUsedStreams = 2;
        _numUsedVertexConstants = 7;
        _polyOffset = Vector.ofArray([polyOffset, 0, 0, 0]);
        _enc = Vector.ofArray(cast [1.0, 255.0, 65025.0, 16581375.0, 1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0]);
        _animatableAttributes = Vector.ofArray(cast ["va0", "va1"]);
        _animationTargetRegisters = Vector.ofArray(cast ["vt0", "vt1"]);
    }

/**
	 * @inheritDoc
	 */

    override public function dispose():Void {
        if (_textures != null) {
            for (i in 0..._textures.length) {
                var map:ObjectMap<IRenderable, Texture> = _textures[i];
                var iterator:Iterator<Texture> = map.iterator();
                for (texture in iterator) {
                    texture.dispose();
                }
            }
            _textures = null;
        }
    }

    private function updateProjectionTextures():Void {
        if (_textures != null) {
            for (i in 0..._textures.length) {
                var map:ObjectMap<IRenderable, Texture> = _textures[i];
                var iterator:Iterator<Texture> = map.iterator();
                for (texture in iterator) {
                    texture.dispose();
                }
            }
            _textures = null;
        }

        _textures = new Vector<ObjectMap<IRenderable, Texture>>(8);
        _projections = new ObjectMap<IRenderable, Matrix3D>();
        _projectionTexturesInvalid = false;
    }

/**
	 * @inheritDoc
	 */

    override public function getVertexCode():String {
        var code:String;
// offset
        code = "mul vt7, vt1, vc4.x	\n" + "add vt7, vt7, vt0		\n" + "mov vt7.w, vt0.w		\n";
// project
        code += "m44 vt2, vt7, vc0		\n" + "mov op, vt2			\n";
// perspective divide
        code += "div v0, vt2, vt2.w \n";
        return code;
    }

/**
	 * @inheritDoc
	 */

    override public function getFragmentCode(animationCode:String):String {
        var code:String = "";
// encode float -> rgba
        code += "mul ft0, fc0, v0.z     \n" + "frc ft0, ft0           \n" + "mul ft1, ft0.yzww, fc1 \n" + "sub ft0, ft0, ft1      \n" + "mov oc, ft0            \n";
        return code;
    }

/**
	 * Gets the depth maps rendered for this object from all lights.
	 * @param renderable The renderable for which to retrieve the depth maps.
	 * @param stage3DProxy The Stage3DProxy object currently used for rendering.
	 * @return A list of depth map textures for all supported lights.
	 */

    public function getDepthMap(renderable:IRenderable, stage3DProxy:Stage3DProxy):Texture {
        return _textures[stage3DProxy.stage3DIndex].get(renderable);
    }

/**
	 * Retrieves the depth map projection maps for all lights.
	 * @param renderable The renderable for which to retrieve the projection maps.
	 * @return A list of projection maps for all supported lights.
	 */

    public function getProjection(renderable:IRenderable):Matrix3D {
        return _projections.get(renderable);
    }


/**
	 * @inheritDoc
	 */

    override public function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):Void {
        var matrix:Matrix3D;
        var contextIndex:Int = stage3DProxy.stage3DIndex;
        var context:Context3D = stage3DProxy.context3D;
        var len:Int;
        var light:LightBase;
        var lights:Vector<LightBase> = _lightPicker.allPickedLights;

        if (_textures[contextIndex] == null)
            _textures[contextIndex] = new ObjectMap<IRenderable, Texture>();

        if (!_projections.exists(renderable))
            _projections.set(renderable, new Matrix3D());

        len = lights.length;
// local position = enough
        light = lights[0];

        matrix = light.getObjectProjectionMatrix(renderable, _projections.get(renderable));

// todo: use texture proxy?
        if (!_textures[contextIndex].exists(renderable))
            _textures[contextIndex].set(renderable, context.createTexture(_textureSize, _textureSize, Context3DTextureFormat.BGRA, true));
        var target:Texture = _textures[contextIndex].get(renderable);

        stage3DProxy.setRenderTarget(target, true);
        context.clear(1.0, 1.0, 1.0);
        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _enc, 2);
        renderable.activateVertexBuffer(0, stage3DProxy);
        renderable.activateVertexNormalBuffer(1, stage3DProxy);
        context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
    }

/**
	 * @inheritDoc
	 */

    override public function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):Void {
        if (_projectionTexturesInvalid) updateProjectionTextures();
        super.activate(stage3DProxy, camera);
        stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _polyOffset, 1);
    }

}


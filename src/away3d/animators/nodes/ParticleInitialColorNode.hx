package away3d.animators.nodes;

import Reflect;
import away3d.animators.data.ParticleProperties;
import flash.errors.Error;
import away3d.materials.passes.MaterialPassBase;
import away3d.animators.data.AnimationRegisterCache;
import away3d.materials.compilation.ShaderRegisterElement;
import away3d.animators.data.ParticlePropertiesMode;
import flash.geom.ColorTransform;
import away3d.animators.states.ParticleInitialColorState;

class ParticleInitialColorNode extends ParticleNodeBase {

/** @private */
    static public var MULTIPLIER_INDEX:Int = 0;
/** @private */
    static public var OFFSET_INDEX:Int = 1;
//default values used when creating states
/** @private */
    public var _usesMultiplier:Bool;
/** @private */
    public var _usesOffset:Bool;
/** @private */
    public var _initialColor:ColorTransform;
/**
	 * Reference for color node properties on a single particle (when in local property mode).
	 * Expects a <code>ColorTransform</code> object representing the color transform applied to the particle.
	 */
    static public var COLOR_INITIAL_COLORTRANSFORM:String = "ColorInitialColorTransform";

    public function new(mode:Int, usesMultiplier:Bool = true, usesOffset:Bool = false, initialColor:ColorTransform = null) {
        _stateClass = ParticleInitialColorState;
        _usesMultiplier = usesMultiplier;
        _usesOffset = usesOffset;
        _initialColor = initialColor ;
        if (_initialColor == null)_initialColor = new ColorTransform();
        super("ParticleInitialColor", mode, ((_usesMultiplier && _usesOffset)) ? 8 : 4, ParticleAnimationSet.COLOR_PRIORITY);
    }

/**
	 * @inheritDoc
	 */

    override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String {

        var code:String = "";
        if (animationRegisterCache.needFragmentAnimation) {
            if (_usesMultiplier) {
                var multiplierValue:ShaderRegisterElement = ((_mode == ParticlePropertiesMode.GLOBAL)) ? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
                animationRegisterCache.setRegisterIndex(this, MULTIPLIER_INDEX, multiplierValue.index);
                code += "mul " + animationRegisterCache.colorMulTarget + "," + multiplierValue + "," + animationRegisterCache.colorMulTarget + "\n";
            }
            if (_usesOffset) {
                var offsetValue:ShaderRegisterElement = ((_mode == ParticlePropertiesMode.LOCAL_STATIC)) ? animationRegisterCache.getFreeVertexAttribute() : animationRegisterCache.getFreeVertexConstant();
                animationRegisterCache.setRegisterIndex(this, OFFSET_INDEX, offsetValue.index);
                code += "add " + animationRegisterCache.colorAddTarget + "," + offsetValue + "," + animationRegisterCache.colorAddTarget + "\n";
            }
        }
        return code;
    }

/**
	 * @inheritDoc
	 */

    override public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void {
        if (_usesMultiplier) particleAnimationSet.hasColorMulNode = true;
        if (_usesOffset) particleAnimationSet.hasColorAddNode = true;
    }

/**
	 * @inheritDoc
	 */

    override public function generatePropertyOfOneParticle(param:ParticleProperties):Void {
        var initialColor:ColorTransform = Reflect.field(param, COLOR_INITIAL_COLORTRANSFORM);
        if (initialColor == null) throw (new Error("there is no " + COLOR_INITIAL_COLORTRANSFORM + " in param!"));
        var i:Int = 0;
//multiplier
        if (_usesMultiplier) {
            _oneData[i++] = initialColor.redMultiplier;
            _oneData[i++] = initialColor.greenMultiplier;
            _oneData[i++] = initialColor.blueMultiplier;
            _oneData[i++] = initialColor.alphaMultiplier;
        }
        if (_usesOffset) {
            _oneData[i++] = initialColor.redOffset / 255;
            _oneData[i++] = initialColor.greenOffset / 255;
            _oneData[i++] = initialColor.blueOffset / 255;
            _oneData[i++] = initialColor.alphaOffset / 255;
        }
    }

}


/**
 * Provides an abstract base class for particle animation nodes.
 */
package away3d.animators.nodes;


import away3d.utils.ArrayUtils;
import flash.Vector;
import away3d.animators.data.ParticleProperties;
import away3d.animators.ParticleAnimationSet;
import away3d.animators.data.AnimationRegisterCache;
import away3d.materials.passes.MaterialPassBase;

class ParticleNodeBase extends AnimationNodeBase {
    public var mode(get_mode, never):Int;
    public var priority(get_priority, never):Int;
    public var dataLength(get_dataLength, never):Int;
    public var oneData(get_oneData, never):Vector<Float>;

    private var _mode:Int;
    private var _priority:Int;
    private var _dataLength:Int;
    private var _oneData:Vector<Float>;
    public var dataOffset:Int;
/**
	 * Returns the property mode of the particle animation node. Typically set in the node constructor
	 *
	 * @see away3d.animators.data.ParticlePropertiesMode
	 */

    public function get_mode():Int {
        return _mode;
    }

/**
	 * Returns the priority of the particle animation node, used to order the agal generated in a particle animation set. Set automatically on instantiation.
	 *
	 * @see away3d.animators.ParticleAnimationSet
	 * @see #getAGALVertexCode
	 */

    public function get_priority():Int {
        return _priority;
    }

/**
	 * Returns the length of the data used by the node when in <code>LOCAL_STATIC</code> mode. Used to generate the local static data of the particle animation set.
	 *
	 * @see away3d.animators.ParticleAnimationSet
	 * @see #getAGALVertexCode
	 */

    public function get_dataLength():Int {
        return _dataLength;
    }

/**
	 * Returns the generated data vector of the node after one particle pass during the generation of all local static data of the particle animation set.
	 *
	 * @see away3d.animators.ParticleAnimationSet
	 * @see #generatePropertyOfOneParticle
	 */

    public function get_oneData():Vector<Float> {
        return _oneData;
    }

//modes alias
    static private var GLOBAL:String = "Global";
    static private var LOCAL_STATIC:String = "LocalStatic";
    static private var LOCAL_DYNAMIC:String = "LocalDynamic";
//modes list
    static private var MODES:Dynamic = {
    "0" : GLOBAL,
    "1" : LOCAL_STATIC,
    "2" : LOCAL_DYNAMIC

    };
/**
	 *
	 * @param    particleNodeClass - class of ParticleNodeBase child e.g ParticleBillboardNode, ParticleFollowNode...
	 * @param    particleNodeMode  - mode of particle node ParticlePropertiesMode.GLOBAL, ParticlePropertiesMode.LOCAL_DYNAMIC or ParticlePropertiesMode.LOCAL_STATIC
	 * @return    particle node name
	 */

    static public function getParticleNodeName(particleNodeClass:Dynamic, particleNodeMode:Int):String {
        var nodeName:String = Reflect.field(particleNodeClass, "ANIMATION_NODE_NAME");
        if (nodeName == null) nodeName = getNodeNameFromClass(particleNodeClass);
        return nodeName + MODES[particleNodeMode];
    }

    static private function getNodeNameFromClass(particleNodeClass:Dynamic):String {
        return StringTools.replace(Type.getClassName(particleNodeClass), "Node", "").split("::")[1];
    }

/**
	 * Creates a new <code>ParticleNodeBase</code> object.
	 *
	 * @param               name            Defines the generic name of the particle animation node.
	 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
	 * @param               dataLength      Defines the length of the data used by the node when in <code>LOCAL_STATIC</code> mode.
	 * @param    [optional] priority        the priority of the particle animation node, used to order the agal generated in a particle animation set. Defaults to 1.
	 */

    public function new(name:String, mode:Int, dataLength:Int, priority:Int = 1) {
        _dataLength = 3;
        name = name + MODES[mode];
        this.name = name;
        _mode = mode;
        _priority = priority;
        _dataLength = dataLength;
        _oneData = new Vector<Float>(_dataLength, true);
        ArrayUtils.Prefill(_oneData,_dataLength,0);
        super();
    }

/**
	 * Returns the AGAL code of the particle animation node for use in the vertex shader.
	 */

    public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String {

        return "";
    }

/**
	 * Returns the AGAL code of the particle animation node for use in the fragment shader.
	 */

    public function getAGALFragmentCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String {

        return "";
    }

/**
	 * Returns the AGAL code of the particle animation node for use in the fragment shader when UV coordinates are required.
	 */

    public function getAGALUVCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String {

        return "";
    }

/**
	 * Called internally by the particle animation set when assigning the set of static properties originally defined by the initParticleFunc of the set.
	 *
	 * @see away3d.animators.ParticleAnimationSet#initParticleFunc
	 */

    public function generatePropertyOfOneParticle(param:ParticleProperties):Void {
    }

/**
	 * Called internally by the particle animation set when determining the requirements of the particle animation node AGAL.
	 */

    public function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void {
    }

}


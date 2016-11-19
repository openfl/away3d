package away3d.animators.nodes;

import away3d.animators.data.ParticleProperties;
import away3d.animators.ParticleAnimationSet;
import away3d.animators.data.AnimationRegisterCache;
import away3d.materials.passes.MaterialPassBase;

import openfl.Vector;

/**
 * Provides an abstract base class for particle animation nodes.
 */
class ParticleNodeBase extends AnimationNodeBase
{
	public var mode(get, never):Int;
	public var priority(get, never):Int;
	public var dataLength(get, never):Int;
	public var oneData(get, never):Vector<Float>;
	
	private var _mode:Int;
	private var _priority:Int;
	
	private var _dataLength:Int = 3;
	private var _oneData:Vector<Float>;
	
	@:allow(away3d) private var dataOffset:Int;
	
	/**
	 * Returns the property mode of the particle animation node. Typically set in the node constructor
	 *
	 * @see away3d.animators.data.ParticlePropertiesMode
	 */
	private function get_mode():Int
	{
		return _mode;
	}
	
	/**
	 * Returns the priority of the particle animation node, used to order the agal generated in a particle animation set. Set automatically on instantiation.
	 *
	 * @see away3d.animators.ParticleAnimationSet
	 * @see #getAGALVertexCode
	 */
	private function get_priority():Int
	{
		return _priority;
	}
	
	/**
	 * Returns the length of the data used by the node when in <code>LOCAL_STATIC</code> mode. Used to generate the local static data of the particle animation set.
	 *
	 * @see away3d.animators.ParticleAnimationSet
	 * @see #getAGALVertexCode
	 */
	private function get_dataLength():Int
	{
		return _dataLength;
	}
	
	/**
	 * Returns the generated data vector of the node after one particle pass during the generation of all local static data of the particle animation set.
	 *
	 * @see away3d.animators.ParticleAnimationSet
	 * @see #generatePropertyOfOneParticle
	 */
	private function get_oneData():Vector<Float>
	{
		return _oneData;
	}
	
	//modes alias
	private static var GLOBAL:String = 'Global';
	private static var LOCAL_STATIC:String = 'LocalStatic';
	private static var LOCAL_DYNAMIC:String = 'LocalDynamic';
	
	//modes list
	private static var MODES:Array<String> = [ GLOBAL, LOCAL_STATIC, LOCAL_DYNAMIC];
	
	/**
	 *
	 * @param    particleNodeClass - class of ParticleNodeBase child e.g ParticleBillboardNode, ParticleFollowNode...
	 * @param    particleNodeMode  - mode of particle node ParticlePropertiesMode.GLOBAL, ParticlePropertiesMode.LOCAL_DYNAMIC or ParticlePropertiesMode.LOCAL_STATIC
	 * @return    particle node name
	 */
	public static function getParticleNodeName(particleNodeClass:Dynamic, particleNodeMode:Int):String
	{
		var nodeName:String = particleNodeClass.node.get('ANIMATION_NODE_NAME');
		
		if (nodeName == null)
			nodeName = getNodeNameFromClass(particleNodeClass);
		
		return nodeName + MODES[particleNodeMode];
	}
	
	private static function getNodeNameFromClass(particleNodeClass:Dynamic):String
	{
		return StringTools.replace(Type.getClassName(particleNodeClass), 'Node', '').split('::')[1];
	}
	
	/**
	 * Creates a new <code>ParticleNodeBase</code> object.
	 *
	 * @param               name            Defines the generic name of the particle animation node.
	 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
	 * @param               dataLength      Defines the length of the data used by the node when in <code>LOCAL_STATIC</code> mode.
	 * @param    [optional] priority        the priority of the particle animation node, used to order the agal generated in a particle animation set. Defaults to 1.
	 */
	public function new(name:String, mode:Int, dataLength:Int, priority:Int = 1)
	{
		super();
		
		name = name + MODES[mode];
		
		this.name = name;
		_mode = mode;
		_priority = priority;
		_dataLength = dataLength;
		
		_oneData = new Vector<Float>(_dataLength, true);
	}
	
	/**
	 * Returns the AGAL code of the particle animation node for use in the vertex shader.
	 */
	public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		return "";
	}
	
	/**
	 * Returns the AGAL code of the particle animation node for use in the fragment shader.
	 */
	public function getAGALFragmentCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		return "";
	}
	
	/**
	 * Returns the AGAL code of the particle animation node for use in the fragment shader when UV coordinates are required.
	 */
	public function getAGALUVCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
	{
		return "";
	}
	
	/**
	 * Called internally by the particle animation set when assigning the set of static properties originally defined by the initParticleFunc of the set.
	 *
	 * @see away3d.animators.ParticleAnimationSet#initParticleFunc
	 */
	@:allow(away3d) private function generatePropertyOfOneParticle(param:ParticleProperties):Void
	{
	}
	
	/**
	 * Called internally by the particle animation set when determining the requirements of the particle animation node AGAL.
	 */
	@:allow(away3d) private function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):Void
	{
	}
}
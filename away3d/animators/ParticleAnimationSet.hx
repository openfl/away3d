/**
 * The animation data set used by particle-based animators, containing particle animation data.
 *
 * @see away3d.animators.ParticleAnimator
 */
package away3d.animators;

import away3d.animators.data.ParticleAnimationData;
import away3d.animators.data.ParticleProperties;
import away3d.core.base.data.ParticleData;
import away3d.core.base.SubMesh;
import away3d.core.base.ISubGeometry;
import away3d.core.base.ParticleGeometry;
import away3d.entities.Mesh;
import away3d.animators.data.AnimationSubGeometry;
import openfl.display3D.Context3D;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.passes.MaterialPassBase;
import away3d.animators.data.ParticlePropertiesMode;
import away3d.animators.nodes.AnimationNodeBase;
import haxe.macro.Expr.Function;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.nodes.ParticleTimeNode;
import haxe.ds.ObjectMap;
import away3d.animators.nodes.ParticleNodeBase;
import openfl.errors.Error;
import openfl.Vector;

class ParticleAnimationSet extends AnimationSetBase implements IAnimationSet {
    public var particleNodes(get, never):Array<ParticleNodeBase>;

    /** @private */
    public var animationRegisterCache:AnimationRegisterCache;
    
    //all other nodes dependent on it
    private var _timeNode:ParticleTimeNode;

    /**
	 * Property used by particle nodes that require compilation at the end of the shader
	 */
    static public var POST_PRIORITY:Int = 9;

    /**
	 * Property used by particle nodes that require color compilation
	 */
    static public var COLOR_PRIORITY:Int = 18;
    private var _animationSubGeometries:ObjectMap<ISubGeometry, AnimationSubGeometry>;
    private var _particleNodes:Array<ParticleNodeBase>;
    private var _localDynamicNodes:Array<ParticleNodeBase>;
    private var _localStaticNodes:Array<ParticleNodeBase>;
    private var _totalLenOfOneVertex:Int;
    
    //set true if has an node which will change UV
    public var hasUVNode:Bool;
    
    //set if the other nodes need to access the velocity
    public var needVelocity:Bool;
    
    //set if has a billboard node.
    public var hasBillboard:Bool;
    
    //set if has an node which will apply color multiple operation
    public var hasColorMulNode:Bool;
    
    //set if has an node which will apply color add operation
    public var hasColorAddNode:Bool;

    /**
	 * Initialiser function for static particle properties. Needs to reference a function with teh following format
	 *
	 * <code>
	 * function initParticleFunc(prop:ParticleProperties):void
	 * {
	 * 		//code for settings local properties
	 * }
	 * </code>
	 *
	 * Aside from setting any properties required in particle animation nodes using local static properties, the initParticleFunc function
	 * is required to time node requirements as they may be needed. These properties on the ParticleProperties object can include
	 * <code>startTime</code>, <code>duration</code> and <code>delay</code>. The use of these properties is determined by the setting
	 * arguments passed in the constructor of the particle animation set. By default, only the <code>startTime</code> property is required.
	 */
    public var initParticleFunc:Dynamic -> Void;
    
    /**
	 * Creates a new <code>ParticleAnimationSet</code>
	 *
	 * @param    [optional] usesDuration    Defines whether the animation set uses the <code>duration</code> data in its static properties function to determine how long a particle is visible for. Defaults to false.
	 * @param    [optional] usesLooping     Defines whether the animation set uses a looping timeframe for each particle determined by the <code>startTime</code>, <code>duration</code> and <code>delay</code> data in its static properties function. Defaults to false. Requires <code>usesDuration</code> to be true.
	 * @param    [optional] usesDelay       Defines whether the animation set uses the <code>delay</code> data in its static properties function to determine how long a particle is hidden for. Defaults to false. Requires <code>usesLooping</code> to be true.
	 */
    public function new(usesDuration:Bool = false, usesLooping:Bool = false, usesDelay:Bool = false) {
        _animationSubGeometries = new ObjectMap<ISubGeometry, AnimationSubGeometry>();
        _particleNodes = new Array<ParticleNodeBase>();
        _localDynamicNodes = new Array<ParticleNodeBase>();
        _localStaticNodes = new Array<ParticleNodeBase>();
        _totalLenOfOneVertex = 0;
        
        //automatically add a particle time node to the set
        super();
        addAnimation(_timeNode = new ParticleTimeNode(usesDuration, usesLooping, usesDelay));

    }

    /**
	 * Returns a vector of the particle animation nodes contained within the set.
	 */
    private function get_particleNodes():Array<ParticleNodeBase> {
        return _particleNodes;
    }

    /**
	 * @inheritDoc
	 */
    override public function addAnimation(node:AnimationNodeBase):Void {
        var i:Int;
        var n:ParticleNodeBase = cast(node, ParticleNodeBase);
        n.processAnimationSetting(this);
        if (n.mode == ParticlePropertiesMode.LOCAL_STATIC) {
            n.dataOffset = _totalLenOfOneVertex;
            _totalLenOfOneVertex += n.dataLength;
            _localStaticNodes.push(n);
        }

        else if (n.mode == ParticlePropertiesMode.LOCAL_DYNAMIC) _localDynamicNodes.push(n);
        i = _particleNodes.length - 1;
        while (i >= 0) {
            if (_particleNodes[i].priority <= n.priority) break;
            i--;
        }
        _particleNodes.insert(i + 1, n);
        super.addAnimation(node);
    }

    /**
	 * @inheritDoc
	 */
    public function activate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):Void {
        animationRegisterCache = pass.animationRegisterCache;
    }

    /**
	 * @inheritDoc
	 */
    public function deactivate(stage3DProxy:Stage3DProxy, pass:MaterialPassBase):Void {
        var context:Context3D = stage3DProxy.context3D;
        var offset:Int = animationRegisterCache.vertexAttributesOffset;
        var used:Int = animationRegisterCache.numUsedStreams;
        var i:Int = offset;
        while (i < used) {
            context.setVertexBufferAt(i, null);
            i++;
        }
    }

    /**
	 * @inheritDoc
     */
    public function getAGALVertexCode(pass:MaterialPassBase, sourceRegisters:Vector<String>, targetRegisters:Vector<String>, profile:String):String {
        
        //grab animationRegisterCache from the materialpassbase or create a new one if the first time
        animationRegisterCache = (pass.animationRegisterCache != null ? pass.animationRegisterCache : pass.animationRegisterCache = new AnimationRegisterCache(profile));
        
        //reset animationRegisterCache
        animationRegisterCache.vertexConstantOffset = pass.numUsedVertexConstants;
        animationRegisterCache.vertexAttributesOffset = pass.numUsedStreams;
        animationRegisterCache.varyingsOffset = pass.numUsedVaryings;
        animationRegisterCache.fragmentConstantOffset = pass.numUsedFragmentConstants;
        animationRegisterCache.hasUVNode = hasUVNode;
        animationRegisterCache.needVelocity = needVelocity;
        animationRegisterCache.hasBillboard = hasBillboard;
        animationRegisterCache.sourceRegisters = sourceRegisters;
        animationRegisterCache.targetRegisters = targetRegisters;
        animationRegisterCache.needFragmentAnimation = pass.needFragmentAnimation;
        animationRegisterCache.needUVAnimation = pass.needUVAnimation;
        animationRegisterCache.hasColorAddNode = hasColorAddNode;
        animationRegisterCache.hasColorMulNode = hasColorMulNode;
        animationRegisterCache.reset();
        var code:String = "";
        code += animationRegisterCache.getInitCode();
        var node:ParticleNodeBase;
        for (node in _particleNodes) {
            if (node.priority < POST_PRIORITY) code += node.getAGALVertexCode(pass, animationRegisterCache);
        }

        code += animationRegisterCache.getCombinationCode();
        for (node in _particleNodes) {
            if (node.priority >= POST_PRIORITY && node.priority < COLOR_PRIORITY) code += node.getAGALVertexCode(pass, animationRegisterCache);
        }

        code += animationRegisterCache.initColorRegisters();
        for (node in _particleNodes) {
            if (node.priority >= COLOR_PRIORITY) code += node.getAGALVertexCode(pass, animationRegisterCache);
        }

        code += animationRegisterCache.getColorPassCode();
        return code;
    }

    /**
	 * @inheritDoc
	 */
    public function getAGALUVCode(pass:MaterialPassBase, UVSource:String, UVTarget:String):String {
        var code:String = "";
        if (hasUVNode) {
            animationRegisterCache.setUVSourceAndTarget(UVSource, UVTarget);
            code += "mov " + animationRegisterCache.uvTarget + ".xy," + animationRegisterCache.uvAttribute.toString() + "\n";
            var node:ParticleNodeBase;
            for (node in _particleNodes)code += node.getAGALUVCode(pass, animationRegisterCache);
            code += "mov " + animationRegisterCache.uvVar.toString() + "," + animationRegisterCache.uvTarget + ".xy\n";
        }

        else code += "mov " + UVTarget + "," + UVSource + "\n";
        return code;
    }

    /**
	 * @inheritDoc
	 */
    public function getAGALFragmentCode(pass:MaterialPassBase, shadedTarget:String, profile:String):String {
        return animationRegisterCache.getColorCombinationCode(shadedTarget);
    }

    /**
	 * @inheritDoc
	 */
    public function doneAGALCode(pass:MaterialPassBase):Void {
        animationRegisterCache.setDataLength();
        
        //set vertexZeroConst,vertexOneConst,vertexTwoConst
        animationRegisterCache.setVertexConst(animationRegisterCache.vertexZeroConst.index, 0, 1, 2, 0);
    }

    /**
	 * @inheritDoc
	 */
    override private function get_usesCPU():Bool {
        return false;
    }

    /**
	 * @inheritDoc
	 */
    override public function cancelGPUCompatibility():Void {
    }

    override public function dispose():Void {
        var subGeometry:AnimationSubGeometry;
        for (subGeometry in _animationSubGeometries) subGeometry.dispose();
        super.dispose();
    }

    /** @private */
    public function generateAnimationSubGeometries(mesh:Mesh):Void {
        if (initParticleFunc == null) 
            throw (new Error("no initParticleFunc set"));
        
        var geometry:ParticleGeometry = cast(mesh.geometry, ParticleGeometry);
        if (geometry == null) 
            throw (new Error("Particle animation can only be performed on a ParticleGeometry object"));
        
        var i:Int;
        var j:Int;
        var animationSubGeometry:AnimationSubGeometry = null;
        var newAnimationSubGeometry:Bool = false;
        var subGeometry:ISubGeometry;
        var subMesh:SubMesh;
        var localNode:ParticleNodeBase;
        i = 0;
        while (i < mesh.subMeshes.length) {
            subMesh = mesh.subMeshes[i];
            subGeometry = subMesh.subGeometry;
            if (mesh.shareAnimationGeometry) {
                animationSubGeometry = _animationSubGeometries.get(subGeometry);
                if (animationSubGeometry != null) {
                    subMesh.animationSubGeometry = animationSubGeometry;
                    {
                        i++;
                        continue;
                    }

                }
            }
            animationSubGeometry = subMesh.animationSubGeometry = new AnimationSubGeometry();
            if (mesh.shareAnimationGeometry)
                _animationSubGeometries.set(subGeometry, animationSubGeometry);
            newAnimationSubGeometry = true;
            
            //create the vertexData vector that will be used for local node data
            animationSubGeometry.createVertexData(subGeometry.numVertices, _totalLenOfOneVertex);
            i++;
        }
        
        if (newAnimationSubGeometry == false) return;
        
        var particles:Array<ParticleData> = geometry.particles;
        var particlesLength:Int = particles.length;
        var numParticles:Int = geometry.numParticles;
        var particleProperties:ParticleProperties = new ParticleProperties();
        var particle:ParticleData = null;
        var oneDataLen:Int;
        var oneDataOffset:Int;
        var counterForVertex:Int;
        var counterForOneData:Int;
        var oneData:Array<Float>;
        var numVertices:Int;
        var vertexData:Vector<Float>;
        var vertexLength:Int;
        var startingOffset:Int;
        var vertexOffset:Int;
        
        //default values for particle param
        particleProperties.total = numParticles;
        particleProperties.startTime = 0;
        particleProperties.duration = 1000;
        particleProperties.delay = 0.1;
        i = 0;
        j = 0;
        while (i < numParticles) {
            particleProperties.index = i;
            
            //call the init function on the particle parameters
            initParticleFunc(particleProperties);
            
            //create the next set of node properties for the particle
            for (k in 0..._localStaticNodes.length) {
                var localNode:ParticleNodeBase = _localStaticNodes[k];
                localNode.generatePropertyOfOneParticle(particleProperties);
                
                //loop through all particle data for the curent particle
                while (j < particlesLength && (particle = particles[j]).particleIndex == i) {

                    //find the target animationSubGeometry
                    for (subMesh in mesh.subMeshes) {
                        if (subMesh.subGeometry == particle.subGeometry) {
                            animationSubGeometry = subMesh.animationSubGeometry;
                            break;
                        }
                    }

                    numVertices = particle.numVertices;
                    vertexData = animationSubGeometry.vertexData;
                    vertexLength = numVertices * _totalLenOfOneVertex;
                    startingOffset = animationSubGeometry.numProcessedVertices * _totalLenOfOneVertex;

                    //loop through each static local node in the animation set
                    for (localNode in _localStaticNodes) {
                        oneData = localNode.oneData;
                        oneDataLen = localNode.dataLength;
                        oneDataOffset = startingOffset + localNode.dataOffset;

                        //loop through each vertex set in the vertex data
                        counterForVertex = 0;
                        while (counterForVertex < vertexLength) {
                            vertexOffset = oneDataOffset + counterForVertex;

                            //add the data for the local node to the vertex data
                            counterForOneData = 0;
                            while (counterForOneData < oneDataLen) {
                                vertexData[vertexOffset + counterForOneData] = oneData[counterForOneData];
                                counterForOneData++;
                            }
                            counterForVertex += _totalLenOfOneVertex;
                        }
                    }

                    //store particle properties if they need to be retreived for dynamic local nodes
                    if (_localDynamicNodes.length > 0) animationSubGeometry.animationParticles.push(new ParticleAnimationData(i, particleProperties.startTime, particleProperties.duration, particleProperties.delay, particle));
                    animationSubGeometry.numProcessedVertices += numVertices;

                    //next index
                    j++;
                }
            }
    
            //next particle
            i++;
        }
    }
}


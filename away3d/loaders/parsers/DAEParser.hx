package away3d.loaders.parsers;

import away3d.animators.SkeletonAnimationSet;
import away3d.animators.data.JointPose;
import away3d.animators.data.Skeleton;
import away3d.animators.data.SkeletonJoint;
import away3d.animators.data.SkeletonPose;
import away3d.animators.nodes.AnimationNodeBase;
import away3d.animators.nodes.SkeletonClipNode;
import away3d.containers.ObjectContainer3D;
import away3d.core.base.CompactSubGeometry;
import away3d.core.base.Geometry;
import away3d.core.base.SkinnedSubGeometry;
import away3d.debug.Debug;
import away3d.entities.Mesh;
import away3d.loaders.misc.ResourceDependency;
import away3d.materials.ColorMaterial;
import away3d.materials.ColorMultiPassMaterial;
import away3d.materials.MaterialBase;
import away3d.materials.MultiPassMaterialBase;
import away3d.materials.SinglePassMaterialBase;
import away3d.materials.TextureMaterial;
import away3d.materials.TextureMultiPassMaterial;
import away3d.materials.methods.BasicAmbientMethod;
import away3d.materials.methods.BasicDiffuseMethod;
import away3d.materials.methods.BasicSpecularMethod;
import away3d.materials.utils.DefaultMaterialManager;
import away3d.textures.BitmapTexture;
import away3d.textures.Texture2DBase;

#if (haxe_ver >= 4)
import haxe.xml.Access;
#else
import haxe.xml.Fast as Access;
#end

import haxe.EnumTools;
import openfl.display.BitmapData;
import openfl.errors.Error;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;
import openfl.Vector;
using Reflect;
using StringTools;

/**
 * DAEParser provides a parser for the DAE data type.
 */
class DAEParser extends ParserBase
{
	public static inline var CONFIG_USE_GPU:Int = 1;
	public static inline var CONFIG_DEFAULT:Int = CONFIG_USE_GPU;
	public static inline var PARSE_GEOMETRIES:Int = 1;
	public static inline var PARSE_IMAGES:Int = 2;
	public static inline var PARSE_MATERIALS:Int = 4;
	public static inline var PARSE_VISUAL_SCENES:Int = 8;
	public static var PARSE_DEFAULT:Int = PARSE_GEOMETRIES | PARSE_IMAGES | PARSE_MATERIALS | PARSE_VISUAL_SCENES;
	
	private var _doc:Xml;
	private var _fastDoc:Access;
	private var _parseState:DAEParserState = DAEParserState.LOAD_XML;
	private var _imageList:#if (haxe_ver >= "4.0.0") Array<Access> #else List<Access> #end;
	private var _imageCount:Int;
	private var _currentImage:Int;
	private var _dependencyCount:Int = 0;
	private var _configFlags:Int;
	private var _parseFlags:Int;
	private var _libImages:Map<String, DAEImage>;
	private var _libMaterials:Map<String, DAEMaterial>;
	private var _libEffects:Map<String, DAEEffect>;
	private var _libGeometries:Map<String, DAEGeometry>;
	private var _libControllers:Map<String, DAEController>;
	private var _libAnimations:Map<String, DAEAnimation>;
	private var _scene:DAEScene;
	private var _root:DAEVisualScene;
	//private var _rootContainer : ObjectContainer3D;
	private var _geometries:Vector<Geometry>;
	private var _animationInfo:DAEAnimationInfo;
	//private var _animators : Vector.<IAnimator>;
	private var _rootNodes:Vector<AnimationNodeBase>;
	private var _defaultBitmapMaterial:MaterialBase = DefaultMaterialManager.getDefaultMaterial();
	private var _defaultColorMaterial:ColorMaterial = new ColorMaterial(0xff0000);
	private var _defaultColorMaterialMulti:ColorMultiPassMaterial = new ColorMultiPassMaterial(0xff0000);
	private static var _numInstances:Int = 0;
	
	/**
	 * @param    configFlags    Bitfield to configure the parser. 
	 * @see DAEParser.CONFIG_USE_GPU etc.
	 */
	public function new(configFlags:Int = 0)
	{
		_configFlags = configFlags > 0? configFlags : CONFIG_DEFAULT;
		_parseFlags = PARSE_DEFAULT;
		
		super(ParserDataFormat.PLAIN_TEXT);
	}
	
	public function getGeometryByName(name:String, clone:Bool = false):Geometry
	{
		if (_geometries == null)
			return null;
		
		for (geometry in _geometries) {
			if (geometry.name == name)
				return (clone? geometry.clone() : geometry);
		}
		
		return null;
	}
	
	/**
	 * Indicates whether or not a given file extension is supported by the parser.
	 * @param extension The file extension of a potential file to be parsed.
	 * @return Whether or not the given file type is supported.
	 */
	public static function supportsType(extension:String):Bool
	{
		extension = extension.toLowerCase();
		return extension == "dae";
	}
	
	/**
	 * Tests whether a data block can be parsed by the parser.
	 * @param data The data block to potentially be parsed.
	 * @return Whether or not the given data is supported.
	 */
	public static function supportsData(data:Dynamic):Bool
	{
		var text = Std.string (data);
		if (text.indexOf("COLLADA") != -1 || text.indexOf("collada") != -1)
			return true;
		
		return false;
	}
	
	
	/**
	 * @inheritDoc
	 */
	override private function resolveDependency(resourceDependency:ResourceDependency):Void
	{
		if (resourceDependency.assets.length != 1)
			return;
		var resource:Texture2DBase = #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(resourceDependency.assets[0], Texture2DBase) ? cast resourceDependency.assets[0] : null;
		_dependencyCount--;
		
		if (resource != null && cast(resource, BitmapTexture).bitmapData != null) {
			var image:DAEImage = _libImages.get(resourceDependency.id);
			
			if (image != null)
				image.resource = cast(resource, BitmapTexture);
		}
		
		if (_dependencyCount == 0)
			_parseState = DAEParserState.PARSE_MATERIALS;
	}
	
	
	/**
	 * @inheritDoc
	 */
	override private function resolveDependencyFailure(resourceDependency:ResourceDependency):Void
	{
		_dependencyCount--;
		
		if (_dependencyCount == 0)
			_parseState = DAEParserState.PARSE_MATERIALS;
	}
	
	
	/**
	 * @inheritDoc
	 */
	override private function proceedParsing():Bool
	{
		if (_defaultBitmapMaterial == null)
			_defaultBitmapMaterial = buildDefaultMaterial();
		
		var empty = #if (haxe_ver >= "4.0.0") new Array<Access>() #else new List<Access>() #end;
		switch (_parseState) {
			case DAEParserState.LOAD_XML:
				try {
					_doc = Xml.parse(getTextData());
					_fastDoc = new Access(_doc.firstElement());
					_imageList = _fastDoc.hasNode.library_images ? _fastDoc.node.resolve("library_images").nodes.resolve("image") : empty;
					_imageCount = _dependencyCount = _imageList.length;
					_currentImage = 0;
					_parseState = _imageCount > 0? DAEParserState.PARSE_IMAGES : DAEParserState.PARSE_MATERIALS;
					
				} catch (e:Error) {
					return ParserBase.PARSING_DONE;
				}
			
			case DAEParserState.PARSE_IMAGES:
				_libImages = parseLibrary(_fastDoc.hasNode.library_images ? _fastDoc.node.resolve("library_images").nodes.resolve("image") : empty, DAEImage);
				var keys:Iterator<String> = _libImages.keys();
				for (imageId in keys) {
					var image:DAEImage = _libImages[imageId];
					addDependency(image.id, new URLRequest(image.init_from));
				}
				pauseAndRetrieveDependencies();
			
			case DAEParserState.PARSE_MATERIALS:
				_libMaterials = parseLibrary(_fastDoc.hasNode.library_materials ? _fastDoc.node.resolve("library_materials").nodes.resolve("material") : empty, DAEMaterial);
				_libEffects = parseLibrary(_fastDoc.hasNode.library_effects ? _fastDoc.node.resolve("library_effects").nodes.resolve("effect") : empty, DAEEffect);
				setupMaterials();
				_parseState = DAEParserState.PARSE_GEOMETRIES;
			
			case DAEParserState.PARSE_GEOMETRIES:
				_libGeometries = parseLibrary(_fastDoc.hasNode.library_geometries ? _fastDoc.node.resolve("library_geometries").nodes.resolve("geometry") : empty, DAEGeometry);
				_geometries = translateGeometries();
				_parseState = DAEParserState.PARSE_CONTROLLERS;
			
			case DAEParserState.PARSE_CONTROLLERS:
				_libControllers = parseLibrary(_fastDoc.hasNode.library_controllers ? _fastDoc.node.resolve("library_controllers").nodes.resolve("controller") : empty, DAEController);
				_parseState = DAEParserState.PARSE_VISUAL_SCENE;
			
			case DAEParserState.PARSE_VISUAL_SCENE:
				_scene = null;
				_root = null;
				//Unlike images, materials, effects, geometry, and controllers, animations can be nested.
				var animationList = empty;
				if(_fastDoc.hasNode.library_animations) {
					//Use an array to collect the data, even in Haxe 3.
					#if (haxe_ver >= "4.0.0")
					var animationArray = _fastDoc.node.library_animations.nodes.animation;
					#else
					var animationArray = Lambda.array(_fastDoc.node.library_animations.nodes.animation);
					#end
					
					//Iterate through, including any animations that are added during iteration. Neither
					//the default array iterator nor the default list iterator handles this correctly.
					var i:Int = 0;
					while(i < animationArray.length) {
						if(animationArray[i].hasNode.animation) {
							for(childAnimation in animationArray[i].nodes.animation) {
								animationArray.push(childAnimation);
							}
							
							//Often, parent nodes will contain no animation data of their own,
							//meaning there's no need to make a DAEAnimation for them.
							if(!animationArray[i].hasNode.source) {
								animationArray.splice(i, 1);
								i--;
							}
						}
						
						i++;
					}
					
					#if (haxe_ver >= "4.0.0")
					animationList = animationArray;
					#else
					animationList = Lambda.list(animationArray);
					#end
				}
				
				_libAnimations = parseLibrary(animationList, DAEAnimation);
				//_animators = new Vector.<IAnimator>();
				_rootNodes = new Vector<AnimationNodeBase>();
				
				if (_fastDoc.hasNode.resolve("scene")) {
					_scene = new DAEScene(_fastDoc.node.scene);
					
					var list = #if (haxe_ver >= "4.0.0") new Array<Access>() #else new List<Access>() #end;
					var visualScenes = _fastDoc.node.library_visual_scenes.nodes.resolve("visual_scene");
					for (visualScene in visualScenes) {
						if (visualScene.att.id == _scene.instance_visual_scene.url) {
							list.push(visualScene);
						}
					}
					
					if (list.length > 0) {
						//_rootContainer = new ObjectContainer3D();
						_root = new DAEVisualScene(this, #if (haxe_ver >= "4.0.0") list[0] #else list.first() #end);
						_root.updateTransforms(_root);
						_animationInfo = parseAnimationInfo();
						parseSceneGraph(_root);
					}
				}
				_parseState = isAnimated? DAEParserState.PARSE_ANIMATIONS : DAEParserState.PARSE_COMPLETE;
			
			case DAEParserState.PARSE_ANIMATIONS:
				_parseState = DAEParserState.PARSE_COMPLETE;
			
			case DAEParserState.PARSE_COMPLETE:
				return ParserBase.PARSING_DONE;
		}
		
		return ParserBase.MORE_TO_PARSE;
	}
	
	private function buildDefaultMaterial(map:BitmapData = null):MaterialBase
	{
		//TODO:fix this duplication mess
		if (map != null) {
			if (materialMode < 2)
				_defaultBitmapMaterial = new TextureMaterial(new BitmapTexture(map));
			else
				_defaultBitmapMaterial = new TextureMultiPassMaterial(new BitmapTexture(map));
		} else if (materialMode < 2)
			_defaultBitmapMaterial = DefaultMaterialManager.getDefaultMaterial();
		else
			_defaultBitmapMaterial = new TextureMultiPassMaterial(DefaultMaterialManager.getDefaultTexture());
		
		return _defaultBitmapMaterial;
	}
	
	private function applySkinBindShape(geometry:Geometry, skin:DAESkin):Void
	{
		var vec:Vector3D = new Vector3D();
		var i:Int;
		var sub:CompactSubGeometry;
		for (sub in geometry.subGeometries) {
			var vertexData:Vector<Float> = sub.vertexData;
			
			i = sub.vertexOffset;
			while (i < vertexData.length) {
				vec.x = vertexData[i + 0];
				vec.y = vertexData[i + 1];
				vec.z = vertexData[i + 2];
				vec = skin.bind_shape_matrix.transformVector(vec);
				vertexData[i + 0] = vec.x;
				vertexData[i + 1] = vec.y;
				vertexData[i + 2] = vec.z;
				i += sub.vertexStride;
			}
			cast(sub, CompactSubGeometry).updateData(vertexData);
		}
	}
	
	private function applySkinController(geometry:Geometry, mesh:DAEMesh, skin:DAESkin, skeleton:Skeleton):Void
	{
		var sub:CompactSubGeometry;
		var skinned_sub_geom:SkinnedSubGeometry;
		var primitive:DAEPrimitive;
		var jointIndices:Vector<Float>;
		var jointWeights:Vector<Float>;
		var i:Int, j:Int, k:Int, l:Int;
		
		for (i in 0...geometry.subGeometries.length) {
			sub = cast(geometry.subGeometries[i], CompactSubGeometry);
			primitive = mesh.primitives[i];
			jointIndices = new Vector<Float>(skin.maxBones * primitive.vertices.length, true);
			jointWeights = new Vector<Float>(skin.maxBones * primitive.vertices.length, true);
			l = 0;
			
			for (j in 0...primitive.vertices.length) {
				var weights:Vector<DAEVertexWeight> = skin.weights[primitive.vertices[j].daeIndex];
				
				for (k in 0...weights.length) {
					var influence:DAEVertexWeight = weights[k];
					// indices need to be multiplied by 3 (amount of matrix registers)
					jointIndices[l] = influence.joint*3;
					jointWeights[l++] = influence.weight;
				}
				
				for (k in weights.length...skin.maxBones) {
					jointIndices[l] = 0;
					jointWeights[l++] = 0;
				}
			}
			
			skinned_sub_geom = new SkinnedSubGeometry(skin.maxBones);
			skinned_sub_geom.updateData(sub.vertexData.concat());
			skinned_sub_geom.updateIndexData(sub.indexData);
			skinned_sub_geom.updateJointIndexData(jointIndices);
			skinned_sub_geom.updateJointWeightsData(jointWeights);
			geometry.subGeometries[i] = skinned_sub_geom;
			geometry.subGeometries[i].parentGeometry = geometry;
		}
	}
	
	private function parseAnimationInfo():DAEAnimationInfo
	{
		var info:DAEAnimationInfo = new DAEAnimationInfo();
		info.minTime = Math.POSITIVE_INFINITY;
		info.maxTime = -info.minTime;
		info.numFrames = 0;
		
		var animation:DAEAnimation;
		for (animation in _libAnimations) {
			var channel:DAEChannel;
			for (channel in animation.channels) {
				var node:DAENode = _root.findNodeById(channel.targetId);
				if (node != null) {
					node.channels.push(channel);
					info.minTime = Math.min(info.minTime, channel.sampler.minTime);
					info.maxTime = Math.max(info.maxTime, channel.sampler.maxTime);
					info.numFrames = Std.int(Math.max(info.numFrames, channel.sampler.input.length));
				}
			}
		}
		
		if(!Math.isFinite(info.minTime)) {
			info.minTime = 0;
		}
		if(!Math.isFinite(info.maxTime)) {
			info.maxTime = 0;
		}
		
		return info;
	}
	
	private function parseLibrary<T>(list:#if (haxe_ver >= "4.0.0") Array<Access> #else List<Access> #end, clas:Class<T>):Map<String, T>
	{
		var library:Map<String, T> = new Map<String, T>();
		for (element in list) {
			var obj:T = Type.createInstance(clas, [element]);
			library.set(untyped obj.id, obj);
		}
		
		return library;
	}
	
	private function parseSceneGraph(node:DAENode, parent:ObjectContainer3D = null, tab:String = ""):Void
	{
		var _tab:String = tab + "-";
		
		Debug.trace(_tab + node.name);
		
		if (node.type != "JOINT") {
			Debug.trace(_tab + "ObjectContainer3D : " + node.name);
			
			var container:ObjectContainer3D;
			
			if (node.instance_geometries.length > 0)
				container = processGeometries(node, parent);
			else if (node.instance_controllers.length > 0)
				container = processControllers(node, parent);
			else {
				// trace("Should be a container " + node.id)
				container = new ObjectContainer3D();
				container.name = node.id;
				container.transform.rawData = node.matrix.rawData;
				finalizeAsset(container, node.id);
				
				if (parent != null)
					parent.addChild(container);
			}
			
			parent = container;
		}
		for (i in 0...node.nodes.length)
			parseSceneGraph(node.nodes[i], parent, _tab);
	}
	
	private function processController(controller:DAEController, instance:DAEInstanceController):Geometry
	{
		var geometry:Geometry = null;
		if (controller == null)
			return null;
		
		if (controller.morph != null)
			geometry = processControllerMorph(controller, instance);
		else if (controller.skin != null)
			geometry = processControllerSkin(controller, instance);
		
		return geometry;
	}
	
	private function processControllerMorph(controller:DAEController, instance:DAEInstanceController):Geometry
	{
		Debug.trace(" * processControllerMorph : " + controller);
		
		var morph:DAEMorph = controller.morph;
		
		var base:Geometry = processController(_libControllers[morph.source], instance);
		if (base == null)
			return null;
		
		var targets:Vector<Geometry> = new Vector<Geometry>();
		base = getGeometryByName(morph.source);
		var vertexData:Vector<Float>;
		var sub:CompactSubGeometry;
		var startWeight:Float = 1.0;
		var j:Int, k:Int;
		var geometry:Geometry;
		
		for (i in 0...morph.targets.length) {
			geometry = getGeometryByName(morph.targets[i]);
			if (geometry == null)
				return null;
			
			targets.push(geometry);
			startWeight -= morph.weights[i];
		}
		
		for (i in 0...base.subGeometries.length) {
			sub = cast(base.subGeometries[i], CompactSubGeometry);
			vertexData = sub.vertexData.concat();
			for (v in 0...Std.int(vertexData.length/13)) {
				j = sub.vertexOffset + v*sub.vertexStride;
				vertexData[j] = morph.method == "NORMALIZED"? startWeight*sub.vertexData[j] : sub.vertexData[j];
				for (k in 0...morph.targets.length)
					vertexData[j] += morph.weights[k]*targets[k].subGeometries[i].vertexData[j];
			}
			sub.updateData(vertexData);
		}
		
		return base;
	}
	
	private function processControllerSkin(controller:DAEController, instance:DAEInstanceController):Geometry
	{
		Debug.trace(" * processControllerSkin : " + controller);
		
		var geometry:Geometry = getGeometryByName(controller.skin.source);
		
		if (geometry == null)
			geometry = processController(_libControllers[controller.skin.source], instance);
		
		if (geometry == null)
			return null;
		
		var skeleton:Skeleton = parseSkeleton(instance);
		var daeGeometry:DAEGeometry = _libGeometries[geometry.name];
		applySkinBindShape(geometry, controller.skin);
		applySkinController(geometry, daeGeometry.mesh, controller.skin, skeleton);
		controller.skin.userData = skeleton;
		
		finalizeAsset(skeleton);
		
		return geometry;
	}
	
	private function processControllers(node:DAENode, container:ObjectContainer3D):Mesh
	{
		Debug.trace(" * processControllers : " + node.name);
		
		var instance:DAEInstanceController = null;
		var daeGeometry:DAEGeometry = null;
		var controller:DAEController = null;
		var effects:Vector<DAEEffect> = null;
		var geometry:Geometry = null;
		var mesh:Mesh = null;
		var skeleton:Skeleton = null;
		var clip:SkeletonClipNode = null;
		//var anim:SkeletonAnimation;
		var animationSet:SkeletonAnimationSet = null;
		var hasMaterial:Bool;
		var weights:Int;
		var jpv:Int;
		
		for (i in 0...node.instance_controllers.length) {
			instance = node.instance_controllers[i];
			controller = _libControllers[instance.url];
			
			geometry = processController(controller, instance);
			if (geometry == null)
				continue;
			
			daeGeometry = _libGeometries[geometry.name];
			effects = getMeshEffects(instance.bind_material, daeGeometry.mesh);
			
			mesh = new Mesh(geometry, null);
			hasMaterial = false;
			
			if (node.name != "")
				mesh.name = node.name;
			
			if (effects.length > 0) {
				for (j in 0...mesh.subMeshes.length) {
					if (effects[j].material != null) {
						mesh.subMeshes[j].material = effects[j].material;
						hasMaterial = true;
					}
				}
			}
			
			if (!hasMaterial)
				mesh.material = _defaultBitmapMaterial;
			
			if (container != null)
				container.addChild(mesh);
			
			if (controller.skin != null && #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end(controller.skin.userData, Skeleton)) {
				
				if (animationSet == null)
					animationSet = new SkeletonAnimationSet(controller.skin.maxBones);
				
				skeleton = cast(controller.skin.userData, Skeleton);
				
				clip = processSkinAnimation(controller.skin, mesh, skeleton);
				clip.looping = true;
				
				weights = cast(mesh.geometry.subGeometries[0], SkinnedSubGeometry).jointIndexData.length;
				jpv = Std.int(weights / (mesh.geometry.subGeometries[0].vertexData.length / 3));
				//anim = new SkeletonAnimation(skeleton, jpv);
				
				//var state:SkeletonAnimationState = SkeletonAnimationState(mesh.animationState);
				//animator = new SmoothSkeletonAnimator(state);
				//SmoothSkeletonAnimator(animator).addSequence(SkeletonAnimationSequence(sequence));
				clip.name = "node_" + _rootNodes.length;
				animationSet.addAnimation(clip);
				
				//_animators.push(animator);
				_rootNodes.push(clip);
			}
			
			finalizeAsset(mesh);
		}
		
		if (animationSet != null)
			finalizeAsset(animationSet);
		
		return mesh;
	}
	
	private function processSkinAnimation(skin:DAESkin, mesh:Mesh, skeleton:Skeleton):SkeletonClipNode
	{
		Debug.trace(" * processSkinAnimation : " + mesh.name);
		
		//var useGPU : Bool = _configFlags & CONFIG_USE_GPU ? true : false;
		//var animation : SkeletonAnimation = new SkeletonAnimation(skeleton, skin.maxBones, useGPU);
		var animated:Bool = isAnimatedSkeleton(skeleton);
		// Use maxTime, the total duration should not be affected by the minimum time.
		var duration:Float = _animationInfo.numFrames == 0 ? 1.0 : _animationInfo.maxTime;
		// Fixed abnormal bone animation data with less than 50frame
		var numFrames:Int = Std.int(Math.max(_animationInfo.numFrames, (animated ? _animationInfo.numFrames : 2)));
		var frameDuration:Float = duration / numFrames;
		// Use minTime, avoid getting uninitialized bone poses at the initial frame.
		var t:Float = _animationInfo.minTime;
		var clip:SkeletonClipNode = new SkeletonClipNode();
		//mesh.geometry.animation = animation;
		var skeletonPose:SkeletonPose = null;
		var identity:Matrix3D = null;
		var matrix:Matrix3D = null;
		var node:DAENode = null;
		var pose:JointPose = null;
		
		for (i in 0...numFrames) {
			skeletonPose = new SkeletonPose();
			
			for (j in 0...skin.joints.length) {
				node = _root.findNodeById(skin.joints[j]);
				if (node == null)
					node = _root.findNodeBySid(skin.joints[j]);
				pose = new JointPose();
				
				// Fix matrix
				matrix = node.getAnimatedMatrix(t);
				if(matrix == null)
					matrix = node.matrix;

				pose.name = skin.joints[j];
				pose.orientation.fromMatrix(matrix);
				pose.translation.copyFrom(matrix.position);
				
				if (Math.isNaN(pose.orientation.x)) {
					if (identity == null)
						identity = new Matrix3D();
					pose.orientation.fromMatrix(identity);
				}
				
				skeletonPose.jointPoses.push(pose);
			}
			
			t += frameDuration;
			if(t >= _animationInfo.maxTime)
				t = _animationInfo.maxTime;
			
			clip.addFrame(skeletonPose, Std.int(frameDuration * 1000));

		}
		
		finalizeAsset(clip);
		
		return clip;
	}
	
	private function isAnimatedSkeleton(skeleton:Skeleton):Bool
	{
		var node:DAENode;
		
		for (i in 0...skeleton.joints.length) {
			try {
				node = _root.findNodeById(skeleton.joints[i].name);
				if (node == null)
					node = _root.findNodeBySid(skeleton.joints[i].name);
			} catch (e:Error) {
				Debug.trace("Errors found in skeleton joints data");
				return false;
			}
			if (node != null && node.channels.length != 0)
				return true;
		}
		
		return false;
	}
	
	private function processGeometries(node:DAENode, container:ObjectContainer3D):Mesh
	{
		Debug.trace(" * processGeometries : " + node.name);
		var instance:DAEInstanceGeometry = null;
		var daeGeometry:DAEGeometry = null;
		var effects:Vector<DAEEffect> = null;
		var mesh:Mesh = null;
		var geometry:Geometry = null;
		
		for (i in 0...node.instance_geometries.length) {
			instance = node.instance_geometries[i];
			daeGeometry = _libGeometries[instance.url];
			
			if (daeGeometry != null && daeGeometry.mesh != null) {
				geometry = getGeometryByName(instance.url);
				effects = getMeshEffects(instance.bind_material, daeGeometry.mesh);
				
				if (geometry != null) {
					mesh = new Mesh(geometry);
					
					if (node.name != "")
						mesh.name = node.name;
					
					if (effects.length == geometry.subGeometries.length) {
						for (j in 0...mesh.subMeshes.length)
							mesh.subMeshes[j].material = effects[j].material;
					}
					mesh.transform = node.matrix;
					
					if (container != null)
						container.addChild(mesh);
					
					finalizeAsset(mesh);
				}
			}
		}
		
		return mesh;
	}
	
	private function getMeshEffects(bindMaterial:DAEBindMaterial, mesh:DAEMesh):Vector<DAEEffect>
	{
		var effects:Vector<DAEEffect> = new Vector<DAEEffect>();
		if (bindMaterial == null)
			return effects;
		
		var material:DAEMaterial;
		var effect:DAEEffect;
		var instance:DAEInstanceMaterial;
		var i:Int, j:Int;
		
		for (i in 0...mesh.primitives.length) {
			if (bindMaterial.instance_material == null)
				continue;
			for (j in 0...bindMaterial.instance_material.length) {
				instance = bindMaterial.instance_material[j];
				if (mesh.primitives[i].material == instance.symbol) {
					material = _libMaterials.get(instance.target);
					effect = _libEffects.get(material.instance_effect.url);
					if (effect != null)
						effects.push(effect);
					break;
				}
			}
		}
		
		return effects;
	}
	
	private function parseSkeleton(instance_controller:DAEInstanceController):Skeleton
	{
		if (instance_controller.skeleton.length == 0)
			return null;
		
		Debug.trace(" * parseSkeleton : " + instance_controller);
		
		var controller:DAEController = _libControllers[instance_controller.url];
		var skeletonId:String = instance_controller.skeleton[0];
		var skeletonRoot:DAENode = _root.findNodeById(skeletonId);
		if (skeletonRoot == null)
			skeletonRoot = _root.findNodeBySid(skeletonId);
		
		if (skeletonRoot == null)
			return null;
		
		var skeleton:Skeleton = new Skeleton();
		skeleton.joints = new Vector<SkeletonJoint>(controller.skin.joints.length, true);
		parseSkeletonHierarchy(skeletonRoot, controller.skin, skeleton);
		
		return skeleton;
	}
	
	private function parseSkeletonHierarchy(node:DAENode, skin:DAESkin, skeleton:Skeleton, parent:Int = -1, tab:String = ""):Void
	{
		var _tab:String = tab + "-";
		
		Debug.trace(_tab + "[" + node.id + "," + node.sid + "]");
		
		var jointIndex:Int = skin.jointSourceType == "IDREF_array"? skin.getJointIndex(node.id) : skin.getJointIndex(node.sid);
		
		if (jointIndex >= 0) {
			var joint:SkeletonJoint = new SkeletonJoint();
			joint.parentIndex = parent;
			
			if (!Math.isNaN(jointIndex) && jointIndex < skin.joints.length) {
				if (skin.joints[jointIndex] != null)
					joint.name = skin.joints[jointIndex];
			} else {
				Debug.trace("Error: skin.joints index out of range");
				return;
			}
			
			var ibm:Matrix3D = skin.inv_bind_matrix[jointIndex];
			
			joint.inverseBindPose = ibm.rawData;
			
			skeleton.joints[jointIndex] = joint;
		} else
			Debug.trace(_tab + "no jointIndex!");
		
		for (i in 0...node.nodes.length) {
			try {
				parseSkeletonHierarchy(node.nodes[i], skin, skeleton, jointIndex);
			} catch (e:Error) {
				Debug.trace(e.message);
			}
		}
	}
	
	private function setupMaterial(material:DAEMaterial, effect:DAEEffect):MaterialBase
	{
		if (effect == null || material == null)
			return null;
		
		var mat:MaterialBase;
		if (materialMode < 2)
			mat = _defaultColorMaterial;
		else
			mat = new ColorMultiPassMaterial(_defaultColorMaterial.color);
		
		var textureMaterial:TextureMaterial;
		var ambient:DAEColorOrTexture = effect.shader.props.ambient;
		var diffuse:DAEColorOrTexture = effect.shader.props.diffuse;
		var specular:DAEColorOrTexture = effect.shader.props.specular;
		var shininess:Float = effect.shader.props.hasField("shininess") ? (Std.isOfType(effect.shader.props.shininess, String) ? Std.parseFloat(effect.shader.props.shininess) : effect.shader.props.shininess) : 10;
		var transparency:Float = effect.shader.props.hasField("transparency") ? (Std.isOfType(effect.shader.props.transparency, String) ? Std.parseFloat(effect.shader.props.transparency) : effect.shader.props.transparency) : 1;
		
		if (diffuse != null && diffuse.texture != null && effect.surface != null && _libImages != null) {
			var image:DAEImage = _libImages[effect.surface.init_from];
			
			if (image.resource != null && isBitmapDataValid(cast(image.resource, BitmapTexture).bitmapData)) {
				mat = buildDefaultMaterial(cast(image.resource, BitmapTexture).bitmapData);
				if (materialMode < 2)
					cast(mat, TextureMaterial).alpha = transparency;
			} else
				mat = buildDefaultMaterial();
			
		}
		
		else if (diffuse != null && diffuse.color != null) {
			if (materialMode < 2)
				mat = new ColorMaterial(diffuse.color.rgb, transparency);
			else
				mat = new ColorMultiPassMaterial(diffuse.color.rgb);
		}
		Debug.trace("mat = " + materialMode);
		if (mat != null) {
			if (materialMode < 2) {
				cast(mat, SinglePassMaterialBase).ambientMethod = new BasicAmbientMethod();
				cast(mat, SinglePassMaterialBase).diffuseMethod = new BasicDiffuseMethod();
				cast(mat, SinglePassMaterialBase).specularMethod = new BasicSpecularMethod();
				cast(mat, SinglePassMaterialBase).colorTransform = new ColorTransform();
				cast(mat, SinglePassMaterialBase).ambientColor = (ambient != null && ambient.color != null) ? ambient.color.rgb : 0x303030;
				cast(mat, SinglePassMaterialBase).specularColor = (specular != null && specular.color != null) ? specular.color.rgb : 0x202020;
				cast(mat, SinglePassMaterialBase).gloss = shininess;
				cast(mat, SinglePassMaterialBase).ambient = 1;
				cast(mat, SinglePassMaterialBase).specular = 1;
			} else {
				cast(mat, MultiPassMaterialBase).ambientMethod = new BasicAmbientMethod();
				cast(mat, MultiPassMaterialBase).diffuseMethod = new BasicDiffuseMethod();
				cast(mat, MultiPassMaterialBase).specularMethod = new BasicSpecularMethod();
				cast(mat, MultiPassMaterialBase).ambientColor = (ambient != null && ambient.color != null) ? ambient.color.rgb : 0x303030;
				cast(mat, MultiPassMaterialBase).specularColor = (specular != null && specular.color != null) ? specular.color.rgb : 0x202020;
				cast(mat, MultiPassMaterialBase).gloss = shininess;
				cast(mat, MultiPassMaterialBase).ambient = 1;
				cast(mat, MultiPassMaterialBase).specular = 1;
				
			}
		}
		
		mat.name = material.id;
		finalizeAsset(mat);
		
		return mat;
	}
	
	private function setupMaterials():Void
	{
		var material:DAEMaterial;
		for (material in _libMaterials) {
			if (_libEffects.exists(material.instance_effect.url)) {
				var effect:DAEEffect = _libEffects[material.instance_effect.url];
				effect.material = setupMaterial(material, effect);
			}
		}
	}
	
	private function translateGeometries():Vector<Geometry>
	{
		var geometries:Vector<Geometry> = new Vector<Geometry>();
		var daeGeometry:DAEGeometry;
		var geometry:Geometry;
		
		var id:String;
		var keys:Iterator<String> = _libGeometries.keys();
		for (id in keys) {
			daeGeometry = _libGeometries[id];
			if (daeGeometry.mesh != null) {
				geometry = translateGeometry(daeGeometry.mesh);
				if (geometry.subGeometries.length != 0) {
					if (id != null && Math.isNaN(Std.parseFloat(id)))
						geometry.name = id;
					geometries.push(geometry);
					
					finalizeAsset(geometry);
				}
			}
		}
		
		return geometries;
	}
	
	private function translateGeometry(mesh:DAEMesh):Geometry
	{
		var geometry:Geometry = new Geometry();
		for (i in 0...mesh.primitives.length) {
			var sub:CompactSubGeometry = translatePrimitive(mesh, mesh.primitives[i]);
			if (sub != null)
				geometry.addSubGeometry(sub);
		}
		
		return geometry;
	}
	
	private function translatePrimitive(mesh:DAEMesh, primitive:DAEPrimitive, reverseTriangles:Bool = true, autoDeriveVertexNormals:Bool = true, autoDeriveVertexTangents:Bool = true):CompactSubGeometry
	{
		var sub:CompactSubGeometry = new CompactSubGeometry();
		var indexData:Vector<UInt> = new Vector<UInt>();
		var data:Vector<Float> = new Vector<Float>();
		var faces:Vector<DAEFace> = primitive.create(mesh);
		var v:DAEVertex, f:DAEFace;
		var i:Int, j:Int;
		
		// vertices, normals and uvs
		for (i in 0...primitive.vertices.length) {
			v = primitive.vertices[i];
			data.push(v.x);
			data.push(v.y);
			data.push(v.z);
			data.push(v.nx);
			data.push(v.ny);
			data.push(v.nz);
			data.push(0);
			data.push(0);
			data.push(0);
			
			if (v.numTexcoordSets > 0) {
				data.push(v.uvx);
				data.push(1.0 - v.uvy);
				if (v.numTexcoordSets > 1) {
					data.push(v.uvx2);
					data.push(1.0 - v.uvy2);
				} else {
					data.push(v.uvx);
					data.push(1.0 - v.uvy);
				}
			} else {
				data.push(0);
				data.push(0);
				data.push(0);
				data.push(0);
			}
		}
		
		// triangles
		for (i in 0...faces.length) {
			f = faces[i];
			for (j in 0...f.vertices.length) {
				v = f.vertices[j];
				indexData.push(v.index);
			}
		}
		
		if (reverseTriangles)
			indexData.reverse();
		
		sub.autoDeriveVertexNormals = autoDeriveVertexNormals;
		sub.autoDeriveVertexTangents = autoDeriveVertexTangents;
		sub.updateData(data);
		sub.updateIndexData(indexData);
		
		return sub;
	}
	
	public var geometries(get, null):Vector<Geometry>;
	
	private function get_geometries():Vector<Geometry>
	{
		return _geometries;
	}
	
	public var effects(get, null):Map<String, DAEEffect>;
	
	private function get_effects():Map<String, DAEEffect>
	{
		return _libEffects;
	}
	
	public var images(get, null):Map<String, DAEImage>;
	
	private function get_images():Map<String, DAEImage>
	{
		return _libImages;
	}
	
	public var materials(get, null):Map<String, DAEMaterial>;
	
	private function get_materials():Map<String, DAEMaterial>
	{
		return _libMaterials;
	}
	
	public var isAnimated(get, null):Bool;
	
	private function get_isAnimated():Bool
	{
		var animations = _fastDoc.hasNode.library_animations;
		return (animations ? _fastDoc.node.resolve("library_animations").hasNode.resolve("animation") : false);
	}

}

class DAEAnimationInfo
{
	public var minTime:Float;
	public var maxTime:Float;
	public var numFrames:UInt;
	
	public function new()
	{
	}
}

class DAEElement
{
	public static var USE_LEFT_HANDED:Bool = true;
	public var id:String;
	public var name:String;
	public var sid:String;
	public var userData:Dynamic;
	
	public function new(element:Access = null)
	{
		if (element != null)
			deserialize(element);
	
	}
	
	public function deserialize(element:Access):Void
	{
		id = element.has.id ? element.att.id : "";
		name = element.has.name ? element.att.name : "";
		sid = element.has.sid ? element.att.sid : "";
	}
	
	public function dispose():Void
	{
	
	}
	
	private function traverseChildHandler(child:Access, nodeName:String):Void
	{
	}
	
	private function traverseChildren(element:Access, name:String = null):Void
	{
		if (name != null) {
			var children = element.nodes.resolve("" + name);
			for (child in children)
				traverseChildHandler(child, child.name);
		} else {
			var children = element.elements;
			for (child in children)
				traverseChildHandler(child, child.name);
		}
	}
	
	private function convertMatrix(matrix:Matrix3D):Void
	{
		var indices:Array<Int> = [2, 6, 8, 9, 11, 14];
		var raw:Vector<Float> = matrix.rawData;
		for (i in 0...indices.length)
			raw[indices[i]] *= -1.0;
		
		matrix.rawData = raw;
	}
	
	private function getRootElement(element:Access):Access
	{
		var xml:Xml = element.x;
		while (xml.nodeName != "COLLADA")
			xml = xml.parent;
		
		return (xml.nodeName == "COLLADA" ? new Access(xml) : null);
	}
	
	private function readFloatArray(element:Access):Vector<Float>
	{
		var raw:String = readText(element);
		var parts:Array<String> = ~/\s+/g.split(raw);
		var floats:Vector<Float> = new Vector<Float>();
		
		for (i in 0...parts.length)
			floats.push(Std.parseFloat(parts[i]));
		
		return floats;
	}
	
	private function readIntArray(element:Access):Vector<Int>
	{
		var raw:String = readText(element);
		var parts:Array<String> = ~/\s+/g.split(raw);
		var ints:Vector<Int> = new Vector<Int>();
		
		for (i in 0...parts.length)
			ints.push(Std.parseInt(parts[i]));
		
		return ints;
	}
	
	private function readStringArray(element:Access):Vector<String> {
		var raw:String = readText(element);
		var parts:Array<String> = ~/\s+/g.split(raw);
		var strings:Vector<String> = new Vector<String>();
		
		for (i in 0...parts.length)
			strings.push(parts[i]);
		
		return strings;
	}
	
	private function readIntAttr(element:Access, name:String, defaultValue:Int = 0):Int
	{
		return element.has.resolve(name) ? Std.parseInt(element.att.resolve(name)) : defaultValue;
	}
	
	private function readText(element:Access):String
	{
		return trimString(element.innerData);
	}
	
	private function trimString(s:String):String
	{
		var result:String = ~/^\s+/.replace(s, "");
		result = ~/\s+$/.replace(result, "");
		return result;
	}
}

class DAEImage extends DAEElement
{
	public var init_from:String;
	public var resource:Dynamic;
	
	public function new(element:Access = null):Void
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void {
		super.deserialize(element);
		init_from = readText(element.node.resolve("init_from"));
		resource = null;
	}
}

class DAEParam extends DAEElement
{
	public var type:String;
	
	public function new(element:Access = null):Void
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.type = element.att.type;
	}
}

class DAEAccessor extends DAEElement
{
	public var params:Vector<DAEParam>;
	public var source:String;
	public var stride:Int;
	public var count:Int;
	
	public function new(element:Access = null):Void
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.params = new Vector<DAEParam>();
		this.source = ~/^#/.replace(element.att.source, "");
		this.stride = readIntAttr(element, "stride", 1);
		this.count = readIntAttr(element, "count", 0);
		traverseChildren(element, "param");
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		if (nodeName == "param")
			this.params.push(new DAEParam(child));
	}
}

class DAESource extends DAEElement
{
	public var accessor:DAEAccessor;
	public var type:String;
	public var floats:Vector<Float>;
	public var ints:Vector<Int>;
	public var bools:Vector<Bool>;
	public var strings:Vector<String>;
	
	public function new(element:Access = null):Void
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		traverseChildren(element);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		switch (nodeName) {
			case "float_array":
				this.type = nodeName;
				this.floats = readFloatArray(child);
			case "int_array":
				this.type = nodeName;
				this.ints = readIntArray(child);
			case "bool_array":
				throw new Error("Cannot handle bool_array");
			case "Name_array", "IDREF_array":
				this.type = nodeName;
				this.strings = readStringArray(child);
			case "technique_common":
				this.accessor = new DAEAccessor(child.node.resolve("accessor"));
		}
	}
}

class DAEInput extends DAEElement
{
	public var semantic:String;
	public var source:String;
	public var offset:Int;
	public var set:Int;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		
		this.semantic = element.att.semantic;
		this.source = ~/^#/.replace(element.att.source, "");
		this.offset = readIntAttr(element, "offset");
		this.set = readIntAttr(element, "set");
	}
}

class DAEVertex
{
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var nx:Float;
	public var ny:Float;
	public var nz:Float;
	public var uvx:Float;
	public var uvy:Float;
	public var uvx2:Float;
	public var uvy2:Float;
	public var numTexcoordSets:Int = 0;
	public var index:Int = 0;
	public var daeIndex:Int = 0;
	
	public function new(numTexcoordSets:Int)
	{
		this.numTexcoordSets = numTexcoordSets;
		x = y = z = nx = ny = nz = uvx = uvy = uvx2 = uvy2 = 0;
	}
	
	public var hash(get, null):String;
	
	private function get_hash():String
	{
		var s:String = format(x);
		s += "_" + format(y);
		s += "_" + format(z);
		s += "_" + format(nx);
		s += "_" + format(ny);
		s += "_" + format(nz);
		s += "_" + format(uvx);
		s += "_" + format(uvy);
		s += "_" + format(uvx2);
		s += "_" + format(uvy2);
		return s;
	}
	
	private function format(v:Float, numDecimals:Float = 4):String
	{
		var dp:Float = Math.pow(10., numDecimals);
		return Std.string(Math.round(v * dp) / dp);
	}
}

class DAEFace
{
	public var vertices:Vector<DAEVertex>;
	
	public function new():Void
	{
		this.vertices = new Vector<DAEVertex>();
	}
}

class DAEPrimitive extends DAEElement
{
	public var type:String;
	public var material:String;
	public var count:Int;
	public var vertices:Vector<DAEVertex>;
	private var _inputs:Vector<DAEInput>;
	private var _p:Vector<Int>;
	private var _vcount:Vector<Int>;
	private var _texcoordSets:Vector<Int>;
	
	public function new(element:Access = null)
	{
		super(element);
	}

	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.type = element.name;
		if (element.has.material)  this.material = element.att.material;
		this.count = readIntAttr(element, "count", 0);
		
		_inputs = new Vector<DAEInput>();
		_p = null;
		_vcount = null;
		
		var list = element.nodes.resolve("input");
		
		for (item in list)
			_inputs.push(new DAEInput(item));
		
		if (element.hasNode.resolve("p") && element.nodes.resolve("p").length > 0)
			_p = readIntArray(element.nodes.resolve("p") #if (haxe_ver >= "4.0.0") [0] #else .first() #end);
		
		if (element.hasNode.resolve("vcount") && element.nodes.resolve("vcount").length > 0)
			_vcount = readIntArray(element.nodes.resolve("vcount") #if (haxe_ver >= "4.0.0") [0] #else .first() #end);
	}
	
	public function create(mesh:DAEMesh):Vector<DAEFace>
	{
		if (!prepareInputs(mesh))
			return null;
		
		var faces:Vector<DAEFace> = new Vector<DAEFace>();
		var input:DAEInput;
		var source:DAESource;
		//var numInputs : uint = _inputs.length;  //shared inputs offsets VERTEX and TEXCOORD
		var numInputs:Int = 0;
		if (_inputs.length > 1) {
			var offsets:Array<Bool> = [];
			for (daei in _inputs) {
				if (!offsets[daei.offset]) {
					offsets[daei.offset] = true;
					numInputs++;
				}
			}
		} else
			numInputs = _inputs.length;
		
		var idx:Int = 0, index:Int;
		var i:Int, j:Int;
		var vertexDict:Map<String, DAEVertex> = new Map<String, DAEVertex>();
		var idx32:Int;
		this.vertices = new Vector<DAEVertex>();
		
		while (idx < _p.length) {
			var vcount:Int = _vcount != null? _vcount.shift() : 3;
			var face:DAEFace = new DAEFace();
			
			for (i in 0...vcount) {
				var t:Int = i*numInputs;
				var vertex:DAEVertex = new DAEVertex(_texcoordSets.length);
				
				for (j in 0..._inputs.length) {
					input = _inputs[j];
					index = _p[idx + t + input.offset];
					source = mesh.sources[input.source];
					idx32 = index*source.accessor.params.length;
					
					switch (input.semantic) {
						case "VERTEX":
							vertex.x = source.floats[idx32 + 0];
							vertex.y = source.floats[idx32 + 1];
							if (DAEElement.USE_LEFT_HANDED)
								vertex.z = -source.floats[idx32 + 2];
							else
								vertex.z = source.floats[idx32 + 2];
							vertex.daeIndex = index;
						case "NORMAL":
							vertex.nx = source.floats[idx32 + 0];
							vertex.ny = source.floats[idx32 + 1];
							if (DAEElement.USE_LEFT_HANDED)
								vertex.nz = -source.floats[idx32 + 2];
							else
								vertex.nz = source.floats[idx32 + 2];
						case "TEXCOORD":
							if (input.set == _texcoordSets[0]) {
								vertex.uvx = source.floats[idx32 + 0];
								vertex.uvy = source.floats[idx32 + 1];
							} else {
								vertex.uvx2 = source.floats[idx32 + 0];
								vertex.uvy2 = source.floats[idx32 + 1];
							}
						default:
					}
				}
				var hash:String = vertex.hash;
				
				if (vertexDict.exists(hash))
					face.vertices.push(vertexDict.get(hash));
				else {
					vertex.index = this.vertices.length;
					vertexDict[hash] = vertex;
					face.vertices.push(vertex);
					this.vertices.push(vertex);
				}
			}
			
			if (face.vertices.length > 3) {
				// triangulate
				var v0:DAEVertex = face.vertices[0];
				for (k in 1...face.vertices.length - 1) {
					var f:DAEFace = new DAEFace();
					f.vertices.push(v0);
					f.vertices.push(face.vertices[k]);
					f.vertices.push(face.vertices[k + 1]);
					faces.push(f);
				}
				
			} else if (face.vertices.length == 3)
				faces.push(face);
			idx += (vcount*numInputs);
		}
		return faces;
	}
	
	private function prepareInputs(mesh:DAEMesh):Bool
	{
		var input:DAEInput;
		var i:UInt, j:UInt;
		var result:Bool = true;
		_texcoordSets = new Vector<Int>();
		
		for (i in 0..._inputs.length) {
			input = _inputs[i];
			
			if (input.semantic == "TEXCOORD")
				_texcoordSets.push(input.set);
			
			if (!mesh.sources.exists(input.source)) {
				result = false;
				if (input.source == mesh.vertices.id) {
					for (j in 0...mesh.vertices.inputs.length) {
						if (mesh.vertices.inputs[j].semantic == "POSITION") {
							input.source = mesh.vertices.inputs[j].source;
							result = true;
							break;
						}
					}
				}
			}
		}
		
		return result;
	}
}

class DAEVertices extends DAEElement
{
	public var mesh:DAEMesh;
	public var inputs:Vector<DAEInput>;
	
	public function new(mesh:DAEMesh, element:Access = null)
	{
		this.mesh = mesh;
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.inputs = new Vector<DAEInput>();
		traverseChildren(element, "input");
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		this.inputs.push(new DAEInput(child));
	}
}

class DAEGeometry extends DAEElement
{
	public var mesh:DAEMesh;
	public var meshName:String = "";
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		traverseChildren(element);
		meshName = element.att.hasField("name") ? element.att.resolve("name") : element.att.resolve("id");
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		if (nodeName == "mesh")
			this.mesh = new DAEMesh(this, child); //case "spline"//case "convex_mesh":
	}
}

class DAEMesh extends DAEElement
{
	public var geometry:DAEGeometry;
	public var sources:Map<String, DAESource>;
	public var vertices:DAEVertices;
	public var primitives:Vector<DAEPrimitive>;
	
	public function new(geometry:DAEGeometry, element:Access = null)
	{
		this.geometry = geometry;
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.sources = new Map<String, DAESource>();
		this.vertices = null;
		this.primitives = new Vector<DAEPrimitive>();
		traverseChildren(element);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		switch (nodeName) {
			case "source":
				var source:DAESource = new DAESource(child);
				this.sources[source.id] = source;
			case "vertices":
				this.vertices = new DAEVertices(this, child);
			case "triangles", "polylist", "polygon":
				this.primitives.push(new DAEPrimitive(child));
		}
	}
}

class DAEBindMaterial extends DAEElement
{
	public var instance_material:Vector<DAEInstanceMaterial>;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.instance_material = new Vector<DAEInstanceMaterial>();
		traverseChildren(element);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		if (nodeName == "technique_common") {
			for (element in child.elements)
				this.instance_material.push(new DAEInstanceMaterial(element));
		}
	}
}

class DAEBindVertexInput extends DAEElement
{
	public var semantic:String;
	public var input_semantic:String;
	public var input_set:Int;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.semantic = element.att.semantic;
		this.input_semantic = element.att.input_semantic;
		this.input_set = readIntAttr(element, "input_set");
	}
}

class DAEInstance extends DAEElement
{
	public var url:String;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.url = ~/^#/.replace(element.has.url ? element.att.url : "", "");
	}
}

class DAEInstanceController extends DAEInstance
{
	public var bind_material:DAEBindMaterial;
	public var skeleton:Vector<String>;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.bind_material = null;
		this.skeleton = new Vector<String>();
		traverseChildren(element);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		switch (nodeName) {
			case "skeleton":
				this.skeleton.push(~/^#/.replace(readText(child), ""));
			case "bind_material":
				this.bind_material = new DAEBindMaterial(child);
		}
	}
}

class DAEInstanceEffect extends DAEInstance
{
	public function new(element:Access = null)
	{
		super(element);
	}
}

class DAEInstanceGeometry extends DAEInstance
{
	public var bind_material:DAEBindMaterial;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.bind_material = null;
		traverseChildren(element);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		if (nodeName == "bind_material")
			this.bind_material = new DAEBindMaterial(child);
	}
}

class DAEInstanceMaterial extends DAEInstance
{
	public var target:String;
	public var symbol:String;
	public var bind_vertex_input:Vector<DAEBindVertexInput>;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.target = ~/^#/.replace(element.att.target, "");
		this.symbol = element.att.symbol;
		this.bind_vertex_input = new Vector<DAEBindVertexInput>();
		traverseChildren(element);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		if (nodeName == "bind_vertex_input")
			this.bind_vertex_input.push(new DAEBindVertexInput(child));
	}
}

class DAEInstanceNode extends DAEInstance
{
	public function new(element:Access = null)
	{
		super(element);
	}
}

class DAEInstanceVisualScene extends DAEInstance
{
	public function new(element:Access = null)
	{
		super(element);
	}
}

class DAEColor
{
	public var r:Float;
	public var g:Float;
	public var b:Float;
	public var a:Float;
	
	public function new()
	{
	}
	
	public var rgb(get, null):UInt;
	
	private function get_rgb():UInt
	{
		return Std.int(r * 255.0) << 16 | Std.int(g * 255.0) << 8 | Std.int(b * 255.0);
	}
	
	public var rgba(get, null):UInt;
	
	private function get_rgba():UInt
	{
		return (Std.int(a * 255.0) << 24 | Std.int(r * 255.0) << 16 | Std.int(g * 255.0) << 8 | Std.int(b * 255.0));
	}
}

class DAETexture
{
	public var texture:String;
	public var texcoord:String;
	
	public function new()
	{
	}
}

class DAEColorOrTexture extends DAEElement
{
	public var color:DAEColor;
	public var texture:DAETexture;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.color = null;
		this.texture = null;
		traverseChildren(element);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		switch (nodeName) {
			case "color":
				var values:Vector<Float> = readFloatArray(child);
				this.color = new DAEColor();
				this.color.r = values[0];
				this.color.g = values[1];
				this.color.b = values[2];
				this.color.a = values.length > 3? values[3] : 1.0;
			
			case "texture":
				this.texture = new DAETexture();
				if (child.has.texcoord) this.texture.texcoord = child.att.texcoord;
				this.texture.texture = child.att.texture;
			
			default:
		}
	}
}

class DAESurface extends DAEElement
{
	public var type:String;
	public var init_from:String;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.type = element.att.type;
		this.init_from = readText(element.node.resolve("init_from"));
	}
}

class DAESampler2D extends DAEElement
{
	public var source:String;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.source = readText(element.node.resolve("source"));
	}
}

class DAEShader extends DAEElement
{
	public var type:String;
	public var props:Dynamic;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.type = element.name;
		this.props = {};
		traverseChildren(element);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		switch (nodeName) {
			case "ambient", "diffuse", "specular", "emission", "transparent", "reflective":
				this.props.setField(nodeName, new DAEColorOrTexture(child));
			
			case "shininess", "reflectivity", "transparency", "index_of_refraction":
				this.props.setField(nodeName, Std.parseFloat(readText(child.node.resolve("float"))));
			
			default:
				Debug.trace("[WARNING] unhandled DAEShader property: " + nodeName);
		}
	}
}

class DAEEffect extends DAEElement
{
	public var shader:DAEShader;
	public var surface:DAESurface;
	public var sampler:DAESampler2D;
	public var material:Dynamic;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.shader = null;
		this.surface = null;
		this.sampler = null;
		traverseChildren(element);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		if (nodeName == "profile_COMMON")
			deserializeProfile(child);
	}
	
	private function deserializeProfile(element:Access):Void
	{
		var children = element.elements;
		
		for (child in children) {
			var name:String = child.name;
			
			switch (name) {
				case "technique":
					deserializeShader(child);
				case "newparam":
					deserializeNewParam(child);
			}
		}
	}
	
	private function deserializeNewParam(element:Access):Void
	{
		var children = element.elements;
		
		for (child in children) {
			var name:String = child.name;
			
			switch (name) {
				case "surface":
					this.surface = new DAESurface(child);
					this.surface.sid = element.att.sid;
				case "sampler2D":
					this.sampler = new DAESampler2D(child);
					this.sampler.sid = element.att.sid;
				default:
					Debug.trace("[WARNING] unhandled newparam: " + name);
			}
		}
	}
	
	private function deserializeShader(technique:Access):Void
	{
		var children = technique.elements;
		this.shader = null;
		
		for (child in children) {
			var name:String = child.name;
			
			switch (name) {
				case "constant", "lambert", "blinn", "phong":
					this.shader = new DAEShader(child);
			}
		}
	}
}

class DAEMaterial extends DAEElement
{
	public var instance_effect:DAEInstanceEffect;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.instance_effect = null;
		traverseChildren(element);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		if (nodeName == "instance_effect")
			this.instance_effect = new DAEInstanceEffect(child);
	}
}

class DAETransform extends DAEElement
{
	public var type:String;
	public var data:Vector<Float>;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.type = element.name;
		this.data = readFloatArray(element);
	}
	
	public var matrix(get, null):Matrix3D;
	
	private function get_matrix():Matrix3D
	{
		var matrix:Matrix3D = new Matrix3D();
		switch (this.type) {
			case "matrix":
				matrix = new Matrix3D(this.data);
				matrix.transpose();
			case "scale":
				matrix.appendScale(this.data[0], this.data[1], this.data[2]);
			case "translate":
				matrix.appendTranslation(this.data[0], this.data[1], this.data[2]);
			case "rotate":
				var axis:Vector3D = new Vector3D(this.data[0], this.data[1], this.data[2]);
				matrix.appendRotation(this.data[3], axis);
		}
		return matrix;
	}
}

class DAENode extends DAEElement
{
	public var type:String;
	public var parent:DAENode;
	public var parser:DAEParser;
	public var nodes:Vector<DAENode>;
	public var transforms:Vector<DAETransform>;
	public var instance_controllers:Vector<DAEInstanceController>;
	public var instance_geometries:Vector<DAEInstanceGeometry>;
	public var world:Matrix3D;
	public var channels:Vector<DAEChannel>;
	private var _root:Access;
	
	public function new(parser:DAEParser, element:Access = null, parent:DAENode = null)
	{
		this.parser = parser;
		this.parent = parent;
		this.channels = new Vector<DAEChannel>();
		
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		
		_root = getRootElement(element);
		
		this.type = element.has.type ? element.att.type.toString() : "NODE";
		this.nodes = new Vector<DAENode>();
		this.transforms = new Vector<DAETransform>();
		this.instance_controllers = new Vector<DAEInstanceController>();
		this.instance_geometries = new Vector<DAEInstanceGeometry>();
		traverseChildren(element);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		var instances;
		
		switch (nodeName) {
			case "node":
				this.nodes.push(new DAENode(this.parser, child, this));
			

			case "instance_controller":
				var instance = new DAEInstanceController(child);
				this.instance_controllers.push(instance);
			

			case "instance_geometry":
				this.instance_geometries.push(new DAEInstanceGeometry(child));

			
			case "instance_node":
				var instance = new DAEInstanceNode(child);

				instances = #if (haxe_ver >= "4.0.0") new Array<Access>() #else new List<Access>() #end;
				var libList = _root.nodes.resolve("library_nodes");
				for (lib in libList.iterator()) {
					var nodes = lib.nodes.resolve("node");
					for (node in nodes) {
						if (node.att.id == instance.url) {
							instances.push(node);
						}
					}
				}
				if (instances.length > 0)
					this.nodes.push(new DAENode(this.parser, #if (haxe_ver >= "4.0.0") instances[0] #else instances.first() #end, this));
			
			case "matrix", "translate", "scale", "rotate":
				this.transforms.push(new DAETransform(child));
		}
	}
	
	public function getMatrixBySID(sid:String):Matrix3D
	{
		var transform:DAETransform = getTransformBySID(sid);
		if (transform != null)
			return transform.matrix;
		
		return null;
	}
	
	public function getTransformBySID(sid:String):DAETransform
	{
		for (transform in this.transforms)
			if (transform.sid == sid)
				return transform;
		return null;
	}
	
	public function getAnimatedMatrix(time:Float):Matrix3D
	{
		var matrix:Matrix3D = new Matrix3D();
		var tdata:Vector<Float>;
		var odata:Vector<Float>;
		var channelsBySID:Map<String, DAEChannel> = new Map<String, DAEChannel>();
		var transform:DAETransform;
		var channel:DAEChannel;
		var minTime:Float = Math.NEGATIVE_INFINITY;
		var maxTime:Float = -minTime;
		//var frame : int;
		
		for (i in 0...this.channels.length) {
			channel = this.channels[i];
			minTime = Math.min(minTime, channel.sampler.minTime);
			maxTime = Math.max(maxTime, channel.sampler.maxTime);
			channelsBySID.set(channel.targetSid, channel);
		}
		
		for (i in 0...this.transforms.length) {
			transform = this.transforms[i];
			tdata = transform.data;
			if (channelsBySID.exists(transform.sid)) {
				var m:Matrix3D = new Matrix3D();
				//var found : Bool = false;
				var frameData:DAEFrameData = null;
				channel = channelsBySID[transform.sid];
				frameData = channel.sampler.getFrameData(time);
				
				if (frameData != null) {
					odata = frameData.data;
					
					switch (transform.type) {
						case "matrix":
							if (channel.arrayAccess) {
								//m.rawData = tdata;
								//m.transpose();
								if (channel.arrayIndices.length > 1) {
									//	m.rawData[channel.arrayIndices[0] * 4 + channel.arrayIndices[1]] = odata[0];
									//	trace(channel.arrayIndices[0] * 4 + channel.arrayIndices[1])
								}
								
							} else if (channel.dotAccess)
								Debug.trace("unhandled matrix array access");
							
							else if (odata.length == 16) {
								m.rawData = odata;
								m.transpose();
								
							} else
								Debug.trace("unhandled matrix " + transform.sid + " " + odata);
						
						case "rotate":
							if (channel.arrayAccess)
								Debug.trace("unhandled rotate array access");
							
							else if (channel.dotAccess) {
								
								switch (channel.dotAccessor) {
									case "ANGLE":
										m.appendRotation(odata[0], new Vector3D(tdata[0], tdata[1], tdata[2]));
									default:
										Debug.trace("unhandled rotate dot access " + channel.dotAccessor);
								}
								
							} else
								Debug.trace("unhandled rotate");
						
						case "scale":
							if (channel.arrayAccess)
								Debug.trace("unhandled scale array access");
							
							else if (channel.dotAccess) {
								
								switch (channel.dotAccessor) {
									case "X":
										m.appendScale(odata[0], tdata[1], tdata[2]);
									case "Y":
										m.appendScale(tdata[0], odata[0], tdata[2]);
									case "Z":
										m.appendScale(tdata[0], tdata[1], odata[0]);
									default:
										Debug.trace("unhandled scale dot access " + channel.dotAccessor);
								}
								
							} else
								Debug.trace("unhandled scale: " + odata.length);
						
						case "translate":
							if (channel.arrayAccess)
								Debug.trace("unhandled translate array access");
							
							else if (channel.dotAccess) {
								
								switch (channel.dotAccessor) {
									case "X":
										m.appendTranslation(odata[0], tdata[1], tdata[2]);
									case "Y":
										m.appendTranslation(tdata[0], odata[0], tdata[2]);
									case "Z":
										m.appendTranslation(tdata[0], tdata[1], odata[0]);
									default:
										Debug.trace("unhandled translate dot access " + channel.dotAccessor);
								}
								
							} else
								m.appendTranslation(odata[0], odata[1], odata[2]);
						
						default:
							Debug.trace("unhandled transform type " + transform.type);
							continue;
					}
					matrix.prepend(m);
					
				} else
					matrix.prepend(transform.matrix);
				
			} else
				matrix.prepend(transform.matrix);
		}
		
		if (DAEElement.USE_LEFT_HANDED)
			convertMatrix(matrix);
		
		return matrix;
	}
	
	public var matrix(get, null):Matrix3D;
	
	private function get_matrix():Matrix3D
	{
		var matrix:Matrix3D = new Matrix3D();
		for (i in 0...this.transforms.length)
			matrix.prepend(this.transforms[i].matrix);
		
		if (DAEElement.USE_LEFT_HANDED)
			convertMatrix(matrix);
		
		return matrix;
	}
}

class DAEVisualScene extends DAENode
{
	public function new(parser:DAEParser, element:Access = null)
	{
		super(parser, element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
	}
	
	public function findNodeById(id:String, node:DAENode = null):DAENode
	{
		if (node == null)
			node = this;
		
		if (node.id == id)
			return node;
		
		for (i in 0...node.nodes.length) {
			var result:DAENode = findNodeById(id, node.nodes[i]);
			if (result != null)
				return result;
		}
		
		return null;
	}
	
	public function findNodeBySid(sid:String, node:DAENode = null):DAENode
	{
		if (node == null)
			node = this;

		if (node.sid == sid)
			return node;
		
		for (i in 0...node.nodes.length) {
			var result:DAENode = findNodeBySid(sid, node.nodes[i]);
			if (result != null)
				return result;
		}
		
		return null;
	}
	
	public function updateTransforms(node:DAENode, parent:DAENode = null):Void
	{
		node.world = node.matrix.clone();
		if (parent != null && parent.world != null)
			node.world.append(parent.world);
		
		for (i in 0...node.nodes.length)
			updateTransforms(node.nodes[i], node);
	}
}

class DAEScene extends DAEElement
{
	public var instance_visual_scene:DAEInstanceVisualScene;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.instance_visual_scene = null;
		traverseChildren(element);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		if (nodeName == "instance_visual_scene")
			this.instance_visual_scene = new DAEInstanceVisualScene(child);
	}
}

class DAEMorph extends DAEEffect
{
	public var source:String;
	public var method:String;
	public var targets:Vector<String>;
	public var weights:Vector<Float>;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.source = ~/^#/.replace(element.att.source, "");
		this.method = element.att.method;
		this.method = this.method.length != 0 ? this.method : "NORMALIZED";
		this.targets = new Vector<String>();
		this.weights = new Vector<Float>();
		
		var sources:Map<String, DAESource> = new Map<String, DAESource>();
		var source:DAESource;
		var input:DAEInput;
		var list = element.nodes.resolve("" + this.source);
		
		if (element.hasNode.resolve("targets") && element.nodes.resolve("targets").length > 0) {
			for (item in list.iterator()) {
				source = new DAESource(item);
				sources[source.id] = source;
			}
			list = element.node.resolve("targets").nodes.resolve("input");
			for (item in list.iterator()) {
				input = new DAEInput(item);
				source = sources[input.source];
				switch (input.semantic) {
					case "MORPH_TARGET":
						this.targets = source.strings;
					case "MORPH_WEIGHT":
						this.weights = source.floats;
				}
			}
		}
	}
}

class DAEVertexWeight
{
	public var vertex:UInt;
	public var joint:UInt;
	public var weight:Float;
	
	public function new()
	{
	}
}

class DAESkin extends DAEElement
{
	public var source:String;
	public var bind_shape_matrix:Matrix3D;
	public var joints:Vector<String>;
	public var inv_bind_matrix:Vector<Matrix3D>;
	public var weights:Vector<Vector<DAEVertexWeight>>;
	public var jointSourceType:String;
	public var maxBones:UInt;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		
		this.source = ~/^#/.replace(element.att.source, "");
		this.bind_shape_matrix = new Matrix3D();
		this.inv_bind_matrix = new Vector<Matrix3D>();
		this.joints = new Vector<String>();
		this.weights = new Vector<Vector<DAEVertexWeight>>();
		
		var children:Iterator<Access> = element.elements;
		var sources:Map<String, DAESource> = new Map<String, DAESource>();
		
		var sourceList = element.nodes.resolve("source");
		for (item in sourceList.iterator()) {
			var source:DAESource = new DAESource(item);
			sources[source.id] = source;
		}

		for (child in children) {
			var name:String = child.name;
			
			switch (name) {
				case "bind_shape_matrix":
					parseBindShapeMatrix(child);
				case "source":
				case "joints":
					parseJoints(child, sources);
				case "vertex_weights":
					parseVertexWeights(child, sources);
				default:
			}
		}
	}
	
	public function getJointIndex(joint:String):Int
	{
		for (i in 0...this.joints.length) {
			if (this.joints[i] == joint)
				return i;
		}
		return -1;
	}
	
	private function parseBindShapeMatrix(element:Access):Void
	{
		var values:Vector<Float> = readFloatArray(element);
		this.bind_shape_matrix = new Matrix3D(values);
		this.bind_shape_matrix.transpose();
		if (DAEElement.USE_LEFT_HANDED)
			convertMatrix(this.bind_shape_matrix);
	}
	
	private function parseJoints(element:Access, sources:Map<String, DAESource>):Void
	{
		var list = element.nodes.resolve("input");
		var input:DAEInput;
		var source:DAESource;
		
		for (item in list.iterator()) {
			input = new DAEInput(item);
			source = sources[input.source];
			
			switch (input.semantic) {
				case "JOINT":
					this.joints = source.strings;
					this.jointSourceType = source.type;
				case "INV_BIND_MATRIX":
					var j:Int = 0;
					while (j < source.floats.length) {
						var matrix:Matrix3D = new Matrix3D(source.floats.slice(j, j + source.accessor.stride));
						matrix.transpose();
						if (DAEElement.USE_LEFT_HANDED)
							convertMatrix(matrix);
						inv_bind_matrix.push(matrix);

						j += source.accessor.stride;
					}
			}
		}
	}
	
	private function parseVertexWeights(element:Access, sources:Map<String, DAESource>):Void
	{
		var list = element.nodes.resolve("input");
		var input:DAEInput;
		var inputs:Vector<DAEInput> = new Vector<DAEInput>();
		var source:DAESource;
		var i:Int, j:Int, k:Int;
		
		if ((!element.hasNode.resolve("vcount")) || (!element.hasNode.resolve("v")))
			throw new Error("Can't parse vertex weights");
		
		var vcount:Vector<Int> = readIntArray(element.node.resolve("vcount"));
		var v:Vector<Int> = readIntArray(element.node.resolve("v"));
		var numWeights:Int = Std.parseInt(element.att.count);
		var index:Int = 0;
		this.maxBones = 0;
		
		for (item in list.iterator())
			inputs.push(new DAEInput(item));
		
		for (i in 0...vcount.length) {
			var numBones:Int = vcount[i];
			var vertex_weights:Vector<DAEVertexWeight> = new Vector<DAEVertexWeight>();
			
			this.maxBones = Std.int(Math.max(this.maxBones, numBones));
			
			for (j in 0...numBones) {
				var influence:DAEVertexWeight = new DAEVertexWeight();
				
				for (k in 0...inputs.length) {
					input = inputs[k];
					source = sources[input.source];
					
					switch (input.semantic) {
						case "JOINT":
							influence.joint = v[index + input.offset];
						case "WEIGHT":
							influence.weight = source.floats[v[index + input.offset]];
						default:
					}
				}
				influence.vertex = i;
				vertex_weights.push(influence);
				index += inputs.length;
			}
			
			this.weights.push(vertex_weights);
		}
	}
}

class DAEController extends DAEElement
{
	public var skin:DAESkin;
	public var morph:DAEMorph;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.skin = null;
		this.morph = null;
		
		if (element.hasNode.resolve("skin") && element.nodes.resolve("skin").length > 0)
			this.skin = new DAESkin(element.node.resolve("skin"));
		else if (element.hasNode.resolve("morph") && element.nodes.resolve("morph").length > 0)
			this.morph = new DAEMorph(element.node.resolve("morph"));
		else
			throw new Error("DAEController: could not find a <skin> or <morph> element");
	}
}

class DAESampler extends DAEElement
{
	public var input:Vector<Float>;
	public var output:Vector<Vector<Float>>;
	public var dataType:String;
	public var interpolation:Vector<String>;
	public var minTime:Float;
	public var maxTime:Float;
	private var _inputs:Vector<DAEInput>;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		var list = element.nodes.resolve("input");
		_inputs = new Vector<DAEInput>();
		
		for (item in list.iterator())
			_inputs.push(new DAEInput(item));
	}
	
	public function create(sources:Map<String, DAESource>):Void
	{
		var input:DAEInput;
		var source:DAESource;
		var j:Int;
		this.input = new Vector<Float>();
		this.output = new Vector<Vector<Float>>();
		this.interpolation = new Vector<String>();
		this.minTime = 0;
		this.maxTime = 0;
		
		for (i in 0..._inputs.length)
		{
			input = _inputs[i];
			source = sources[input.source];
			
			switch (input.semantic) {
				case "INPUT":
					this.input = source.floats;
					this.minTime = this.input[0];
					this.maxTime = this.input[this.input.length - 1];
				case "OUTPUT":
					j = 0;
					while (j < source.floats.length) {
						this.output.push(source.floats.slice(j, j + source.accessor.stride));
						j += source.accessor.stride;
					}
					this.dataType = source.accessor.params[0].type;
				case "INTEROLATION":
					this.interpolation = source.strings;
			}
		}
	}
	
	public function getFrameData(time:Float):DAEFrameData
	{
		var frameData:DAEFrameData = new DAEFrameData(0, time);
		
		if (this.input == null || this.input.length == 0)
			return null;
		
		var a:Float, b:Float;
		var i:Int;
		frameData.valid = true;
		frameData.time = time;
		
		if (time <= this.input[0]) {
			frameData.frame = 0;
			frameData.dt = 0;
			frameData.data = this.output[0];
			
		} else if (time >= this.input[this.input.length - 1]) {
			frameData.frame = this.input.length - 1;
			frameData.dt = 0;
			frameData.data = this.output[frameData.frame];
			
		} else {
			
			for (i in 0...this.input.length - 1) {
				if (time >= this.input[i] && time < this.input[i + 1]) {
					frameData.frame = i;
					frameData.dt = (time - this.input[i])/(this.input[i + 1] - this.input[i]);
					frameData.data = this.output[i];
					break;
				}
			}
			
			for (i in 0...frameData.data.length) {
				a = this.output[frameData.frame][i];
				b = this.output[frameData.frame + 1][i];
				frameData.data[i] += frameData.dt*(b - a);
			}
		}
		
		return frameData;
	}
}

class DAEFrameData
{
	public var frame:Int;
	public var time:Float;
	public var data:Vector<Float>;
	public var dt:Float;
	public var valid:Bool;
	
	public function new(frame:Int = 0, time:Float = 0.0, dt:Float = 0.0, valid:Bool = false)
	{
		this.frame = frame;
		this.time = time;
		this.dt = dt;
		this.valid = valid;
	}
}

class DAEChannel extends DAEElement
{
	public var source:String;
	public var target:String;
	public var sampler:DAESampler;
	public var targetId:String;
	public var targetSid:String;
	public var arrayAccess:Bool;
	public var dotAccess:Bool;
	public var dotAccessor:String;
	public var arrayIndices:Array<Int>;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		
		this.source = ~/^#/.replace(element.att.source, "");
		this.target = element.att.target.toString();
		this.sampler = null;
		var parts:Array<String> = this.target.split("/");
		this.targetId = parts.shift();
		this.arrayAccess = this.dotAccess = false;
		var tmp:String = parts.shift();
		
		if (tmp.indexOf("(") >= 0) {
			parts = tmp.split("(");
			this.arrayAccess = true;
			this.arrayIndices = [];
			this.targetSid = parts.shift();
			for (i in 0...parts.length) {
				var text:String = StringTools.replace(parts[i], ")", "");
				this.arrayIndices.push(Std.parseInt(text));
			}
			
		} else if (tmp.indexOf(".") >= 0) {
			parts = tmp.split(".");
			this.dotAccess = true;
			this.targetSid = parts[0];
			this.dotAccessor = parts[1];
			
		} else
			this.targetSid = tmp;
	}
}

class DAEAnimation extends DAEElement
{
	public var samplers:Vector<DAESampler>;
	public var channels:Vector<DAEChannel>;
	public var sources:Map<String, DAESource>;
	
	public function new(element:Access = null)
	{
		super(element);
		if (this.id == "")
			this.id = element.node.channel.att.resolve("source");
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		this.samplers = new Vector<DAESampler>();
		this.channels = new Vector<DAEChannel>();
		this.sources = new Map<String, DAESource>();
		traverseChildren(element);
		setupChannels(this.sources);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		switch (nodeName) {
			case "source":
				var source:DAESource = new DAESource(child);
				this.sources[source.id] = source;
			case "sampler":
				this.samplers.push(new DAESampler(child));
			case "channel":
				this.channels.push(new DAEChannel(child));
		}
	}
	
	private function setupChannels(sources:Dynamic):Void
	{
		var channel:DAEChannel;
		for (channel in this.channels) {
			var sampler:DAESampler;
			for (sampler in this.samplers) {
				if (channel.source == sampler.id) {
					sampler.create(sources);
					channel.sampler = sampler;
					break;
				}
			}
		}
	}
}

class DAELightType extends DAEElement
{
	public var color:DAEColor;
	
	public function new(element:Access = null)
	{
		super(element);
	}
	
	override public function deserialize(element:Access):Void
	{
		super.deserialize(element);
		traverseChildren(element);
	}
	
	override private function traverseChildHandler(child:Access, nodeName:String):Void
	{
		if (nodeName == "color") {
			var f:Vector<Float> = readFloatArray(child);
			this.color = new DAEColor();
			color.r = f[0];
			color.g = f[1];
			color.b = f[2];
			color.a = f.length > 3? f[3] : 1.0;
		}
	}
}

enum DAEParserState
{
	LOAD_XML;
	PARSE_IMAGES;
	PARSE_MATERIALS;
	PARSE_GEOMETRIES;
	PARSE_CONTROLLERS;
	PARSE_VISUAL_SCENE;
	PARSE_ANIMATIONS;
	PARSE_COMPLETE;
}
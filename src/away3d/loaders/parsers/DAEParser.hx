package away3d.loaders.parsers;

	import flash.display.BitmapData;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	
	//import away3d.arcane;
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
	
	//use namespace arcane;
	
	/**
	 * DAEParser provides a parser for the DAE data type.
	 */
	class DAEParser extends ParserBase
	{
		public static var CONFIG_USE_GPU:UInt = 1;
		public static var CONFIG_DEFAULT:UInt = CONFIG_USE_GPU;
		public static var PARSE_GEOMETRIES:UInt = 1;
		public static var PARSE_IMAGES:UInt = 2;
		public static var PARSE_MATERIALS:UInt = 4;
		public static var PARSE_VISUAL_SCENES:UInt = 8;
		public static var PARSE_DEFAULT:UInt = PARSE_GEOMETRIES | PARSE_IMAGES | PARSE_MATERIALS | PARSE_VISUAL_SCENES;
		
		var _doc:XML;
		var _ns:Namespace;
		var _parseState:UInt = 0;
		var _imageList:XMLList;
		var _imageCount:UInt;
		var _currentImage:UInt;
		var _dependencyCount:UInt = 0;
		var _configFlags:UInt;
		var _parseFlags:UInt;
		var _libImages:Object;
		var _libMaterials:Object;
		var _libEffects:Object;
		var _libGeometries:Object;
		var _libControllers:Object;
		var _libAnimations:Object;
		var _scene:DAEScene;
		var _root:DAEVisualScene;
		//var _rootContainer : ObjectContainer3D;
		var _geometries:Array<Geometry>;
		var _animationInfo:DAEAnimationInfo;
		//var _animators : Array<IAnimator>;
		var _rootNodes:Array<AnimationNodeBase>;
		var _defaultBitmapMaterial:MaterialBase = DefaultMaterialManager.getDefaultMaterial();
		var _defaultColorMaterial:ColorMaterial = new ColorMaterial(0xff0000);
		var _defaultColorMaterialMulti:ColorMultiPassMaterial = new ColorMultiPassMaterial(0xff0000);
		private static var _numInstances:UInt = 0;
		
		/**
		 * @param    configFlags    Bitfield to configure the parser. 
		 * @see DAEParser.CONFIG_USE_GPU etc.
		 */
		public function new(configFlags:UInt = 0)
		{
			_configFlags = configFlags > 0? configFlags : CONFIG_DEFAULT;
			_parseFlags = PARSE_DEFAULT;
			
			super(ParserDataFormat.PLAIN_TEXT);
		}
		
		public function getGeometryByName(name:String, clone:Bool = false):Geometry
		{
			if (!_geometries)
				return null;
			
			for each (var geometry:Geometry in _geometries) {
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
			if (String(data).indexOf("COLLADA") != -1 || String(data).indexOf("collada") != -1)
				return true;
			
			return false;
		}
		
		
		/**
		 * @inheritDoc
		 */
		override public function resolveDependency(resourceDependency:ResourceDependency):Void
		{
			if (resourceDependency.assets.length != 1)
				return;
			var resource:Texture2DBase = resourceDependency.assets[0] as Texture2DBase;
			_dependencyCount--;
			
			if (resource && BitmapTexture(resource).bitmapData) {
				var image:DAEImage = _libImages[ resourceDependency.id ] as DAEImage;
				
				if (image)
					image.resource = BitmapTexture(resource);
			}
			
			if (_dependencyCount == 0)
				_parseState = DAEParserState.PARSE_MATERIALS;
		}
		
		
		/**
		 * @inheritDoc
		 */
		override public function resolveDependencyFailure(resourceDependency:ResourceDependency):Void
		{
			_dependencyCount--;
			
			if (_dependencyCount == 0)
				_parseState = DAEParserState.PARSE_MATERIALS;
		}
		
		
		/**
		 * @inheritDoc
		 */
		private override function proceedParsing():Bool
		{
			if (!_defaultBitmapMaterial)
				_defaultBitmapMaterial = buildDefaultMaterial();
			
			switch (_parseState) {
				case DAEParserState.LOAD_XML:
					try {
						_doc = new XML(getTextData());
						_ns = _doc.namespace();
						_imageList = _doc._ns::library_images._ns::image;
						_imageCount = _dependencyCount = _imageList.length();
						_currentImage = 0;
						_parseState = _imageCount > 0? DAEParserState.PARSE_IMAGES : DAEParserState.PARSE_MATERIALS;
						
					} catch (e:Error) {
						return PARSING_DONE;
					}
					break;
				
				case DAEParserState.PARSE_IMAGES:
					_libImages = parseLibrary(_doc._ns::library_images._ns::image, DAEImage);
					for (var imageId:String in _libImages) {
						var image:DAEImage = _libImages[imageId] as DAEImage;
						addDependency(image.id, new URLRequest(image.init_from));
					}
					pauseAndRetrieveDependencies();
					break;
				
				case DAEParserState.PARSE_MATERIALS:
					_libMaterials = parseLibrary(_doc._ns::library_materials._ns::material, DAEMaterial);
					_libEffects = parseLibrary(_doc._ns::library_effects._ns::effect, DAEEffect);
					setupMaterials();
					_parseState = DAEParserState.PARSE_GEOMETRIES;
					break;
				
				case DAEParserState.PARSE_GEOMETRIES:
					_libGeometries = parseLibrary(_doc._ns::library_geometries._ns::geometry, DAEGeometry);
					_geometries = translateGeometries();
					_parseState = DAEParserState.PARSE_CONTROLLERS;
					break;
				
				case DAEParserState.PARSE_CONTROLLERS:
					_libControllers = parseLibrary(_doc._ns::library_controllers._ns::controller, DAEController);
					_parseState = DAEParserState.PARSE_VISUAL_SCENE;
					break;
				
				case DAEParserState.PARSE_VISUAL_SCENE:
					_scene = null;
					_root = null;
					_libAnimations = parseLibrary(_doc._ns::library_animations._ns::animation, DAEAnimation);
					//_animators = new Array<IAnimator>();
					_rootNodes = new Array<AnimationNodeBase>();
					
					if (_doc.._ns::scene && _doc.._ns::scene.length()) {
						_scene = new DAEScene(_doc.._ns::scene[0]);
						
						var list:XMLList = _doc.._ns::visual_scene.(@id == _scene.instance_visual_scene.url);
						
						if (list.length()) {
							//_rootContainer = new ObjectContainer3D();
							_root = new DAEVisualScene(this, list[0]);
							_root.updateTransforms(_root);
							_animationInfo = parseAnimationInfo();
							parseSceneGraph(_root);
						}
					}
					_parseState = isAnimated? DAEParserState.PARSE_ANIMATIONS : DAEParserState.PARSE_COMPLETE;
					break;
				
				case DAEParserState.PARSE_ANIMATIONS:
					_parseState = DAEParserState.PARSE_COMPLETE;
					break;
				
				case DAEParserState.PARSE_COMPLETE:
					//finalizeAsset(_rootContainer, "COLLADA_ROOT_" + (_numInstances++));
					return PARSING_DONE;
			}
			
			return MORE_TO_PARSE;
		}
		
		private function buildDefaultMaterial(map:BitmapData = null):MaterialBase
		{
			//TODO:fix this duplication mess
			if (map) {
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
			var i:UInt = 0;
			for each (var sub:CompactSubGeometry in geometry.subGeometries) {
				var vertexData:Array<Float> = sub.vertexData;
				
				// For loop conversion - 								for (i = sub.vertexOffset; i < vertexData.length; i += sub.vertexStride)
				
				for (i in sub.vertexOffset...vertexData.length) {
					vec.x = vertexData[i + 0];
					vec.y = vertexData[i + 1];
					vec.z = vertexData[i + 2];
					vec = skin.bind_shape_matrix.transformVector(vec);
					vertexData[i + 0] = vec.x;
					vertexData[i + 1] = vec.y;
					vertexData[i + 2] = vec.z;
				}
				sub.updateData(vertexData);
			}
		}
		
		private function applySkinController(geometry:Geometry, mesh:DAEMesh, skin:DAESkin, skeleton:Skeleton):Void
		{
			var sub:CompactSubGeometry;
			var skinned_sub_geom:SkinnedSubGeometry;
			var primitive:DAEPrimitive;
			var jointIndices:Array<Float>;
			var jointWeights:Array<Float>;
			var i:UInt, j:UInt, k:UInt, l:Int;
			
			// For loop conversion - 						for (i = 0; i < geometry.subGeometries.length; i++)
			
			for (i in 0...geometry.subGeometries.length) {
				sub = CompactSubGeometry(geometry.subGeometries[i]);
				primitive = mesh.primitives[i];
				jointIndices = new Array<Float>(skin.maxBones*primitive.vertices.length, true);
				jointWeights = new Array<Float>(skin.maxBones*primitive.vertices.length, true);
				l = 0;
				
				// For loop conversion - 								for (j = 0; j < primitive.vertices.length; j++)
				
				for (j in 0...primitive.vertices.length) {
					var weights:Array<DAEVertexWeight> = skin.weights[primitive.vertices[j].daeIndex];
					
					// For loop conversion - 										for (k = 0; k < weights.length; k++)
					
					for (k in 0...weights.length) {
						var influence:DAEVertexWeight = weights[k];
						// indices need to be multiplied by 3 (amount of matrix registers)
						jointIndices[l] = influence.joint*3;
						jointWeights[l++] = influence.weight;
					}
					
					// For loop conversion - 										for (k = weights.length; k < skin.maxBones; k++)
					
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
			info.minTime = Number.MAX_VALUE;
			info.maxTime = -info.minTime;
			info.numFrames = 0;
			
			for each (var animation:DAEAnimation in _libAnimations) {
				for each (var channel:DAEChannel in animation.channels) {
					var node:DAENode = _root.findNodeById(channel.targetId);
					if (node) {
						node.channels.push(channel);
						info.minTime = Math.min(info.minTime, channel.sampler.minTime);
						info.maxTime = Math.max(info.maxTime, channel.sampler.maxTime);
						info.numFrames = Math.max(info.numFrames, channel.sampler.input.length);
					}
				}
			}
			
			return info;
		}
		
		private function parseLibrary(list:XMLList, clas):Object
		{
			var library:Object = {};
			// For loop conversion - 			for (var i:UInt = 0; i < list.length(); i++)
			var i:UInt = 0;
			for (i in 0...list.length()) {
				var obj:Dynamic = new clas(list[i]);
				library[ obj.id ] = obj;
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
					
					if (parent)
						parent.addChild(container);
				}
				
				parent = container;
			}
			// For loop conversion - 			for (var i:UInt = 0; i < node.nodes.length; i++)
			var i:UInt = 0;
			for (i in 0...node.nodes.length)
				parseSceneGraph(node.nodes[i], parent, _tab);
		}
		
		private function processController(controller:DAEController, instance:DAEInstanceController):Geometry
		{
			var geometry:Geometry;
			if (!controller)
				return null;
			
			if (controller.morph)
				geometry = processControllerMorph(controller, instance);
			else if (controller.skin)
				geometry = processControllerSkin(controller, instance);
			
			return geometry;
		}
		
		private function processControllerMorph(controller:DAEController, instance:DAEInstanceController):Geometry
		{
			Debug.trace(" * processControllerMorph : " + controller);
			
			var morph:DAEMorph = controller.morph;
			
			var base:Geometry = processController(_libControllers[morph.source], instance);
			if (!base)
				return null;
			
			var targets:Array<Geometry> = new Array<Geometry>();
			base = getGeometryByName(morph.source);
			var vertexData:Array<Float>;
			var sub:CompactSubGeometry;
			var startWeight:Float = 1.0;
			var i:UInt, j:UInt, k:UInt;
			var geometry:Geometry;
			
			// For loop conversion - 						for (i = 0; i < morph.targets.length; i++)
			
			for (i in 0...morph.targets.length) {
				geometry = getGeometryByName(morph.targets[i]);
				if (!geometry)
					return null;
				
				targets.push(geometry);
				startWeight -= morph.weights[i];
			}
			
			// For loop conversion - 						for (i = 0; i < base.subGeometries.length; i++)
			
			for (i in 0...base.subGeometries.length) {
				sub = CompactSubGeometry(base.subGeometries[i]);
				vertexData = Lambda.array(sub.vertexData);
				// For loop conversion - 				for (var v:Int = 0; v < vertexData.length/13; v++)
				var v:Int;
				for (v in 0...vertexData.length/13) {
					j = sub.vertexOffset + v*sub.vertexStride;
					vertexData[j] = morph.method == "NORMALIZED"? startWeight*sub.vertexData[j] : sub.vertexData[j];
					// For loop conversion - 					for (k = 0; k < morph.targets.length; k++)
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
			
			if (!geometry)
				geometry = processController(_libControllers[controller.skin.source], instance);
			
			if (!geometry)
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
			
			var instance:DAEInstanceController;
			var daeGeometry:DAEGeometry;
			var controller:DAEController;
			var effects:Array<DAEEffect>;
			var geometry:Geometry;
			var mesh:Mesh;
			var skeleton:Skeleton;
			var clip:SkeletonClipNode;
			//var anim:SkeletonAnimation;
			var animationSet:SkeletonAnimationSet;
			var i:UInt, j:UInt;
			var hasMaterial:Bool;
			var weights:UInt;
			var jpv:UInt;
			
			// For loop conversion - 						for (i = 0; i < node.instance_controllers.length; i++)
			
			for (i in 0...node.instance_controllers.length) {
				instance = node.instance_controllers[i];
				controller = _libControllers[instance.url] as DAEController;
				
				geometry = processController(controller, instance);
				if (!geometry)
					continue;
				
				daeGeometry = _libGeometries[geometry.name] as DAEGeometry;
				effects = getMeshEffects(instance.bind_material, daeGeometry.mesh);
				
				mesh = new Mesh(geometry, null);
				hasMaterial = false;
				
				if (node.name != "")
					mesh.name = node.name;
				
				if (effects.length > 0) {
					// For loop conversion - 					for (j = 0; j < mesh.subMeshes.length; j++)
					for (j in 0...mesh.subMeshes.length) {
						if (effects[j].material) {
							mesh.subMeshes[j].material = effects[j].material;
							hasMaterial = true;
						}
					}
				}
				
				if (!hasMaterial)
					mesh.material = _defaultBitmapMaterial;
				
				if (container)
					container.addChild(mesh);
				
				if (controller.skin && controller.skin.userData is Skeleton) {
					
					if (!animationSet)
						animationSet = new SkeletonAnimationSet(controller.skin.maxBones);
					
					skeleton = controller.skin.userData as Skeleton;
					
					clip = processSkinAnimation(controller.skin, mesh, skeleton);
					clip.looping = true;
					
					weights = SkinnedSubGeometry(mesh.geometry.subGeometries[0]).jointIndexData.length;
					jpv = weights/(mesh.geometry.subGeometries[0].vertexData.length/3);
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
			
			if (animationSet)
				finalizeAsset(animationSet);
			
			return mesh;
		}
		
		private function processSkinAnimation(skin:DAESkin, mesh:Mesh, skeleton:Skeleton):SkeletonClipNode
		{
			Debug.trace(" * processSkinAnimation : " + mesh.name);
			
			//var useGPU : Bool = _configFlags & CONFIG_USE_GPU ? true : false;
			//var animation : SkeletonAnimation = new SkeletonAnimation(skeleton, skin.maxBones, useGPU);
			var animated:Bool = isAnimatedSkeleton(skeleton);
			var duration:Float = _animationInfo.numFrames == 0? 1.0 : _animationInfo.maxTime - _animationInfo.minTime;
			var numFrames:Int = Math.max(_animationInfo.numFrames, (animated? 50 : 2));
			var frameDuration:Float = duration/numFrames;
			
			var t:Float = 0;
			var i:UInt, j:UInt;
			var clip:SkeletonClipNode = new SkeletonClipNode();
			//mesh.geometry.animation = animation;
			var skeletonPose:SkeletonPose;
			var identity:Matrix3D;
			var matrix:Matrix3D;
			var node:DAENode;
			var pose:JointPose;
			
			// For loop conversion - 						for (i = 0; i < numFrames; i++)
			
			for (i in 0...numFrames) {
				skeletonPose = new SkeletonPose();
				
				// For loop conversion - 								for (j = 0; j < skin.joints.length; j++)
				
				for (j in 0...skin.joints.length) {
					node = _root.findNodeById(skin.joints[j]) || _root.findNodeBySid(skin.joints[j]);
					pose = new JointPose();
					matrix = node.getAnimatedMatrix(t) || node.matrix;
					pose.name = skin.joints[j];
					pose.orientation.fromMatrix(matrix);
					pose.translation.copyFrom(matrix.position);
					
					if (isNaN(pose.orientation.x)) {
						if (!identity)
							identity = new Matrix3D();
						pose.orientation.fromMatrix(identity);
					}
					
					skeletonPose.jointPoses.push(pose);
				}
				
				t += frameDuration;
				clip.addFrame(skeletonPose, frameDuration*1000);
			}
			
			finalizeAsset(clip);
			
			return clip;
		}
		
		private function isAnimatedSkeleton(skeleton:Skeleton):Bool
		{
			var node:DAENode;
			
			// For loop conversion - 						for (var i:UInt = 0; i < skeleton.joints.length; i++)
			
			var i:UInt = 0;
			
			for (i in 0...skeleton.joints.length) {
				try {
					node = _root.findNodeById(skeleton.joints[i].name) || _root.findNodeBySid(skeleton.joints[i].name);
				} catch (e:Error) {
					trace("Errors found in skeleton joints data");
					return false;
				}
				if (node && node.channels.length)
					return true;
			}
			
			return false;
		}
		
		private function processGeometries(node:DAENode, container:ObjectContainer3D):Mesh
		{
			Debug.trace(" * processGeometries : " + node.name);
			var instance:DAEInstanceGeometry;
			var daeGeometry:DAEGeometry;
			var effects:Array<DAEEffect>;
			var mesh:Mesh;
			var geometry:Geometry;
			var i:UInt, j:UInt;
			
			// For loop conversion - 						for (i = 0; i < node.instance_geometries.length; i++)
			
			for (i in 0...node.instance_geometries.length) {
				instance = node.instance_geometries[i];
				daeGeometry = _libGeometries[instance.url] as DAEGeometry;
				
				if (daeGeometry && daeGeometry.mesh) {
					geometry = getGeometryByName(instance.url);
					effects = getMeshEffects(instance.bind_material, daeGeometry.mesh);
					
					if (geometry) {
						mesh = new Mesh(geometry);
						
						if (node.name != "")
							mesh.name = node.name;
						
						if (effects.length == geometry.subGeometries.length) {
							// For loop conversion - 							for (j = 0; j < mesh.subMeshes.length; j++)
							for (j in 0...mesh.subMeshes.length)
								mesh.subMeshes[j].material = effects[j].material;
						}
						mesh.transform = node.matrix;
						
						if (container)
							container.addChild(mesh);
						
						finalizeAsset(mesh);
					}
				}
			}
			
			return mesh;
		}
		
		private function getMeshEffects(bindMaterial:DAEBindMaterial, mesh:DAEMesh):Array<DAEEffect>
		{
			var effects:Array<DAEEffect> = new Array<DAEEffect>();
			if (!bindMaterial)
				return effects;
			
			var material:DAEMaterial;
			var effect:DAEEffect;
			var instance:DAEInstanceMaterial;
			var i:UInt, j:UInt;
			
			// For loop conversion - 						for (i = 0; i < mesh.primitives.length; i++)
			
			for (i in 0...mesh.primitives.length) {
				if (!bindMaterial.instance_material)
					continue;
				// For loop conversion - 				for (j = 0; j < bindMaterial.instance_material.length; j++)
				for (j in 0...bindMaterial.instance_material.length) {
					instance = bindMaterial.instance_material[j];
					if (mesh.primitives[i].material == instance.symbol) {
						material = _libMaterials[instance.target] as DAEMaterial;
						effect = _libEffects[material.instance_effect.url];
						if (effect)
							effects.push(effect);
						break;
					}
				}
			}
			
			return effects;
		}
		
		private function parseSkeleton(instance_controller:DAEInstanceController):Skeleton
		{
			if (!instance_controller.skeleton.length)
				return null;
			
			Debug.trace(" * parseSkeleton : " + instance_controller);
			
			var controller:DAEController = _libControllers[instance_controller.url] as DAEController;
			var skeletonId:String = instance_controller.skeleton[0];
			var skeletonRoot:DAENode = _root.findNodeById(skeletonId) || _root.findNodeBySid(skeletonId);
			
			if (!skeletonRoot)
				return null;
			
			var skeleton:Skeleton = new Skeleton();
			skeleton.joints = new Array<SkeletonJoint>(controller.skin.joints.length, true);
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
				
				if (!isNaN(jointIndex) && jointIndex < skin.joints.length) {
					if (skin.joints[jointIndex])
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
			
			// For loop conversion - 						for (var i:UInt = 0; i < node.nodes.length; i++)
			
			var i:UInt = 0;
			
			for (i in 0...node.nodes.length) {
				try {
					parseSkeletonHierarchy(node.nodes[i], skin, skeleton, jointIndex);
				} catch (e:Error) {
					trace(e.message);
				}
			}
		}
		
		private function setupMaterial(material:DAEMaterial, effect:DAEEffect):MaterialBase
		{
			if (!effect || !material)
				return null;
			
			var mat:MaterialBase
			if (materialMode < 2)
				mat = _defaultColorMaterial;
			else
				mat = new ColorMultiPassMaterial(_defaultColorMaterial.color);
			
			var textureMaterial:TextureMaterial;
			var ambient:DAEColorOrTexture = effect.shader.props["ambient"];
			var diffuse:DAEColorOrTexture = effect.shader.props["diffuse"];
			var specular:DAEColorOrTexture = effect.shader.props["specular"];
			var shininess:Float = effect.shader.props.hasOwnProperty("shininess")? Number(effect.shader.props["shininess"]) : 10;
			var transparency:Float = effect.shader.props.hasOwnProperty("transparency")? Number(effect.shader.props["transparency"]) : 1;
			
			if (diffuse && diffuse.texture && effect.surface) {
				var image:DAEImage = _libImages[effect.surface.init_from];
				
				if (image.resource !== null && isBitmapDataValid(image.resource.bitmapData)) {
					mat = buildDefaultMaterial(image.resource.bitmapData);
					if (materialMode < 2)
						TextureMaterial(mat).alpha = transparency;
				} else
					mat = buildDefaultMaterial();
				
			}
			
			else if (diffuse && diffuse.color) {
				if (materialMode < 2)
					mat = new ColorMaterial(diffuse.color.rgb, transparency);
				else
					mat = new ColorMultiPassMaterial(diffuse.color.rgb);
			}
			if (mat) {
				if (materialMode < 2) {
					SinglePassMaterialBase(mat).ambientMethod = new BasicAmbientMethod();
					SinglePassMaterialBase(mat).diffuseMethod = new BasicDiffuseMethod();
					SinglePassMaterialBase(mat).specularMethod = new BasicSpecularMethod();
					SinglePassMaterialBase(mat).ambientColor = (ambient && ambient.color)? ambient.color.rgb : 0x303030;
					SinglePassMaterialBase(mat).specularColor = (specular && specular.color)? specular.color.rgb : 0x202020;
					SinglePassMaterialBase(mat).gloss = shininess;
					SinglePassMaterialBase(mat).ambient = 1;
					SinglePassMaterialBase(mat).specular = 1;
				} else {
					MultiPassMaterialBase(mat).ambientMethod = new BasicAmbientMethod();
					MultiPassMaterialBase(mat).diffuseMethod = new BasicDiffuseMethod();
					MultiPassMaterialBase(mat).specularMethod = new BasicSpecularMethod();
					MultiPassMaterialBase(mat).ambientColor = (ambient && ambient.color)? ambient.color.rgb : 0x303030;
					MultiPassMaterialBase(mat).specularColor = (specular && specular.color)? specular.color.rgb : 0x202020;
					MultiPassMaterialBase(mat).gloss = shininess;
					MultiPassMaterialBase(mat).ambient = 1;
					MultiPassMaterialBase(mat).specular = 1;
					
				}
			}
			
			mat.name = material.id;
			finalizeAsset(mat);
			
			return mat;
		}
		
		private function setupMaterials():Void
		{
			for each (var material:DAEMaterial in _libMaterials) {
				if (_libEffects.hasOwnProperty(material.instance_effect.url)) {
					var effect:DAEEffect = _libEffects[material.instance_effect.url] as DAEEffect;
					effect.material = setupMaterial(material, effect);
				}
			}
		}
		
		private function translateGeometries():Array<Geometry>
		{
			var geometries:Array<Geometry> = new Array<Geometry>();
			var daeGeometry:DAEGeometry;
			var geometry:Geometry;
			
			for (var id:String in _libGeometries) {
				daeGeometry = _libGeometries[id] as DAEGeometry;
				if (daeGeometry.mesh) {
					geometry = translateGeometry(daeGeometry.mesh);
					if (geometry.subGeometries.length) {
						if (id && isNaN(Number(id)))
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
			// For loop conversion - 			for (var i:UInt = 0; i < mesh.primitives.length; i++)
			var i:UInt = 0;
			for (i in 0...mesh.primitives.length) {
				var sub:CompactSubGeometry = translatePrimitive(mesh, mesh.primitives[i]);
				if (sub)
					geometry.addSubGeometry(sub);
			}
			
			return geometry;
		}
		
		private function translatePrimitive(mesh:DAEMesh, primitive:DAEPrimitive, reverseTriangles:Bool = true, autoDeriveVertexNormals:Bool = true, autoDeriveVertexTangents:Bool = true):CompactSubGeometry
		{
			var sub:CompactSubGeometry = new CompactSubGeometry();
			var indexData:Array<UInt> = new Array<UInt>();
			var data:Array<Float> = new Array<Float>();
			var faces:Array<DAEFace> = primitive.create(mesh);
			var v:DAEVertex, f:DAEFace;
			var i:UInt, j:UInt;
			
			// vertices, normals and uvs
			// For loop conversion - 			for (i = 0; i < primitive.vertices.length; i++)
			for (i in 0...primitive.vertices.length) {
				v = primitive.vertices[i];
				data.push(v.x, v.y, v.z);
				data.push(v.nx, v.ny, v.nz);
				data.push(0, 0, 0);
				
				if (v.numTexcoordSets > 0) {
					data.push(v.uvx, 1.0 - v.uvy);
					if (v.numTexcoordSets > 1)
						data.push(v.uvx2, 1.0 - v.uvy2);
					else
						data.push(v.uvx, 1.0 - v.uvy);
				} else
					data.push(0, 0, 0, 0);
			}
			
			// triangles
			// For loop conversion - 			for (i = 0; i < faces.length; i++)
			for (i in 0...faces.length) {
				f = faces[i];
				// For loop conversion - 				for (j = 0; j < f.vertices.length; j++)
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
		
		public var geometries(get, null) : Array<Geometry>;
		public function get_geometries() : Array<Geometry>
		{
			return _geometries;
		}
		
		public var effects(get, null) : Object;		
		public function get_effects() : Object
		{
			return _libEffects;
		}
		
		public var images(get, null) : Object;		
		public function get_images() : Object
		{
			return _libImages;
		}
		
		public var materials(get, null) : Object;		
		public function get_materials() : Object
		{
			return _libMaterials;
		}
		
		public var isAnimated(get, null) : Bool;	
		public function get_isAnimated() : Bool
		{
			return (_doc._ns::library_animations._ns::animation.length() > 0);
		}
	
	}
}

import away3d.loaders.parsers.*;

import flash.geom.*;

class DAEAnimationInfo
{
	public var minTime:Float;
	public var maxTime:Float;
	public var numFrames:UInt;
	
	public function DAEAnimationInfo()
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
	var ns:Namespace;
	
	public function DAEElement(element:XML = null)
	{
		if (element)
			deserialize(element);
	}
	
	public function deserialize(element:XML):Void
	{
		ns = element.namespace();
		id = element.@id.toString();
		name = element.@name.toString();
		sid = element.@sid.toString();
	}
	
	public function dispose():Void
	{
	}
	
	private function traverseChildHandler(child:XML, nodeName:String):Void
	{
	}
	
	private function traverseChildren(element:XML, name:String = null):Void
	{
		var children:XMLList = name? element.ns::[name] : element.children();
		var count:Int = children.length();
		
		// For loop conversion - 				for (var i:UInt = 0; i < count; i++)
		
		var i:UInt = 0;
		
		for (i in 0...count)
			traverseChildHandler(children[i], children[i].name().localName);
	}
	
	private function convertMatrix(matrix:Matrix3D):Void
	{
		var indices:Array<Int> = Array<Int>([2, 6, 8, 9, 11, 14]);
		var raw:Array<Float> = matrix.rawData;
		// For loop conversion - 		for (var i:UInt = 0; i < indices.length; i++)
		var i:UInt = 0;
		for (i in 0...indices.length)
			raw[indices[i]] *= -1.0;
		
		matrix.rawData = raw;
	}
	
	private function getRootElement(element:XML):XML
	{
		var tmp:XML = element;
		while (tmp.name().localName != "COLLADA")
			tmp = tmp.parent();
		
		return (tmp.name().localName == "COLLADA"? tmp : null);
	}
	
	private function readFloatArray(element:XML):Array<Float>
	{
		var raw:String = readText(element);
		var parts:Array<Dynamic> = raw.split(/\s+/);
		var floats:Array<Float> = new Array<Float>();
		
		// For loop conversion - 				for (var i:UInt = 0; i < parts.length; i++)
		
		var i:UInt = 0;
		
		for (i in 0...parts.length)
			floats.push(parseFloat(parts[i]));
		
		return floats;
	}
	
	private function readIntArray(element:XML):Array<Int>
	{
		var raw:String = readText(element);
		var parts:Array<Dynamic> = raw.split(/\s+/);
		var ints:Array<Int> = new Array<Int>();
		
		// For loop conversion - 				for (var i:UInt = 0; i < parts.length; i++)
		
		var i:UInt = 0;
		
		for (i in 0...parts.length)
			ints.push(parseInt(parts[i], 10));
		
		return ints;
	}
	
	private function readStringArray(element:XML):Array<String>
	{
		var raw:String = readText(element);
		var parts:Array<Dynamic> = raw.split(/\s+/);
		var strings:Array<String> = new Array<String>();
		
		// For loop conversion - 				for (var i:UInt = 0; i < parts.length; i++)
		
		var i:UInt = 0;
		
		for (i in 0...parts.length)
			strings.push(parts[i]);
		
		return strings;
	}
	
	private function readIntAttr(element:XML, name:String, defaultValue:Int = 0):Int
	{
		var v:Int = parseInt(element.@[name], 10);
		v = v == 0? defaultValue : v;
		return v;
	}
	
	private function readText(element:XML):String
	{
		return trimString(element.text().toString());
	}
	
	private function trimString(s:String):String
	{
		return s.replace(/^\s+/, "").replace(/\s+$/, "");
	}
}

class DAEImage extends DAEElement
{
	public var init_from:String;
	public var resource:Dynamic;
	
	public function DAEImage(element:XML = null):Void
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		init_from = readText(element.ns::init_from[0]);
		resource = null;
	}
}

class DAEParam extends DAEElement
{
	public var type:String;
	
	public function DAEParam(element:XML = null):Void
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.type = element.@type.toString();
	}
}

class DAEAccessor extends DAEElement
{
	public var params:Array<DAEParam>;
	public var source:String;
	public var stride:Int;
	public var count:Int;
	
	public function DAEAccessor(element:XML = null):Void
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.params = new Array<DAEParam>();
		this.source = element.@source.toString().replace(/^#/, "");
		this.stride = readIntAttr(element, "stride", 1);
		this.count = readIntAttr(element, "count", 0);
		traverseChildren(element, "param");
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "param")
			this.params.push(new DAEParam(child));
	}
}

class DAESource extends DAEElement
{
	public var accessor:DAEAccessor;
	public var type:String;
	public var floats:Array<Float>;
	public var ints:Array<Int>;
	public var bools:Array<Bool>;
	public var strings:Array<String>;
	
	public function DAESource(element:XML = null):Void
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		traverseChildren(element);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		switch (nodeName) {
			case "float_array":
				this.type = nodeName;
				this.floats = readFloatArray(child);
				break;
			case "int_array":
				this.type = nodeName;
				this.ints = readIntArray(child);
				break;
			case "bool_array":
				throw new Error("Cannot handle bool_array");
				break;
			case "Name_array":
			case "IDREF_array":
				this.type = nodeName;
				this.strings = readStringArray(child);
				break;
			case "technique_common":
				this.accessor = new DAEAccessor(child.ns::accessor[0]);
		}
	}
}

class DAEInput extends DAEElement
{
	public var semantic:String;
	public var source:String;
	public var offset:Int;
	public var set:Int;
	
	public function DAEInput(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		
		this.semantic = element.@semantic.toString();
		this.source = element.@source.toString().replace(/^#/, "");
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
	public var numTexcoordSets:UInt = 0;
	public var index:UInt = 0;
	public var daeIndex:UInt = 0;
	
	public function DAEVertex(numTexcoordSets:UInt)
	{
		this.numTexcoordSets = numTexcoordSets;
		x = y = z = nx = ny = nz = uvx = uvy = uvx2 = uvy2 = 0;
	}
	
	public var hash(get, null) : String;
	
	public function get_hash() : String
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
	
	private function format(v:Float, numDecimals:Int = 2):String
	{
		return v.toFixed(numDecimals);
	}
}

class DAEFace
{
	public var vertices:Array<DAEVertex>;
	
	public function DAEFace():Void
	{
		this.vertices = new Array<DAEVertex>();
	}
}

class DAEPrimitive extends DAEElement
{
	public var type:String;
	public var material:String;
	public var count:Int;
	public var vertices:Array<DAEVertex>;
	var _inputs:Array<DAEInput>;
	var _p:Array<Int>;
	var _vcount:Array<Int>;
	var _texcoordSets:Array<Int>;
	
	public function DAEPrimitive(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.type = element.name().localName;
		this.material = element.@material.toString();
		this.count = readIntAttr(element, "count", 0);
		
		_inputs = new Array<DAEInput>();
		_p = null;
		_vcount = null;
		
		var list:XMLList = element.ns::input;
		
		// For loop conversion - 				for (var i:UInt = 0; i < list.length(); i++)
		
		var i:UInt = 0;
		
		for (i in 0...list.length())
			_inputs.push(new DAEInput(list[i]));
		
		if (element.ns::p && element.ns::p.length())
			_p = readIntArray(element.ns::p[0]);
		
		if (element.ns::vcount && element.ns::vcount.length())
			_vcount = readIntArray(element.ns::vcount[0]);
	}
	
	public function create(mesh:DAEMesh):Array<DAEFace>
	{
		if (!prepareInputs(mesh))
			return null;
		
		var faces:Array<DAEFace> = new Array<DAEFace>();
		var input:DAEInput;
		var source:DAESource;
		//var numInputs : UInt = _inputs.length;  //shared inputs offsets VERTEX and TEXCOORD
		var numInputs:UInt;
		if (_inputs.length > 1) {
			var offsets:Array<Dynamic> = [];
			for each (var daei:DAEInput in _inputs) {
				if (!offsets[daei.offset]) {
					offsets[daei.offset] = true;
					numInputs++;
				}
			}
		} else
			numInputs = _inputs.length;
		
		var idx:UInt = 0, index:UInt;
		var i:UInt, j:UInt;
		var vertexDict:Object = {};
		var idx32:UInt;
		this.vertices = new Array<DAEVertex>();
		
		while (idx < _p.length) {
			var vcount:UInt = _vcount != null? _vcount.shift() : 3;
			var face:DAEFace = new DAEFace();
			
			// For loop conversion - 						for (i = 0; i < vcount; i++)
			
			for (i in 0...vcount) {
				var t:UInt = i*numInputs;
				var vertex:DAEVertex = new DAEVertex(_texcoordSets.length);
				
				// For loop conversion - 								for (j = 0; j < _inputs.length; j++)
				
				for (j in 0..._inputs.length) {
					input = _inputs[j];
					index = _p[idx + t + input.offset];
					source = mesh.sources[input.source] as DAESource;
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
							break;
						case "NORMAL":
							vertex.nx = source.floats[idx32 + 0];
							vertex.ny = source.floats[idx32 + 1];
							if (DAEElement.USE_LEFT_HANDED)
								vertex.nz = -source.floats[idx32 + 2];
							else
								vertex.nz = source.floats[idx32 + 2];
							break;
						case "TEXCOORD":
							if (input.set == _texcoordSets[0]) {
								vertex.uvx = source.floats[idx32 + 0];
								vertex.uvy = source.floats[idx32 + 1];
							} else {
								vertex.uvx2 = source.floats[idx32 + 0];
								vertex.uvy2 = source.floats[idx32 + 1];
							}
							break;
						default:
							break;
					}
				}
				var hash:String = vertex.hash;
				
				if (vertexDict[hash])
					face.vertices.push(vertexDict[hash]);
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
				// For loop conversion - 				for (var k:UInt = 1; k < face.vertices.length - 1; k++)
				var k:UInt;
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
		_texcoordSets = new Array<Int>();
		
		// For loop conversion - 				for (i = 0; i < _inputs.length; i++)
		
		for (i in 0..._inputs.length) {
			input = _inputs[i];
			
			if (input.semantic == "TEXCOORD")
				_texcoordSets.push(input.set);
			
			if (!mesh.sources[input.source]) {
				result = false;
				if (input.source == mesh.vertices.id) {
					// For loop conversion - 					for (j = 0; j < mesh.vertices.inputs.length; j++)
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
	public var inputs:Array<DAEInput>;
	
	public function DAEVertices(mesh:DAEMesh, element:XML = null)
	{
		this.mesh = mesh;
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.inputs = new Array<DAEInput>();
		traverseChildren(element, "input");
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		nodeName = nodeName;
		this.inputs.push(new DAEInput(child));
	}
}

class DAEGeometry extends DAEElement
{
	public var mesh:DAEMesh;
	public var meshName:String = "";
	
	public function DAEGeometry(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		traverseChildren(element);
		meshName = element.attribute("name");
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "mesh")
			this.mesh = new DAEMesh(this, child); //case "spline"//case "convex_mesh":
	}
}

class DAEMesh extends DAEElement
{
	public var geometry:DAEGeometry;
	public var sources:Object;
	public var vertices:DAEVertices;
	public var primitives:Array<DAEPrimitive>;
	
	public function DAEMesh(geometry:DAEGeometry, element:XML = null)
	{
		this.geometry = geometry;
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.sources = {};
		this.vertices = null;
		this.primitives = new Array<DAEPrimitive>();
		traverseChildren(element);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		switch (nodeName) {
			case "source":
				var source:DAESource = new DAESource(child);
				this.sources[source.id] = source;
				break;
			case "vertices":
				this.vertices = new DAEVertices(this, child);
				break;
			case "triangles":
			case "polylist":
			case "polygon":
				this.primitives.push(new DAEPrimitive(child));
		}
	}
}

class DAEBindMaterial extends DAEElement
{
	public var instance_material:Array<DAEInstanceMaterial>;
	
	public function DAEBindMaterial(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.instance_material = new Array<DAEInstanceMaterial>();
		traverseChildren(element);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "technique_common") {
			// For loop conversion - 			for (var i:UInt = 0; i < child.children().length(); i++)
			var i:UInt = 0;
			for (i in 0...child.children().length())
				this.instance_material.push(new DAEInstanceMaterial(child.children()[i]));
		}
	}
}

class DAEBindVertexInput extends DAEElement
{
	public var semantic:String;
	public var input_semantic:String;
	public var input_set:Int;
	
	public function DAEBindVertexInput(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.semantic = element.@semantic.toString();
		this.input_semantic = element.@input_semantic.toString();
		this.input_set = readIntAttr(element, "input_set");
	}
}

class DAEInstance extends DAEElement
{
	public var url:String;
	
	public function DAEInstance(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.url = element.@url.toString().replace(/^#/, "");
	}
}

class DAEInstanceController extends DAEInstance
{
	public var bind_material:DAEBindMaterial;
	public var skeleton:Array<String>;
	
	public function DAEInstanceController(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.bind_material = null;
		this.skeleton = new Array<String>();
		traverseChildren(element);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		switch (nodeName) {
			case "skeleton":
				this.skeleton.push(readText(child).replace(/^#/, ""));
				break;
			case "bind_material":
				this.bind_material = new DAEBindMaterial(child);
		}
	}
}

class DAEInstanceEffect extends DAEInstance
{
	public function DAEInstanceEffect(element:XML = null)
	{
		super(element);
	}
}

class DAEInstanceGeometry extends DAEInstance
{
	public var bind_material:DAEBindMaterial;
	
	public function DAEInstanceGeometry(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.bind_material = null;
		traverseChildren(element);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "bind_material")
			this.bind_material = new DAEBindMaterial(child);
	}
}

class DAEInstanceMaterial extends DAEInstance
{
	public var target:String;
	public var symbol:String;
	public var bind_vertex_input:Array<DAEBindVertexInput>;
	
	public function DAEInstanceMaterial(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.target = element.@target.toString().replace(/^#/, "");
		this.symbol = element.@symbol.toString();
		this.bind_vertex_input = new Array<DAEBindVertexInput>();
		traverseChildren(element);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "bind_vertex_input")
			this.bind_vertex_input.push(new DAEBindVertexInput(child));
	}
}

class DAEInstanceNode extends DAEInstance
{
	public function DAEInstanceNode(element:XML = null)
	{
		super(element);
	}
}

class DAEInstanceVisualScene extends DAEInstance
{
	public function DAEInstanceVisualScene(element:XML = null)
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
	
	public function DAEColor()
	{
	}
	
	public var rgb(get, null) : UInt;
	
	public function get_rgb() : UInt
	{
		var c:UInt = 0;
		c |= int(r*255.0) << 16;
		c |= int(g*255.0) << 8;
		c |= int(b*255.0);
		
		return c;
	}
	
	public var rgba(get, null) : UInt;
	
	public function get_rgba() : UInt
	{
		return (int(a*255.0) << 24 | this.rgb);
	}
}

class DAETexture
{
	public var texture:String;
	public var texcoord:String;
	
	public function DAETexture()
	{
	}
}

class DAEColorOrTexture extends DAEElement
{
	public var color:DAEColor;
	public var texture:DAETexture;
	
	public function DAEColorOrTexture(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.color = null;
		this.texture = null;
		traverseChildren(element);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		switch (nodeName) {
			case "color":
				var values:Array<Float> = readFloatArray(child);
				this.color = new DAEColor();
				this.color.r = values[0];
				this.color.g = values[1];
				this.color.b = values[2];
				this.color.a = values.length > 3? values[3] : 1.0;
				break;
			
			case "texture":
				this.texture = new DAETexture();
				this.texture.texcoord = child.@texcoord.toString();
				this.texture.texture = child.@texture.toString();
				break;
			
			default:
				break;
		}
	}
}

class DAESurface extends DAEElement
{
	public var type:String;
	public var init_from:String;
	
	public function DAESurface(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.type = element.@type.toString();
		this.init_from = readText(element.ns::init_from[0]);
	}
}

class DAESampler2D extends DAEElement
{
	public var source:String;
	
	public function DAESampler2D(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.source = readText(element.ns::source[0]);
	}
}

class DAEShader extends DAEElement
{
	public var type:String;
	public var props:Object;
	
	public function DAEShader(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.type = element.name().localName;
		this.props = {};
		traverseChildren(element);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		switch (nodeName) {
			case "ambient":
			case "diffuse":
			case "specular":
			case "emission":
			case "transparent":
			case "reflective":
				this.props[nodeName] = new DAEColorOrTexture(child);
				break;
			case "shininess":
			case "reflectivity":
			case "transparency":
			case "index_of_refraction":
				this.props[nodeName] = parseFloat(readText(child.ns::float[0]));
				break;
			default:
				trace("[WARNING] unhandled DAEShader property: " + nodeName);
		}
	}
}

class DAEEffect extends DAEElement
{
	public var shader:DAEShader;
	public var surface:DAESurface;
	public var sampler:DAESampler2D;
	public var material:Dynamic;
	
	public function DAEEffect(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.shader = null;
		this.surface = null;
		this.sampler = null;
		traverseChildren(element);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "profile_COMMON")
			deserializeProfile(child);
	}
	
	private function deserializeProfile(element:XML):Void
	{
		var children:XMLList = element.children();
		
		// For loop conversion - 				for (var i:UInt = 0; i < children.length(); i++)
		
		var i:UInt = 0;
		
		for (i in 0...children.length()) {
			var child:XML = children[i];
			var name:String = child.name().localName;
			
			switch (name) {
				case "technique":
					deserializeShader(child);
					break;
				case "newparam":
					deserializeNewParam(child);
			}
		}
	}
	
	private function deserializeNewParam(element:XML):Void
	{
		var children:XMLList = element.children();
		
		// For loop conversion - 				for (var i:UInt = 0; i < children.length(); i++)
		
		var i:UInt = 0;
		
		for (i in 0...children.length()) {
			var child:XML = children[i];
			var name:String = child.name().localName;
			
			switch (name) {
				case "surface":
					this.surface = new DAESurface(child);
					this.surface.sid = element.@sid.toString();
					break;
				case "sampler2D":
					this.sampler = new DAESampler2D(child);
					this.sampler.sid = element.@sid.toString();
					break;
				default:
					trace("[WARNING] unhandled newparam: " + name);
			}
		}
	}
	
	private function deserializeShader(technique:XML):Void
	{
		var children:XMLList = technique.children();
		this.shader = null;
		
		// For loop conversion - 				for (var i:UInt = 0; i < children.length(); i++)
		
		var i:UInt = 0;
		
		for (i in 0...children.length()) {
			var child:XML = children[i];
			var name:String = child.name().localName;
			
			switch (name) {
				case "constant":
				case "lambert":
				case "blinn":
				case "phong":
					this.shader = new DAEShader(child);
			}
		}
	}
}

class DAEMaterial extends DAEElement
{
	public var instance_effect:DAEInstanceEffect;
	
	public function DAEMaterial(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.instance_effect = null;
		traverseChildren(element);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "instance_effect")
			this.instance_effect = new DAEInstanceEffect(child);
	}
}

class DAETransform extends DAEElement
{
	public var type:String;
	public var data:Array<Float>;
	
	public function DAETransform(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.type = element.name().localName;
		this.data = readFloatArray(element);
	}
	
	public var matrix(get, null) : Matrix3D;
	
	public function get_matrix() : Matrix3D
	{
		var matrix:Matrix3D = new Matrix3D();
		
		switch (this.type) {
			case "matrix":
				matrix = new Matrix3D(this.data);
				matrix.transpose();
				break;
			case "scale":
				matrix.appendScale(this.data[0], this.data[1], this.data[2]);
				break;
			case "translate":
				matrix.appendTranslation(this.data[0], this.data[1], this.data[2]);
				break;
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
	public var nodes:Array<DAENode>;
	public var transforms:Array<DAETransform>;
	public var instance_controllers:Array<DAEInstanceController>;
	public var instance_geometries:Array<DAEInstanceGeometry>;
	public var world:Matrix3D;
	public var channels:Array<DAEChannel>;
	var _root:XML;
	
	public function DAENode(parser:DAEParser, element:XML = null, parent:DAENode = null)
	{
		this.parser = parser;
		this.parent = parent;
		this.channels = new Array<DAEChannel>();
		
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		
		_root = getRootElement(element);
		
		this.type = element.@type.toString().length? element.@type.toString() : "NODE";
		this.nodes = new Array<DAENode>();
		this.transforms = new Array<DAETransform>();
		this.instance_controllers = new Array<DAEInstanceController>();
		this.instance_geometries = new Array<DAEInstanceGeometry>();
		traverseChildren(element);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		var instances:XMLList;
		var instance:DAEInstance;
		
		switch (nodeName) {
			case "node":
				this.nodes.push(new DAENode(this.parser, child, this));
				break;
			
			case "instance_controller":
				instance = new DAEInstanceController(child);
				this.instance_controllers.push(instance);
				break;
			
			case "instance_geometry":
				this.instance_geometries.push(new DAEInstanceGeometry(child));
				break;
			
			case "instance_node":
				instance = new DAEInstanceNode(child);
				instances = _root.ns::library_nodes.ns::node.(@id == instance.url);
				if (instances.length())
					this.nodes.push(new DAENode(this.parser, instances[0], this));
				break;
			
			case "matrix":
			case "translate":
			case "scale":
			case "rotate":
				this.transforms.push(new DAETransform(child));
				break;
		}
	}
	
	public function getMatrixBySID(sid:String):Matrix3D
	{
		var transform:DAETransform = getTransformBySID(sid);
		if (transform)
			return transform.matrix;
		
		return null;
	}
	
	public function getTransformBySID(sid:String):DAETransform
	{
		for each (var transform:DAETransform in this.transforms) {
			if (transform.sid == sid)
				return transform;
		}
		
		return null;
	}
	
	public function getAnimatedMatrix(time:Float):Matrix3D
	{
		var matrix:Matrix3D = new Matrix3D();
		var tdata:Array<Float>;
		var odata:Array<Float>;
		var channelsBySID:Object = {};
		var transform:DAETransform;
		var channel:DAEChannel;
		var minTime:Float = Number.MAX_VALUE;
		var maxTime:Float = -minTime;
		var i:UInt = 0;
		//var j : UInt;
		//var frame : Int;
		
		// For loop conversion - 				for (i = 0; i < this.channels.length; i++)
		
		for (i in 0...this.channels.length) {
			channel = this.channels[i];
			minTime = Math.min(minTime, channel.sampler.minTime);
			minTime = Math.max(maxTime, channel.sampler.maxTime);
			channelsBySID[channel.targetSid] = channel;
		}
		
		// For loop conversion - 				for (i = 0; i < this.transforms.length; i++)
		
		for (i in 0...this.transforms.length) {
			transform = this.transforms[i];
			tdata = transform.data;
			if (channelsBySID.hasOwnProperty(transform.sid)) {
				var m:Matrix3D = new Matrix3D();
				//var found : Bool = false;
				var frameData:DAEFrameData = null;
				channel = channelsBySID[transform.sid] as DAEChannel;
				frameData = channel.sampler.getFrameData(time);
				
				if (frameData) {
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
								trace("unhandled matrix array access");
							
							else if (odata.length == 16) {
								m.rawData = odata;
								m.transpose();
								
							} else
								trace("unhandled matrix " + transform.sid + " " + odata);
							break;
						
						case "rotate":
							if (channel.arrayAccess)
								trace("unhandled rotate array access");
							
							else if (channel.dotAccess) {
								
								switch (channel.dotAccessor) {
									case "ANGLE":
										m.appendRotation(odata[0], new Vector3D(tdata[0], tdata[1], tdata[2]));
										break;
									default:
										trace("unhandled rotate dot access " + channel.dotAccessor);
								}
								
							} else
								trace("unhandled rotate");
							break;
						
						case "scale":
							if (channel.arrayAccess)
								trace("unhandled scale array access");
							
							else if (channel.dotAccess) {
								
								switch (channel.dotAccessor) {
									case "X":
										m.appendScale(odata[0], tdata[1], tdata[2]);
										break;
									case "Y":
										m.appendScale(tdata[0], odata[0], tdata[2]);
										break;
									case "Z":
										m.appendScale(tdata[0], tdata[1], odata[0]);
										break;
									default:
										trace("unhandled scale dot access " + channel.dotAccessor);
								}
								
							} else
								trace("unhandled scale: " + odata.length);
							break;
						
						case "translate":
							if (channel.arrayAccess)
								trace("unhandled translate array access");
							
							else if (channel.dotAccess) {
								
								switch (channel.dotAccessor) {
									case "X":
										m.appendTranslation(odata[0], tdata[1], tdata[2]);
										break;
									case "Y":
										m.appendTranslation(tdata[0], odata[0], tdata[2]);
										break;
									case "Z":
										m.appendTranslation(tdata[0], tdata[1], odata[0]);
										break;
									default:
										trace("unhandled translate dot access " + channel.dotAccessor);
								}
								
							} else
								m.appendTranslation(odata[0], odata[1], odata[2]);
							break;
						
						default:
							trace("unhandled transform type " + transform.type);
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
	
	public var matrix(get, null) : Matrix3D;
	
	public function get_matrix() : Matrix3D
	{
		var matrix:Matrix3D = new Matrix3D();
		// For loop conversion - 		for (var i:UInt = 0; i < this.transforms.length; i++)
		var i:UInt = 0;
		for (i in 0...this.transforms.length)
			matrix.prepend(this.transforms[i].matrix);
		
		if (DAEElement.USE_LEFT_HANDED)
			convertMatrix(matrix);
		
		return matrix;
	}
}

class DAEVisualScene extends DAENode
{
	public function DAEVisualScene(parser:DAEParser, element:XML = null)
	{
		super(parser, element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
	}
	
	public function findNodeById(id:String, node:DAENode = null):DAENode
	{
		node = node || this;
		if (node.id == id)
			return node;
		
		// For loop conversion - 				for (var i:UInt = 0; i < node.nodes.length; i++)
		
		var i:UInt = 0;
		
		for (i in 0...node.nodes.length) {
			var result:DAENode = findNodeById(id, node.nodes[i]);
			if (result)
				return result;
		}
		
		return null;
	}
	
	public function findNodeBySid(sid:String, node:DAENode = null):DAENode
	{
		node = node || this;
		if (node.sid == sid)
			return node;
		
		// For loop conversion - 				for (var i:UInt = 0; i < node.nodes.length; i++)
		
		var i:UInt = 0;
		
		for (i in 0...node.nodes.length) {
			var result:DAENode = findNodeBySid(sid, node.nodes[i]);
			if (result)
				return result;
		}
		
		return null;
	}
	
	public function updateTransforms(node:DAENode, parent:DAENode = null):Void
	{
		node.world = node.matrix.clone();
		if (parent && parent.world)
			node.world.append(parent.world);
		
		// For loop conversion - 				for (var i:UInt = 0; i < node.nodes.length; i++)
		
		var i:UInt = 0;
		
		for (i in 0...node.nodes.length)
			updateTransforms(node.nodes[i], node);
	}
}

class DAEScene extends DAEElement
{
	public var instance_visual_scene:DAEInstanceVisualScene;
	
	public function DAEScene(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.instance_visual_scene = null;
		traverseChildren(element);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "instance_visual_scene")
			this.instance_visual_scene = new DAEInstanceVisualScene(child);
	}
}

class DAEMorph extends DAEEffect
{
	public var source:String;
	public var method:String;
	public var targets:Array<String>;
	public var weights:Array<Float>;
	
	public function DAEMorph(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.source = element.@source.toString().replace(/^#/, "");
		this.method = element.@method.toString();
		this.method = this.method.length? this.method : "NORMALIZED";
		this.targets = new Array<String>();
		this.weights = new Array<Float>();
		
		var sources:Object = {};
		var source:DAESource;
		var input:DAEInput;
		var list:XMLList = element.ns::source;
		
		if (element.ns::targets && element.ns::targets.length() > 0) {
			// For loop conversion - 			for (var i:UInt = 0; i < list.length(); i++)
			var i:UInt = 0;
			for (i in 0...list.length()) {
				source = new DAESource(list[i]);
				sources[source.id] = source;
			}
			list = element.ns::targets[0].ns::input;
			// For loop conversion - 			for (i = 0; i < list.length(); i++)
			for (i in 0...list.length()) {
				input = new DAEInput(list[i]);
				source = sources[input.source];
				switch (input.semantic) {
					case "MORPH_TARGET":
						this.targets = source.strings;
						break;
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
	
	public function DAEVertexWeight()
	{
	}
}

class DAESkin extends DAEElement
{
	public var source:String;
	public var bind_shape_matrix:Matrix3D;
	public var joints:Array<String>;
	public var inv_bind_matrix:Array<Matrix3D>;
	public var weights:Array<Array<DAEVertexWeight>>;
	public var jointSourceType:String;
	public var maxBones:UInt;
	
	public function DAESkin(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		
		this.source = element.@source.toString().replace(/^#/, "");
		this.bind_shape_matrix = new Matrix3D();
		this.inv_bind_matrix = new Array<Matrix3D>();
		this.joints = new Array<String>();
		this.weights = new Array<Array<DAEVertexWeight>>();
		
		var children:XMLList = element.children();
		var i:UInt = 0;
		var sources:Object = {};
		
		// For loop conversion - 				for (i = 0; i < element.ns::source.length(); i++)
		
		for (i in 0...element.ns::source.length()) {
			var source:DAESource = new DAESource(element.ns::source[i]);
			sources[source.id] = source;
		}
		
		// For loop conversion - 				for (i = 0; i < children.length(); i++)
		
		for (i in 0...children.length()) {
			var child:XML = children[i];
			var name:String = child.name().localName;
			
			switch (name) {
				case "bind_shape_matrix":
					parseBindShapeMatrix(child);
					break;
				case "source":
					break;
				case "joints":
					parseJoints(child, sources);
					break;
				case "vertex_weights":
					parseVertexWeights(child, sources);
					break;
				default:
					break;
			}
		}
	}
	
	public function getJointIndex(joint:String):Int
	{
		// For loop conversion - 		for (var i:UInt = 0; i < this.joints.length; i++)
		var i:UInt = 0;
		for (i in 0...this.joints.length) {
			if (this.joints[i] == joint)
				return i;
		}
		return -1;
	}
	
	private function parseBindShapeMatrix(element:XML):Void
	{
		var values:Array<Float> = readFloatArray(element);
		this.bind_shape_matrix = new Matrix3D(values);
		this.bind_shape_matrix.transpose();
		if (DAEElement.USE_LEFT_HANDED)
			convertMatrix(this.bind_shape_matrix);
	}
	
	private function parseJoints(element:XML, sources:Object):Void
	{
		var list:XMLList = element.ns::input;
		var input:DAEInput;
		var source:DAESource;
		var i:UInt, j:UInt;
		
		// For loop conversion - 				for (i = 0; i < list.length(); i++)
		
		for (i in 0...list.length()) {
			input = new DAEInput(list[i]);
			source = sources[input.source];
			
			switch (input.semantic) {
				case "JOINT":
					this.joints = source.strings;
					this.jointSourceType = source.type;
					break;
				case "INV_BIND_MATRIX":
					// For loop conversion - 					for (j = 0; j < source.floats.length; j += source.accessor.stride)
					for (j in 0...source.floats.length) {
						var matrix:Matrix3D = new Matrix3D(source.floats.slice(j, j + source.accessor.stride));
						matrix.transpose();
						if (DAEElement.USE_LEFT_HANDED)
							convertMatrix(matrix);
						inv_bind_matrix.push(matrix);
					}
			}
		}
	}
	
	private function parseVertexWeights(element:XML, sources:Object):Void
	{
		var list:XMLList = element.ns::input;
		var input:DAEInput;
		var inputs:Array<DAEInput> = new Array<DAEInput>();
		var source:DAESource;
		var i:UInt, j:UInt, k:UInt;
		
		if (!element.ns::vcount.length() || !element.ns::v.length())
			throw new Error("Can't parse vertex weights");
		
		var vcount:Array<Int> = readIntArray(element.ns::vcount[0]);
		var v:Array<Int> = readIntArray(element.ns::v[0]);
		var numWeights:UInt = parseInt(element.@count.toString(), 10);
		numWeights = numWeights;
		var index:UInt = 0;
		this.maxBones = 0;
		
		// For loop conversion - 				for (i = 0; i < list.length(); i++)
		
		for (i in 0...list.length())
			inputs.push(new DAEInput(list[i]));
		
		// For loop conversion - 				for (i = 0; i < vcount.length; i++)
		
		for (i in 0...vcount.length) {
			var numBones:UInt = vcount[i];
			var vertex_weights:Array<DAEVertexWeight> = new Array<DAEVertexWeight>();
			
			this.maxBones = Math.max(this.maxBones, numBones);
			
			// For loop conversion - 						for (j = 0; j < numBones; j++)
			
			for (j in 0...numBones) {
				var influence:DAEVertexWeight = new DAEVertexWeight();
				
				// For loop conversion - 								for (k = 0; k < inputs.length; k++)
				
				for (k in 0...inputs.length) {
					input = inputs[k];
					source = sources[input.source];
					
					switch (input.semantic) {
						case "JOINT":
							influence.joint = v[index + input.offset];
							break;
						case "WEIGHT":
							influence.weight = source.floats[v[index + input.offset]];
							break;
						default:
							break;
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
	
	public function DAEController(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.skin = null;
		this.morph = null;
		
		if (element.ns::skin && element.ns::skin.length())
			this.skin = new DAESkin(element.ns::skin[0]);
		else if (element.ns::morph && element.ns::morph.length())
			this.morph = new DAEMorph(element.ns::morph[0]);
		else
			throw new Error("DAEController: could not find a <skin> or <morph> element");
	}
}

class DAESampler extends DAEElement
{
	public var input:Array<Float>;
	public var output:Array<Array<Float>>;
	public var dataType:String;
	public var interpolation:Array<String>;
	public var minTime:Float;
	public var maxTime:Float;
	var _inputs:Array<DAEInput>;
	
	public function DAESampler(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		var list:XMLList = element.ns::input;
		var i:UInt = 0;
		_inputs = new Array<DAEInput>();
		
		// For loop conversion - 				for (i = 0; i < list.length(); i++)
		
		for (i in 0...list.length())
			_inputs.push(new DAEInput(list[i]));
	}
	
	public function create(sources:Object):Void
	{
		var input:DAEInput;
		var source:DAESource;
		var i:UInt, j:UInt;
		this.input = new Array<Float>();
		this.output = new Array<Array<Float>>();
		this.interpolation = new Array<String>();
		this.minTime = 0;
		this.maxTime = 0;
		
		// For loop conversion - 				for (i = 0; i < _inputs.length; i++)
		
		for (i in 0..._inputs.length) {
			input = _inputs[i];
			source = sources[input.source];
			
			switch (input.semantic) {
				case "INPUT":
					this.input = source.floats;
					this.minTime = this.input[0];
					this.maxTime = this.input[this.input.length - 1];
					break;
				case "OUTPUT":
					// For loop conversion - 					for (j = 0; j < source.floats.length; j += source.accessor.stride)
					for (j in 0...source.floats.length)
						this.output.push(source.floats.slice(j, j + source.accessor.stride));
					this.dataType = source.accessor.params[0].type;
					break;
				case "INTEROLATION":
					this.interpolation = source.strings;
			}
		}
	}
	
	public function getFrameData(time:Float):DAEFrameData
	{
		var frameData:DAEFrameData = new DAEFrameData(0, time);
		
		if (!this.input || this.input.length == 0)
			return null;
		
		var a:Float, b:Float;
		var i:UInt = 0;
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
			
			// For loop conversion - 						for (i = 0; i < this.input.length - 1; i++)
			
			for (i in 0...this.input.length - 1) {
				if (time >= this.input[i] && time < this.input[i + 1]) {
					frameData.frame = i;
					frameData.dt = (time - this.input[i])/(this.input[i + 1] - this.input[i]);
					frameData.data = this.output[i];
					break;
				}
			}
			
			// For loop conversion - 						for (i = 0; i < frameData.data.length; i++)
			
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
	public var frame:UInt;
	public var time:Float;
	public var data:Array<Float>;
	public var dt:Float;
	public var valid:Bool;
	
	public function DAEFrameData(frame:UInt = 0, time:Float = 0.0, dt:Float = 0.0, valid:Bool = false)
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
	public var arrayIndices:Array<Dynamic>;
	
	public function DAEChannel(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		
		this.source = element.@source.toString().replace(/^#/, "");
		this.target = element.@target.toString();
		this.sampler = null;
		var parts:Array<Dynamic> = this.target.split("/");
		this.targetId = parts.shift();
		this.arrayAccess = this.dotAccess = false;
		var tmp:String = parts.shift();
		
		if (tmp.indexOf("(") >= 0) {
			parts = tmp.split("(");
			this.arrayAccess = true;
			this.arrayIndices = [];
			this.targetSid = parts.shift();
			// For loop conversion - 			for (var i:UInt = 0; i < parts.length; i++)
			var i:UInt = 0;
			for (i in 0...parts.length)
				this.arrayIndices.push(parseInt(parts[i].replace(")", ""), 10));
			
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
	public var samplers:Array<DAESampler>;
	public var channels:Array<DAEChannel>;
	public var sources:Object;
	
	public function DAEAnimation(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		this.samplers = new Array<DAESampler>();
		this.channels = new Array<DAEChannel>();
		this.sources = {};
		traverseChildren(element);
		setupChannels(this.sources);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		switch (nodeName) {
			case "source":
				var source:DAESource = new DAESource(child);
				this.sources[source.id] = source;
				break;
			case "sampler":
				this.samplers.push(new DAESampler(child));
				break;
			case "channel":
				this.channels.push(new DAEChannel(child));
		}
	}
	
	private function setupChannels(sources:Object):Void
	{
		for each (var channel:DAEChannel in this.channels) {
			for each (var sampler:DAESampler in this.samplers) {
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
	
	public function DAELightType(element:XML = null)
	{
		super(element);
	}
	
	public override function deserialize(element:XML):Void
	{
		super.deserialize(element);
		traverseChildren(element);
	}
	
	private override function traverseChildHandler(child:XML, nodeName:String):Void
	{
		if (nodeName == "color") {
			var f:Array<Float> = readFloatArray(child);
			this.color = new DAEColor();
			color.r = f[0];
			color.g = f[1];
			color.b = f[2];
			color.a = f.length > 3? f[3] : 1.0;
		}
	}
}

class DAEParserState
{
	public static var LOAD_XML:UInt = 0;
	public static var PARSE_IMAGES:UInt = 1;
	public static var PARSE_MATERIALS:UInt = 2;
	public static var PARSE_GEOMETRIES:UInt = 3;
	public static var PARSE_CONTROLLERS:UInt = 4;
	public static var PARSE_VISUAL_SCENE:UInt = 5;
	public static var PARSE_ANIMATIONS:UInt = 6;
	public static var PARSE_COMPLETE:UInt = 7;


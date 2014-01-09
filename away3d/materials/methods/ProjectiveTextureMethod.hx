package away3d.materials.methods;

	//import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.TextureProjector;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	
	import away3d.geom.Matrix3D;
	
	//use namespace arcane;
	
	/**
	 * ProjectiveTextureMethod is a material method used to project a texture unto the surface of an object.
	 * This can be used for various effects apart from acting like a normal projector, such as projecting fake shadows
	 * unto a surface, the impact of light coming through a stained glass window, ...
	 */
	class ProjectiveTextureMethod extends EffectMethodBase
	{
		public static var MULTIPLY:String = "multiply";
		public static var ADD:String = "add";
		public static var MIX:String = "mix";
		
		var _projector:TextureProjector;
		var _uvVarying:ShaderRegisterElement;
		var _projMatrix:Matrix3D = new Matrix3D();
		var _mode:String;
		
		/**
		 * Creates a new ProjectiveTextureMethod object.
		 *
		 * @param projector The TextureProjector object that defines the projection properties as well as the texture.
		 * @param mode The blend mode with which the texture is blended unto the surface.
		 *
		 * @see away3d.entities.TextureProjector
		 */
		public function new(projector:TextureProjector, mode:String = "multiply")
		{
			super();
			_projector = projector;
			_mode = mode;
		}

		/**
		 * @inheritDoc
		 */
		override public function initConstants(vo:MethodVO):Void
		{
			var index:Int = vo.fragmentConstantsIndex;
			var data:Array<Float> = vo.fragmentData;
			data[index] = .5;
			data[index + 1] = -.5;
			data[index + 2] = 1.0;
			data[index + 3] = 1.0;
		}

		/**
		 * @inheritDoc
		 */
		override function cleanCompilationData():Void
		{
			super.cleanCompilationData();
			_uvVarying = null;
		}
		
		/**
		 * The blend mode with which the texture is blended unto the object.
		 * ProjectiveTextureMethod.MULTIPLY can be used to project shadows. To prevent clamping, the texture's alpha should be white!
		 * ProjectiveTextureMethod.ADD can be used to project light, such as a slide projector or light coming through stained glass. To prevent clamping, the texture's alpha should be black!
		 * ProjectiveTextureMethod.MIX provides normal alpha blending. To prevent clamping, the texture's alpha should be transparent!
		 */
		public var mode(get, set) : String;
		public function get_mode() : String
		{
			return _mode;
		}
		
		public function set_mode(value:String) : String
		{
			if (_mode == value)
				return;
			_mode = value;
			invalidateShaderProgram();
		}
		
		/**
		 * The TextureProjector object that defines the projection properties as well as the texture.
		 *
		 * @see away3d.entities.TextureProjector
		 */
		public var projector(get, set) : TextureProjector;
		public function get_projector() : TextureProjector
		{
			return _projector;
		}
		
		public function set_projector(value:TextureProjector) : TextureProjector
		{
			_projector = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override function getVertexCode(vo:MethodVO, regCache:ShaderRegisterCache):String
		{
			var projReg:ShaderRegisterElement = regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexConstant();
			regCache.getFreeVertexVectorTemp();
			vo.vertexConstantsIndex = projReg.index*4;
			_uvVarying = regCache.getFreeVarying();
			
			return "m44 " + _uvVarying + ", vt0, " + projReg + "\n";
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getFragmentCode(vo:MethodVO, regCache:ShaderRegisterCache, targetReg:ShaderRegisterElement):String
		{
			var code:String = "";
			var mapRegister:ShaderRegisterElement = regCache.getFreeTextureReg();
			var col:ShaderRegisterElement = regCache.getFreeFragmentVectorTemp();
			var toTexReg:ShaderRegisterElement = regCache.getFreeFragmentConstant();
			vo.fragmentConstantsIndex = toTexReg.index*4;
			vo.texturesIndex = mapRegister.index;
			
			code += "div " + col + ", " + _uvVarying + ", " + _uvVarying + ".w						\n" +
				"mul " + col + ".xy, " + col + ".xy, " + toTexReg + ".xy	\n" +
				"add " + col + ".xy, " + col + ".xy, " + toTexReg + ".xx	\n";
			code += getTex2DSampleCode(vo, col, mapRegister, _projector.texture, col, "clamp");
			
			if (_mode == MULTIPLY)
				code += "mul " + targetReg + ".xyz, " + targetReg + ".xyz, " + col + ".xyz			\n";
			else if (_mode == ADD)
				code += "add " + targetReg + ".xyz, " + targetReg + ".xyz, " + col + ".xyz			\n";
			else if (_mode == MIX) {
				code += "sub " + col + ".xyz, " + col + ".xyz, " + targetReg + ".xyz				\n" +
					"mul " + col + ".xyz, " + col + ".xyz, " + col + ".w						\n" +
					"add " + targetReg + ".xyz, " + targetReg + ".xyz, " + col + ".xyz			\n";
			} else
				throw new Error("Unknown mode \"" + _mode + "\"");
			
			return code;
		}

		/**
		 * @inheritDoc
		 */
		override function setRenderState(vo:MethodVO, renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):Void
		{
			_projMatrix.copyFrom(_projector.viewProjection);
			_projMatrix.prepend(renderable.getRenderSceneTransform(camera));
			_projMatrix.copyRawDataTo(vo.vertexData, vo.vertexConstantsIndex, true);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function activate(vo:MethodVO, stage3DProxy:Stage3DProxy):Void
		{
			stage3DProxy._context3D.setTextureAt(vo.texturesIndex, _projector.texture.getTextureForStage3D(stage3DProxy));
		}
	}


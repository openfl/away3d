package away3d.lights;

import away3d.*;
import away3d.cameras.*;
import away3d.core.base.*;
import away3d.core.partition.*;
import away3d.entities.*;
import away3d.errors.*;
import away3d.events.*;
import away3d.library.assets.*;
import away3d.lights.shadowmaps.*;

import openfl.geom.Matrix3D;

/**
 * LightBase provides an abstract base class for subtypes representing lights.
 */
class LightBase extends Entity
{
	public var castsShadows(get, set):Bool;
	public var specular(get, set):Float;
	public var diffuse(get, set):Float;
	public var color(get, set):Int;
	public var ambient(get, set):Float;
	public var ambientColor(get, set):Int;
	public var shadowMapper(get, set):ShadowMapperBase;
	
	private var _color:Int = 0xffffff;
	private var _colorR:Float = 1;
	private var _colorG:Float = 1;
	private var _colorB:Float = 1;
	
	private var _ambientColor:Int = 0xffffff;
	private var _ambient:Float = 0;
	@:allow(away3d) private var _ambientR:Float = 0;
	@:allow(away3d) private var _ambientG:Float = 0;
	@:allow(away3d) private var _ambientB:Float = 0;
	
	private var _specular:Float = 1;
	@:allow(away3d) private var _specularR:Float = 1;
	@:allow(away3d) private var _specularG:Float = 1;
	@:allow(away3d) private var _specularB:Float = 1;
	
	private var _diffuse:Float = 1;
	@:allow(away3d) private var _diffuseR:Float = 1;
	@:allow(away3d) private var _diffuseG:Float = 1;
	@:allow(away3d) private var _diffuseB:Float = 1;
	
	public var _castsShadows:Bool;
	
	public var _shadowMapper:ShadowMapperBase;
	
	/**
	 * Create a new LightBase object.
	 * @param positionBased Indicates whether or not the light has a valid position, or is "infinite" such as a DirectionalLight.
	 */
	public function new()
	{
		super();
	}
	
	private function get_castsShadows():Bool
	{
		return _castsShadows;
	}
	
	private function set_castsShadows(value:Bool):Bool
	{
		if (_castsShadows == value)
			return value;
		
		_castsShadows = value;
		
		if (value) {
			if (_shadowMapper == null)
				_shadowMapper = createShadowMapper();
			_shadowMapper.light = this;
		} else {
			if (_shadowMapper != null)
				_shadowMapper.dispose();
			_shadowMapper = null;
		}
		
		dispatchEvent(new LightEvent(LightEvent.CASTS_SHADOW_CHANGE));
		return value;
	}
	
	private function createShadowMapper():ShadowMapperBase
	{
		throw new AbstractMethodError();
		return null;
	}
	
	/**
	 * The specular emission strength of the light. Default value is <code>1</code>.
	 */
	private function get_specular():Float
	{
		return _specular;
	}
	
	private function set_specular(value:Float):Float
	{
		if (value < 0)
			value = 0;
		_specular = value;
		updateSpecular();
		return value;
	}
	
	/**
	 * The diffuse emission strength of the light. Default value is <code>1</code>.
	 */
	private function get_diffuse():Float
	{
		return _diffuse;
	}
	
	private function set_diffuse(value:Float):Float
	{
		if (value < 0)
			value = 0;
		//else if (value > 1) value = 1;
		_diffuse = value;
		updateDiffuse();
		return value;
	}
	
	/**
	 * The color of the light. Default value is <code>0xffffff</code>.
	 */
	private function get_color():Int
	{
		return _color;
	}
	
	private function set_color(value:Int):Int
	{
		_color = value;
		_colorR = ((_color >> 16) & 0xff)/0xff;
		_colorG = ((_color >> 8) & 0xff)/0xff;
		_colorB = (_color & 0xff)/0xff;
		updateDiffuse();
		updateSpecular();
		return value;
	}
	
	/**
	 * The ambient emission strength of the light. Default value is <code>0</code>.
	 */
	private function get_ambient():Float
	{
		return _ambient;
	}
	
	private function set_ambient(value:Float):Float
	{
		if (value < 0)
			value = 0;
		else if (value > 1)
			value = 1;
		_ambient = value;
		updateAmbient();
		return value;
	}
	
	/**
	 * The ambient emission colour of the light. Default value is <code>0xffffff</code>.
	 */
	private function get_ambientColor():Int
	{
		return _ambientColor;
	}
	
	private function set_ambientColor(value:Int):Int {
		_ambientColor = value;
		updateAmbient();
		return value;
	}
	
	private function updateAmbient():Void
	{
		_ambientR = ((_ambientColor >> 16) & 0xff)/0xff*_ambient;
		_ambientG = ((_ambientColor >> 8) & 0xff)/0xff*_ambient;
		_ambientB = (_ambientColor & 0xff)/0xff*_ambient;
	}
	
	/**
	 * Gets the optimal projection matrix to render a light-based depth map for a single object.
	 *
	 * @param renderable The IRenderable object to render to a depth map.
	 * @param target An optional target Matrix3D object. If not provided, an instance will be created.
	 * @return A Matrix3D object containing the projection transformation.
	 */
	@:allow(away3d) private function getObjectProjectionMatrix(renderable:IRenderable, camera:Camera3D, target:Matrix3D = null):Matrix3D
	{
		throw new AbstractMethodError();
		return null;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function createEntityPartitionNode():EntityNode
	{
		return new LightNode(this);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function get_assetType():String
	{
		return Asset3DType.LIGHT;
	}
	
	/**
	 * Updates the total specular components of the light.
	 */
	private function updateSpecular():Void
	{
		_specularR = _colorR*_specular;
		_specularG = _colorG*_specular;
		_specularB = _colorB*_specular;
	}
	
	/**
	 * Updates the total diffuse components of the light.
	 */
	private function updateDiffuse():Void
	{
		_diffuseR = _colorR*_diffuse;
		_diffuseG = _colorG*_diffuse;
		_diffuseB = _colorB*_diffuse;
	}
	
	private function get_shadowMapper():ShadowMapperBase
	{
		return _shadowMapper;
	}
	
	private function set_shadowMapper(value:ShadowMapperBase):ShadowMapperBase
	{
		_shadowMapper = value;
		_shadowMapper.light = this;
		return value;
	}
}
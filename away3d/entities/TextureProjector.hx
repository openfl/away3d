package away3d.entities;

import away3d.cameras.lenses.PerspectiveLens;
import away3d.containers.ObjectContainer3D;
import away3d.events.LensEvent;
import away3d.library.assets.Asset3DType;
import away3d.textures.Texture2DBase;

import openfl.geom.Matrix3D;

/**
 * TextureProjector is an object in the scene that can be used to project textures onto geometry. To do so,
 * the object's material must have a ProjectiveTextureMethod method added to it with a TextureProjector object
 * passed in the constructor.
 * This can be used for various effects apart from acting like a normal projector, such as projecting fake shadows
 * unto a surface, the impact of light coming through a stained glass window, ...
 *
 * @see away3d.materials.methods.ProjectiveTextureMethod
 */
class TextureProjector extends ObjectContainer3D
{
	public var aspectRatio(get, set):Float;
	public var fieldOfView(get, set):Float;
	public var texture(get, set):Texture2DBase;
	public var viewProjection(get, never):Matrix3D;
	
	private var _lens:PerspectiveLens;
	private var _viewProjectionInvalid:Bool = true;
	private var _viewProjection:Matrix3D = new Matrix3D();
	private var _texture:Texture2DBase;
	
	/**
	 * Creates a new TextureProjector object.
	 * @param texture The texture to be projected on the geometry. Since any point that is projected out of the range
	 * of the projector's cone is clamped to the texture's edges, the edges should be entirely neutral.
	 */
	public function new(texture:Texture2DBase)
	{
		_lens = new PerspectiveLens();
		_lens.addEventListener(LensEvent.MATRIX_CHANGED, onInvalidateLensMatrix, false, 0, true);
		_texture = texture;
		_lens.aspectRatio = texture.width/texture.height;
		
		super();
		
		rotationX = -90;
	}
	
	/**
	 * The aspect ratio of the texture or projection. By default this is the same aspect ratio of the texture (width/height)
	 */
	private function get_aspectRatio():Float
	{
		return _lens.aspectRatio;
	}
	
	private function set_aspectRatio(value:Float):Float
	{
		_lens.aspectRatio = value;
		return value;
	}
	
	/**
	 * The vertical field of view of the projection, or the angle of the cone.
	 */
	private function get_fieldOfView():Float
	{
		return _lens.fieldOfView;
	}
	
	private function set_fieldOfView(value:Float):Float
	{
		_lens.fieldOfView = value;
		return value;
	}
	
	override private function get_assetType():String
	{
		return Asset3DType.TEXTURE_PROJECTOR;
	}
	
	/**
	 * The texture to be projected on the geometry.
	 * IMPORTANT: Since any point that is projected out of the range of the projector's cone is clamped to the texture's edges,
	 * the edges should be entirely neutral. Depending on the blend mode, the neutral color is:
	 * White for MULTIPLY,
	 * Black for ADD,
	 * Transparent for MIX
	 */
	private function get_texture():Texture2DBase
	{
		return _texture;
	}
	
	private function set_texture(value:Texture2DBase):Texture2DBase
	{
		if (value == _texture)
			return value;
		_texture = value;
		return value;
	}
	
	/**
	 * The matrix that projects a point in scene space into the texture coordinates.
	 */
	private function get_viewProjection():Matrix3D
	{
		if (_viewProjectionInvalid) {
			_viewProjection.copyFrom(inverseSceneTransform);
			_viewProjection.append(_lens.matrix);
			_viewProjectionInvalid = false;
		}
		return _viewProjection;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function invalidateSceneTransform():Void
	{
		super.invalidateSceneTransform();
		_viewProjectionInvalid = true;
	}
	
	private function onInvalidateLensMatrix(event:LensEvent):Void
	{
		_viewProjectionInvalid = true;
	}
}
package away3d.animators.states;

import away3d.animators.ParticleAnimator;
import away3d.animators.data.AnimationRegisterCache;
import away3d.animators.data.AnimationSubGeometry;
import away3d.animators.nodes.ParticleBillboardNode;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.core.math.MathConsts;
import away3d.core.math.Matrix3DUtils;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.geom.Orientation3D;
import openfl.Vector;

/**
 * ...
 */
class ParticleBillboardState extends ParticleStateBase
{
	public var billboardAxis(get, set):Vector3D;
	
	private var _matrix:Matrix3D = new Matrix3D();
	
	private var _billboardAxis:Vector3D;
	
	/**
	 *
	 */
	public function new(animator:ParticleAnimator, particleNode:ParticleBillboardNode)
	{
		super(animator, particleNode);
		billboardAxis = particleNode._billboardAxis;
	}
	
	override public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, animationSubGeometry:AnimationSubGeometry, animationRegisterCache:AnimationRegisterCache, camera:Camera3D):Void
	{
		// TODO: not used
		
		var comps:Vector<Vector3D>;
		if (_billboardAxis != null) {
			var pos:Vector3D = renderable.getRenderSceneTransform(camera).position;
			var look:Vector3D = camera.sceneTransform.position.subtract(pos);
			var right:Vector3D = look.crossProduct(_billboardAxis);
			right.normalize();
			look = _billboardAxis.crossProduct(right);
			look.normalize();
			
			//create a quick inverse projection matrix
			_matrix.copyFrom(renderable.getRenderSceneTransform(camera));
			comps = Matrix3DUtils.decompose(_matrix, Orientation3D.AXIS_ANGLE);
			_matrix.copyColumnFrom(0, right);
			_matrix.copyColumnFrom(1, _billboardAxis);
			_matrix.copyColumnFrom(2, look);
			_matrix.copyColumnFrom(3, pos);
			_matrix.appendRotation(-comps[1].w*MathConsts.RADIANS_TO_DEGREES, comps[1]);
		} else {
			//create a quick inverse projection matrix
			_matrix.copyFrom(renderable.getRenderSceneTransform(camera));
			_matrix.append(camera.inverseSceneTransform);
			
			//decompose using axis angle rotations
			comps = Matrix3DUtils.decompose(_matrix, Orientation3D.AXIS_ANGLE);
			
			//recreate the matrix with just the rotation data
			_matrix.identity();
			_matrix.appendRotation(-comps[1].w*MathConsts.RADIANS_TO_DEGREES, comps[1]);
		}
		
		//set a new matrix transform constant
		animationRegisterCache.setVertexConstFromMatrix(animationRegisterCache.getRegisterIndex(_animationNode, ParticleBillboardNode.MATRIX_INDEX), _matrix);
	}
	
	/**
	 * Defines the billboard axis.
	 */
	private function get_billboardAxis():Vector3D
	{
		return _billboardAxis;
	}
	
	private function set_billboardAxis(value:Vector3D):Vector3D
	{
		_billboardAxis = (value != null) ? value.clone() : null;
		
		if (_billboardAxis != null)
			_billboardAxis.normalize();
		
		return value;
	}
}

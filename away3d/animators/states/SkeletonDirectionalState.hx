package away3d.animators.states;

import away3d.animators.*;
import away3d.animators.data.*;
import away3d.animators.nodes.*;

import openfl.geom.Vector3D;
import openfl.Vector;

/**
 *
 */
class SkeletonDirectionalState extends AnimationStateBase implements ISkeletonAnimationState
{
	public var direction(get, set):Float;
	
	private var _skeletonAnimationNode:SkeletonDirectionalNode;
	private var _skeletonPose:SkeletonPose = new SkeletonPose();
	private var _skeletonPoseDirty:Bool = true;
	private var _inputA:ISkeletonAnimationState;
	private var _inputB:ISkeletonAnimationState;
	private var _blendWeight:Float = 0;
	private var _direction:Float = 0;
	private var _blendDirty:Bool = true;
	private var _forward:ISkeletonAnimationState;
	private var _backward:ISkeletonAnimationState;
	private var _left:ISkeletonAnimationState;
	private var _right:ISkeletonAnimationState;
	
	/**
	 * Defines the direction in degrees of the aniamtion between the forwards (0), right(90) backwards (180) and left(270) input nodes,
	 * used to produce the skeleton pose output.
	 */
	private function set_direction(value:Float):Float
	{
		if (_direction == value)
			return value;
		
		_direction = value;
		
		_blendDirty = true;
		
		_skeletonPoseDirty = true;
		_positionDeltaDirty = true;
		return value;
	}
	
	private function get_direction():Float
	{
		return _direction;
	}

	public function new(animator:IAnimator, skeletonAnimationNode:SkeletonDirectionalNode)
	{
		super(animator, skeletonAnimationNode);
		
		_skeletonAnimationNode = skeletonAnimationNode;
		
		_forward = cast(animator.getAnimationState(_skeletonAnimationNode.forward), ISkeletonAnimationState);
		_backward = cast(animator.getAnimationState(_skeletonAnimationNode.backward), ISkeletonAnimationState);
		_left = cast(animator.getAnimationState(_skeletonAnimationNode.left), ISkeletonAnimationState);
		_right = cast(animator.getAnimationState(_skeletonAnimationNode.right), ISkeletonAnimationState);
	}
	
	/**
	 * @inheritDoc
	 */
	override public function phase(value:Float):Void
	{
		if (_blendDirty)
			updateBlend();
		
		_skeletonPoseDirty = true;
		
		_positionDeltaDirty = true;
		
		_inputA.phase(value);
		_inputB.phase(value);
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updateTime(time:Int):Void
	{
		if (_blendDirty)
			updateBlend();
		
		_skeletonPoseDirty = true;
		
		_inputA.update(time);
		_inputB.update(time);
		
		super.updateTime(time);
	}
	
	/**
	 * Returns the current skeleton pose of the animation in the clip based on the internal playhead position.
	 */
	public function getSkeletonPose(skeleton:Skeleton):SkeletonPose
	{
		if (_skeletonPoseDirty)
			updateSkeletonPose(skeleton);
		
		return _skeletonPose;
	}
	
	/**
	 * @inheritDoc
	 */
	override private function updatePositionDelta():Void
	{
		_positionDeltaDirty = false;
		if (_blendDirty)
			updateBlend();
		
		var deltA:Vector3D = _inputA.positionDelta;
		var deltB:Vector3D = _inputB.positionDelta;
		
		positionDelta.x = deltA.x + _blendWeight*(deltB.x - deltA.x);
		positionDelta.y = deltA.y + _blendWeight*(deltB.y - deltA.y);
		positionDelta.z = deltA.z + _blendWeight*(deltB.z - deltA.z);
	}
	
	/**
	 * Updates the output skeleton pose of the node based on the direction value between forward, backwards, left and right input nodes.
	 *
	 * @param skeleton The skeleton used by the animator requesting the ouput pose.
	 */
	private function updateSkeletonPose(skeleton:Skeleton):Void
	{
		_skeletonPoseDirty = false;
		
		if (_blendDirty)
			updateBlend();
		
		var endPose:JointPose;
		var endPoses:Vector<JointPose> = _skeletonPose.jointPoses;
		var poses1:Vector<JointPose> = _inputA.getSkeletonPose(skeleton).jointPoses;
		var poses2:Vector<JointPose> = _inputB.getSkeletonPose(skeleton).jointPoses;
		var pose1:JointPose, pose2:JointPose;
		var p1:Vector3D, p2:Vector3D;
		var tr:Vector3D;
		var numJoints:Int = skeleton.numJoints;
		
		// :s
		if (endPoses.length != numJoints)
			endPoses.length = numJoints;
		
		for (i in 0...numJoints) {
			if (endPoses[i] == null) endPoses[i] = new JointPose();
			endPose = endPoses[i] ;
			pose1 = poses1[i];
			pose2 = poses2[i];
			p1 = pose1.translation;
			p2 = pose2.translation;
			
			endPose.orientation.lerp(pose1.orientation, pose2.orientation, _blendWeight);
			
			tr = endPose.translation;
			tr.x = p1.x + _blendWeight*(p2.x - p1.x);
			tr.y = p1.y + _blendWeight*(p2.y - p1.y);
			tr.z = p1.z + _blendWeight*(p2.z - p1.z);
		}
	}
	
	/**
	 * Updates the blend value for the animation output based on the direction value between forward, backwards, left and right input nodes.
	 *
	 * @private
	 */
	@:allow(away3d) private function updateBlend():Void
	{
		_blendDirty = false;
		
		if (_direction < 0 || _direction > 360) {
			_direction %= 360;
			if (_direction < 0)
				_direction += 360;
		}
		
		if (_direction < 90) {
			_inputA = _forward;
			_inputB = _right;
			_blendWeight = _direction/90;
		} else if (_direction < 180) {
			_inputA = _right;
			_inputB = _backward;
			_blendWeight = (_direction - 90)/90;
		} else if (_direction < 270) {
			_inputA = _backward;
			_inputB = _left;
			_blendWeight = (_direction - 180)/90;
		} else {
			_inputA = _left;
			_inputB = _forward;
			_blendWeight = (_direction - 270)/90;
		}
	}
}
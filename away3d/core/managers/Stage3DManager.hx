package away3d.core.managers;

import openfl.errors.Error;
import openfl.display.Stage;
import openfl.Vector;

/**
 * The Stage3DManager class provides a multiton object that handles management for Stage3D objects. Stage3D objects
 * should not be requested directly, but are exposed by a Stage3DProxy.
 *
 * @see away3d.core.managers.Stage3DProxy
 */
class Stage3DManager
{
	public var hasFreeStage3DProxy(get, never):Bool;
	public var numProxySlotsFree(get, never):Int;
	public var numProxySlotsUsed(get, never):Int;
	public var numProxySlotsTotal(get, never):Int;
	
	private static var _instances:Map<Stage, Stage3DManager>;
	private static var _stageProxies:Vector<Stage3DProxy>;
	private static var _numStageProxies:Int = 0;
	
	private var _stage:Stage;
	
	/**
	 * Creates a new Stage3DManager class.
	 * @param stage The Stage object that contains the Stage3D objects to be managed.
	 * @private
	 */
	@:allow(away3d) private function new(stage:Stage)
	{
		_stage = stage;
		
		if (_stageProxies == null) 
			_stageProxies = new Vector<Stage3DProxy>(_stage.stage3Ds.length, true);
	}
	
	/**
	 * Gets a Stage3DManager instance for the given Stage object.
	 * @param stage The Stage object that contains the Stage3D objects to be managed.
	 * @return The Stage3DManager instance for the given Stage object.
	 */
	public static function getInstance(stage:Stage):Stage3DManager
	{
		if (_instances == null)
			_instances = new Map();
		
		var manager:Stage3DManager = _instances[stage];
		if (manager == null) {
			manager = new Stage3DManager(stage);
			_instances[stage] = manager;
		}
		return manager;
	}
	
	/**
	 * Requests the Stage3DProxy for the given index.
	 * @param index The index of the requested Stage3D.
	 * @param forceSoftware Whether to force software mode even if hardware acceleration is available.
	 * @param profile The compatibility profile, an enumeration of Context3DProfile
	 * @return The Stage3DProxy for the given index.
	 */
	public function getStage3DProxy(index:Int, forceSoftware:Bool = false, profile:String = "baseline"):Stage3DProxy
	{
		if (_stageProxies[index] == null) {
			_numStageProxies++;
			_stageProxies[index] = new Stage3DProxy(index, _stage.stage3Ds[index], this, forceSoftware, profile);
		}
		
		return _stageProxies[index];
	}
	
	/**
	 * Removes a Stage3DProxy from the manager.
	 * @param stage3DProxy
	 * @private
	 */
	@:allow(away3d) private function removeStage3DProxy(stage3DProxy:Stage3DProxy):Void
	{
		_numStageProxies--;
		_stageProxies[stage3DProxy.stage3DIndex] = null;
	}
	
	/**
	 * Get the next available stage3DProxy. An error is thrown if there are no Stage3DProxies available
	 * @param forceSoftware Whether to force software mode even if hardware acceleration is available.
	 * @param profile The compatibility profile, an enumeration of Context3DProfile
	 * @return The allocated stage3DProxy
	 */
	public function getFreeStage3DProxy(forceSoftware:Bool = false, profile:String = "baseline"):Stage3DProxy
	{
		var i:Int = 0;
		var len:Int = _stageProxies.length;
		
		while (i < len) {
			if (_stageProxies[i] == null) {
				getStage3DProxy(i, forceSoftware, profile);
				_stageProxies[i].width = _stage.stageWidth;
				_stageProxies[i].height = _stage.stageHeight;
				return _stageProxies[i];
			}
			++i;
		}
		
		throw new Error("Too many Stage3D instances used!");
		return null;
	}
	
	/**
	 * Checks if a new stage3DProxy can be created and managed by the class.
	 * @return true if there is one slot free for a new stage3DProxy
	 */
	private function get_hasFreeStage3DProxy():Bool
	{
		return _numStageProxies < _stageProxies.length? true : false;
	}
	
	/**
	 * Returns the amount of stage3DProxy objects that can be created and managed by the class
	 * @return the amount of free slots
	 */
	private function get_numProxySlotsFree():Int
	{
		return _stageProxies.length - _numStageProxies;
	}
	
	/**
	 * Returns the amount of Stage3DProxy objects currently managed by the class.
	 * @return the amount of slots used
	 */
	private function get_numProxySlotsUsed():Int
	{
		return _numStageProxies;
	}
	
	/**
	 * Returns the maximum amount of Stage3DProxy objects that can be managed by the class
	 * @return the maximum amount of Stage3DProxy objects that can be managed by the class
	 */
	private function get_numProxySlotsTotal():Int
	{
		return _stageProxies.length;
	}
}
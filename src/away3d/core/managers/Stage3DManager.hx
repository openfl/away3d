/**
 * The Stage3DManager class provides a multiton object that handles management for Stage3D objects. Stage3D objects
 * should not be requested directly, but are exposed by a Stage3DProxy.
 *
 * @see away3d.core.managers.Stage3DProxy
 */
package away3d.core.managers;


import flash.errors.Error;
import flash.Vector;
import flash.display.Stage;
import haxe.ds.ObjectMap;
using OpenFLStage3D;

class Stage3DManager {
    public var hasFreeStage3DProxy(get_hasFreeStage3DProxy, never):Bool;
    public var numProxySlotsFree(get_numProxySlotsFree, never):Int;
    public var numProxySlotsUsed(get_numProxySlotsUsed, never):Int;
    public var numProxySlotsTotal(get_numProxySlotsTotal, never):Int;

    static private var _instances:ObjectMap<Stage, Stage3DManager>;
    static private var _stageProxies:Vector<Stage3DProxy>;
    static private var _numStageProxies:Int = 0;
    private var _stage:Stage;
/**
	 * Creates a new Stage3DManager class.
	 * @param stage The Stage object that contains the Stage3D objects to be managed.
	 * @private
	 */
    private var stage3DsLength:Int;

    public function new(stage:Stage, Stage3DManagerSingletonEnforcer:Stage3DManagerSingletonEnforcer) {
        if (Stage3DManagerSingletonEnforcer == null) throw new Error("This class is a multiton and cannot be instantiated manually. Use Stage3DManager.getInstance instead.");
        _stage = stage;
        stage3DsLength = 1;
#if flash
			stage3DsLength = _stage.stage3Ds.length;
		#end
        if (_stageProxies == null) _stageProxies = new Vector<Stage3DProxy>(stage3DsLength, true);

    }

/**
	 * Gets a Stage3DManager instance for the given Stage object.
	 * @param stage The Stage object that contains the Stage3D objects to be managed.
	 * @return The Stage3DManager instance for the given Stage object.
	 */

    static public function getInstance(stage:Stage):Stage3DManager {
        if (_instances == null)
            _instances = new ObjectMap();

        var manager:Stage3DManager = _instances.get(stage);
        if (manager == null) {
            manager = new Stage3DManager(stage, new Stage3DManagerSingletonEnforcer());
            _instances.set(stage, manager);
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

    public function getStage3DProxy(index:Int, forceSoftware:Bool = false, profile:String = "baseline"):Stage3DProxy {
//why

        if (_stageProxies[index] == null) {
            _numStageProxies++;
            _stageProxies[index] = new Stage3DProxy(index, _stage.getStage3D(index), this, forceSoftware, profile); 

        }

        return _stageProxies[index];
    }

/**
	 * Removes a Stage3DProxy from the manager.
	 * @param stage3DProxy
	 * @private
	 */

    public function removeStage3DProxy(stage3DProxy:Stage3DProxy):Void {
        _numStageProxies--;
        _stageProxies[stage3DProxy.stage3DIndex] = null;
    }

/**
	 * Get the next available stage3DProxy. An error is thrown if there are no Stage3DProxies available
	 * @param forceSoftware Whether to force software mode even if hardware acceleration is available.
	 * @param profile The compatibility profile, an enumeration of Context3DProfile
	 * @return The allocated stage3DProxy
	 */

    public function getFreeStage3DProxy(forceSoftware:Bool = false, profile:String = "baseline"):Stage3DProxy {
        var i:Int = 0;
        var len:Int = stage3DsLength;
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

    public function get_hasFreeStage3DProxy():Bool {
        return Std.int(_numStageProxies) < (_stageProxies.length) ? true : false;
    }

/**
	 * Returns the amount of stage3DProxy objects that can be created and managed by the class
	 * @return the amount of free slots
	 */

    public function get_numProxySlotsFree():Int {
        return _stageProxies.length - _numStageProxies;
    }

/**
	 * Returns the amount of Stage3DProxy objects currently managed by the class.
	 * @return the amount of slots used
	 */

    public function get_numProxySlotsUsed():Int {
        return _numStageProxies;
    }

/**
	 * Returns the maximum amount of Stage3DProxy objects that can be managed by the class
	 * @return the maximum amount of Stage3DProxy objects that can be managed by the class
	 */

    public function get_numProxySlotsTotal():Int {
        return _stageProxies.length;
    }

}

class Stage3DManagerSingletonEnforcer {

    public function new() {}
}


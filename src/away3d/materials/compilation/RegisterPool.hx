/**
 * RegisterPool is used by the shader compilation process to keep track of which registers of a certain type are
 * currently used and should not be allowed to be written to. Either entire registers can be requested and locked,
 * or single components (x, y, z, w) of a single register.
 * It is used by ShaderRegisterCache to track usages of individual register types.
 *
 * @see away3d.materials.compilation.ShaderRegisterCache
 */
package away3d.materials.compilation;

import flash.errors.Error;
import flash.Vector;
import haxe.ds.StringMap;
#if (cpp || neko || js)
using away3d.Stage3DUtils;
#end
class RegisterPool {

    public static var _regPool:StringMap<Vector<ShaderRegisterElement>> = new StringMap<Vector<ShaderRegisterElement>>();
    public static var _regCompsPool:StringMap<Array<Array<ShaderRegisterElement>>> = new StringMap<Array<Array<ShaderRegisterElement>>>();
    private var _vectorRegisters:Vector<ShaderRegisterElement>;
    private var _registerComponents:Array<Dynamic>;
    private var _regName:String;
    private var _usedSingleCount:Vector<Vector<UInt>>;
    private var _usedVectorCount:Vector<UInt>;
    private var _regCount:Int;
    private var _persistent:Bool;
/**
	 * Creates a new RegisterPool object.
	 * @param regName The base name of the register type ("ft" for fragment temporaries, "vc" for vertex constants, etc)
	 * @param regCount The amount of available registers of this type.
	 * @param persistent Whether or not registers, once reserved, can be freed again. For example, temporaries are not persistent, but constants are.
	 */

    public function new(regName:String, regCount:Int, persistent:Bool = true) {
        _regName = regName;
        _regCount = regCount;
        _persistent = persistent;
        initRegisters(regName, regCount);
    }

/**
	 * Retrieve an entire vector register that's still available.
	 */

    public function requestFreeVectorReg():ShaderRegisterElement {
        var i:Int = 0;
        while (i < _regCount) {
            if (!isRegisterUsed(i)) {
                if (_persistent) _usedVectorCount[i]++;
                return _vectorRegisters[i];
            }
            ++i;
        }
        throw new Error("Register overflow!");
    }

/**
	 * Retrieve a single vector component that's still available.
	 */

    public function requestFreeRegComponent():ShaderRegisterElement {
        var i:Int = 0;
        while (i < _regCount) {
            if (_usedVectorCount[i] > 0) {
                ++i;
                continue;
            }
            ;
            var j:Int = 0;
            while (j < 4) {
                if (_usedSingleCount[j][i] == 0) {
                    if (_persistent) _usedSingleCount[j][i]++;
                    return _registerComponents[j][i];
                }
                ++j;
            }
            ++i;
        }
        throw new Error("Register overflow!");
    }

/**
	 * Marks a register as used, so it cannot be retrieved. The register won't be able to be used until removeUsage
	 * has been called usageCount times again.
	 * @param register The register to mark as used.
	 * @param usageCount The amount of usages to add.
	 */

    public function addUsage(register:ShaderRegisterElement, usageCount:Int):Void {
        if (register._component > -1) _usedSingleCount[register._component][register.index] += usageCount
        else _usedVectorCount[register.index] += usageCount;
    }

/**
	 * Removes a usage from a register. When usages reach 0, the register is freed again.
	 * @param register The register for which to remove a usage.
	 */

    public function removeUsage(register:ShaderRegisterElement):Void {
        if (register._component > -1) {
            if (--_usedSingleCount[register._component][register.index] < 0) throw new Error("More usages removed than exist!");
        }

        else {
            if (--_usedVectorCount[register.index] < 0) throw new Error("More usages removed than exist!");
        }

    }

/**
	 * Disposes any resources used by the current RegisterPool object.
	 */

    public function dispose():Void {
        _vectorRegisters = null;
        _registerComponents = null;
        _usedSingleCount = null;
        _usedVectorCount = null;
    }

/**
	 * Indicates whether or not any registers are in use.
	 */

    public function hasRegisteredRegs():Bool {
        var i:Int = 0;
        while (i < _regCount) {
            if (isRegisterUsed(i)) return true;
            ++i;
        }
        return false;
    }

/**
	 * Initializes all registers.
	 */

    private function initRegisters(regName:String, regCount:Int):Void {
        var hash:String = RegisterPool._initPool(regName, regCount);
        _vectorRegisters = RegisterPool._regPool.get(hash);
        _registerComponents = RegisterPool._regCompsPool.get(hash);
        _usedVectorCount = new Vector<UInt>(regCount, true);
        _usedSingleCount = new Vector<Vector<UInt>>(4, true);
        _usedSingleCount[0] = new Vector<UInt>(regCount, true);
        _usedSingleCount[1] = new Vector<UInt>(regCount, true);
        _usedSingleCount[2] = new Vector<UInt>(regCount, true);
        _usedSingleCount[3] = new Vector<UInt>(regCount, true);
		
		
		#if (cpp || neko || js) 
			_usedVectorCount.fillVector(0, regCount,0);
			_usedSingleCount[0].fillVector(0, regCount, 0);
			_usedSingleCount[1].fillVector(0, regCount, 0);
			_usedSingleCount[2].fillVector(0, regCount, 0);
			_usedSingleCount[3].fillVector(0, regCount,0);
		#end
    }

    static private function _initPool(regName:String, regCount:Int):String {
        var hash:String = regName + regCount;

        if (_regPool.exists(hash))
            return hash;

        var vectorRegisters:Vector<ShaderRegisterElement> = new Vector<ShaderRegisterElement>(regCount, true);
        _regPool.set(hash, vectorRegisters);

        var registerComponents:Array<Array<ShaderRegisterElement>> = [[], [], [], []];
        _regCompsPool.set(hash, registerComponents);

        for (i in 0...regCount) {
            vectorRegisters[i] = new ShaderRegisterElement(regName, i);

            for (j in 0...4) {
                registerComponents[j][i] = new ShaderRegisterElement(regName, i, j);
            }
        }
        return hash;
    }

/**
	 * Check if the temp register is either used for single or vector use
	 */

    private function isRegisterUsed(index:Int):Bool {
        if (_usedVectorCount[index] > 0) return true;
        var i:Int = 0;
        while (i < 4) {
            if (_usedSingleCount[i][index] > 0) return true;
            ++i;
        }
        return false;
    }

}


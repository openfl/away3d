package away3d.materials.compilation;

//	import flash.utils.Dictionary;
	import away3d.utils.ArrayUtils;
	import haxe.ds.StringMap;
	import flash.errors.Error;
	
	/**
	 * RegisterPool is used by the shader compilation process to keep track of which registers of a certain type are
	 * currently used and should not be allowed to be written to. Either entire registers can be requested and locked,
	 * or single components (x, y, z, w) of a single register.
	 * It is used by ShaderRegisterCache to track usages of individual register types.
	 *
	 * @see away3d.materials.compilation.ShaderRegisterCache
	 */
	class RegisterPool
	{
		public static var _regPool:StringMap<Array<ShaderRegisterElement>> = new StringMap<Array<ShaderRegisterElement>>();
		public static var _regCompsPool:StringMap<Array<Dynamic>> = new StringMap<Array<Dynamic>>();
		
		var _vectorRegisters:Array<ShaderRegisterElement>;
		var _registerComponents:Array<Dynamic>;
		
		var _regName:String;
		var _usedSingleCount:Array<Array<UInt>>;
		var _usedVectorCount:Array<UInt>;
		var _regCount:Int;
		
		var _persistent:Bool;
		
		/**
		 * Creates a new RegisterPool object.
		 * @param regName The base name of the register type ("ft" for fragment temporaries, "vc" for vertex constants, etc)
		 * @param regCount The amount of available registers of this type.
		 * @param persistent Whether or not registers, once reserved, can be freed again. For example, temporaries are not persistent, but constants are.
		 */
		public function new(regName:String, regCount:Int, persistent:Bool = true)
		{
			_regName = regName;
			_regCount = regCount;
			_persistent = persistent;
			initRegisters(regName, regCount);
		}
		
		/**
		 * Retrieve an entire vector register that's still available.
		 */
		public function requestFreeVectorReg():ShaderRegisterElement
		{
			// For loop conversion - 			for (var i:Int = 0; i < _regCount; ++i)
			var i:Int;
			for (i in 0..._regCount) {
				if (!isRegisterUsed(i)) {
					if (_persistent)
						_usedVectorCount[i]++;
					return _vectorRegisters[i];
				}
			}
			
			throw new Error("Register overflow!");
			return null;
		}
		
		/**
		 * Retrieve a single vector component that's still available.
		 */
		public function requestFreeRegComponent():ShaderRegisterElement
		{
			// For loop conversion - 			for (var i:Int = 0; i < _regCount; ++i)
			var i:Int;
			for (i in 0..._regCount) {
				if (_usedVectorCount[i] > 0)
					continue;
				// For loop conversion - 				for (var j:Int = 0; j < 4; ++j)
				var j:Int;
				for (j in 0...4) {
					if (_usedSingleCount[j][i] == 0) {
						if (_persistent)
							_usedSingleCount[j][i]++;
						return _registerComponents[j][i];
					}
				}
			}
			
			throw new Error("Register overflow!");
			return null;
		}
		
		/**
		 * Marks a register as used, so it cannot be retrieved. The register won't be able to be used until removeUsage
		 * has been called usageCount times again.
		 * @param register The register to mark as used.
		 * @param usageCount The amount of usages to add.
		 */
		public function addUsage(register:ShaderRegisterElement, usageCount:Int):Void
		{
			if (register._component > -1)
				_usedSingleCount[register._component][register.index] += usageCount;
			else
				_usedVectorCount[register.index] += usageCount;
		}
		
		/**
		 * Removes a usage from a register. When usages reach 0, the register is freed again.
		 * @param register The register for which to remove a usage.
		 */
		public function removeUsage(register:ShaderRegisterElement):Void
		{
			if (register._component > -1) {
				if (--_usedSingleCount[register._component][register.index] < 0)
					throw new Error("More usages removed than exist!");
			} else {
				if (--_usedVectorCount[register.index] < 0)
					throw new Error("More usages removed than exist!");
			}
		}

		/**
		 * Disposes any resources used by the current RegisterPool object.
		 */
		public function dispose():Void
		{
			_vectorRegisters = null;
			_registerComponents = null;
			_usedSingleCount = null;
			_usedVectorCount = null;
		}
		
		/**
		 * Indicates whether or not any registers are in use.
		 */
		public function hasRegisteredRegs():Bool
		{
			// For loop conversion - 			for (var i:Int = 0; i < _regCount; ++i)
			var i:Int;
			for (i in 0..._regCount) {
				if (isRegisterUsed(i))
					return true;
			}
			
			return false;
		}
		
		/**
		 * Initializes all registers.
		 */
		public function initRegisters(regName:String, regCount:Int):Void
		{
			
			var hash:String = _initPool(regName, regCount);
			
			_vectorRegisters = _regPool.get(hash);
			_registerComponents = _regCompsPool.get(hash);
			
			_usedVectorCount = new Array<UInt>();
			_usedSingleCount = new Array<Array<UInt>>();
			
			_usedSingleCount[0] = new Array<UInt>();
			_usedSingleCount[1] = new Array<UInt>();
			_usedSingleCount[2] = new Array<UInt>();
			_usedSingleCount[3] = new Array<UInt>();
			ArrayUtils.Prefill(_usedVectorCount, regCount,0);
			ArrayUtils.Prefill(_usedSingleCount[0],regCount, 0);
			ArrayUtils.Prefill(_usedSingleCount[1], regCount, 0);
			ArrayUtils.Prefill(_usedSingleCount[2], regCount, 0);
			ArrayUtils.Prefill(_usedSingleCount[3], regCount, 0);
		 
		
		}
		
		public static function _initPool(regName:String, regCount:Int):String
		{
			var hash:String = regName + regCount;
			
			if (_regPool.get(hash) != null)
				return hash;
			
			var vectorRegisters:Array<ShaderRegisterElement> = new Array<ShaderRegisterElement>();
			_regPool.set(hash, vectorRegisters);
			
			var registerComponents:Array<Array<ShaderRegisterElement>> = new Array<Array<ShaderRegisterElement>>();
			_regCompsPool.set(hash, registerComponents);
			
			// For loop conversion - 						for (var i:Int = 0; i < regCount; ++i)
			
			var i:Int;
			
			for (i in 0...regCount) {
				vectorRegisters[i] = new ShaderRegisterElement(regName, i);
				
				// For loop conversion - 								for (var j:Int = 0; j < 4; ++j)
				
				var j:Int;
				for (j in 0...4) {
					if (registerComponents[j]==null) registerComponents[j] = new Array<ShaderRegisterElement>();
					registerComponents[j][i] = new ShaderRegisterElement(regName, i, j);
				}
			}
			return hash;
		}
		
		/**
		 * Check if the temp register is either used for single or vector use
		 */
		private function isRegisterUsed(index:Int):Bool
		{
			if (_usedVectorCount[index] > 0)
				return true;
			// For loop conversion - 			for (var i:Int = 0; i < 4; ++i)
			var i:Int;
			for (i in 0...4) {
				if (_usedSingleCount[i][index] > 0)
					return true;
			}
			
			return false;
		}
	}


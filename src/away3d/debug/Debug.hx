/** Class for emmiting debuging messages, warnings and errors */
/**
 * @private
 */
package away3d.debug;

import flash.errors.Error;
class Debug {

    static public var active:Bool = false;
    static public var warningsAsErrors:Bool = false;

    static public function clear():Void {
    }

    static public function delimiter():Void {
    }

    static public function trace(message:Dynamic):Void {
        if (active) trace(message);
    }

    static public function warning(message:Dynamic):Void {
        if (warningsAsErrors) {
            error(message);
            return;
        }
        trace("WARNING: " + message);
    }

    static public function error(message:Dynamic):Void {
        trace("ERROR: " + message);
        throw new Error(message);
    }

}


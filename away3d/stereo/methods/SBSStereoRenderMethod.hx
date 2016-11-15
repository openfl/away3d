package away3d.stereo.methods;

import away3d.core.managers.RTTBufferManager;
import away3d.core.managers.Stage3DProxy;
import openfl.display3D.Context3DProgramType;
import openfl.Vector;

class SBSStereoRenderMethod extends StereoRenderMethodBase {

	private var _sbsData:Vector<Float>;

	public function new() {
		super();
		_sbsData = Vector.ofArray( [ 5.0, 10.0, 15.0, 1.0, 10.0, 20.0, 30.0, 40.0 ] );
	}

	override public function activate(stage3DProxy:Stage3DProxy):Void {
		if (_textureSizeInvalid) {

			var rttManager : RTTBufferManager;
			
			rttManager = RTTBufferManager.getInstance(stage3DProxy);
			_textureSizeInvalid = false;
			
			// xPos is the left edge offset of the RTT.x in relation to the texture width 
			// (e.g. 800 view with 1024 texture - left edge offset = 112)
			var xPos : Float = (rttManager.renderToTextureRect.x / rttManager.textureWidth);
			
			// For the two image offsets, need to take into consideration that the RTT is a larger
			// texture than the view so need to apply offsets to both left/right views
			_sbsData[ 0] = 2;
			_sbsData[ 1] = rttManager.renderToTextureRect.width;
			_sbsData[ 2] = 1;
			_sbsData[ 3] = .5;

			_sbsData[ 4] = (0.5 - xPos) * 0.5; 
			_sbsData[ 5] = (0.5 - xPos) * -0.5; 
			_sbsData[ 6] = 0;
			_sbsData[ 7] = 0;
		}
					
		stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _sbsData, 2);
	}

	override public function deactivate(stage3DProxy:Stage3DProxy):Void {
		stage3DProxy.context3D.setTextureAt(2, null);
	}

	override public function getFragmentCode():String {
		return  "add ft0, v1, fc1.xzzz				\n" +	// translate: ft0.x = ft0.x + (left offset); ft0.yzw = v1.yzw + 0;
				"tex ft1, ft0, fs0 <2d,linear,nomip>\n" +	// ft1 = getColorAt(texture=fs0, position=ft0)
				"add ft0, v1, fc1.yzzz				\n" +	// translate: ft0.x = ft0.x - (right offset); ft0.yzw = v1.yzw + 0;
				"tex ft2, ft0, fs1 <2d,linear,nomip>\n" +	// ft2 = getColorAt(texture=fs1, position=ft0)
				"div ft3, v0.x, fc0.y 				\n" +	// ratio: get fraction of way across the screen (range 0-1, see next line)
				"frc ft3, ft3						\n" +	// ratio: ft3 = fraction(v0.x / renderWidth);
				"slt ft4, ft3, fc0.w 				\n" +	// ft4 = (ft3 < 0.5) ? 1 : 0;
				"sge ft5, ft3, fc0.w 				\n" +	// ft5 = (ft3 >= 0.5) ? 1 : 0;
				"mul ft6, ft2, ft4 					\n" +	// ft6 = ft1 * ft4;		// ft6 = (right side of screen) ? texture_fs1 : transparent
				"mul ft7, ft1, ft5 					\n" +	// ft7 = ft1 * ft4;		// ft7 = (left side of screen) ? texture_fs0 : transparent
				"add oc, ft7, ft6 					\n"; 	// outputcolor = ft7 + ft6;		// merge two images
	}
}


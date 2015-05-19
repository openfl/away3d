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
			
			// RTT.x is the left pos of the view within the RTT as we are sampling from the RTT not the view
			var xPos : Float = -(rttManager.renderToTextureRect.x / rttManager.textureWidth);
			var wOff : Float = -(rttManager.renderToTextureRect.width / rttManager.textureWidth);
			
			// For the two image offsets, need to take into consideration that the RTT is a larger
			// texture than the view so need to apply offsets to both left/right views
			_sbsData[ 0] = 2;
			_sbsData[ 1] = rttManager.renderToTextureRect.width;
			_sbsData[ 2] = 1;
			_sbsData[ 3] = .5;

			_sbsData[ 4] = 0.25; //xPos; 
			_sbsData[ 5] = 0.75; //wOff + xPos;
			_sbsData[ 6] = 0;
			_sbsData[ 7] = 0;
			
			_sbsData[ 8] = 1; // Take samples every double step (along x) to scale image down
			_sbsData[ 9] = 1;
			_sbsData[10] = 1;
			_sbsData[11] = 1;
		}
					
        stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _sbsData, 3);
    }

    override public function deactivate(stage3DProxy:Stage3DProxy):Void {
        stage3DProxy.context3D.setTextureAt(2, null);
    }

    override public function getFragmentCode():String {
        return  //"mul ft0, v1, fc2					\n" +	// scale: ft0.x = v1.x * 2; ft0.yzw = v1.yzw * 1;
				"add ft0, v1, fc1.xzzz				\n" +	// translate: ft0.x = ft0.x + (view.x/rtt.width); ft0.yzw = v1.yzw + 0;
				"tex ft1, ft0, fs0 <2d,linear,nomip>\n" +	// ft1 = getColorAt(texture=fs0, position=ft0)
				"add ft0, v1, fc1.yzzz				\n" +	// translate: ft0.x = ft0.x - (view.width/rtt.width) + (view.x/rtt.width); ft0.yzw = v1.yzw + 0;
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


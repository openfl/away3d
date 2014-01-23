/**
 * An abstract base class for all lens classes. Lens objects provides a projection matrix that transforms 3D geometry to normalized homogeneous coordinates.
 */
package away3d.cameras.lenses;

import away3d.utils.ArrayUtils;
import flash.Vector;
import flash.events.EventDispatcher;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;

import away3d.errors.AbstractMethodError;
import away3d.events.LensEvent;

class LensBase extends EventDispatcher {
    public var frustumCorners(get_frustumCorners, set_frustumCorners):Vector<Float>;
    public var matrix(get_matrix, set_matrix):Matrix3D;
    public var near(get_near, set_near):Float;
    public var far(get_far, set_far):Float;
    public var unprojectionMatrix(get_unprojectionMatrix, never):Matrix3D;
    public var aspectRatio(get_aspectRatio, set_aspectRatio):Float;

    private var _matrix:Matrix3D;
    private var _scissorRect:Rectangle;
    private var _viewPort:Rectangle;
    private var _near:Float;
    private var _far:Float;
    private var _aspectRatio:Float;
    private var _matrixInvalid:Bool;
    private var _frustumCorners:Vector<Float>;
    private var _unprojection:Matrix3D;
    private var _unprojectionInvalid:Bool;
/**
	 * Creates a new LensBase object.
	 */

    public function new() {
        super();
        _scissorRect = new Rectangle();
        _viewPort = new Rectangle();
        _near = 20;
        _far = 3000;
        _aspectRatio = 1;
        _matrixInvalid = true;
        _frustumCorners = new Vector<Float>(8 * 3, true);
        ArrayUtils.Prefill(_frustumCorners,8 * 3,0);
        _unprojectionInvalid = true;
        _matrix = new Matrix3D();
    }

/**
	 * Retrieves the corner points of the lens frustum.
	 */

    public function get_frustumCorners():Vector<Float> {
        return _frustumCorners;
    }

    public function set_frustumCorners(frustumCorners:Vector<Float>):Vector<Float> {
        _frustumCorners = frustumCorners;
        return frustumCorners;
    }

/**
	 * The projection matrix that transforms 3D geometry to normalized homogeneous coordinates.
	 */

    public function get_matrix():Matrix3D {
        if (_matrixInvalid) {
            updateMatrix();
            _matrixInvalid = false;
        }
        return _matrix;
    }

    public function set_matrix(value:Matrix3D):Matrix3D {
        _matrix = value;
        invalidateMatrix();
        return value;
    }

/**
	 * The distance to the near plane of the frustum. Anything behind near plane will not be rendered.
	 */

    public function get_near():Float {
        return _near;
    }

    public function set_near(value:Float):Float {
        if (value == _near) return value;
        _near = value;
        invalidateMatrix();
        return value;
    }

/**
	 * The distance to the far plane of the frustum. Anything beyond the far plane will not be rendered.
	 */

    public function get_far():Float {
        return _far;
    }

    public function set_far(value:Float):Float {
        if (value == _far) return value;
        _far = value;
        invalidateMatrix();
        return value;
    }

/**
	 * Calculates the normalised position in screen space of the given scene position relative to the camera.
	 *
	 * @param point3d the position vector of the scene coordinates to be projected.
	 * @return The normalised screen position of the given scene coordinates relative to the camera.
	 */

    public function project(point3d:Vector3D):Vector3D {
        var v:Vector3D = matrix.transformVector(point3d);
        v.x = v.x / v.w;
        v.y = -v.y / v.w;
//z is unaffected by transform
        v.z = point3d.z;
        return v;
    }

    public function get_unprojectionMatrix():Matrix3D {
        if (_unprojectionInvalid) {
            if (_unprojection == null)
                _unprojection = new Matrix3D();
            _unprojection.copyFrom(matrix);
            _unprojection.invert();
            _unprojectionInvalid = false;
        }
        return _unprojection;
    }

/**
	 * Calculates the scene position relative to the camera of the given normalized coordinates in screen space.
	 *
	 * @param nX The normalised x coordinate in screen space, -1 corresponds to the left edge of the viewport, 1 to the right.
	 * @param nY The normalised y coordinate in screen space, -1 corresponds to the top edge of the viewport, 1 to the bottom.
	 * @param sZ The z coordinate in screen space, representing the distance into the screen.
	 * @return The scene position relative to the camera of the given screen coordinates.
	 */

    public function unproject(nX:Float, nY:Float, sZ:Float):Vector3D {

        throw new AbstractMethodError();
        return null;
    }

/**
	 * Creates an exact duplicate of the lens
	 */

    public function clone():LensBase {
        throw new AbstractMethodError();
        return null;
    }

/**
	 * The aspect ratio (width/height) of the view. Set by the renderer.
	 * @private
	 */

    private function get_aspectRatio():Float {
        return _aspectRatio;
    }

    private function set_aspectRatio(value:Float):Float {

        if (_aspectRatio == value || (value * 0) != 0) return value;
        _aspectRatio = value;

        invalidateMatrix();
        return value;
    }

/**
	 * Invalidates the projection matrix, which will cause it to be updated on the next request.
	 */

    private function invalidateMatrix():Void {
        _matrixInvalid = true;
        _unprojectionInvalid = true;
// notify the camera that the lens matrix is changing. this will mark the
// viewProjectionMatrix in the camera as invalid, and force the matrix to
// be re-queried from the lens, and therefore rebuilt.
        dispatchEvent(new LensEvent(LensEvent.MATRIX_CHANGED, this));
    }

/**
	 * Updates the matrix
	 */

    private function updateMatrix():Void {
        throw new AbstractMethodError();
    }

    public function updateScissorRect(x:Float, y:Float, width:Float, height:Float):Void {
        _scissorRect.x = x;
        _scissorRect.y = y;
        _scissorRect.width = width;
        _scissorRect.height = height;
        invalidateMatrix();
    }

    public function updateViewport(x:Float, y:Float, width:Float, height:Float):Void {
        _viewPort.x = x;
        _viewPort.y = y;
        _viewPort.width = width;
        _viewPort.height = height;
        invalidateMatrix();
    }

}


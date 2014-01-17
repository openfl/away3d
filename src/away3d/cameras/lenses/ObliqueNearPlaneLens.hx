package away3d.cameras.lenses;


import flash.Vector;
import away3d.core.math.Plane3D;
import away3d.events.LensEvent;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

class ObliqueNearPlaneLens extends LensBase {
    public var plane(get_plane, set_plane):Plane3D;
    public var baseLens(never, set_baseLens):LensBase;

    private var _baseLens:LensBase;
    private var _plane:Plane3D;

    public function new(baseLens:LensBase, plane:Plane3D) {
        this.baseLens = baseLens;
        this.plane = plane;
        super();
    }

    override public function get_frustumCorners():Vector<Float> {
        return _baseLens.frustumCorners;
    }

    override public function get_near():Float {
        return _baseLens.near;
    }

    override public function set_near(value:Float):Float {
        _baseLens.near = value;
        return value;
    }

    override public function get_far():Float {
        return _baseLens.far;
    }

    override public function set_far(value:Float):Float {
        _baseLens.far = value;
        return value;
    }

    override private function get_aspectRatio():Float {
        return _baseLens.aspectRatio;
    }

    override private function set_aspectRatio(value:Float):Float {
        _baseLens.aspectRatio = value;
        return value;
    }

    public function get_plane():Plane3D {
        return _plane;
    }

    public function set_plane(value:Plane3D):Plane3D {
        _plane = value;
        invalidateMatrix();
        return value;
    }

    public function set_baseLens(value:LensBase):LensBase {
        if (_baseLens != null) _baseLens.removeEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);
        _baseLens = value;
        if (_baseLens != null) _baseLens.addEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);
        invalidateMatrix();
        return value;
    }

    private function onLensMatrixChanged(event:LensEvent):Void {
        invalidateMatrix();
    }

    override private function updateMatrix():Void {
        _matrix.copyFrom(_baseLens.matrix);
        var cx:Float = _plane.a;
        var cy:Float = _plane.b;
        var cz:Float = _plane.c;
        var cw:Float = -_plane.d + .05;
        var signX:Float = cx >= (0) ? 1 : -1;
        var signY:Float = cy >= (0) ? 1 : -1;
        var p:Vector3D = new Vector3D(signX, signY, 1, 1);
        var inverse:Matrix3D = _matrix.clone();
        inverse.invert();
        var q:Vector3D = inverse.transformVector(p);
        _matrix.copyRowTo(3, p);
        var a:Float = (q.x * p.x + q.y * p.y + q.z * p.z + q.w * p.w) / (cx * q.x + cy * q.y + cz * q.z + cw * q.w);
        _matrix.copyRowFrom(2, new Vector3D(cx * a, cy * a, cz * a, cw * a));
    }

}


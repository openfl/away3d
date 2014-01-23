/**
 * ...
 */
package away3d.tools.helpers.data;

import flash.geom.Matrix;
import flash.geom.Matrix3D;

class ParticleGeometryTransform {
    public var vertexTransform(get_vertexTransform, set_vertexTransform):Matrix3D;
    public var UVTransform(get_UVTransform, set_UVTransform):Matrix;
    public var invVertexTransform(get_invVertexTransform, never):Matrix3D;

    private var _defaultVertexTransform:Matrix3D;
    private var _defaultInvVertexTransform:Matrix3D;
    private var _defaultUVTransform:Matrix;

    public function new() {
    }

    public function set_vertexTransform(value:Matrix3D):Matrix3D {
        _defaultVertexTransform = value;
        _defaultInvVertexTransform = value.clone();
        _defaultInvVertexTransform.invert();
        _defaultInvVertexTransform.transpose();
        return value;
    }

    public function set_UVTransform(value:Matrix):Matrix {
        _defaultUVTransform = value;
        return value;
    }

    public function get_UVTransform():Matrix {
        return _defaultUVTransform;
    }

    public function get_vertexTransform():Matrix3D {
        return _defaultVertexTransform;
    }

    public function get_invVertexTransform():Matrix3D {
        return _defaultInvVertexTransform;
    }

}


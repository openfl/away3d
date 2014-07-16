package openfl.display3D;

#if display
extern class Context3D extends openfl.events.EventDispatcher {
    var driverInfo(default,null) : String;
    var enableErrorChecking : Bool;
    function clear(red : Float = 0, green : Float = 0, blue : Float = 0, alpha : Float = 1, depth : Float = 1, stencil : UInt = 0, mask : UInt = 0xFFFFFFFF) : Void;
    function configureBackBuffer(width : Int, height : Int, antiAlias : Int, enableDepthAndStencil : Bool = true, wantsBestResolution : Bool = false) : Void;
    function createCubeTexture(size : Int, format : Context3DTextureFormat, optimizeForRenderToTexture : Bool, streamingLevels : Int = 0) : openfl.display3D.textures.CubeTexture;
    function createIndexBuffer(numIndices : Int) : IndexBuffer3D;
    function createProgram() : Program3D;
    function createTexture(width : Int, height : Int, format : Context3DTextureFormat, optimizeForRenderToTexture : Bool, streamingLevels : Int = 0) : openfl.display3D.textures.Texture;
    function createVertexBuffer(numVertices : Int, data32PerVertex : Int) : VertexBuffer3D;
    function dispose(recreate : Bool = true) : Void;
    function drawToBitmapData(destination : openfl.display.BitmapData) : Void;
    function drawTriangles(indexBuffer : IndexBuffer3D, firstIndex : Int = 0, numTriangles : Int = -1) : Void;
    function present() : Void;
    function setBlendFactors(sourceFactor : Context3DBlendFactor, destinationFactor : Context3DBlendFactor) : Void;
    function setColorMask(red : Bool, green : Bool, blue : Bool, alpha : Bool) : Void;
    function setCulling(triangleFaceToCull : Context3DTriangleFace) : Void;
    function setDepthTest(depthMask : Bool, passCompareMode : Context3DCompareMode) : Void;
    function setProgram(program : Program3D) : Void;
    @:require(flash11_2) function setProgramConstantsFromByteArray(programType : Context3DProgramType, firstRegister : Int, numRegisters : Int, data : openfl.utils.ByteArray, byteArrayOffset : UInt) : Void;
    function setProgramConstantsFromMatrix(programType : Context3DProgramType, firstRegister : Int, matrix : openfl.geom.Matrix3D, transposedMatrix : Bool = false) : Void;
    function setProgramConstantsFromVector(programType : Context3DProgramType, firstRegister : Int, data : openfl.Vector<Float>, numRegisters : Int = -1) : Void;
    function setRenderToBackBuffer() : Void;
    function setRenderToTexture(texture : openfl.display3D.textures.TextureBase, enableDepthAndStencil : Bool = false, antiAlias : Int = 0, surfaceSelector : Int = 0) : Void;
    @:require(flash11_6) function setSamplerStateAt(sampler : Int, wrap : Context3DWrapMode, filter : Context3DTextureFilter, mipfilter : Context3DMipFilter) : Void;
    function setScissorRectangle(rectangle : openfl.geom.Rectangle) : Void;
    function setStencilActions(?triangleFace : Context3DTriangleFace, ?compareMode : Context3DCompareMode, ?actionOnBothPass : Context3DStencilAction, ?actionOnDepthFail : Context3DStencilAction, ?actionOnDepthPassStencilFail : Context3DStencilAction) : Void;
    function setStencilReferenceValue(referenceValue : UInt, readMask : UInt = 255, writeMask : UInt = 255) : Void;
    function setTextureAt(sampler : Int, texture : openfl.display3D.textures.TextureBase) : Void;
    function setVertexBufferAt(index : Int, buffer : VertexBuffer3D, bufferOffset : Int = 0, ?format : Context3DVertexBufferFormat) : Void;
}
#end
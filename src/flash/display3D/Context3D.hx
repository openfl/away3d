/****
* 
****/

package flash.display3D;
#if (flash || display)
@:final extern class Context3D extends flash.events.EventDispatcher {
    var driverInfo(default,null) : String;
    var enableErrorChecking : Bool;
    function clear(red : Float = 0, green : Float = 0, blue : Float = 0, alpha : Float = 1, depth : Float = 1, stencil : UInt = 0, mask : UInt = 0xFFFFFFFF) : Void;
    function configureBackBuffer(width : Int, height : Int, antiAlias : Int, enableDepthAndStencil : Bool = true, wantsBestResolution : Bool = false) : Void;
    function createCubeTexture(size : Int, format : Context3DTextureFormat, optimizeForRenderToTexture : Bool, streamingLevels : Int = 0) : flash.display3D.textures.CubeTexture;
    function createIndexBuffer(numIndices : Int) : IndexBuffer3D;
    function createProgram() : Program3D;
    function createTexture(width : Int, height : Int, format : Context3DTextureFormat, optimizeForRenderToTexture : Bool, streamingLevels : Int = 0) : flash.display3D.textures.Texture;
    function createVertexBuffer(numVertices : Int, data32PerVertex : Int) : VertexBuffer3D;
    function dispose(recreate : Bool = true) : Void;
    function drawToBitmapData(destination : flash.display.BitmapData) : Void;
    function drawTriangles(indexBuffer : IndexBuffer3D, firstIndex : Int = 0, numTriangles : Int = -1) : Void;
    function present() : Void;
    function setBlendFactors(sourceFactor : Context3DBlendFactor, destinationFactor : Context3DBlendFactor) : Void;
    function setColorMask(red : Bool, green : Bool, blue : Bool, alpha : Bool) : Void;
    function setCulling(triangleFaceToCull : Context3DTriangleFace) : Void;
    function setDepthTest(depthMask : Bool, passCompareMode : Context3DCompareMode) : Void;
    function setProgram(program : Program3D) : Void;
    @:require(flash11_2) function setProgramConstantsFromByteArray(programType : Context3DProgramType, firstRegister : Int, numRegisters : Int, data : flash.utils.ByteArray, byteArrayOffset : UInt) : Void;
    function setProgramConstantsFromMatrix(programType : Context3DProgramType, firstRegister : Int, matrix : flash.geom.Matrix3D, transposedMatrix : Bool = false) : Void;
    function setProgramConstantsFromVector(programType : Context3DProgramType, firstRegister : Int, data : flash.Vector<Float>, numRegisters : Int = -1) : Void;
    function setRenderToBackBuffer() : Void;
    function setRenderToTexture(texture : flash.display3D.textures.TextureBase, enableDepthAndStencil : Bool = false, antiAlias : Int = 0, surfaceSelector : Int = 0) : Void;
    @:require(flash11_6) function setSamplerStateAt(sampler : Int, wrap : Context3DWrapMode, filter : Context3DTextureFilter, mipfilter : Context3DMipFilter) : Void;
    function setScissorRectangle(rectangle : flash.geom.Rectangle) : Void;
    function setStencilActions(?triangleFace : Context3DTriangleFace, ?compareMode : Context3DCompareMode, ?actionOnBothPass : Context3DStencilAction, ?actionOnDepthFail : Context3DStencilAction, ?actionOnDepthPassStencilFail : Context3DStencilAction) : Void;
    function setStencilReferenceValue(referenceValue : UInt, readMask : UInt = 255, writeMask : UInt = 255) : Void;
    function setTextureAt(sampler : Int, texture : flash.display3D.textures.TextureBase) : Void;
    function setVertexBufferAt(index : Int, buffer : VertexBuffer3D, bufferOffset : Int = 0, ?format : Context3DVertexBufferFormat) : Void;
}
#else
import openfl.utils.Float32Array;
import flash.display3D.textures.CubeTexture;
import flash.display3D.textures.Texture;
import flash.display3D.textures.TextureBase;
import flash.display.BitmapData;
import openfl.display.OpenGLView;
import flash.errors.Error;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import openfl.gl.GL;
import openfl.gl.GLFramebuffer;
import openfl.gl.GLProgram;
import flash.utils.ByteArray;
import flash.Lib;
import flash.Vector;

#if html5
typedef Location = openfl.gl.GLUniformLocation;
#else
typedef Location = Int;
#end

class Context3D 
{
   public var driverInfo(default, null):String; // TODO
   public var enableErrorChecking:Bool; // TODO   ( use GL.getError() and GL.validateProgram(program) )

   private var currentProgram : Program3D;
   private var ogl:OpenGLView;

   // to mimic Stage3d behavior of keeping blending across frames:
   private var blendDestinationFactor:Int;
   private var blendEnabled:Bool;
   private var blendSourceFactor:Int;

   private var stencilCompareMode:Int;
   private var stencilRef:Int;
   private var stencilReadMask:Int;

   // to mimic Stage3d behavior of not allowing calls to drawTriangles between present and clear
   private var drawing:Bool;

    private var disposed : Bool;

    // to keep track of stuff to dispose when calling dispose
    private var vertexBuffersCreated : Array<VertexBuffer3D>;
    private var indexBuffersCreated : Array<IndexBuffer3D>;
    private var programsCreated : Array<Program3D>;
    private var texturesCreated : Array<TextureBase>;

    private var tmpFrameBuffer : GLFramebuffer;

    private var boundTextures : Map<Location,TextureBase>;
    private var samplerParameters : Map<Location,Array<Dynamic>>; //TODO : use Tupple3

   public function new() 
   {
        disposed = false;
        vertexBuffersCreated = new Array();
        indexBuffersCreated = new Array();
        programsCreated = new Array();
        texturesCreated = new Array();
        boundTextures = new Map();
        samplerParameters = new Map();

      var stage = Lib.current.stage;

      ogl = new OpenGLView();
      ogl.scrollRect = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
      ogl.width = stage.stageWidth;
      ogl.height = stage.stageHeight;
	  //todo html something 
		#if html5
		stage.addChild(ogl);
		#else
		stage.addChildAt(ogl, 0);
		#end
      
   }

   public function clear(red:Float = 0, green:Float = 0, blue:Float = 0, alpha:Float = 1, depth:Float = 1, stencil:Int = 0, mask:Int = Context3DClearMask.ALL):Void 
   {
      if (!drawing) 
      {
         updateBlendStatus();
         drawing = true;
      }


      GL.depthMask(true);
      GL.clearColor(red, green, blue, alpha);
      GL.clearDepth(depth);
      GL.clearStencil(stencil);

      GL.clear(mask);
   }

   public function configureBackBuffer(width:Int, height:Int, antiAlias:Int, enableDepthAndStencil:Bool = true):Void 
   {
        if (enableDepthAndStencil)
        {
            // TODO check whether this is kept across frame
            GL.enable(GL.DEPTH_TEST);
            GL.enable(GL.STENCIL_TEST);
        }

        // TODO use antiAlias parameter
        //GL.enable(GL.)
      ogl.scrollRect = new Rectangle(0, 0, width, height);
   }

   public function createCubeTexture(size:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int = 0):CubeTexture 
   {
        var texture = new flash.display3D.textures.CubeTexture (GL.createTexture (), size);     // TODO use format, optimizeForRenderToTexture and  streamingLevels?
        texturesCreated.push(texture);
        return texture;
   }

   public function createIndexBuffer(numIndices:Int):IndexBuffer3D 
   {
      var indexBuffer = new IndexBuffer3D(GL.createBuffer(), numIndices);
        indexBuffersCreated.push(indexBuffer);
        return indexBuffer;
   }

   public function createProgram():Program3D 
   {
      var program = new Program3D(GL.createProgram());
        programsCreated.push(program);
        return program;
   }

   public function createTexture(width:Int, height:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int = 0):flash.display3D.textures.Texture 
   {
       var texture = new flash.display3D.textures.Texture (GL.createTexture (), width, height);     // TODO use format, optimizeForRenderToTexture and  streamingLevels?
       texturesCreated.push(texture);
        return texture;
   }

   public function createVertexBuffer(numVertices:Int, data32PerVertex:Int):VertexBuffer3D 
   {
      var vertexBuffer = new VertexBuffer3D(GL.createBuffer(), numVertices, data32PerVertex);
        vertexBuffersCreated.push(vertexBuffer);
        return vertexBuffer;
   }

   // TODO simulate context loss by recreating a context3d and dispatch event on Stage3d(see Adobe Doc)
    // TODO add error on other method when context3d is disposed
   public function dispose():Void 
   {
        for(vertexBuffer in vertexBuffersCreated)
        {
            vertexBuffer.dispose();
        }
        vertexBuffersCreated = null;

        for(indexBuffer in indexBuffersCreated)
        {
            indexBuffer.dispose();
        }
        indexBuffersCreated = null;

        for(program in programsCreated)
        {
            program.dispose();
        }
        programsCreated = null;

        boundTextures = null;
        samplerParameters = null;

        for(texture in texturesCreated)
        {
            texture.dispose();
        }
        texturesCreated = null;

        if(tmpFrameBuffer != null){
            GL.deleteFramebuffer(tmpFrameBuffer);
            tmpFrameBuffer = null;
        }


        disposed = true;
   }

   public function drawToBitmapData(destination:BitmapData):Void 
   {
      // TODO
   }

   public function drawTriangles(indexBuffer:IndexBuffer3D, firstIndex:Int = 0, numTriangles:Int = -1):Void 
   {
      if (!drawing) 
      {
         throw new Error("Need to clear before drawing if the buffer has not been cleared since the last present() call.");
      }

      var numIndices;

      if (numTriangles == -1) 
      {
         numIndices = indexBuffer.numIndices;

      } else 
      {
         numIndices = numTriangles * 3;
      }

      var byteOffset = firstIndex * 2;

      GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer.glBuffer);
      GL.drawElements(GL.TRIANGLES, numIndices, GL.UNSIGNED_SHORT, byteOffset);
   }

   public function present():Void 
   {
      drawing = false;
      GL.useProgram(null);
      
      GL.bindBuffer(GL.ARRAY_BUFFER, null);
   }

   // TODO: Type as Context3DBlendFactor instead of Int?
   public function setBlendFactors(sourceFactor:Int, destinationFactor:Int):Void 
   {
      blendEnabled = true;
      blendSourceFactor = sourceFactor;
      blendDestinationFactor = destinationFactor;

      updateBlendStatus();
   }

   public function setColorMask(red:Bool, green:Bool, blue:Bool, alpha:Bool):Void 
   {
      GL.colorMask(red, green, blue, alpha);
   }

   // TODO: Type as Context3DTriangleFace instead of Int?
   public function setCulling(triangleFaceToCull:Int):Void 
   {
      if (triangleFaceToCull == Context3DTriangleFace.NONE)
      {
            GL.disable(GL.CULL_FACE);
        }else
        {
            GL.cullFace(triangleFaceToCull);
            GL.enable(GL.CULL_FACE);
        }
   }

   // TODO: Type as Context3DCompareMode insteaad of Int?
   public function setDepthTest(depthMask:Bool, passCompareMode:Int):Void 
   {
      GL.depthFunc(passCompareMode);
      GL.depthMask(depthMask);
   }

   public function setProgram(program3D:Program3D):Void 
   {
      var glProgram:GLProgram = null;

      if (program3D != null) 
      {
         glProgram = program3D.glProgram;
      }

      GL.useProgram(glProgram);
      currentProgram = program3D;
      //TODO reset bound textures, buffers... ?
      // Or maybe we should have arrays and map for each program so we can switch them while keeping the bounded texture and variable?
   }

    private function getUniformLocationNameFromAgalRegisterIndex(programType : Context3DProgramType, firstRegister : Int) : String
    {
      if (programType == Context3DProgramType.VERTEX) 
      {
         return "vc" + firstRegister;

      } else if (programType == Context3DProgramType.FRAGMENT) 
      {
         return "fc" + firstRegister;
      }

        throw "Program Type " + programType + " not supported";
    }

    public function setProgramConstantsFromByteArray(programType:Context3DProgramType, firstRegister:Int, numRegisters:Int, data:ByteArray, byteArrayOffset:Int):Void 
    {
        data.position = byteArrayOffset;
        for(i in 0...numRegisters)
        {
            var locationName = getUniformLocationNameFromAgalRegisterIndex(programType, firstRegister + i);
            setGLSLProgramConstantsFromByteArray(locationName,data);
        }
   }

   public function setProgramConstantsFromMatrix(programType:Context3DProgramType, firstRegister:Int, matrix:Matrix3D, transposedMatrix:Bool = false):Void 
   {
      var locationName = getUniformLocationNameFromAgalRegisterIndex(programType, firstRegister);
      //setGLSLProgramConstantsFromMatrix(locationName,matrix,transposedMatrix);
      setProgramConstantsFromVector(programType, firstRegister, matrix.rawData, 16);
   }

   public function setProgramConstantsFromVector(programType:Context3DProgramType, firstRegister:Int, data:Vector<Float>, numRegisters:Int = -1):Void 
   {
        for(i in 0...numRegisters)
        {
            var currentIndex = i * 4;
            var locationName = getUniformLocationNameFromAgalRegisterIndex(programType, firstRegister + i);
            setGLSLProgramConstantsFromVector4(locationName,data,currentIndex);
        }
   }

    public function setGLSLProgramConstantsFromByteArray(locationName : String, data:ByteArray, byteArrayOffset : Int = -1):Void 
    {
        if (byteArrayOffset != -1)
        {
            data.position = byteArrayOffset;
        }
        var location = GL.getUniformLocation(currentProgram.glProgram, locationName);
        GL.uniform4f(location, data.readFloat(),data.readFloat(),data.readFloat(),data.readFloat());
    }

    public function setGLSLProgramConstantsFromMatrix(locationName : String, matrix:Matrix3D, transposedMatrix:Bool = false):Void 
    {
        var location = GL.getUniformLocation(currentProgram.glProgram, locationName);
        GL.uniformMatrix3D(location, !transposedMatrix, matrix);
    }

    public function setGLSLProgramConstantsFromVector4(locationName : String, data:Vector<Float>, startIndex : Int = 0):Void 
    {
        var location = GL.getUniformLocation(currentProgram.glProgram, locationName);
        GL.uniform4f(location, data[startIndex],data[startIndex+1],data[startIndex+2],data[startIndex+3]);
    }

   // TODO: Conform to API?
   public function setRenderMethod(func:flash.events.Event -> Void):Void
   {
      ogl.render = function(rect : Rectangle) func(null);
   }

   public function removeRenderMethod(func:flash.events.Event -> Void):Void{
      ogl.render = null;
   }

   public function setRenderToBackBuffer ():Void {

        GL.bindFramebuffer(GL.FRAMEBUFFER, null);
        //GL.viewport(Std.int(ogl.scrollRect.x),Std.int(ogl.scrollRect.y),Std.int(ogl.scrollRect.width),Std.int(ogl.scrollRect.height));

    }

    // TODO : currently does not work (frameBufferStatus always return zero)
    public function setRenderToTexture (texture:TextureBase, enableDepthAndStencil:Bool = false, antiAlias:Int = 0, surfaceSelector:Int = 0):Void {

        // TODO antiAlias (could this be achieved using a texture multiple of the screensize ?)
        // TODO surfaceSelector

        if(tmpFrameBuffer == null){
            tmpFrameBuffer = GL.createFramebuffer();
        }
        GL.bindFramebuffer(GL.FRAMEBUFFER, tmpFrameBuffer);


        GL.bindTexture(GL.TEXTURE_2D, texture.glTexture);


        //TODO ? poor filterring needed  (http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-14-render-to-texture/)?
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);


        GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture.glTexture, 0);

        //TODO :
        //        if(enableDepthAndStencil){
        //            var depthRenderBuffer = GL.createRenderbuffer();
        //            GL.bindRenderbuffer(GL.RENDERBUFFER, depthRenderBuffer);
        //            GL.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT, texture.width, texture.heigth);
        //            GL.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, depthRenderBuffer);
        //        }

        var frameBufferStatus = GL.checkFramebufferStatus(GL.FRAMEBUFFER);
        switch(frameBufferStatus){
            case GL.FRAMEBUFFER_COMPLETE: trace("FRAMEBUFFER_COMPLETE");
            case GL.FRAMEBUFFER_INCOMPLETE_ATTACHMENT: trace("FRAMEBUFFER_INCOMPLETE_ATTACHMENT");
            case GL.FRAMEBUFFER_INCOMPLETE_DIMENSIONS: trace("FRAMEBUFFER_INCOMPLETE_DIMENSIONS");
            case GL.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: trace("FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT");
            case GL.FRAMEBUFFER_UNSUPPORTED : trace("FRAMEBUFFER_UNSUPPORTED");
            default : trace("frameBufferStatus " + frameBufferStatus);
        }


        // Render to our framebuffer
        //GL.bindFramebuffer(GL.FRAMEBUFFER, tmpFrameBuffer);

        //TODO viewport ? with other textures type
        //var texture2d : Texture= cast(texture);
        //GL.viewport(0,0,texture2d.width,texture2d.height);


    }

   public function setSamplerStateAt(sampler:Int, wrap:Context3DWrapMode, filter:Context3DTextureFilter, mipfilter:Context3DMipFilter):Void
   {
        //TODO for flash < 11.6 : patch the AGAL (using specific opcodes) and rebuild the program?
        var locationName =  "fs" + sampler;
        setGLSLSamplerStateAt(locationName, wrap, filter, mipfilter);
   }

   public function setGLSLSamplerStateAt(locationName:String, wrap:Context3DWrapMode, filter:Context3DTextureFilter, mipfilter:Context3DMipFilter):Void
   {
        var location = GL.getUniformLocation (currentProgram.glProgram, locationName);


        samplerParameters.set(location,[wrap,filter,mipfilter]);

        var texture = boundTextures.get(location);

        if(texture != null)
        {
            setTextureParameters(texture,wrap, filter, mipfilter);
        }


   }

   private function setTextureParameters(texture : TextureBase, wrap : Context3DWrapMode, filter : Context3DTextureFilter, mipfilter : Context3DMipFilter):Void{

       if (Std.is (texture, flash.display3D.textures.Texture)) {

            GL.bindTexture(GL.TEXTURE_2D, cast(texture, flash.display3D.textures.Texture).glTexture);

            switch(wrap){
                case Context3DWrapMode.CLAMP:
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
                case Context3DWrapMode.REPEAT:
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.REPEAT);
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.REPEAT);
            }


            switch(filter){
                case Context3DTextureFilter.LINEAR:
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);

                case Context3DTextureFilter.NEAREST:
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
            }

            //TODO CHECK the mipmap filters
            switch(mipfilter){
                case Context3DMipFilter.MIPLINEAR:
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_LINEAR);

                case Context3DMipFilter.MIPNEAREST:
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST_MIPMAP_NEAREST);

                case Context3DMipFilter.MIPNONE:
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);

            }


        }else if (Std.is (texture, flash.display3D.textures.CubeTexture)) {
            GL.bindTexture(GL.TEXTURE_CUBE_MAP, cast(texture, flash.display3D.textures.CubeTexture).glTexture);

            switch(wrap){
                case Context3DWrapMode.CLAMP:
                    GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
                    GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
                case Context3DWrapMode.REPEAT:
                    GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_S, GL.REPEAT);
                    GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_WRAP_T, GL.REPEAT);
            }


            switch(filter){
                case Context3DTextureFilter.LINEAR:
                    GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_MAG_FILTER, GL.LINEAR);

                case Context3DTextureFilter.NEAREST:
                    GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
            }

            //TODO CHECK the mipmap filters
            switch(mipfilter){
                case Context3DMipFilter.MIPLINEAR:
                    GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_LINEAR);

                case Context3DMipFilter.MIPNEAREST:
                    GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_MIN_FILTER, GL.NEAREST_MIPMAP_NEAREST);

                case Context3DMipFilter.MIPNONE:
                    GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_MIN_FILTER, GL.NEAREST);

            }

        }else{
            throw "Texture of type " + Type.getClassName(Type.getClass(texture)) + " not supported yet";
        }
   }

   public function setScissorRectangle(rectangle:Rectangle):Void 
   {
        // TODO test it
		if (rectangle == null) {
			 
			return;
		}
        GL.scissor(Std.int(rectangle.x), Std.int(rectangle.y), Std.int(rectangle.width), Std.int(rectangle.height));
   }

   public function setStencilActions(?triangleFace:Int, ?compareMode:Int, ?actionOnBothPass:Int, ?actionOnDepthFail:Int, ?actionOnDepthPassStencilFail:Int):Void 
   {
      this.stencilCompareMode = compareMode;
      GL.stencilOp(actionOnBothPass, actionOnDepthFail, actionOnDepthPassStencilFail);
      GL.stencilFunc(stencilCompareMode, stencilRef, stencilReadMask);
   }

   public function setStencilReferenceValue(referenceValue:Int, readMask:Int = 0xFF, writeMask:Int = 0xFF):Void 
   {
      stencilReadMask = readMask;
      stencilRef = referenceValue;

      GL.stencilFunc(stencilCompareMode, stencilRef, stencilReadMask);
      GL.stencilMask(writeMask);
   }

     public function setTextureAt (sampler:Int, texture:TextureBase):Void {
        var locationName =  "fs" + sampler;
        setGLSLTextureAt(locationName, texture, sampler);
    }


    public function setGLSLTextureAt (locationName:String, texture:TextureBase, textureIndex : Int):Void {

        var location = GL.getUniformLocation (currentProgram.glProgram, locationName);
        switch(textureIndex){
            case 0 : GL.activeTexture (GL.TEXTURE0);
            case 1 : GL.activeTexture (GL.TEXTURE1);
            case 2 : GL.activeTexture (GL.TEXTURE2);
            case 3 : GL.activeTexture (GL.TEXTURE3);
            case 4 : GL.activeTexture (GL.TEXTURE4);
            case 5 : GL.activeTexture (GL.TEXTURE5);
            case 6 : GL.activeTexture (GL.TEXTURE6);
            case 7 : GL.activeTexture (GL.TEXTURE7);
            // TODO more?
            default: throw "Does not support texture8 or more";
        }

        if ( texture==null )
        {
            GL.bindTexture( GL.TEXTURE_2D, null );
            GL.bindTexture( GL.TEXTURE_CUBE_MAP, null );
            return;
        } 

        if ( Std.is (texture, flash.display3D.textures.Texture) )
        {
            GL.bindTexture(GL.TEXTURE_2D, cast(texture, flash.display3D.textures.Texture).glTexture);
            GL.uniform1i(location, textureIndex);
            boundTextures.set(location, texture);
        } 
        else if ( Std.is(texture, CubeTexture) )
        {        
            GL.bindTexture( GL.TEXTURE_CUBE_MAP, cast(texture, flash.display3D.textures.CubeTexture).glTexture );
            GL.uniform1i( location, textureIndex );
            boundTextures.set(location, texture);
        }
        else {
            throw "Texture of type " + Type.getClassName(Type.getClass(texture)) + " not supported yet";
        }

        var parameters = samplerParameters.get(location);
        if(parameters != null){
            setTextureParameters(texture, parameters[0], parameters[1], parameters[2]);
        }else{
            setTextureParameters(texture, Context3DWrapMode.REPEAT, Context3DTextureFilter.NEAREST, Context3DMipFilter.MIPNONE);
        }


    }

    public function setVertexBufferAt(index:Int,buffer:VertexBuffer3D, bufferOffset:Int = 0, ?format:Context3DVertexBufferFormat):Void 
    {
        var locationName = "va" + index;
        setGLSLVertexBufferAt(locationName, buffer, bufferOffset, format);
    }

   public function setGLSLVertexBufferAt(locationName, buffer:VertexBuffer3D, bufferOffset:Int = 0, ?format:Context3DVertexBufferFormat):Void 
   {
      var location = GL.getAttribLocation(currentProgram.glProgram,locationName);

      if (buffer == null)
      {
        if ( location > -1 ) {
            GL.disableVertexAttribArray( location );
            GL.bindBuffer(GL.ARRAY_BUFFER, null);
        }
        return;
      }

      GL.bindBuffer(GL.ARRAY_BUFFER, buffer.glBuffer);

      var dimension = 4;
      var type = GL.FLOAT;
      var numBytes = 4;

      if (format == Context3DVertexBufferFormat.BYTES_4) 
      {
         dimension = 4;
         type = GL.FLOAT;
         numBytes = 4;

      } else if (format == Context3DVertexBufferFormat.FLOAT_1) 
      {
         dimension = 1;
         type = GL.FLOAT;
         numBytes = 4;

      } else if (format == Context3DVertexBufferFormat.FLOAT_2) 
      {
         dimension = 2;
         type = GL.FLOAT;
         numBytes = 4;

      } else if (format == Context3DVertexBufferFormat.FLOAT_3) 
      {
         dimension = 3;
         type = GL.FLOAT;
         numBytes = 4;

      } else if (format == Context3DVertexBufferFormat.FLOAT_4) 
      {
         dimension = 4;
         type = GL.FLOAT;
         numBytes = 4;

      } else 
      {
         throw "Buffer format " + format + " is not supported";
      }

      GL.enableVertexAttribArray(location);
      GL.vertexAttribPointer(location, dimension, type, false, buffer.data32PerVertex * numBytes, bufferOffset * numBytes);
   }

    //TODO do the same for other states ?
   private function updateBlendStatus():Void 
   {
      if (blendEnabled) 
      {
         GL.enable(GL.BLEND);
         GL.blendEquation(GL.FUNC_ADD);
         GL.blendFunc(blendSourceFactor, blendDestinationFactor);

      } else 
      {
         GL.disable(GL.BLEND);
      }
   }
}

#end
package openfl.display3D;

import haxe.ds.IntMap.IntMap;
import openfl.gl.GLRenderbuffer;
import openfl.utils.Float32Array;
import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.RectangleTexture;
import openfl.display3D.textures.TextureBase;
import openfl.display.BitmapData;
import openfl.display.OpenGLView;
import openfl.errors.Error;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.gl.GL;
import openfl.gl.GLFramebuffer;
import openfl.gl.GLProgram;
import openfl.utils.ByteArray;
import openfl.Lib;

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

    private var framebuffer : GLFramebuffer;
	private var renderbuffer : GLRenderbuffer;
    private var depthbuffer : GLRenderbuffer;
    private var stencilbuffer : GLRenderbuffer;
    private var defaultFrameBuffer : GLFramebuffer;

    private var samplerParameters :Array<SamplerState>; //TODO : use Tupple3
	private var scrollRect:Rectangle;
	public static var MAX_SAMPLERS:Int = 8;
   
    public function new() 
    {
        disposed = false;
        vertexBuffersCreated = new Array();
        indexBuffersCreated = new Array();
        programsCreated = new Array();
        texturesCreated = new Array(); 
        samplerParameters = new Array<SamplerState>();
		for (  i in 0...MAX_SAMPLERS) {
			this.samplerParameters[ i ] = new SamplerState(); 
			this.samplerParameters[ i ].wrap = Context3DWrapMode.REPEAT;
			this.samplerParameters[ i ].filter = Context3DTextureFilter.LINEAR;
			this.samplerParameters[ i ].mipfilter =Context3DMipFilter.MIPNONE;
		}

        var stage = Lib.current.stage;

        ogl = new OpenGLView();
        ogl.scrollRect = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
        scrollRect = ogl.scrollRect.clone();
        ogl.width = stage.stageWidth;
        ogl.height = stage.stageHeight;
        
        //todo html something 
		//#if html5
		//stage.addChild(ogl);
		//#else
		stage.addChildAt(ogl, 0);
		//#end      
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
        ogl.scrollRect = new Rectangle(0, 0, width, height);
        scrollRect = ogl.scrollRect.clone();
        GL.viewport(Std.int(scrollRect.x),Std.int(scrollRect.y),Std.int(scrollRect.width),Std.int(scrollRect.height));
        #if ios
        defaultFrameBuffer = GL.getParameter(GL.FRAMEBUFFER_BINDING);
        #end
    }

    public function createCubeTexture(size:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int = 0):CubeTexture 
    {
        var texture = new openfl.display3D.textures.CubeTexture (GL.createTexture (), size);     // TODO use format, optimizeForRenderToTexture and  streamingLevels?
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

    public function createTexture(width:Int, height:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int = 0):openfl.display3D.textures.Texture 
    {
        var texture = new openfl.display3D.textures.Texture (GL.createTexture (), optimizeForRenderToTexture,width, height);     // TODO use format, optimizeForRenderToTexture and  streamingLevels?
        texturesCreated.push(texture);
        return texture;
    }

    public function createRectangleTexture(width:Int, height:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool):openfl.display3D.textures.RectangleTexture 
    {
        var texture = new openfl.display3D.textures.RectangleTexture(GL.createTexture(), optimizeForRenderToTexture, width, height);     // TODO use format, optimizeForRenderToTexture and  streamingLevels?
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
 
        samplerParameters = null;

        for(texture in texturesCreated)
        {
            texture.dispose();
        }
        texturesCreated = null;

        if(framebuffer != null){
            GL.deleteFramebuffer(framebuffer);
            framebuffer = null;
        }
		
        if(renderbuffer != null){
            GL.deleteRenderbuffer(renderbuffer);
            renderbuffer = null;
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
        GL.disable(GL.CULL_FACE);
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
            GL.enable(GL.CULL_FACE);
            switch (triangleFaceToCull) {
                case Context3DTriangleFace.FRONT:
                    GL.cullFace(GL.BACK);
                case Context3DTriangleFace.BACK:
                    GL.cullFace(GL.FRONT);
                case Context3DTriangleFace.FRONT_AND_BACK:
                    GL.cullFace(GL.FRONT_AND_BACK);
                default:
                    throw "Unknown Context3DTriangleFace type.";
            }
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
            glProgram = program3D.glProgram;

        GL.useProgram(glProgram);
        currentProgram = program3D;
        //TODO reset bound textures, buffers... ?
        // Or maybe we should have arrays and map for each program so we can switch them while keeping the bounded texture and variable?
    }

    private function getUniformLocationNameFromAgalRegisterIndex(programType : Context3DProgramType, firstRegister : Int) : String
    {
        if (programType == Context3DProgramType.VERTEX) {
            return "vc" + firstRegister;
        } else if (programType == Context3DProgramType.FRAGMENT) {
            return "fc" + firstRegister;
        }

        throw "Program Type " + programType + " not supported";
    }

    public function setProgramConstantsFromByteArray(programType:Context3DProgramType, firstRegister:Int, numRegisters:Int, data:ByteArray, byteArrayOffset:Int):Void 
    {
        data.position = byteArrayOffset;
        for (i in 0...numRegisters) {
            var locationName = getUniformLocationNameFromAgalRegisterIndex(programType, firstRegister + i);
            setGLSLProgramConstantsFromByteArray(locationName,data);
        }
    }

    public function setProgramConstantsFromMatrix(programType:Context3DProgramType, firstRegister:Int, matrix:Matrix3D, transposedMatrix:Bool = false):Void 
    {
        var locationName = getUniformLocationNameFromAgalRegisterIndex(programType, firstRegister);
        setProgramConstantsFromVector(programType, firstRegister, matrix.rawData, 16);
    }

    public function setProgramConstantsFromVector(programType:Context3DProgramType, firstRegister:Int, data:Array<Float>, numRegisters:Int = 1):Void 
    {
        for (i in 0...numRegisters)
        {
            var currentIndex = i * 4;
            var locationName = getUniformLocationNameFromAgalRegisterIndex(programType, firstRegister + i);
            setGLSLProgramConstantsFromVector4(locationName,data,currentIndex);
        }
    }

    public function setGLSLProgramConstantsFromByteArray(locationName : String, data:ByteArray, byteArrayOffset : Int = 0):Void 
    {
        data.position = byteArrayOffset;
        var location = GL.getUniformLocation(currentProgram.glProgram, locationName);
        GL.uniform4f(location, data.readFloat(), data.readFloat(), data.readFloat(), data.readFloat());
    }

    public function setGLSLProgramConstantsFromMatrix(locationName : String, matrix:Matrix3D, transposedMatrix:Bool = false):Void 
    {
        var location = GL.getUniformLocation(currentProgram.glProgram, locationName);
        GL.uniformMatrix3D(location, !transposedMatrix, matrix);
    }

    public function setGLSLProgramConstantsFromVector4(locationName : String, data:Array<Float>, startIndex : Int = 0):Void 
    {
        var location = GL.getUniformLocation(currentProgram.glProgram, locationName);
        GL.uniform4f(location, data[startIndex],data[startIndex+1],data[startIndex+2],data[startIndex+3]);
    }

    // TODO: Conform to API?
    public function setRenderMethod(func:openfl.events.Event -> Void):Void
    {
        ogl.render = function(rect : Rectangle) func(null);
    }

    public function removeRenderMethod(func:openfl.events.Event -> Void):Void{
        ogl.render = null;
    }

    public function setRenderToBackBuffer ():Void {
        GL.bindFramebuffer(GL.FRAMEBUFFER, defaultFrameBuffer );
    }

    // TODO : currently does not work (framebufferStatus always return zero)
    public function setRenderToTexture (texture:TextureBase, enableDepthAndStencil:Bool = false, antiAlias:Int = 0, surfaceSelector:Int = 0):Void {		 
        
        if (framebuffer == null) 
            framebuffer = GL.createFramebuffer();

        GL.bindFramebuffer(GL.FRAMEBUFFER, framebuffer);

        if (renderbuffer == null) 
            renderbuffer = GL.createRenderbuffer();

        GL.bindRenderbuffer(GL.RENDERBUFFER, renderbuffer);
        #if ios
        GL.renderbufferStorage(GL.RENDERBUFFER, 0x88F0, texture.width, texture.height);
        #else
        GL.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_STENCIL, texture.width, texture.height);
        #end

        GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture.glTexture, 0);

        if (enableDepthAndStencil) {
            GL.enable(GL.DEPTH_TEST);
            GL.enable(GL.STENCIL_TEST);

            GL.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_STENCIL_ATTACHMENT, GL.RENDERBUFFER, renderbuffer);
        }

        GL.bindTexture(GL.TEXTURE_2D, texture.glTexture);
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, texture.width, texture.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);

        GL.viewport(0, 0, texture.width, texture.height); 
    }

    public function setSamplerStateAt(sampler:Int, wrap:Context3DWrapMode, filter:Context3DTextureFilter, mipfilter:Context3DMipFilter):Void
    {
        //TODO for flash < 11.6 : patch the AGAL (using specific opcodes) and rebuild the program? 

    	if (0 <= sampler && sampler <  MAX_SAMPLERS) {
    		this.samplerParameters[ sampler ].wrap = wrap;
    		this.samplerParameters[ sampler ].filter = filter;
    		this.samplerParameters[ sampler ].mipfilter = mipfilter;
    	} else {
    		throw "Sampler is out of bounds.";
    	}
    }

    private function setTextureParameters(texture : TextureBase, wrap : Context3DWrapMode, filter : Context3DTextureFilter, mipfilter : Context3DMipFilter):Void{

        if (Std.is (texture, openfl.display3D.textures.Texture)) {

            GL.bindTexture(GL.TEXTURE_2D, cast(texture, openfl.display3D.textures.Texture).glTexture);
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
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR); 
            } 
        } else if (Std.is (texture, openfl.display3D.textures.RectangleTexture)) {
            
            GL.bindTexture(GL.TEXTURE_2D, cast(texture, openfl.display3D.textures.RectangleTexture).glTexture);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
            
            switch(filter){
                case Context3DTextureFilter.LINEAR:
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);

                case Context3DTextureFilter.NEAREST:
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
            }

            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        } else if (Std.is (texture, openfl.display3D.textures.CubeTexture)) {
            GL.bindTexture(GL.TEXTURE_CUBE_MAP, cast(texture, openfl.display3D.textures.CubeTexture).glTexture);

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
                    GL.texParameteri(GL.TEXTURE_CUBE_MAP, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
            }

        } else {
            throw "Texture of type " + Type.getClassName(Type.getClass(texture)) + " not supported yet";
        }
    }

    public function setScissorRectangle(rectangle:Rectangle):Void 
    {
        // TODO test it
    	if (rectangle == null) {
    		GL.disable(GL.SCISSOR_TEST);
    		return;
    	}

    	GL.enable(GL.SCISSOR_TEST);
        GL.scissor(Std.int(rectangle.x), Std.int(scrollRect.height - rectangle.y - rectangle.height), Std.int(rectangle.width), Std.int(rectangle.height));
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

        switch(textureIndex) {
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

        if ( texture==null ) {
            GL.bindTexture( GL.TEXTURE_2D, null );
            GL.bindTexture( GL.TEXTURE_CUBE_MAP, null );
            return;
        } 

        var location = GL.getUniformLocation (currentProgram.glProgram, locationName);
        if ( Std.is (texture, openfl.display3D.textures.Texture) ) {
            GL.bindTexture(GL.TEXTURE_2D, cast(texture, openfl.display3D.textures.Texture).glTexture);
            GL.uniform1i(location, textureIndex);  

        } else if ( Std.is(texture, RectangleTexture) ) {
            GL.bindTexture(GL.TEXTURE_2D, cast(texture, openfl.display3D.textures.RectangleTexture).glTexture);
            GL.uniform1i(location, textureIndex);
            
        } else if ( Std.is(texture, CubeTexture) ) {        
            GL.bindTexture( GL.TEXTURE_CUBE_MAP, cast(texture, openfl.display3D.textures.CubeTexture).glTexture );
            GL.uniform1i( location, textureIndex ); 
        } else {
            throw "Texture of type " + Type.getClassName(Type.getClass(texture)) + " not supported yet";
        }

        var parameters:SamplerState= samplerParameters[textureIndex];
        if (parameters != null) {
            setTextureParameters(texture, parameters.wrap, parameters.filter, parameters.mipfilter);
        } else {
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
        var location = (currentProgram!=null && currentProgram.glProgram!=null) ? GL.getAttribLocation(currentProgram.glProgram,locationName) : -1;
        if (buffer == null) {
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

        if (format == Context3DVertexBufferFormat.BYTES_4) {
            dimension = 4;
            type = GL.FLOAT;
            numBytes = 4;
        } else if (format == Context3DVertexBufferFormat.FLOAT_1) {
            dimension = 1;
            type = GL.FLOAT;
            numBytes = 4;
        } else if (format == Context3DVertexBufferFormat.FLOAT_2) {
            dimension = 2;
            type = GL.FLOAT;
            numBytes = 4;
        } else if (format == Context3DVertexBufferFormat.FLOAT_3) {
            dimension = 3;
            type = GL.FLOAT;
            numBytes = 4;
        } else if (format == Context3DVertexBufferFormat.FLOAT_4) {
            dimension = 4;
            type = GL.FLOAT;
            numBytes = 4;
        } else {
            throw "Buffer format " + format + " is not supported";
        }

        GL.enableVertexAttribArray(location);
        GL.vertexAttribPointer(location, dimension, type, false, buffer.data32PerVertex * numBytes, bufferOffset * numBytes);
    }

    //TODO do the same for other states ?
    private function updateBlendStatus():Void 
    {
        if (blendEnabled) {
            GL.enable(GL.BLEND);
            GL.blendEquation(GL.FUNC_ADD);
            GL.blendFunc(blendSourceFactor, blendDestinationFactor);
        } else {
            GL.disable(GL.BLEND);
        }
    }    
}

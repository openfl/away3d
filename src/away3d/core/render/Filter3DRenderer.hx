/**
 */
package away3d.core.render;


import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.VertexBuffer3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Context3D;
import away3d.cameras.Camera3D;
import away3d.filters.Filter3DBase;
import flash.events.Event;
import away3d.core.managers.Stage3DProxy;
import away3d.core.managers.RTTBufferManager;
import flash.display3D.textures.Texture;
import flash.Vector;
import away3d.filters.tasks.Filter3DTaskBase;
class Filter3DRenderer {
    public var requireDepthRender(get_requireDepthRender, never):Bool;
    public var filters(get_filters, set_filters):Array<Dynamic>;

    private var _filters:Array<Dynamic>;
    private var _tasks:Vector<Filter3DTaskBase>;
    private var _filterTasksInvalid:Bool;
    private var _mainInputTexture:Texture;
    private var _requireDepthRender:Bool;
    private var _rttManager:RTTBufferManager;
    private var _stage3DProxy:Stage3DProxy;
    private var _filterSizesInvalid:Bool;

    public function new(stage3DProxy:Stage3DProxy) {
        _filterSizesInvalid = true;
        _stage3DProxy = stage3DProxy;
        _rttManager = RTTBufferManager.getInstance(stage3DProxy);
        _rttManager.addEventListener(Event.RESIZE, onRTTResize);
    }

    private function onRTTResize(event:Event):Void {
        _filterSizesInvalid = true;
    }

    public function get_requireDepthRender():Bool {
        return _requireDepthRender;
    }

    public function getMainInputTexture(stage3DProxy:Stage3DProxy):Texture {
        if (_filterTasksInvalid) updateFilterTasks(stage3DProxy);
        return _mainInputTexture;
    }

    public function get_filters():Array<Dynamic> {
        return _filters;
    }

    public function set_filters(value:Array<Dynamic>):Array<Dynamic> {
        _filters = value;
        _filterTasksInvalid = true;
        _requireDepthRender = false;
        if (_filters == null) return null;
        var i:Int = 0;
        while (i < _filters.length) {
            if (!_requireDepthRender)
                _requireDepthRender = cast((_filters[i].requireDepthRender != null), Bool);
            ++i;
        }
        _filterSizesInvalid = true;
        return value;
    }

    private function updateFilterTasks(stage3DProxy:Stage3DProxy):Void {
        var len:Int;
        if (_filterSizesInvalid) updateFilterSizes();
        if (_filters == null) {
            _tasks = null;
            return ;
        }
        _tasks = new Vector<Filter3DTaskBase>();
        len = _filters.length - 1;
        var filter:Filter3DBase;
        var i:Int = 0;
        while (i <= len) {
// make sure all internal tasks are linked together
            filter = _filters[i];
            filter.setRenderTargets(i == (len) ? null : cast((_filters[i + 1]), Filter3DBase).getMainInputTexture(stage3DProxy), stage3DProxy);
            _tasks = _tasks.concat(filter.tasks);
            ++i;
        }
        _mainInputTexture = _filters[0].getMainInputTexture(stage3DProxy);
    }

    public function render(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void {
        var len:Int;
        var i:Int;
        var task:Filter3DTaskBase;
        var context:Context3D = stage3DProxy.context3D;
        var indexBuffer:IndexBuffer3D = _rttManager.indexBuffer;
        var vertexBuffer:VertexBuffer3D = _rttManager.renderToTextureVertexBuffer;
        if (_filters == null) return;
        if (_filterSizesInvalid) updateFilterSizes();
        if (_filterTasksInvalid) updateFilterTasks(stage3DProxy);
        len = _filters.length;
        i = 0;
        while (i < len) {
            _filters[i].update(stage3DProxy, camera3D);
            ++i;
        }
        len = _tasks.length;
        if (len > 1) {
            context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
            context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
        }
        i = 0;
        while (i < len) {
            task = _tasks[i];
            stage3DProxy.setRenderTarget(task.target);
			context.setProgram(task.getProgram3D(stage3DProxy));
            if (task.target == null) {
                stage3DProxy.scissorRect = null;
                vertexBuffer = _rttManager.renderToScreenVertexBuffer;
                context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
                context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
            }
            context.setTextureAt(0, task.getMainInputTexture(stage3DProxy));            
            context.clear(0.0, 0.0, 0.0, 0.0);
            task.activate(stage3DProxy, camera3D, depthTexture);
            context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
            context.drawTriangles(indexBuffer, 0, 2);
            task.deactivate(stage3DProxy);
            ++i;
        }
        context.setTextureAt(0, null);
        context.setVertexBufferAt(0, null);
        context.setVertexBufferAt(1, null);
    }

    private function updateFilterSizes():Void {
        var i:Int = 0;
        while (i < _filters.length) {
            _filters[i].textureWidth = _rttManager.textureWidth;
            _filters[i].textureHeight = _rttManager.textureHeight;
            ++i;
        }
        _filterSizesInvalid = true;
    }

    public function dispose():Void {
        _rttManager.removeEventListener(Event.RESIZE, onRTTResize);
        _rttManager = null;
        _stage3DProxy = null;
    }

}


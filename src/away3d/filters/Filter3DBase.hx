package away3d.filters;

import flash.Vector;
import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import away3d.filters.tasks.Filter3DTaskBase;
import flash.display3D.textures.Texture;

class Filter3DBase {
    public var requireDepthRender(get_requireDepthRender, never):Bool;
    public var tasks(get_tasks, never):Vector<Filter3DTaskBase>;
    public var textureWidth(get_textureWidth, set_textureWidth):Int;
    public var textureHeight(get_textureHeight, set_textureHeight):Int;

    private var _tasks:Vector<Filter3DTaskBase>;
    private var _requireDepthRender:Bool;
    private var _textureWidth:Int;
    private var _textureHeight:Int;

    public function new() {
        _tasks = new Vector<Filter3DTaskBase>();
    }

    public function get_requireDepthRender():Bool {
        return _requireDepthRender;
    }

    private function addTask(filter:Filter3DTaskBase):Void {
        _tasks.push(filter);
        if (!_requireDepthRender)
            _requireDepthRender = filter.requireDepthRender;
    }

    public function get_tasks():Vector<Filter3DTaskBase> {
        return _tasks;
    }

    public function getMainInputTexture(stage3DProxy:Stage3DProxy):Texture {
        return _tasks[0].getMainInputTexture(stage3DProxy);
    }

    public function get_textureWidth():Int {
        return _textureWidth;
    }

    public function set_textureWidth(value:Int):Int {
        _textureWidth = value;
        var i:Int = 0;
        while (i < _tasks.length) {
            _tasks[i].textureWidth = value;
            ++i;
        }
        return value;
    }

    public function get_textureHeight():Int {
        return _textureHeight;
    }

    public function set_textureHeight(value:Int):Int {
        _textureHeight = value;
        var i:Int = 0;
        while (i < _tasks.length) {
            _tasks[i].textureHeight = value;
            ++i;
        }
        return value;
    }

// link up the filters correctly with the next filter

    public function setRenderTargets(mainTarget:Texture, stage3DProxy:Stage3DProxy):Void {
        _tasks[_tasks.length - 1].target = mainTarget;
    }

    public function dispose():Void {
        var i:Int = 0;
        while (i < _tasks.length) {
            _tasks[i].dispose();
            ++i;
        }
    }

    public function update(stage:Stage3DProxy, camera:Camera3D):Void {
    }

}


package away3d.filters;

import away3d.cameras.Camera3D;
import away3d.core.managers.Stage3DProxy;
import away3d.filters.tasks.Filter3DTaskBase;
import openfl.display3D.textures.Texture;

class Filter3DBase {
    public var requireDepthRender(get, never):Bool;
    public var tasks(get, never):Array<Filter3DTaskBase>;
    public var textureWidth(get, set):Int;
    public var textureHeight(get, set):Int;

    private var _tasks:Array<Filter3DTaskBase>;
    private var _requireDepthRender:Bool;
    private var _textureWidth:Int;
    private var _textureHeight:Int;

    public function new() {
        _tasks = new Array<Filter3DTaskBase>();
    }

    private function get_requireDepthRender():Bool {
        return _requireDepthRender;
    }

    private function addTask(filter:Filter3DTaskBase):Void {
        _tasks.push(filter);
        if (!_requireDepthRender)
            _requireDepthRender = filter.requireDepthRender;
    }

    private function get_tasks():Array<Filter3DTaskBase> {
        return _tasks;
    }

    public function getMainInputTexture(stage3DProxy:Stage3DProxy):Texture {
        return _tasks[0].getMainInputTexture(stage3DProxy);
    }

    private function get_textureWidth():Int {
        return _textureWidth;
    }

    private function set_textureWidth(value:Int):Int {
        _textureWidth = value;
        var i:Int = 0;
        while (i < _tasks.length) {
            _tasks[i].textureWidth = value;
            ++i;
        }
        return value;
    }

    private function get_textureHeight():Int {
        return _textureHeight;
    }

    private function set_textureHeight(value:Int):Int {
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


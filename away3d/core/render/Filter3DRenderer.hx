package away3d.core.render;

import away3d.cameras.*;
import away3d.core.managers.*;
import away3d.events.Stage3DEvent;
import away3d.filters.*;
import away3d.filters.tasks.*;

import openfl.display3D.*;
import openfl.display3D.textures.*;
import openfl.events.*;
import openfl.Vector;

/**
 */
class Filter3DRenderer
{
	public var requireDepthRender(get, never):Bool;
	public var filters(get, set):Array<Filter3DBase>;
	
	private var _filters:Array<Filter3DBase>;
	private var _tasks:Vector<Filter3DTaskBase>;
	private var _filterTasksInvalid:Bool;
	private var _mainInputTexture:Texture;
	
	private var _requireDepthRender:Bool;
	
	private var _rttManager:RTTBufferManager;
	private var _stage3DProxy:Stage3DProxy;
	private var _filterSizesInvalid:Bool = true;
	
	public function new(stage3DProxy:Stage3DProxy)
	{
		_stage3DProxy = stage3DProxy;
		_stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContext3DRecreated);
		_rttManager = RTTBufferManager.getInstance(stage3DProxy);
		_rttManager.addEventListener(Event.RESIZE, onRTTResize);
	}
	
	private function onContext3DRecreated(event:Stage3DEvent):Void
	{
		_filterSizesInvalid = true;
	}
	
	private function onRTTResize(event:Event):Void
	{
		_filterSizesInvalid = true;
	}
	
	private function get_requireDepthRender():Bool
	{
		return _requireDepthRender;
	}

	public function getMainInputTexture(stage3DProxy:Stage3DProxy):Texture
	{
		if (_filterTasksInvalid)
			updateFilterTasks(stage3DProxy);
		return _mainInputTexture;
	}
	
	private function get_filters():Array<Filter3DBase>
	{
		return _filters;
	}
	
	private function set_filters(value:Array<Filter3DBase>):Array<Filter3DBase>
	{
		_filters = value;
		_filterTasksInvalid = true;
		
		_requireDepthRender = false;
		if (_filters == null)
			return null;
		
		for (i in 0...filters.length) {
			if (!_requireDepthRender)
				_requireDepthRender = _filters[i].requireDepthRender;
		}
		_filterSizesInvalid = true;
		return value;
	}
	
	private function updateFilterTasks(stage3DProxy:Stage3DProxy):Void
	{
		var len:Int;
		
		if (_filterSizesInvalid)
			updateFilterSizes();
		
		if (_filters == null) {
			_tasks = null;
			return ;
		}
		
		_tasks = new Vector<Filter3DTaskBase>();
		
		len = _filters.length - 1;
		
		var filter:Filter3DBase;
		
		for (i in 0...(len + 1)) {
			// make sure all internal tasks are linked together
			filter = _filters[i];
			filter.setRenderTargets(i == len? null : _filters[i + 1].getMainInputTexture(stage3DProxy), stage3DProxy);
			_tasks = _tasks.concat(filter.tasks);
		}
		
		_mainInputTexture = _filters[0].getMainInputTexture(stage3DProxy);
	}
	
	public function render(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):Void
	{
		var len:Int;
		var i:Int;
		var task:Filter3DTaskBase;
		var context:Context3D = stage3DProxy.context3D;
		var indexBuffer:IndexBuffer3D = _rttManager.indexBuffer;
		var vertexBuffer:VertexBuffer3D = _rttManager.renderToTextureVertexBuffer;
		
		if (_filters == null)
			return;
		if (_filterSizesInvalid)
			updateFilterSizes();
		if (_filterTasksInvalid)
			updateFilterTasks(stage3DProxy);
		
		len = _filters.length;
		for (i in 0...len)
			_filters[i].update(stage3DProxy, camera3D);
		
		len = _tasks.length;
		
		if (len > 1) {
			context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
		}
		
		for (i in 0...len) {
			task = _tasks[i];
			stage3DProxy.setRenderTarget(task.target);
			
			if (task.target == null) {
				stage3DProxy.scissorRect = null;
				vertexBuffer = _rttManager.renderToScreenVertexBuffer;
				context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
				context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			}
			context.setTextureAt(0, task.getMainInputTexture(stage3DProxy));
			context.setProgram(task.getProgram3D(stage3DProxy));
			context.clear(0.0, 0.0, 0.0, 0.0);
			
			task.activate(stage3DProxy, camera3D, depthTexture);
			
			context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			stage3DProxy.drawTriangles(indexBuffer, 0, 2);
			
			task.deactivate(stage3DProxy);
		}
		
		context.setTextureAt(0, null);
		context.setVertexBufferAt(0, null);
		context.setVertexBufferAt(1, null);
	}
	
	private function updateFilterSizes():Void
	{
		for (i in 0..._filters.length) {
			_filters[i].textureWidth = _rttManager.textureWidth;
			_filters[i].textureHeight = _rttManager.textureHeight;
		}
		
		_filterSizesInvalid = true;
	}
	
	public function dispose():Void
	{
		_rttManager.removeEventListener(Event.RESIZE, onRTTResize);
		_rttManager = null;
		_stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_RECREATED, onContext3DRecreated);
		_stage3DProxy = null;
	}
}
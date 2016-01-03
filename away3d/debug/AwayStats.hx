/**
 * <p>Stats monitor for Away3D or general use in any project. The widget was designed to
 * display all the necessary data in ways that are easily readable, while maintaining a
 * tiny size.</p>
 *
 * <p>The following data is displayed by the widget, either graphically, through
 * text, or both.</p>
 * <ul>
 *   <li>Current frame rate in FPS (white in graph/bar)</li>
 *   <li>SWF frame rate (Stage.frameRate)</li>
 *   <li>Average FPS (blue in graph/bar)</li>
 *   <li>Min/Max FPS (only on frame rate bar in minimized mode)</li>
 *   <li>Current RAM usage (pink in graph)</li>
 *   <li>Maximum RAM usage</li>
 *   <li>Number of polygons in scene</li>
 *   <li>Number of polygons last rendered (yellow in graph)</li>
 * </ul>
 *
 * <p>There are two display modes; standard and minimized, which are alternated by clicking
 * the button in the upper right corner, at runtime. The widget can also be configured to
 * start in minimized mode by setting the relevant constructor parameter.</p>
 *
 * <p>All data can be reset at any time, by clicking the lower part of the widget (where
 * the RAM and POLY counters are located. The average FPS can be reset separately by
 * clicking it's ²displayed value. Furthermore, the stage frame rate can be increased or
 * decreased by clicking the upper and lower parts of the graph, respectively. Clicking close
 * to the center will increment in small values, and further away will increase the steps.
 * The graph itself is only visible in standard (as opposed to minimized) display mode.</p>
 *
 * <p>The average FPS is calculated using one of two methods, configurable via constructor
 * parameters. By setting the meanDataLength to a non-zero value, the number of recorded
 * frame rate values on which the average is based can be configured. This has a tiny
 * impact on CPU usage, which is the reason why the default number is zero, denoting that
 * the average is calculated from a running sum since the widget was last reset.</p>
 */
package away3d.debug;

import away3d.core.math.MathConsts;
import openfl.Lib;
import away3d.containers.View3D;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.display.PixelSnapping;
import openfl.display.CapsStyle;
import openfl.display.Graphics;
import openfl.display.LineScaleMode;
import openfl.display.Loader;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import haxe.Timer;
import openfl.geom.Matrix;
import away3d.core.managers.Stage3DProxy;
import openfl.utils.ByteArray;
import openfl.Assets;

class AwayStats extends Sprite {
    public var max_ram(get, never):Float;
    public var ram(get, never):Float;
    public var avg_fps(get, never):Float;
    public var max_fps(get, never):Float;
    public var fps(get, never):Float;
    
    static public var instance(get, never):AwayStats;

    private var _views:Array<View3D>;
    private var _timer:Timer;
    private var _last_frame__timestamp:Float;
    private var _fps:Float;
    private var _ram:Float;
    private var _max_ram:Float;
    private var _min_fps:Float;
    private var _avg_fps:Float;
    private var _max_fps:Float;
    private var _tfaces:Int;
    private var _rfaces:Int;
    private var _num_frames:Int;
    private var _fps_sum:Float;
    private var _stats_panel:Sprite;
    private var _btm_bar:Sprite;
    private var _dragOverlay:Sprite;
    private var _data_format:TextFormat;
    private var _fps_bar:Shape;
    private var _afps_bar:Shape;
    private var _lfps_bar:Shape;
    private var _hfps_bar:Shape;
    private var _diagram:Sprite;
    private var _dia_bmp:BitmapData;
    private var _tmp_bmp:BitmapData;
    private var _mem_points:Array<Dynamic>;
    private var _mem_graph:Shape;
    private var _updates:Int;
    private var _fps_tf:TextField;
    private var _afps_tf:TextField;
    private var _ram_tf:TextField;
    private var _poly_tf:TextField;
    private var _vb_ib_tf:TextField;
    private var _draw_tf:TextField;
    private var _drag_dx:Float;
    private var _drag_dy:Float;
    private var _dragging:Bool;
    private var _mean_data:Array<Dynamic>;
    private var _mean_data_length:Int;
    private var _transparent:Bool;
    private var _currentFPS:Float;
    private var _cacheCount:Int;
    private var _times:Array <Float>;
    private var _counters:Sprite;
    private var _logo:Sprite;
    private var _lastTextY:Int;

    static private var _WIDTH:Int = 200;
    static private var _HEIGHT:Int = 105;
    static private var _DIAG_X:Int = 80;
    static private var _DIAG_WIDTH:Int = _WIDTH - _DIAG_X;
    static private var _DIAG_HEIGHT:Int = 50;
    static private var _UPPER_Y:Float = -1;
    static private var _MID_Y:Float = 9;
    static private var _LOWER_Y:Float = 19;
    static private var _LOWEST_Y:Float = 29;
    static private var _BOTTOM_BAR_HEIGHT:Int = 41;
    static private var _POLY_COL:Int = 0xffcc00;
    static private var _MEM_COL:Int = 0xff00cc;
    static private var _PT:Point = new Point();
    static private var _DPT:Point = new Point(1, 0);

    // Singleton instance reference
    static private var _INSTANCE:AwayStats;
    
    /**
     * <p>Create an Away3D stats widget. The widget can be added to the stage
     * and positioned like any other display object. Once on the stage, you
     * can drag the widget to re-position it at runtime.</p>
     *
     * <p>If you pass a View3D instance, the widget will be able to display
     * the total number of faces in your scene, and the amount of faces that
     * were rendered during the last render() call. Views can also be registered
     * after construction using the registerView() method. Omit the view
     * constructor parameter to disable this feature altogether.</p>
     *
     * @param view A reference to your Away3D view. This is required if you
     * want the stats widget to display polycounts.
     *
     * @param minimized Defines whether the widget should start up in minimized
     * mode. By default, it is shown in full-size mode on launch.
     *
     * @param transparent Defines whether to omit the background plate and print
     * statistics directly on top of the underlying stage.
     *
     * @param meanDataLength The number of frames on which to base the average
     * frame rate calculation. The default value of zero indicates that all
     * frames since the last reset will be used.
     *
     * @param enableClickToReset Enables interaction allowing you to reset all
     * counters by clicking the bottom bar of the widget. When activated, you
     * can also click the average frame rate trace-out to reset just that one
     * value.
     *
     * @param enableModifyFramerate When enabled, allows you to click the upper
     * and lower parts of the graph area to increase and decrease SWF frame rate
     * respectively.
     */
    public function new(view3d:View3D = null, meanDataLength:Int = 0) {
        super();
        
        _mean_data_length = meanDataLength;
        _views = new Array<View3D>();
        
        if (view3d != null) 
            _views.push(view3d);
        
        if (_INSTANCE != null) 
            trace("Creating several statistics windows in one project. Is this intentional?");
        
        _INSTANCE = this;
        _fps = 0;
        _num_frames = 0;
        _avg_fps = 0;
        _ram = 0;
        _max_ram = 0;
        _tfaces = 0;
        _rfaces = 0;
        _last_frame__timestamp = 0;
        _lastTextY = 0;
        
        init();
    }

    private function get_max_ram():Float {
        return _max_ram;
    }

    private function get_ram():Float {
        return _ram;
    }

    private function get_avg_fps():Float {
        return _avg_fps;
    }

    private function get_max_fps():Float {
        return _max_fps;
    }

    private function get_fps():Float {
        return _fps;
    }

    private function init():Void {
        initMisc();
        initStats();
        initInteraction();
        
        reset();

        addEventListener(Event.ADDED_TO_STAGE, _onAddedToStage);
        addEventListener(Event.REMOVED_FROM_STAGE, _onRemovedFromStage);
    }

    /**
     * Holds a reference to the stats widget (or if several have been created
     * during session, the one that was last instantiated.) Allows you to set
     * properties and register views from anywhere in your code.
     */

    static private function get_instance():AwayStats {
        return (_INSTANCE != null) ? _INSTANCE : _INSTANCE = new AwayStats();
    }

    /**
     * Add a view to the list of those that are taken into account when
     * calculating on-screen and total poly counts. Use this method when the
     * stats widget is not instantiated in the same place as where you create
     * your view, or when using several views, or when views are created and
     * destroyed dynamically at runtime.
     */
    public function registerView(view3d:View3D):Void {
        if (view3d != null && _views.indexOf(view3d) < 0) _views.push(view3d);
    }

    /**
     * Remove a view from the list of those that are taken into account when
     * calculating on-screen and total poly counts. If the supplied view is
     * the only one known to the stats widget, calling this will leave the
     * list empty, disabling poly count statistics altogether.
     */
    public function unregisterView(view3d:View3D):Void {
        if (view3d != null) {
            var idx:Int = _views.indexOf(view3d);
            if (idx >= 0) _views.splice(idx, 1);
        }
    }

    private function initMisc():Void {
        _currentFPS = 0;
        _cacheCount = 0;
        _times = [];
        _timer = new Timer(200);
        _timer.run = onTimer;
        _data_format = new TextFormat("_sans", 9, 0xffffff, false);
        
        if (_mean_data_length > 0) {
            var i:Int;
            _mean_data = [];
            i = 0;
            while (i < _mean_data_length) {
                _mean_data[i] = 0.0;
                i++;
            }
        }

        _dia_bmp = new BitmapData(_DIAG_WIDTH, _DIAG_HEIGHT, true, 0);
        _tmp_bmp = new BitmapData(_DIAG_WIDTH, _DIAG_HEIGHT, true, 0);
        
     }

    /**
     * @private
     * Draw logo and create title textfield.
     */
    private function initStats():Void {
        
        _stats_panel = new Sprite();   
        _stats_panel.graphics.beginFill(0x555555, 0.4);
        _stats_panel.graphics.drawRect(0, 0, _WIDTH, _HEIGHT);
        _stats_panel.graphics.endFill();

        _stats_panel.graphics.lineStyle(1, 0xaaaaaa);
        _stats_panel.graphics.moveTo( _DIAG_X, 0 );
        _stats_panel.graphics.lineTo( _DIAG_X, _DIAG_HEIGHT + 5 );
        _stats_panel.graphics.moveTo( _DIAG_X - 5, _DIAG_HEIGHT );
        _stats_panel.graphics.lineTo( _DIAG_X + _DIAG_WIDTH, _DIAG_HEIGHT );
        
        addChild(_stats_panel);
  
        // Add the counters
        _counters = new Sprite();
        _counters.x = _DIAG_X;
        _counters.y = _DIAG_HEIGHT;
        addChild(_counters);

        _afps_tf = new TextField();
        addText( "AV/TRG", _afps_tf, 0x3388dd );

        _ram_tf = new TextField();
        addText( "RAM", _ram_tf, _MEM_COL );

        _poly_tf = new TextField();
        addText( "POLY", _poly_tf, _POLY_COL );

        _vb_ib_tf = new TextField();
        addText( "VB/IB", _vb_ib_tf, 0xffffff );

        _draw_tf = new TextField();
        addText( "DRAWS", _draw_tf, 0xffffff );
       
        // Graph
        var graph = new Bitmap( _dia_bmp );
        _mem_graph = new Shape();
        graph.x = _mem_graph.x = _DIAG_X;
        _stats_panel.addChild( graph );
        _stats_panel.addChild( _mem_graph );

        // Hit area for bottom bar (to avoid having textfields
        // affect interaction badly.)
        _dragOverlay = new Sprite();
        _dragOverlay.graphics.beginFill(0, 0);
        _dragOverlay.graphics.drawRect(0, 1, _WIDTH, _HEIGHT);
        _stats_panel.addChild(_dragOverlay);

        // Current FPS
        _fps_tf = new TextField();
        _fps_tf.defaultTextFormat = new TextFormat("_sans", 40, 0xffffff, true, false, false, null, null, TextFormatAlign.CENTER);
        _fps_tf.width = 60;
        _fps_tf.x = 10;
        _fps_tf.y = 55;
        _fps_tf.selectable = false;
        _stats_panel.addChild(_fps_tf);

        var logoData = 
            "iVBORw0KGgoAAAANSUhEUgAAAIAAAABuBAMAAAAdXgYKAAAAD1BMVEUAAAAbq8FN" + 
            "v9B61+O76fBSwR2CAAAAAXRSTlMAQObYZgAAAAFiS0dEAIgFHUgAAAAJcEhZcwAA" + 
            "D9sAAA/bAQ1E0UgAAAAHdElNRQffBRMIKAYf3Sl8AAAEIElEQVRYw7WY7YHrKAxF" + 
            "ccYFINNAsm5gHVwAu6b/mh4gEMIfMZB5/Ml4Eh1fCZAEQvzN8cCPsRvwP36obsAm" + 
            "EWA67Uf9JcAiYFC2GwAR0CdhjABQ65eAee3zwW4a5C8ABg8wXR44AASA7gJYAmht" + 
            "bRdABwAEgOnwIADk14DBA9YOH6wHvKKCPsBWAEy7BwEgEsC2e8AAuhewxHXgAabV" + 
            "AxfDXwDIDLCtHhSA9QuASADT6AEBpgiwjQI2DxC/CjBtHhBA6TgNvYCfBLBNHvgY" + 
            "9gJGAvxbAkwfYNApirbFgwDA4jp3AXwM37E6E8A0eECTwBZCMwDwH0BRtA0hYIBB" + 
            "EcBUC0jp5DuAjAAggK32wAOAAHOKYhPgnQCuRyGAqfUgpGQCQBcAQBwBttaDHUAR" + 
            "wNQJcIClBOhmwCsDBuwRqnywNAlAMfSAuRnwzgLQB1vlw0gAnMR/3HKIPtRF0RIA" + 
            "GzTwy2EKE7lW+WAphk6Asw+A0KuptcYH8mBzO9Hbg28ywGkYWgEv+QiG/uQEoduj" + 
            "KNqaEGwg3JufNAlOz9wEWLwAyaZRCmXvfRgzwAmY8heDl1ABoJ9Y3x4+hSgkrPc+" + 
            "ZIB758S/8Y/jrYT8i/8EjwBKEI96wPYUfCegBDnc+pDXsevRJU4fAP7pAXMtYFuO" + 
            "AC/pbjGynShfII6Au8XINlIMAQcMHrBWATQDoPcIeN5kFZ5OBa6CEiCH6WNWGUmA" + 
            "CwD5TYCHPz59TK2sIMgrgPpUZEmAy4aPBMhBTIDLElfUxHMAnX5OJbCqfuUCAtaP" + 
            "gE1jQTgChgC47lV4Y+MB0zngumFjrRmeuE8WEtaJi4Ytd6chExwBYXegD2dda26P" + 
            "l7h7nxkAkP9WF503nRBib5e2c0rqOSoXnTcJ0GnS/O+T98AiMZ+fHkjAGygH7lLa" + 
            "kxq2kyPUSAJSc/k6JlUETfrsCDUmAak9PkvrrPM+HANJgJa8lHABqcyExnkvIQtY" + 
            "imp2+vBDEsz+rO5GLme8uBaFVmgi7G4bNPZD7K2S7PmczDo5Ud7Y5DNS7gomnJCy" + 
            "0OJRll/MjLs1kIWnFqecUoqj4XdOvL33QyIhbG9/DVFoS6uJXxmVnSXuoAcCwu7k" + 
            "dNpThgl4ly0NRJMfHXGw71y9BEMXh4U90EibKQ0mEJNburn09sDUc5PiMZ9hMMXH" + 
            "299gL4tZTmPdyud3fouvMt6HcQv2wOKbB21zGvEwCYEQ7ost2ssc3cI877M4XvGn" + 
            "geB92MgeMGGR+ty0FSIgNw/+ynpM8YedvS0GQzCHQRnxkEVYzs1LP5Yc8kHxtaPO" + 
            "1J+JWGCfMkU8XFy+foc47K8igPbD2AWyEKA+qD+IWI4Adf96jlgOab/SPFcwKAVU" + 
            "qN+JKNO+qn49a6XKJGcbR66CoVyttnlsuYoJbbvG5m3/ABGuVkEUmYMPAAAAAElF" + 
            "TkSuQmCC";

        _logo = new Sprite();
        _logo.mouseEnabled = true;
        _logo.x = _logo.y = 5;
        _logo.scaleX = _logo.scaleY = 0.5;
        _stats_panel.addChild(_logo);

        #if flash
        var logoLdr:Loader = new Loader();
        logoLdr.contentLoaderInfo.addEventListener(Event.COMPLETE, onLogoData);
        logoLdr.loadBytes( haxe.crypto.Base64.decode( logoData ).getData() );
        #else 
            #if !openfl_legacy
            var logoBmp = new Bitmap( BitmapData.fromBytes( ByteArray.fromBytes( haxe.crypto.Base64.decode( logoData ) ) ), PixelSnapping.AUTO, true );
            #else
            var logoBmp = new Bitmap( BitmapData.loadFromHaxeBytes( haxe.crypto.Base64.decode( logoData ) ), PixelSnapping.AUTO, true );
            #end

            _logo.addChild( logoBmp );
        #end
    }

    private function onLogoData( e:Event ) {
        //var logoBmp = new Bitmap( e.currentTarget.content, PixelSnapping.AUTO, true );    
        _logo.addChild( e.currentTarget.content );
    }

    private function addText( label:String, txtFld:TextField, col:UInt = 0xffffff ) {
        var lbl = new TextField();
        lbl.defaultTextFormat = new TextFormat("_sans", 9, col, false);
        lbl.autoSize = TextFieldAutoSize.LEFT;
        lbl.text = label+":";
        lbl.y = _lastTextY;
        lbl.selectable = false;
        lbl.mouseEnabled = false;
        _counters.addChild(lbl);
        
        txtFld.defaultTextFormat = _data_format;
        txtFld.autoSize = TextFieldAutoSize.LEFT;
        txtFld.x = 45;
        txtFld.y = lbl.y;
        txtFld.selectable = false;
        txtFld.mouseEnabled = false;
        _counters.addChild(txtFld);

        _lastTextY += 10;
    }

    private function initInteraction():Void {
        // Mouse down to drag on the title
        _dragOverlay.addEventListener(MouseEvent.MOUSE_DOWN, onDragOverlayMouseDown);

        // Reset functionality
        _logo.addEventListener(MouseEvent.CLICK, onResetCounters);
        _fps_tf.addEventListener(MouseEvent.MOUSE_UP, onResetAvgFPS, false, 1);
    }

    private function redrawStats():Void {
        var dia_y:Int;

        // Redraw counters
        _fps_tf.text = Std.string(_fps);
        _afps_tf.text = Std.string(Math.round(_avg_fps)) + ("/" + Std.string(stage.frameRate));
        _ram_tf.text = "not impl"; //getRamString(_ram) + (" / " + getRamString(_max_ram));
        
        // Move entire diagram
        _tmp_bmp.fillRect(_tmp_bmp.rect, 0x0);
        _tmp_bmp.copyPixels( _dia_bmp, _dia_bmp.rect, _DPT);
        _dia_bmp.fillRect(_dia_bmp.rect, 0x0);
        _dia_bmp.copyPixels( _tmp_bmp, _dia_bmp.rect, _PT);
        
        // Only redraw polycount if there is a  view available
        // or they won't have been calculated properly
        if (_views.length > 0) {
            //_poly_tf.text = _rfaces.toString().concat(' / ', _tfaces); // TODO: Total faces not yet available in 4.x
            _poly_tf.text = _rfaces + "";

            // Plot rendered faces
            dia_y = _dia_bmp.height - Math.floor(_rfaces / _tfaces * _dia_bmp.height);
            _dia_bmp.setPixel32(1, dia_y, _POLY_COL + 0xff000000);
        } else
            _poly_tf.text = "n/a (no view)";

        _vb_ib_tf.text = Stage3DProxy.vertexBufferCount + " / " + Stage3DProxy.indexBufferCount;
       
        _draw_tf.text = Std.string( Stage3DProxy.drawTriangleCount );

        dia_y = _dia_bmp.height - Math.floor(_fps / stage.frameRate * _dia_bmp.height);
        _dia_bmp.setPixel32(1, dia_y, 0xffffffff);

        // Plot average framerate
        dia_y = _dia_bmp.height - Math.floor(_avg_fps / stage.frameRate * _dia_bmp.height);
        _dia_bmp.setPixel32(1, dia_y, 0xff33bbff);

        // Redraw diagrams
        //if (_updates % 5 == 0)
            //redrawMemGraph();

        _mem_graph.x = _updates % 5;
        _updates++;

        //_dia_bmp.draw( _tmp_bmp );
    }

    private function redrawMemGraph():Void {
        var i:Int;
        var g:Graphics;
        var max_val:Float = 0;

        // Redraw memory graph (only every 5th update)
        _mem_graph.scaleY = 1;
        g = _mem_graph.graphics;
        g.clear();
        g.lineStyle(1, _MEM_COL, 1, true, LineScaleMode.NONE);
        g.moveTo(5 * (_mem_points.length - 1), -_mem_points[_mem_points.length - 1]);
        i = _mem_points.length - 1;
        
        while (i >= 0) {
            trace(" - "+(i * 5)+":"+_mem_points[i]+" "+_mem_points[i + 1]);
            if (_mem_points[i + 1] == 0 || _mem_points[i] == 0) {
                g.moveTo(i * 5, -_mem_points[i]);
                {
                    --i;
                    continue;
                }

            }
            g.lineTo(i * 5, -_mem_points[i]);
            if (_mem_points[i] > max_val) max_val = _mem_points[i];
            --i;
        }
        _mem_graph.scaleY = _dia_bmp.height / max_val;
    }

    private function getRamString(ram:Float):String {
        var ram_unit:String = "B";
        if (ram > 1048576) {
            ram /= 1048576;
            ram_unit = "M";
        }

        else if (ram > 1024) {
            ram /= 1024;
            ram_unit = "K";
        }
        return Math.round(ram*10)/10 + ram_unit;
    }

    public function reset():Void {
        var i:Int;

        // Reset all values
        _updates = 0;
        _num_frames = 0;
        _min_fps = Math.POSITIVE_INFINITY;
        _max_fps = 0;
        _avg_fps = 0;
        _fps_sum = 0;
        _max_ram = 0;

        // // Reset RAM usage log
        i = 0;
        _mem_points = [];
        while (i < _WIDTH / 5) {
            _mem_points[i] = 0;
            i++;
        }

        // Reset FPS log if any
        if (_mean_data != null) {
            i = 0;
            while (i < _mean_data.length) {
                _mean_data[i] = 0.0;
                i++;
            }
        }

        _dia_bmp.fillRect(_dia_bmp.rect, 0);
    }

    private function _endDrag():Void {
        if (this.x < -_WIDTH)
            this.x = -(_WIDTH - 20)
        else if (this.x > stage.stageWidth)
            this.x = stage.stageWidth - 20;

        if (this.y < 0)
            this.y = 0
        else if (this.y > stage.stageHeight)
            this.y = stage.stageHeight - 15;

        this.x = Math.round(this.x);
        this.y = Math.round(this.y);
        _dragging = false;

        stage.removeEventListener(Event.MOUSE_LEAVE, onMouseUpOrLeave);
        stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpOrLeave);
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    }

    private function _onAddedToStage(ev:Event):Void {
        _timer = new Timer(200);
        _timer.run = onTimer;
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    private function _onRemovedFromStage(ev:Event):Void {
        _timer.stop();
        removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    private function onTimer():Void {
        // Store current and max RAM
        _ram = System.totalMemory;
        if (_ram > _max_ram)
            _max_ram = _ram;

        if (_updates % 5 == 0) {
            _mem_points.unshift(_ram / 1024);
            _mem_points.pop();
        }
        _tfaces = _rfaces = 0;

        // Update polycount if views are available
        if (_views.length > 0) {
            var i:Int;

            // Sum up poly counts across all registered views
            i = 0;
            while (i < _views.length) {
                _rfaces += _views[i].renderedFacesCount;

                //_tfaces += 0;// TODO: total faces
                i++;
            }
        }
        redrawStats();
    }

    private function onEnterFrame(ev:Event):Void {
        var currentTime = Timer.stamp ();
        _times.push (currentTime);
        
        while (_times[0] < currentTime - 1) {
            
            _times.shift ();
            
        }
        
        var _currentCount = _times.length;
        _currentFPS = Math.round ((_currentCount + _cacheCount) / 2);
        
        if (_currentCount != _cacheCount /*&& visible*/) {
            
            _fps = _currentFPS;
            
        }
        
        _cacheCount = _currentCount;
        _fps_sum += _fps;

        // Update min/max fps
        if (_fps > _max_fps)
            _max_fps = _fps
        else if (_fps != 0 && _fps < _min_fps)
            _min_fps = _fps;

        if (_mean_data != null) {
            _mean_data.push(_fps);
            _fps_sum -= Std.parseInt(_mean_data.shift()) /* WARNING check type */;

            // Average = sum of all log entries over
            // number of log entries.
            _avg_fps = _fps_sum / _mean_data_length;
        } else {
            // Regular average calculation, i.e. using
            // a running sum since last reset
            _num_frames++;
            _avg_fps = _fps_sum / _num_frames;
        }
        _last_frame__timestamp = Lib.getTimer();
    }

    /**
     * @private
     * Reset just the average FPS counter.
     */
    private function onResetAvgFPS(ev:MouseEvent):Void {
        if (!_dragging) {
            var i:Int;
            _num_frames = 0;
            _fps_sum = 0;
            if (_mean_data != null) {
                i = 0;
                while (i < _mean_data.length) {
                    _mean_data[i] = 0.0;
                    i++;
                }
            }
        }
    }

    private function onResetCounters(ev:MouseEvent):Void {
        reset();
    }

    private function onDragOverlayMouseDown(ev:MouseEvent):Void {
        _drag_dx = this.mouseX;
        _drag_dy = this.mouseY;
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpOrLeave);
        stage.addEventListener(Event.MOUSE_LEAVE, onMouseUpOrLeave);
    }

    private function onMouseMove(ev:MouseEvent):Void {
        _dragging = true;
        this.x = stage.mouseX - _drag_dx;
        this.y = stage.mouseY - _drag_dy;
    }

    private function onMouseUpOrLeave(ev:Event):Void {
        _endDrag();
    }
}

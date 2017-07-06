//
// Cedricici
//

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
using Toybox.Application;
using Toybox.ActivityMonitor as Act;



var partialUpdatesAllowed = false;


class Shape {
    var type;
    var fill;
    var hide;
    var points;

    function initialize(type,points,fill,hide){
        me.type=type;me.points=points;me.fill=fill;me.hide=hide;
    }


}


class CedricWatchView extends WatchUi.WatchFace {
    // var font;
    var isAwake;
    var screenShape;
    // var dndIcon;
    var offscreenBuffer;
    // var dateBuffer;
    // var curClip;
    var screenCenterPoint;
    var fullScreenRefresh;



    // Toutes ces valeurs valent pour un ecran 215x180 ou 215x215.
    // il faudra mettre à l'échelle pour des écran différents
    var segments = [
    new Shape("polygon",[ [2,0],[24,0],[17,6],[7,6] ],true,false),
    new Shape("polygon",[ [19,8],[26,2],[17,56],[11,52] ],true,false),
    new Shape("polygon",[ [9,64],[16,62],[6,117],[1,111] ],true,false),
    new Shape("polygon",[ [-11,113],[-1,113],[4,119],[-18,119] ],true,false),
    new Shape("polygon",[ [-11,62],[-5,64],[-13,111],[-20,117] ],true,false),
    new Shape("polygon",[ [0,2],[5,8],[-2,52],[-9,55] ],true,false),
    new Shape("polygon",[ [-1,55],[9,55],[14,58],[9,61],[-4,61],[-8,59] ],true,false) 
    ];

    var batterie = [
    new Shape("line",[ [0,2],[-15,2],[-21,38],[-36,38],[0,2] ],false,false),
    new Shape("box",[ [6,0],[11,2] ],true,false)
    ];

    var batterieState = [
    new Shape("polygon",[ [2,4],[14,4],[8,37],[-4,37] ],true,false)
    ];

    var mail = [
    new Shape("box",[ [0,0],[19,12] ],false,false),
    new Shape("line",[ [0,0],[10,7],[19,0] ],false,false)
    ];

    var bluetooth = [
    new Shape("line",[ [0,4],[9,13],[4,18],[4,0],[77,4],[6,13] ],false,false)
    ];

    var numbers = [
    [true,true,true,true,true,true,false],
    [false,true,true,false,false,false,false],
    [true,true,false,true,true,false,true],
    [true,true,true,true,false,false,true],
    [false,true,true,false,false,true,true],
    [true,false,true,true,false,true,true],
    [true,false,true,true,true,true,true],
    [true,true,true,false,false,false,false],
    [true,true,true,true,true,true,true],
    [true,true,true,true,false,true,true]
    ];





    // Initialize variables for this view
    function initialize() {
        WatchFace.initialize();
        screenShape = System.getDeviceSettings().screenShape;
        fullScreenRefresh = true;
        partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate );
    }


    // Configure the layout of the watchface for this device
    function onLayout(dc) {

        // If this device supports BufferedBitmap, allocate the buffers we use for drawing
        if(Toybox.Graphics has :BufferedBitmap) {
            // Allocate a full screen size buffer with a palette of only 4 colors to draw
            // the background image of the watchface.  This is used to facilitate blanking
            // the second hand during partial updates of the display
            offscreenBuffer = new Graphics.BufferedBitmap({
                :width=>dc.getWidth(),
                :height=>dc.getHeight(),
                :palette=> [
                    Graphics.COLOR_BLACK,
                    Graphics.COLOR_RED
                ]
            });
        } else {
            offscreenBuffer = null;
        }

        //curClip = null;

       // screenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];
    }

    // Handle the update event
    function onUpdate(dc) {

        var width;
        var height;
        var screenWidth = dc.getWidth();
        var clockTime = System.getClockTime();
        var targetDc = null; // pour utiliser ou pas le Dbuffer

        var mySettings = System.getDeviceSettings();
        //var myStats = System.getDeviceStats(); 


        // We always want to refresh the full screen when we get a regular onUpdate call.
        fullScreenRefresh = true;

        if(null != offscreenBuffer) {
            //dc.clearClip();
            //curClip = null;

            // If we have an offscreen buffer that we are using to draw the background,
            // set the draw context of that buffer as our target.
            targetDc = offscreenBuffer.getDc();
        } else {
            targetDc = dc;
        }

        width = targetDc.getWidth();
        height = targetDc.getHeight();

        // Fill the entire background with Black.
        targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        targetDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());


        drawTime(targetDc,clockTime);

        drawState(targetDc,mySettings.phoneConnected,mySettings.notificationCount);


        //flush Dbuffer in dc
        drawBackground(dc);

        fullScreenRefresh = false;
    }

    function drawState(dc,btStatus,notifCount){
        if(btStatus){
            drawShape(dc,bluetooth,[178,110],Graphics.COLOR_RED,Graphics.COLOR_RED,3,null);
        }
        if(notifCount>0){
            drawShape(dc,mail,[177,83],Graphics.COLOR_RED,Graphics.COLOR_RED,3,null);
        }

    }


    function drawTime(dc,clockTime){
        var H1 = Math.floor(clockTime.hour/10);
        var H2 = clockTime.hour%10;
        
        for (var i=0;i<segments.size();i++){
            segments[i].hide=numbers[H1][i];
        }
        drawShape(dc,segments,[54,30],Graphics.COLOR_RED,Graphics.COLOR_RED,3,null);
        
        for (var i=0;i<segments.size();i++){
            segments[i].hide=numbers[H2][i];
        }
        drawShape(dc,segments,[84,30],Graphics.COLOR_RED,Graphics.COLOR_RED,3,null);
        
        dc.fillCircle(109,76,3);
        
        dc.fillCircle(105,103,3);

        var M1 = Math.floor(clockTime.min/10);
        var M2 = clockTime.min%10;
        
        for (var i=0;i<segments.size();i++){
            segments[i].hide=numbers[M1][i];
        }
        drawShape(dc,segments,[123,30],Graphics.COLOR_RED,Graphics.COLOR_RED,3,null);
        
        for (var i=0;i<segments.size();i++){
            segments[i].hide=numbers[M2][i];
        }
        drawShape(dc,segments,[153,30],Graphics.COLOR_RED,Graphics.COLOR_RED,3,null);
        

    }

    function drawShape(dc,shapes,coord,frontColor,backColor,penWidth,options){

        dc.setColor(frontColor,backColor);
        dc.setPenWidth(penWidth);
        for (var i=0;i<shapes.size();i++) {
            var points=shapes[i].points;
            if(! shapes[i].hide){continue;}
            switch(shapes[i].type){
            case "line":
                var p1=points[0];
                for ( var n=1;n<points.size();n++ ) {
                    dc.drawLine(coord[0]+p1[0],coord[1]+p1[1],coord[0]+points[n][0],coord[1]+points[n][1]);
                }
                break;
            case "box":
                if(shapes[i].fill){
                    dc.fillRectangle(coord[0]+points[0][0],coord[1]+points[0][1],coord[0]+points[1][0],coord[1]+points[1][1]);
                }else{
                    dc.drawRectangle(coord[0]+points[0][0],coord[1]+points[0][1],coord[0]+points[1][0],coord[1]+points[1][1]);
                }
                break;
            case "polygon":
                if(shapes[i].fill){
                    var poly=new[points.size()];
                    for ( var n=0;n<points.size();n++ ) {
                        poly[n]=[coord[0]+points[n][0],coord[1]+points[n][1]];
                    }
                    dc.fillPolygon(poly);
                }else{
                    //convert to line?
                }
                break;
            }
        }


    }



    // bouble buffer
    function drawBackground(dc) {

        if(offscreenBuffer!=null) {
            dc.drawBitmap(0, 0, offscreenBuffer);
        }

    }

    // This method is called when the device re-enters sleep mode.
    // Set the isAwake flag to let onUpdate know it should stop rendering the second hand.
    function onEnterSleep() {
        isAwake = false;
        WatchUi.requestUpdate();
    }

    // This method is called when the device exits sleep mode.
    // Set the isAwake flag to let onUpdate know it should render the second hand.
    function onExitSleep() {
        isAwake = true;
    }
}

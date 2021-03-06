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
var firstPartial=0;
var frontColor=Graphics.COLOR_RED;



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
    // var segments = [
    // new Shape(:polygon,[ [2,0],[24,0],[17,6],[7,6] ],true,false),
    // new Shape(:polygon,[ [19,8],[26,2],[17,56],[11,52] ],true,false),
    // new Shape(:polygon,[ [9,64],[16,62],[6,117],[1,111] ],true,false),
    // new Shape(:polygon,[ [-11,113],[-1,113],[4,119],[-18,119] ],true,false),
    // new Shape(:polygon,[ [-11,62],[-5,64],[-13,111],[-20,117] ],true,false),
    // new Shape(:polygon,[ [0,2],[5,8],[-2,52],[-9,55] ],true,false),
    // new Shape(:polygon,[ [-1,55],[9,55],[14,58],[9,61],[-4,61],[-8,59] ],true,false) 
    // ];

    var segments = [
    new Shape(:polygon,[ [0 ,0  ],[45,0  ],[30,20 ],[15,20 ] ],true,false),
    new Shape(:polygon,[ [30,20 ],[45,0  ],[45,80 ],[30,70 ] ],true,false),
    new Shape(:polygon,[ [30,90 ],[45,80 ],[45,160],[30,140] ],true,false),
    new Shape(:polygon,[ [15,140],[30,140],[45,160],[0 ,160] ],true,false),
    new Shape(:polygon,[ [0 ,80 ],[15,90 ],[15,140],[0 ,160] ],true,false),
    new Shape(:polygon,[ [0 ,0  ],[15,20 ],[15,70 ],[0 ,80 ] ],true,false),
    new Shape(:polygon,[ [15,70 ],[30,70 ],[45,80 ],[30,90 ],[15, 90] ,[0, 80] ],true,false)
    ];



    var batterie = [
    new Shape(:box,[ [0,3],[12,40] ],false,false),
    new Shape(:box,[ [4,0],[8,3] ],true,false)
    ];

    var mail = [
    new Shape(:box,[ [0,0],[12,8] ],false,false),
    new Shape(:line,[ [0,0],[6,4],[12,0] ],false,false)
    ];

    var bluetooth = [
    new Shape(:line,[ [0,4],[9,13],[4,18],[4,0],[9,4],[0,13] ],false,false)
    ];

    var numbers = [
    [false,false,false,false,false,false,true],
    [true,false,false,true,true,true,true],
    [false,false,true,false,false,true,false],
    [false,false,false,false,true,true,false],
    [true,false,false,true,true,false,false],
    [false,true,false,false,true,false,false],
    [false,true,false,false,false,false,false],
    [false,false,false,true,true,true,true],
    [false,false,false,false,false,false,false],
    [false,false,false,false,true,false,false]
    ];

    var dotR=3;
    var lineW=2;
    var Hcolor = Graphics.COLOR_YELLOW;
    var Mcolor = Graphics.COLOR_WHITE;
    var BackColor = Graphics.COLOR_BLACK;

    // Initialize variables for this view
    function initialize() {
        WatchFace.initialize();
        screenShape = System.getDeviceSettings().screenShape;
        fullScreenRefresh = true;
        partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate );
        System.println(partialUpdatesAllowed);
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
                    Mcolor,
                    Hcolor,
                    BackColor
                ]
            });
        } else {
            offscreenBuffer = null;
        }

        //curClip = null;

       screenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];
    }

    // Handle the update event
    function onUpdate(dc) {

        var width;
        var height;
        var screenWidth = dc.getWidth();
        var clockTime = System.getClockTime();
        var targetDc = null; // pour utiliser ou pas le Dbuffer

        var mySettings = System.getDeviceSettings();
        var myStats = System.getSystemStats(); 

        if(null != offscreenBuffer) {
            dc.clearClip();
            curClip = null;

            // If we have an offscreen buffer that we are using to draw the background,
            // set the draw context of that buffer as our target.
            targetDc = offscreenBuffer.getDc();
        } else {
            targetDc = dc;
        }

        width = targetDc.getWidth();
        height = targetDc.getHeight();

        // Dessin du BG
        targetDc.setColor(BackColor,BackColor);
        targetDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        drawDate(targetDc);

        drawTime(targetDc,clockTime);

        drawState(targetDc,mySettings.phoneConnected,mySettings.notificationCount);

        drawBattery(targetDc,myStats.battery);

        //flush Dbuffer in dc
        drawBackground(dc);

        fullScreenRefresh = false;

    }

    function drawDate(dc) {
        var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]);

        dc.setColor(Mcolor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(108, 0, Graphics.FONT_XTINY, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
    }


    function drawState(dc,btStatus,notifCount){

        if(btStatus){
            drawShape(dc,bluetooth,[31,57],Mcolor,Graphics.COLOR_TRANSPARENT,2,null);
        }
        if(notifCount>0){
            drawShape(dc,mail,[31,35],Mcolor,Graphics.COLOR_RED,2,null);
        }
    }


    function drawBattery(dc,batteryLevel){

        var o=[30,105];
        
        var batP = [ [0,(batteryLevel/100)*batterie[0].points[1][1]],batterie[0].points[1] ];

        var bl=new Shape(:box,batP,true,false);


        drawShape(dc,[bl],o,Hcolor,Mcolor,2,null);
        
        drawShape(dc,batterie,o,Mcolor,Graphics.COLOR_TRANSPARENT,2,null);

    }


    function drawTime(dc,clockTime){
        var H1 = Math.floor(clockTime.hour/10);
        var H2 = clockTime.hour%10;
        
        for (var i=0;i<segments.size();i++){
            segments[i].hide=numbers[H1][i];
        }

        drawShape(dc,segments,[13,10],Hcolor,Hcolor,3,null);
        
        for (var i=0;i<segments.size();i++){
            segments[i].hide=numbers[H2][i];
        }

        drawShape(dc,segments,[60,10],Hcolor,Hcolor,3,null);

        var M1 = Math.floor(clockTime.min/10);
        var M2 = clockTime.min%10;
        
        for (var i=0;i<segments.size();i++){
            segments[i].hide=numbers[M1][i];
        }

        drawShape(dc,segments,[110,10],Mcolor,Mcolor,3,null);
        
        for (var i=0;i<segments.size();i++){
            segments[i].hide=numbers[M2][i];
        }

        drawShape(dc,segments,[157,10],Mcolor,Mcolor,3,null);        

    }

    function drawShape(dc,shapes,coord,frontColor,backColor,penWidth,options){

        dc.setColor(frontColor,backColor);
        dc.setPenWidth(penWidth);
        for (var i=0;i<shapes.size();i++) {
            var points=shapes[i].points;
            if(shapes[i].hide){continue;}
            switch(shapes[i].type){
            case :line :
                var p1=points[0];
                for ( var n=1;n<points.size();n++ ) {
                    dc.drawLine(coord[0]+p1[0],coord[1]+p1[1],coord[0]+points[n][0],coord[1]+points[n][1]);
                    p1=points[n];
                }
                break;
            case :box :
                var px=coord[0]+points[0][0];
                var py=coord[1]+points[0][1];
                var w =coord[0]+points[1][0]-px;
                var h =coord[1]+points[1][1]-py;
                if(shapes[i].fill){
                    dc.fillRectangle(px,py,w,h);
                }else{
                    dc.drawRectangle(px,py,w,h);
                }
                break;
            case :polygon :
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

    function drawAllSeconds(dc,toS){

        dc.setColor(MColor, Graphics.COLOR_TRANSPARENT);
        
        for (var s=0;s<toS;s++ ) {
            drawSecondDot(dc,s);
        }

    }

    function drawSecondDot(dc,s){

        var angle = s / 60.0 * Math.PI * 2.016666667;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
        var x = screenCenterPoint[0]+d*sin;
        var y = screenCenterPoint[1]-d*cos;
        y=(y<4)?4:y;
        var max=dc.getHeight()-4;
        y=(y>max)?max:y;


    function onPartialUpdate(dc) {

        if(!fullScreenRefresh) {
            drawBackground(dc);
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

class AnalogDelegate extends WatchUi.WatchFaceDelegate {

    function initialize(){
        WatchFaceDelegate.initialize();
    }
    // permet de limiter l'usage du rafraichissement par seconde
    // => surutilisation , alors on block le rafraichissement
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
        partialUpdatesAllowed = false;
    }
}

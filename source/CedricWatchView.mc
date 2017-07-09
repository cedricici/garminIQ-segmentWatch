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
    var segments = [
    new Shape(:polygon,[ [2,0],[24,0],[17,6],[7,6] ],true,false),
    new Shape(:polygon,[ [19,8],[26,2],[17,56],[11,52] ],true,false),
    new Shape(:polygon,[ [9,64],[16,62],[6,117],[1,111] ],true,false),
    new Shape(:polygon,[ [-11,113],[-1,113],[4,119],[-18,119] ],true,false),
    new Shape(:polygon,[ [-11,62],[-5,64],[-13,111],[-20,117] ],true,false),
    new Shape(:polygon,[ [0,2],[5,8],[-2,52],[-9,55] ],true,false),
    new Shape(:polygon,[ [-1,55],[9,55],[14,58],[9,61],[-4,61],[-8,59] ],true,false) 
    ];

    var batterie = [
    new Shape(:line,[ [0,3],[15,3],[9,38],[-6,38],[0,3] ],false,false),
    new Shape(:box,[ [6,0],[11,3] ],true,false)
    ];

    var mail = [
    new Shape(:box,[ [0,0],[19,12] ],false,false),
    new Shape(:line,[ [0,0],[10,7],[19,0] ],false,false)
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
                    Graphics.COLOR_LT_GRAY,
                    Graphics.COLOR_DK_GRAY,
                    Graphics.COLOR_BLACK,
                    frontColor
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

        var firstPartial=0;

        System.println("update, t="+clockTime.sec+"s ");


        // We always want to refresh the full screen when we get a regular onUpdate call.
        //fullScreenRefresh = true;

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
        targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        targetDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
        
        targetDc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        targetDc.fillCircle(screenCenterPoint[0],screenCenterPoint[1], (targetDc.getWidth()/2)-11);

        targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        targetDc.fillRectangle(0, 0, targetDc.getWidth(), 10);
        targetDc.fillRectangle(0,targetDc.getHeight()-10, targetDc.getWidth(), 10);

        drawTime(targetDc,clockTime);

        drawState(targetDc,mySettings.phoneConnected,mySettings.notificationCount);

        drawBattery(targetDc,myStats.battery);

        //flush Dbuffer in dc
        drawBackground(dc);

        //fullScreenRefresh = false;
        if ( isAwake  && partialUpdatesAllowed ) {
            onPartialUpdate(dc);
        }


    }



    // tracage des secondes par dessus
    // directement dans le DC mais avec un clip.
    function onPartialUpdate(dc) {


        var clockTime = System.getClockTime();
        var sec = clockTime.sec;
        var d=(dc.getWidth()/2)-4;


        if(firstPartial==0){
            drawAllSeconds(dc,sec);
            firstPartial=sec;
        }else{
            dc.setColor(frontColor, Graphics.COLOR_TRANSPARENT);
            drawSecondDot(dc,s);    
        }

        System.println("Partial "+firstPartial+" t="+sec+"s ");


    }



    function drawState(dc,btStatus,notifCount){

        if(btStatus){
            drawShape(dc,bluetooth,[178,110],frontColor,Graphics.COLOR_TRANSPARENT,2,null);
        }
        if(notifCount>0){
            drawShape(dc,mail,[177,83],frontColor,Graphics.COLOR_RED,2,null);
        }

    }

    function drawBattery(dc,batteryLevel){

        //calcul du polygon de chargement
        var batP = new[batterie[0].points.size()-1];
        for(var n=0;n<batP.size();n++){
            batP[n]=[batterie[0].points[n][0],batterie[0].points[n][1]];
        }

        var h=Math.floor((batP[3][1]-batP[0][1])*batteryLevel/100);
        var w=Math.floor((batP[0][0]-batP[3][0])*batteryLevel/100);
        
        batP[0][0]=batP[3][0]+w;
        batP[0][1]=batP[3][1]-h;
        batP[1][0]=batP[2][0]+w;
        batP[1][1]=batP[2][1]-h;


        var bl=new Shape(:polygon,batP,true,false);


        drawShape(dc,[bl],[23,67],frontColor,frontColor,2,null);
        
        drawShape(dc,batterie,[23,67],frontColor,Graphics.COLOR_TRANSPARENT,2,null);

    }


    function drawTime(dc,clockTime){
        var H1 = Math.floor(clockTime.hour/10);
        var H2 = clockTime.hour%10;
        
        for (var i=0;i<segments.size();i++){
            segments[i].hide=numbers[H1][i];
        }
        drawShape(dc,segments,[54,30],frontColor,frontColor,3,null);
        
        for (var i=0;i<segments.size();i++){
            segments[i].hide=numbers[H2][i];
        }
        drawShape(dc,segments,[84,30],frontColor,frontColor,3,null);
        
        dc.fillCircle(109,76,dotR);
        
        dc.fillCircle(105,103,dotR);

        var M1 = Math.floor(clockTime.min/10);
        var M2 = clockTime.min%10;
        
        for (var i=0;i<segments.size();i++){
            segments[i].hide=numbers[M1][i];
        }
        drawShape(dc,segments,[123,30],frontColor,frontColor,3,null);
        
        for (var i=0;i<segments.size();i++){
            segments[i].hide=numbers[M2][i];
        }
        drawShape(dc,segments,[153,30],frontColor,frontColor,3,null);
        

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

        dc.setColor(frontColor, Graphics.COLOR_TRANSPARENT);
        
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


        dc.setClip(x-dotR,y-dotR, dorR*2, dotR*2);
        dc.fillCircle(x,y,dotR);

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

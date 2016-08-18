//
// Copyright 2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.WatchUi as Ui;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Activity as Activity;

// This implements an analog watch face
// Original design by Austen Harbour
class AnalogView extends Ui.WatchFace
{
    var font;
    var isAwake;
    var screenShape;
    var dndIcon;
    var clockFace;


    function initialize() {
        WatchFace.initialize();
        screenShape = Sys.getDeviceSettings().screenShape;
    }

    function onLayout(dc) {
        font = Ui.loadResource(Rez.Fonts.id_font_black_diamond);

        clockFace = Ui.loadResource(Rez.Drawables.ClockFace);

        if (Sys.getDeviceSettings() has :doNotDisturb) {
            dndIcon = Ui.loadResource(Rez.Drawables.DoNotDisturbIcon);
        } else {
            dndIcon = null;
        }
    }

    function drawHand(dc, angle, length, width, endWidth) {
        // Map out the coordinates of the watch hand
        var halfEndWidth; 
        var coords;
        var result = new [4];
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
        
    	if(endWidth > 0) {
        	halfEndWidth = endWidth / 2;
        } else {
        	halfEndWidth = 0;
        }
        
        coords = [[-(width / 2),0], [-halfEndWidth, -length], [halfEndWidth, -length], [width / 2, 0]];

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [centerX + x, centerY + y];
        }

        // Draw the polygon
        dc.fillPolygon(result);
        dc.fillPolygon(result);
    }

	function drawStats(dc, screenWidth, screenHeight) {
	    var bluetooth;
		
		drawBatteryStat(dc);
		drawDeviceSettings(dc, screenWidth, screenHeight);
		drawActivityInfo(dc, screenWidth, screenHeight);
        drawAlt(dc, screenWidth, screenHeight);
        
	}

    function drawAlt(dc, screenWidth, screenHeight) {
        var info = Activity.getActivityInfo();

        dc.drawText(screenWidth - 2, screenHeight - 20, Gfx.FONT_XTINY, info.altitude.format( "%d" ) + " m", Gfx.TEXT_JUSTIFY_RIGHT);

    }
	
	function drawActivityInfo(dc, screenWidth, screenHeight) {
		var info = ActivityMonitor.getInfo();
        var distKm = info.distance.toFloat() / 100000; // convert from cm to km
		
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
        dc.drawText(2, screenHeight - 37, Gfx.FONT_TINY, distKm.format( "%.02f" ) + " km", Gfx.TEXT_JUSTIFY_LEFT);
		dc.drawText(2, screenHeight - 20, Gfx.FONT_SMALL, info.steps.format( "%d" ), Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(screenWidth - 2, screenHeight - 37, Gfx.FONT_TINY, info.floorsClimbed.format( "%d" ) + " fl", Gfx.TEXT_JUSTIFY_RIGHT);
	}
	
	function drawDeviceSettings(dc, screenWidth, screenHeight) {
        var deviceSettings = Sys.getDeviceSettings();
		var count = deviceSettings.alarmCount;
        var isConnected = deviceSettings.phoneConnected;
		
		dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
		dc.drawText(screenWidth - 6, 16, Gfx.FONT_SMALL, count.format( "%d" ), Gfx.TEXT_JUSTIFY_RIGHT);
        if(!isConnected) {
            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
            dc.fillPolygon([[screenWidth / 2 - 10, screenHeight - 16], [screenWidth / 2 + 10, screenHeight - 16], [screenWidth / 2 + 10, screenHeight - 30], [screenWidth / 2 - 10, screenHeight - 30]]);
            
        }
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
		
	}
	
	function drawBatteryStat(dc) {
	    var battery;
	    var color;
	    
		battery = Sys.getSystemStats().battery;
		color = Gfx.COLOR_DK_BLUE;
		if(battery < 30) {
			color = Gfx.COLOR_DK_RED;
		}
		dc.setColor(color, Gfx.COLOR_WHITE);
        dc.drawText(2, 16, Gfx.FONT_SMALL, battery.format( "%d" ), Gfx.TEXT_JUSTIFY_LEFT);
		
	}

    function drawDate(dateLong, dc, width) {
        var dateStr = Lang.format("$1$ $2$", [dateLong.day, dateLong.month]);
        var weekDay = dateLong.day_of_week;


        dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_WHITE);
        dc.drawText(width / 2 + 12, 0, Gfx.FONT_MEDIUM, dateStr, Gfx.TEXT_JUSTIFY_RIGHT);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
        dc.drawText(width / 2 + 50, 4, Gfx.FONT_XTINY, weekDay, Gfx.TEXT_JUSTIFY_RIGHT);
    }

    function drawHands(clockTime, dc, screenWidth, screenHeight) {
        var hourHand;
        var minuteHand;
        var secondHand;
        var secondTail;
        var timeString = format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);


        // Draw the hour. Convert it to minutes and compute the angle.
        hourHand = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHand = hourHand / (12 * 60.0);
        hourHand = hourHand * Math.PI * 2;
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
        drawHand(dc, hourHand, 44, 12, 0);

        // Draw the minute
        minuteHand = (clockTime.min / 60.0) * Math.PI * 2;
        drawHand(dc, minuteHand, 64, 12, 0);

        // Draw the second
        if (isAwake) {
            timeString += ":" + clockTime.sec.format("%02d");
            dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
            secondHand = (clockTime.sec / 60.0) * Math.PI * 2;
            secondTail = secondHand - Math.PI;
            drawHand(dc, secondHand, 64, 4, 0);
            drawHand(dc, secondTail, 15, 4, 4);
        }
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);        
        dc.drawText(screenWidth / 2, screenHeight - 18, Gfx.FONT_XTINY, timeString, Gfx.TEXT_JUSTIFY_CENTER);

    }

    function onUpdate(dc) {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        var clockTime = Sys.getClockTime();        
        var now = Time.now();        
        var dateLong = Calendar.info(now, Time.FORMAT_LONG);



        // Clear the screen
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.fillRectangle(0, 0, screenWidth, screenHeight);

        //Draw clock face
        dc.drawBitmap( 0, 0, clockFace);        

        drawDate(dateLong, dc, screenWidth);

        drawHands(clockTime, dc, screenWidth, screenHeight);

        
        drawStats(dc, screenWidth, screenHeight);


        // Draw the arbor
        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
        dc.fillCircle(screenWidth / 2, screenHeight / 2, 7);
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
        dc.fillCircle(screenWidth / 2, screenHeight / 2, 4);
        

    }

    function onEnterSleep() {
        isAwake = false;
        Ui.requestUpdate();
    }

    function onExitSleep() {
        isAwake = true;
    }
}

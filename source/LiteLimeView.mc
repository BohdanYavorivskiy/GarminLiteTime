using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Time;
using Toybox.Time.Gregorian;

class LiteLimeView extends WatchUi.WatchFace {
var sunTimes = new SunTimesCache();

private var fontHours = Graphics.FONT_SYSTEM_NUMBER_HOT;//FONT_NUMBER_HOT;
private var fontDate = Graphics.FONT_SYSTEM_XTINY;
private var fontBat = Graphics.FONT_SYSTEM_XTINY;
private var fontHoursMarks = Graphics.FONT_SYSTEM_XTINY;
private var centerX = null;
private var centerY = null;
private var fontHoursHeigth = null;
private var fontDateHeigth = null;
private var fontBatHeigth = null;

private var image = null;

private const BackgroundColor = Graphics.COLOR_BLACK;
private const DailyLightColor = Graphics.COLOR_DK_GREEN; 
private const DailyLightColorDuskLite = 0x005500; 
private const DailyLightColorDusk = 0x005555; 
private const DailyMarksColor = Graphics.COLOR_WHITE;
private const DailyHoursMarksColor = Graphics.COLOR_LT_GRAY;
private const TimeColorMain = Graphics.COLOR_WHITE;
private const DateColor = Graphics.COLOR_WHITE;
private const BatColor = Graphics.COLOR_LT_GRAY;

private var converter;
private var lastMajorRedrawTime = 0;

    function initialize() 
    {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) 
    {
    	var settings = System.getDeviceSettings();
    	
    	// init converter
    	converter = new ConverterXY(dc.getWidth() / 2);
    
    	centerX = (dc.getWidth() - 1) / 2;
   	    centerY = (dc.getHeight() - 1) / 2;
   	    fontHoursHeigth = dc.getFontHeight(fontHours);
   	    fontDateHeigth = dc.getFontHeight(fontDate);
   	    fontBatHeigth = dc.getFontHeight(fontBat);
   	    
   	    // load mountain mg and calc position
		image = new WatchUi.Bitmap({:rezId=>Rez.Drawables.MountainsImg });
    	image.locX = centerX - image.getDimensions()[0] / 2	;
		image.locY = centerY + fontHoursHeigth / 2 + (centerY / 10);
		
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {    }

    // Update the view
    function onUpdate(dc)
    {
    	var timeDiff = lastMajorRedrawTime - Time.now().value();
    	if (timeDiff.abs() >= 550)
    	{
    		majorRedraw(dc, true);
    	
	// debug update	
		    	var currentTime = System.getClockTime();
				dc.setColor(TimeColorMain, BackgroundColor);			
		    	var timeStr = Lang.format("$1$:$2$",[currentTime.hour.format("%02d"), currentTime.min.format("%02d")]);
		    	var batPos =  converter.convert(270, 90); 
		    	dc.drawText(batPos.x, batPos.y, fontBat, timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);	
		}
		
	 // main time
	 	var currentTime = System.getClockTime();
		dc.setColor(TimeColorMain, BackgroundColor);			
    	var timeStr = Lang.format("$1$:$2$",[currentTime.hour.format("%02d"), currentTime.min.format("%02d")]);
    	dc.drawText(centerX, centerY - (fontHoursHeigth / 2), fontHours, timeStr, Graphics.TEXT_JUSTIFY_CENTER);	
   		
    // date
		dc.setColor(DateColor, BackgroundColor);
		var calendar = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);  
    	var dateStr =  Lang.format("$1$ $2$ ", [calendar.month, calendar.day.format("%02d")]);
    	var datePos =  converter.convert(90, 45); 
		dc.drawText(datePos.x, datePos.y, fontDate, dateStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

    // battary
//    	dc.setColor(BatColor, BackgroundColor);
//    	var batStr =  Lang.format("$1$% ", [System.getSystemStats().battery.format("%03.1f")]);
//    	var batPos =  converter.convert(270, 90); 
//		dc.drawText(batPos.x, batPos.y, fontBat, batStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    	
    
//        dc.setColor(Graphics.COLOR_YELLOW, BackgroundColor);
//		dc.setPenWidth(1);
//		dc.drawArc(centerX, centerY, centerX - 5, Graphics.ARC_CLOCKWISE, 1, 359);
//		dc.drawArc(centerX, centerY, centerX - 5, Graphics.ARC_CLOCKWISE, 91, 89);
//		dc.drawArc(centerX, centerY, centerX - 5, Graphics.ARC_CLOCKWISE, 181, 179);
//		dc.drawArc(centerX, centerY, centerX - 5, Graphics.ARC_CLOCKWISE, 271, 269);
    }

	function majorRedraw(dc, isExtended)
	{
		dc.setColor(BackgroundColor, BackgroundColor);
		dc.clear();

	// draw mountains
		image.draw(dc);
    
    	drawDailyMarks(dc);
		drawDailyLight(dc, sunTimes.requestData(isExtended), isExtended);
		
	// ceche
		lastMajorRedrawTime = Time.now().value();
	}
	
	function timeToDegree(time) 
	{
		var degree = ((time.hour + (time.min / 60.0)) * 15).toNumber() + 90;
		return 360 - (degree % 360);
	}
	
    function drawDailyLight(dc, times, reqExtended) 
    {
    // up - 12 // 90
    // down - 24 // 270
    // left - 6 // 180
    // right - 18 // 0
    	if (times == null || times.sunrise == null || times.sunset == null)
    	{
    		return;
		}

		dc.setPenWidth(6);

		var maxSunriseDegree = null;
		var maxSunsetDegree = null;
		
		if (reqExtended && times.isExpanded)
		{
			if (times.sunriseDusk != null && times.sunsetDusk != null)
			{
				maxSunriseDegree = timeToDegree(times.sunriseDusk);
    			maxSunsetDegree = timeToDegree(times.sunsetDusk);
    			dc.setColor(DailyLightColorDusk, BackgroundColor);
    			dc.drawArc(centerX, centerY, centerX - 2, Graphics.ARC_CLOCKWISE, maxSunriseDegree, maxSunsetDegree);
			}
			
			if (times.sunriseLiteDusk != null && times.sunsetLiteDusk != null)
			{
				var sunriseDegree = timeToDegree(times.sunriseLiteDusk);
    			var sunsetDegree = timeToDegree(times.sunsetLiteDusk);
    			dc.setColor(DailyLightColorDuskLite, BackgroundColor);
    			dc.drawArc(centerX, centerY, centerX - 2, Graphics.ARC_CLOCKWISE, sunriseDegree, sunsetDegree);
			}
		}
		
    	var sunriseDegree = timeToDegree(times.sunrise);
    	var sunsetDegree = timeToDegree(times.sunset);
    		
		if (maxSunriseDegree == null || maxSunsetDegree == null)
		{
			maxSunriseDegree = sunriseDegree;
			maxSunsetDegree = sunsetDegree;
		}
		
    	dc.setColor(DailyLightColor, BackgroundColor);

    	dc.drawArc(centerX, centerY, centerX - 2, Graphics.ARC_CLOCKWISE, sunriseDegree, sunsetDegree);
    	    	
    	// draw current time
		var currentTime = System.getClockTime();
    	var currentTimeDegree = timeToDegree(currentTime);
    	var pi = converter.convert(currentTimeDegree, 88);
    	
    	var degreeWidth = 2.5;

		var posExtL = converter.convert(currentTimeDegree - degreeWidth, 100);
		var posExtR = converter.convert(currentTimeDegree + degreeWidth, 100);
		var posIntL = converter.convert(currentTimeDegree - degreeWidth, 97);
		var posIntR = converter.convert(currentTimeDegree + degreeWidth, 97);
		var posIntCenterL = converter.convert(currentTimeDegree - 0.6, 92);
		var posIntCenterR = converter.convert(currentTimeDegree + 0.6, 92);
		var arr =  [[posIntL.x.toNumber(), posIntL.y.toNumber()], 
					[posExtL.x.toNumber(), posExtL.y.toNumber()], 
					[posExtR.x.toNumber(), posExtR.y.toNumber()], 
					[posIntR.x.toNumber(), posIntR.y.toNumber()], 
					[posIntCenterR.x.toNumber(), posIntCenterR.y.toNumber()],
					[posIntCenterL.x.toNumber(), posIntCenterL.y.toNumber()]];
		dc.fillPolygon(arr);
    	
    	if(currentTimeDegree < maxSunriseDegree + 5 && currentTimeDegree > maxSunsetDegree - 5)//TODO; change to times compare
    	{
    		dc.setColor(BackgroundColor, BackgroundColor);
    		dc.setPenWidth(2);
    	
    		var lineShift = degreeWidth + 0.5;
    		var posLineExtL = converter.convert(currentTimeDegree - lineShift, 100);
			var posLineExtR = converter.convert(currentTimeDegree + lineShift, 100);
    		var posLineIntL = converter.convert(currentTimeDegree - lineShift, 94);
			var posLineIntR = converter.convert(currentTimeDegree + lineShift, 94);
    		dc.drawLine(posLineExtL.x, posLineExtL.y, posLineIntL.x, posLineIntL.y);
    		dc.drawLine(posLineExtR.x, posLineExtR.y, posLineIntR.x, posLineIntR.y);
    	}
    }

    function drawDailyMarks(dc) 
    {
    	var MarkLenTo = 92;
    	var MainMarkLenTo = 88;
    	var MarkHourPos = 77;
    	var screenRadius = centerX;
    	
    	dc.setColor(DailyMarksColor, BackgroundColor);
    	dc.setPenWidth(1);
    		
    	for(var i = 0; i < 360; i += 15)
		{
		    if (i % 90 != 0 && i != 255 && i != 285)
	       	{
   			    var pi = converter.convert(i, MarkLenTo);
				var pe = converter.convert(i, 100);
    			dc.drawLine(pi.x, pi.y, pe.x, pe.y);
			}
    	}
    	
    	dc.setPenWidth(2);
    	
    	for(var i = 0; i < 270; i += 90)
		{
   		    var pi = converter.convert(i, MainMarkLenTo);
			var pe = converter.convert(i, 100);
    		dc.drawLine(pi.x, pi.y, pe.x, pe.y);
    	}
    	
    	
    	dc.setColor(DailyHoursMarksColor, BackgroundColor);
    	var hourValue = 24;
    	for(var i = 0; i < 270; i += 90)
		{
    		hourValue -= 6;
    		var hourPos = converter.convert(i, MarkHourPos);
    		var timeStr = Lang.format("$1$",[hourValue.format("%02d")]);
    		dc.drawText(hourPos.x, hourPos.y, fontHoursMarks, timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);	
    	}
	}

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() 
    {
    	 //majorRedraw(dc, true);
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() 
    {
    	// majorRedraw(dc, false);
    }

}

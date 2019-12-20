using Toybox.System;
using Toybox.Lang;
using Toybox.Time.Gregorian;
//using SunTimes;

class SunTimesCache
{
	var cache = new SunTimesData();
	var engine = new SunTimesEngine();
	
	var lastReculcTime = null;
	var lastReculcTimeZone = null; // in sec offset
	var lastReculcLocation = null;
	
	var currentTime = null;
	var currentTimeZone = null; // in sec offset
	var currentLocation = null;
	
function requestData(reqExpandedData)
{
	currentLocation = getLocation();
			
	if (isLastTimeActual() && !locationWasCanged())
	{	
		if (reqExpandedData == false || cache.isExpanded == reqExpandedData)
		{
			return cache;
		}
	}

	var locationForCalc = null;
	if (currentLocation != null)
	{
		locationForCalc = currentLocation;
	}
	if (lastReculcLocation != null)
	{
		locationForCalc = lastReculcLocation;
	}
	if (locationForCalc == null) // cant calc, because hasnt location
	{	
		return null;
	}
	cache = engine.calcTimes(locationForCalc, reqExpandedData);
	
	// update cache
	lastReculcTime = currentTime;
	lastReculcTimeZone = currentTimeZone;
	lastReculcLocation = locationForCalc;

	return cache;
} 

function locationWasCanged()
{
	if (lastReculcLocation != null && currentLocation != null)
	{
		if (lastReculcLocation[1].toFloat().toNumber() != currentLocation[1].toFloat().toNumber()
			|| lastReculcLocation[0].toFloat().toNumber() != currentLocation[0].toFloat().toNumber())
		{
			return true;
		}
	}
	return false;
}

function isLastTimeActual()
{
	currentTime = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
	currentTimeZone = System.getClockTime().timeZoneOffset;
	
	if (lastReculcTime == null || lastReculcTime.day != currentTime.day 
		|| currentTimeZone != lastReculcTimeZone)
 	{
 		return false;
 	}

	return true; 	
}

function getLocation() 
{
	var pos = Activity.getActivityInfo().currentLocation;
	if (pos != null)
	{
		pos = pos.toDegrees();
//		App.getApp().setProperty("location", pos); // save the location to fix a Fenix 5 bug that is loosing the location often
		return pos;
	}
	
//	pos = App.getApp().getProperty("location"); // load the last location to fix a Fenix 5 bug that is loosing the location often
	return pos;
}
}
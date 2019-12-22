using Toybox.Math as Math;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;

class SunTimesData
{
	var sunrise = null;
	var sunset = null;
	
	var isExpanded = false;
	
	var sunriseLiteDusk = null; 	
	var sunsetLiteDusk = null; 	
	var sunriseDusk = null;	
	var sunsetDusk = null;		
}

class SunTimesEngine
{
    const D2R = Math.PI / 180.0d;
    const R2D = 180.0d / Math.PI;	
	const OfficialZenith = 90.83333333333333; 
	const LiteDuskZenith = 96.0; 
	const DuskZenith = 102.0; 
	
function toClockTime(value) // convert value from computeSunriset to ClockTime
{
	var clockTime = System.getClockTime();
	clockTime.hour = value.toNumber() % 24;
	clockTime.min = ((value - clockTime.hour) * 60) + 0.5;
	return clockTime;
}
	
function calcTimes(location, reqExpandedData) 
{
	if (location == null)
	{
		return null;
	}
	
	// use absolute to get west as positive
	var lonW = location[1].toFloat();
	var latN = location[0].toFloat();

	// compute current date as day number
	var utcOffset = System.getClockTime().timeZoneOffset;
	var timeInfo = Calendar.info(Time.now().add(new Time.Duration(utcOffset)), Calendar.FORMAT_SHORT);
	var now = dayInYear(timeInfo.day, timeInfo.month);
	
	// for adjust to timezone + dst when active

	var sunriseT = computeSunriset(now, lonW, latN, true, OfficialZenith);
	var sunsetT = computeSunriset(now, lonW, latN, false, OfficialZenith);
	
	// if newer sunset / sunrise
	if (sunriseT == null || sunsetT == null)
	{
	  	return new SunTimesData();
	}
	
	var offset = new Time.Duration(utcOffset).value() / 3600;
	var data = new SunTimesData();
	data.sunrise = toClockTime(sunriseT + offset);
	data.sunset = toClockTime(sunsetT + offset);
	
	// handle reqExpandedData
	if (reqExpandedData)
	{	
		data.isExpanded = true;
		
		var duskTimes = computeSunriset(now, lonW, latN, false, LiteDuskZenith);
		if (duskTimes != null)
		{
			data.sunsetLiteDusk = toClockTime(duskTimes + offset);
		}
		
		duskTimes = computeSunriset(now, lonW, latN, true, LiteDuskZenith);
		if (duskTimes != null)
		{
			data.sunriseLiteDusk = toClockTime(duskTimes + offset); 	
		}
		
		duskTimes = computeSunriset(now, lonW, latN, false, DuskZenith);
		if (duskTimes != null)
		{
			data.sunsetDusk = toClockTime(duskTimes + offset); 	
		}
		
		duskTimes = computeSunriset(now, lonW, latN, true, DuskZenith);
		if (duskTimes != null)
		{
			data.sunriseDusk = toClockTime(duskTimes + offset); 	
		}
	}
	
	return data;
}

// returns the number of the day from 0 to 365
function dayInYear(day, month)
{
	var arr = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365];
	return arr[month - 1] + day;
    //Sys.println("dayOfYear: " + dayOfYear.format("%d"));
}

function computeSunriset (day, longitude, latitude, sunrise, zenith)
{
    // convert the longitude to hour value and calculate an approximate time
    var lnHour = longitude / 15;
    var t;
    if (sunrise)
    {
        t = day + ((6 - lnHour) / 24);
    }
    else
    {
        t = day + ((18 - lnHour) / 24);
    }

    //calculate the Sun's mean anomaly
    var M = (0.9856 * t) - 3.289;

    //calculate the Sun's true longitude
    var L = M + (1.916 * Math.sin(M * D2R)) + (0.020 * Math.sin(2 * M * D2R)) + 282.634;
    if (L >= 360)
    {
        L -= 360;
    } 
    else if (L < 0)
    {
        L += 360;
    }

    //calculate the Sun's right ascension
    var RA = R2D * Math.atan(0.91764 * Math.tan(L * D2R));
    if (RA >= 360)
    {
        RA -= 360;
    } 
    else if (RA < 0)
    {
        RA += 360;
    }

    //right ascension value needs to be in the same qua
    var Lquadrant = (floor(L / 90)) * 90;
    var RAquadrant = (floor(RA / 90)) * 90;
    RA = RA + (Lquadrant - RAquadrant);

    //right ascension value needs to be converted into hours
    RA = RA / 15;

    //calculate the Sun's declination
    var sinDec = 0.39782 * Math.sin(L * D2R);
    var cosDec = Math.cos(Math.asin(sinDec));

    //calculate the Sun's local hour angle
    var cosH = (Math.cos(zenith * D2R) - (sinDec * Math.sin(latitude * D2R))) / (cosDec * Math.cos(latitude * D2R));
    
//	  the sun never rises on this location (on the specified date)
//	  the sun never sets on this location (on the specified date)
	if (cosH > 1 || cosH < -1)
	{
		return null;
	}
		    
    var H;
    if (sunrise) 
    {
        H = 360 - R2D * Math.acos(cosH);
    } 
    else 
    {
        H = R2D * Math.acos(cosH);
    }
    H = H / 15;

    //calculate local mean time of rising/setting
    var T = H + RA - (0.06571 * t) - 6.622;

    //adjust back to UTC
    var UT = T - lnHour;
    if (UT >= 24) 
    {
        UT -= 24;
    } 
    else if (UT < 0)
    {
        UT += 24;
    }
    return UT;
}

function floor (f)
{
	if  (f >= 0)
	{
		return f.toNumber();
	}
	return (f + 1.0).toNumber();// -3.4 => -3
} 

}

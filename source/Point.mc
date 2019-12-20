using Toybox.Math as Math;

class Point
{
	var x = 0;
	var y = 0;
}

class ConverterXY
{
protected var screenRadius,
  	screenCenterShift,
  	screenRadiusOnPercent;

protected const RAD = Math.PI / 180.0;
 
function initialize( screenRad )
{
  	self.screenRadius = screenRad;
  	// real screen radius = (screenW / 2) - 0.5; because pixels are numeration from 0;
  	screenCenterShift = screenRad - 0.5;
  	screenRadiusOnPercent = screenRad / 100.0;
}
    
//0 degrees: 3 o'clock position.
//90 degrees: 12 o'clock position.
//180 degrees: 9 o'clock position.
//270 degrees: 6 o'clock position.

function convert(degree, percent) // percent from center
{
	var p = new Point();
    
    p.x = (Math.cos(degree * RAD) * (screenRadiusOnPercent * percent)) + screenCenterShift;			
	p.y = (Math.sin(-degree * RAD) * (screenRadiusOnPercent * percent)) + screenCenterShift;
	
	return p;
}
}
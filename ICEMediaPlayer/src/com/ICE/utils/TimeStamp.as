package com.ICE.utils {	
	
	
	
	/**
	 * ...
	 * @author Paul Makarov
	 */

    public  class TimeStamp 
	{
		public static var timeStamp:Date;
		
		public function TimeStamp()
		{
			timeStamp = new Date();
		}
		
		public static function get NewTimeStamp():Date 
		{
			timeStamp = new Date();
			return timeStamp;
		}

    }
}
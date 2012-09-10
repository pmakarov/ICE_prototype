package com.ICE.utils 
{
	import flash.display.LoaderInfo;
	/**
	 * ...
	 * @author Paul Makarov
	 */
	public class FlashVarUtil
	{
		public static var paramObj:Object;
		
		public static function setFlashVar(obj:Object):Boolean
		{
			
			var count:int = 0;
			for (var varName:String in obj) 
			{
				trace(String(obj[varName]));
				count++;
			}
			paramObj =  obj;
			return (count > 0) ? true : false;
			
		}
		
		public static function getValue(key:String):String
		{
		    if( paramObj[ key ])
            return paramObj[key] as String;
            else return "";

			
		}


		public static function hasKey(key:String):Boolean
		{	
			return FlashVarUtil.getValue(key) ? true : false;
		}
		
		
	}

}
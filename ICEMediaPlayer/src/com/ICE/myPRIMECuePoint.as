package com.ICE
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	/**
	 * ...
	 * @author Paul Makarov
	 */
	public class  myPRIMECuePoint extends EventDispatcher
	{
		public var time:Number = 0;
		public var type:String = "";
		public var interrupt:Boolean = false;
		public var id:String = "";
		public var actions:Array = new Array();
		public var savePoint:Boolean;
		public var spRef:MovieClip;
		public var complete:Boolean = false;
		public function myPRIMECuePoint(xml:XML = null):void
		{
			time = xml.@time;
			id = xml.@id;
			type = xml.@type;
			
			
			for each ( var command:XML in xml..action )
			{
				var tmp:Object = new Object();
				tmp.type = command.@type.toString();
				tmp.interrupt = command.@interrupt;
				if (tmp.type == "save")
				{
					savePoint = true;
				}
				tmp.data = command.toString();
				actions.push(tmp);
			}
		}
		
		public function getActions() : Array
		{
			return actions;
		}
		
		
	}
	
}
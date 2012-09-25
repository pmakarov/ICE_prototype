package com.ICE
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	/**
	 * ...
	 * @author Paul Makarov
	 */
	public class  ICECuePoint extends EventDispatcher
	{
		public var time:Number = 0;
		public var type:String = "";
		public var interrupt:Boolean = false;
		public var id:String = "";
		public var begin:String = "";
		public var dur:String = "";
		public var actions:Array = new Array();
		public var savePoint:Boolean;
		public var spRef:MovieClip;
		public var complete:Boolean = false;
		
		public function ICECuePoint(xml:XML = null):void
		{
			time = xml.@time;
			id = xml.@id;
			type = xml.@type;
			dur = xml.@dur;
			begin = xml.@begin;
			
			
			for each ( var command:XML in xml..action )
			{
				var tmp:Object = new Object();
				tmp.type = command.@type.toString();
				tmp.interrupt = command.@interrupt;
				tmp.src = command.@src;
				if (tmp.type == "save")
				{
					savePoint = true;
				}
				tmp.data = command.toString();
				tmp.dur = dur;
				actions.push(tmp);
			}
		}
		
		public function getActions() : Array
		{
			return actions;
		}
		
		
	}
	
}
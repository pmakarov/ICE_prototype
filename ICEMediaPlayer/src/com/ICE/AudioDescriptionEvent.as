package com.ICE
{
	import flash.events.Event;
	
	
	public class AudioDescriptionEvent extends Event
	{
		public static const AUDIO_DESCRIPTION_EVENT: String = "audioDescriptionEvent";

		public var data:Object;

		public function AudioDescriptionEvent(type:String, data: Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);

			this.data = data;
		}

		override public function clone():Event
		{
			return new AudioDescriptionEvent (type, data, bubbles, cancelable);
		}

	}

}
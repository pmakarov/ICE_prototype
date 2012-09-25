package com.ICE.utils 
{
	import com.ICE.ICECuePoint;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class VideoXMLLoader extends EventDispatcher
	{
		protected var xml:XML;
		protected var scene:Object;
		protected var steps:Array = [];
		protected var totalSavePoints:uint = 0;
		protected var url:String;
		protected var caption:String;
		protected var captionText:String;
		protected var audioDescriptionText:String;
		
		public function VideoXMLLoader(url:String) 
		{
			super(this);
			var loader:URLLoader = new URLLoader();			
			loader.addEventListener( Event.COMPLETE, onLoadXML );
			loader.dataFormat = "e4x";
			loader.load( new URLRequest(url) );
		}
		
		protected function onLoadXML( e:Event ) : void
		{
					
			var loader:URLLoader = e.target as URLLoader;
			xml = new XML(loader.data);	
			this.url = xml.element.file.@src.toString();
			this.caption = xml.element.caption.@src.toString();
			this.captionText = xml.element.caption.toString();
			this.audioDescriptionText = xml.element.audioDescriptionText.toString();
			for each (var cues:XML in xml..cuePoint)
			{
				steps.push( new ICECuePoint(cues));
				if (steps[steps.length - 1].savePoint)
				{
					totalSavePoints++;
				}
			}
			
			dispatchEvent( new Event(Event.COMPLETE) );
		}
		
		public function getURL(): String {return url;}
		
		public function getCuePoints() : Array { return steps; }
		
		public function getTotalSavePoints():uint { return totalSavePoints; }
		
		public function getCaptionURL():String { return caption; }
		
		public function getCaption():String { return captionText; }
		
		public function getAudioDescriptionURL():String { return audioDescriptionText;}
		
		
	}
	
}

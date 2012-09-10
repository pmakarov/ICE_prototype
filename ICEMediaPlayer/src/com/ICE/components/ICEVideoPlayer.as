package com.ICE.components
{
	import com.ICE.FeedbackEvent;
	import com.ICE.FontManager;
	import com.ICE.utils.VideoXMLLoader;
	import com.greensock.TweenMax;
	import fl.video.FLVPlayback;
	import fl.video.MetadataEvent;
	import fl.video.VideoEvent;
	import fl.video.VideoPlayer;
	import fl.video.VideoScaleMode;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.net.*;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Mouse;
	import flash.utils.Timer;

	/**
	 * ...
	 * @author pmakarov
	 */
	public class ICEVideoPlayer extends Sprite
	{
		private var videoPlayBack:FLVPlayback;
		private var videoPath:String = "";
		private var pbBG:videoProgressBarBG; 
		private var pb:videoProgressBar;
		private var videoContainer:Sprite;
		private var hArea:Sprite;
		private var vol:volumeControl;
		private var playPause:videoPlayButton;
		private var videoControlsContainer:MovieClip;
		private var videoXML:VideoXMLLoader;
		private var cuePoints:Array;
		private var savePoints:Array;
		private var spCounter:uint = 0;
		private var cueCount:uint = 0;
		public var complete:Boolean = false;
		private var time:String = "";
		private var bolProgressScrub:Boolean = false;
		private var bolVolumeScrub:Boolean = false;
		private var scrubber:ProgressScrubber;
		private var volumeScrubber:MovieClip;
		private var tmrDisplay:Timer;
		private var myTimer:Timer;
		private var previousVolumePosition:Number;
		private const DISPLAY_TIMER_UPDATE_DELAY:int = 10;
		private var capBox:captionBox;
		private var captionText:TextField;
		public var caption:String;
		public var captionURL:String;
		private var showMouse:Boolean = true;
		
		
		public function ICEVideoPlayer(videoXML:VideoXMLLoader = null):void 
		{
			videoContainer = new Sprite();
		
			var vbg:MovieClip = new MovieClip();
			vbg.x = 0;
			vbg.y = 0;
			
			videoContainer.addChild(vbg);
			
			videoPlayBack = new FLVPlayback();
			videoPlayBack.autoPlay = false;
			videoPlayBack.scaleMode = VideoScaleMode.EXACT_FIT;
			
			//this.addEventListener(Event.REMOVED_FROM_STAGE,deactivate); 
			
			videoContainer.addChild(videoPlayBack);
			//videoContainer.addEventListener(MouseEvent.ROLL_OVER, handleVideoRollOver);
			//videoContainer.addEventListener(MouseEvent.ROLL_OUT, handleVideoRollOut);
			videoControlsContainer = new MovieClip();
			
			buildVideoControls();
			
			capBox = new captionBox();
			//capBox.width = 1018;
			capBox.y = videoContainer.y;
			capBox.width = videoContainer.width / 2;
			capBox.height = 405 - 36;
			capBox.x = videoContainer.width / 2;
			
			
			var format:TextFormat = new TextFormat();
			format.font = "Arial";
			format.color = 0xFFFFFF;
            format.size = 16;
			format.align = "left";
			//format.bold = true;
						
			captionText = new TextField();
			captionText.autoSize = TextFieldAutoSize.LEFT;
            //captionText.background = true; //use true for doing generic labels
			//captionText.backgroundColor = 0x000000;
            //captionText.border = true;      // ** same
			captionText.multiline = true;
			captionText.antiAliasType = "advanced";
			captionText.gridFitType = GridFitType.NONE;
			captionText.sharpness = -200;
			captionText.wordWrap = true;
            captionText.defaultTextFormat = format;			
			captionText.x = capBox.x + 8
			captionText.y = 0;
			captionText.width = capBox.width - 20;
			captionText.htmlText = "";
			captionText.name = "captionText";
			captionText.tabEnabled = true;
			capBox.addChild(captionText);
			capBox.visible = captionText.visible = false;
			videoContainer.addChild(capBox);
			videoContainer.addChild(captionText);
			
			videoContainer.name = "container";
			addChild(videoContainer);
			
			videoPlayBack.source = videoXML.getURL();	
			this.captionURL = videoXML.getCaptionURL();
			this.caption = videoXML.getCaption();
			
			this.addEventListener("CUE_COMPLETE", cueCompleteHandler);
			videoPlayBack.addEventListener( MetadataEvent.CUE_POINT, doCuePoint);	
			videoPlayBack.addEventListener(MetadataEvent.METADATA_RECEIVED, metadataReceived);
			videoPlayBack.addEventListener(VideoEvent.STATE_CHANGE, videoStateHandler);
			videoPlayBack.addEventListener(VideoEvent.PLAYHEAD_UPDATE, progressHandler);
			videoPlayBack.addEventListener(VideoEvent.COMPLETE, handleVideoComplete); 
			tmrDisplay = new Timer(DISPLAY_TIMER_UPDATE_DELAY);
			tmrDisplay.addEventListener(TimerEvent.TIMER, updateDisplay);
			myTimer = new Timer(3000, 1);
			myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timerHandler);
			
			setVolume(1);			
			if (videoXML.getCuePoints().length > 0)
			{
				addCuePoints(videoXML);
			}
			else
			{
				videoPlayBack.play();
			}
			
			
		}	
		public function deactivate(e:Event):void
		{
			
			trace("Deactivating an ICEVideo"); 
			this.removeEventListener("CUE_COMPLETE", cueCompleteHandler);
			tmrDisplay.removeEventListener(TimerEvent.TIMER, updateDisplay);
			myTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, timerHandler);
			hArea.removeEventListener(MouseEvent.CLICK, onClick);
			playPause.removeEventListener(MouseEvent.CLICK, togglePlayPauseButton);
			pbBG.removeEventListener(MouseEvent.CLICK, progressClick);
			vol.muteButton.removeEventListener(MouseEvent.CLICK, toggleMute);
			this.removeEventListener(MouseEvent.MOUSE_MOVE, showPanel);
			stage.removeEventListener( MouseEvent.MOUSE_UP, mouseReleased);
			dispatchEvent(new Event("VIDEO_DEACTIVATED"));
		}
		private function buildVideoControls():void
		{
			hArea = new Sprite();
			hArea.graphics.beginFill(0x0000FF);
			hArea.alpha = 0;
			hArea.graphics.drawRect(0,0,721,405);
			hArea.graphics.endFill();
			hArea.x = 721/2-hArea.width/2;
			//hArea.y = 721/2-hArea.height/2;
			hArea.y =0;
			hArea.addEventListener(MouseEvent.CLICK, onClick);
			videoControlsContainer.addChild(hArea);
			
			var mediaBG:mediaBarBG = new mediaBarBG();
			mediaBG.width = 721;
			mediaBG.x = 721 / 2 - mediaBG.width / 2;
			mediaBG.y = 405 - mediaBG.height;
			videoControlsContainer.addChild(mediaBG);
			
			pbBG = new videoProgressBarBG();
			pbBG.height = 6;
			pbBG.width = 480;
			pbBG.x = mediaBG.x + 41;
			pbBG.y = mediaBG.y + (mediaBG.height - pbBG.height)/2;
			videoControlsContainer.addChild(pbBG);
			pbBG.addEventListener(MouseEvent.CLICK, progressClick);
			
			pb = new videoProgressBar();
			pb.mouseEnabled = false;
			pb.height = 4;
			pb.width = 0;
			pb.alpha = .5;
			pb.x = mediaBG.x + 41;
			pb.y = mediaBG.y + (mediaBG.height - pbBG.height) / 2 + 1;
			pb.name = "progressBar";
			videoControlsContainer.addChild(pb);

			
			/*scrubber = new ProgressScrubber();
			scrubber.x = pb.x + 5;
			scrubber.y = pb.y - 2;
			scrubber.addEventListener(MouseEvent.MOUSE_DOWN, progressScrubberClicked);
			videoControlsContainer.addChild(scrubber);*/
			
			playPause = new videoPlayButton();
			playPause.x = mediaBG.x + 6;
			playPause.y = mediaBG.y + (mediaBG.height - playPause.height)/2;
			playPause.addEventListener(MouseEvent.CLICK, togglePlayPauseButton);
			playPause.name = "playPause";
			playPause.buttonMode = true;
			playPause.tabEnabled = true;
			
			
			videoPlayBack.playPauseButton = playPause;
			
			videoControlsContainer.addChild(playPause);
			
			var format:TextFormat = new TextFormat();
			//format.font = "Verdana";
			format.font = FontManager.ButtonTextFormatWhite.font;
			format.color = 0xFFFFFF;
            format.size = 10;
			format.bold = true;
						
			var timeText_mc:TextField = new TextField();
			timeText_mc.autoSize = TextFieldAutoSize.LEFT;
            timeText_mc.background = false; //use true for doing generic labels
            timeText_mc.border = false;      // ** same
			//timeText_mc.embedFonts = true;
			timeText_mc.antiAliasType = "advanced";
			timeText_mc.gridFitType = GridFitType.NONE;
			//timeText_mc.sharpness = -200;
			timeText_mc.wordWrap = false;
            timeText_mc.defaultTextFormat = format;			
			timeText_mc.x = pbBG.x + pbBG.width + 24;
			timeText_mc.y = pbBG.y - 5;
			timeText_mc.width = 200;
			timeText_mc.text = "00 : 00";
			timeText_mc.name = "time";
			videoControlsContainer.addChild(timeText_mc);
			TweenMax.to(timeText_mc, .6, {glowFilter:{ color:0xDDEEFF, alpha:1, blurX:10, blurY:10 , strength:1, quality:3 }} );
			
			vol  = new volumeControl();
			vol.x = mediaBG.x + mediaBG.width - (vol.width) + 2;
			vol.y = mediaBG.y + 6;
			vol.buttonMode = true;
			//vol.addEventListener(MouseEvent.ROLL_OVER, handleVolumeControlRollOver);
			//vol.addEventListener(MouseEvent.ROLL_OUT, handleVolumeControlRollOut);
			videoControlsContainer.addChild(vol);
			
			//vol.control.alpha = 1;
			//volumeScrubber = vol.control.scrub as MovieClip;
			//volumeScrubber.addEventListener(MouseEvent.MOUSE_DOWN, volumeScrubberClicked);
			vol.gotoAndStop(1);
			vol.muteButton.addEventListener(MouseEvent.CLICK, toggleMute);
			
			/*var cc:closedCaption = new closedCaption();
			cc.x = vol.x - cc.width;
			cc.y = mediaBG.y + 6;
			cc.buttonMode = true;
			cc.mouseChildren = false;
			cc.addEventListener(MouseEvent.CLICK, toggleClosedCaptioning);
			videoControlsContainer.addChild(cc);*/
			
			videoContainer.addChild(videoControlsContainer);
			videoControlsContainer.x = 0;
			videoControlsContainer.y = 0;
		
			/*videoControlsContainer.visible = false;
			videoControlsContainer.alpha = 0;*/
			
		}
		public function onClick(e:MouseEvent):void
		{
			togglePlayPause();
			//videoPlayBack.playing ? videoPlayBack.pause() : videoPlayBack.play();
		}
		public function toggleClosedCaptioning(e:MouseEvent):void
		{
			var clc:MovieClip = e.target as MovieClip;
			if (clc.currentFrame == 1)
			{
				clc.gotoAndStop(2);
				capBox.visible = captionText.visible = true;
			}
			else
			{
				clc.gotoAndStop(1);
				capBox.visible = captionText.visible = false;

			}
		}
		public function toggleMute(e:MouseEvent):void
		{
			var mute:MovieClip = e.target as MovieClip;
			if (mute.currentFrame == 1)
			{
				//previousVolumePosition = volumeScrubber.y;
				setVolume(0);
				//volumeScrubber.y = 98;
				mute.gotoAndStop(2);
			}
			else
			{
				//volumeScrubber.y = previousVolumePosition;
				var vol:Number = (98)/84;
				setVolume(vol);
				mute.gotoAndStop(1);
			}
		}
		public function progressClick(e:MouseEvent):void
		{	
			videoPlayBack.pause();
			videoPlayBack.seek(Math.round((pbBG.mouseX / 15.75) * videoPlayBack.totalTime));
			//trace((pbBG.mouseX / 15.75) * videoPlayBack.totalTime);
			//trace(videoPlayBack.totalTime);
			videoPlayBack.play();
		}
		
		public function handleVolumeControlRollOver(e:MouseEvent):void
		{
			var vol:volumeControl = e.target as volumeControl;
			TweenMax.to(vol.control, .75, { y: -110 } );
		}
		public function handleVolumeControlRollOut(e:MouseEvent):void
		{
			var vol:volumeControl = e.target as volumeControl;
			TweenMax.to(vol.control, .75, { y:0 } );
		}
		
		public function handleVideoRollOver(e:MouseEvent):void 
		{
			videoControlsContainer.visible = true;
			TweenMax.to(videoControlsContainer, .75, { alpha:1 } );
			this.addEventListener(MouseEvent.MOUSE_MOVE, showPanel);
		}
		public function handleVideoRollOut(e:MouseEvent):void 
		{
			showMouse = true;
			TweenMax.to(videoControlsContainer, 1.5, { alpha:0 } );
			if (stage != null)
			{
				this.removeEventListener(MouseEvent.MOUSE_MOVE, showPanel);
			}
			myTimer.reset();
			Mouse.show();
		}
		
		public function showPanel(e:Event):void {
			videoControlsContainer.visible = true;
			Mouse.show();
			TweenMax.to(videoControlsContainer, .75, { alpha:1 } );
			myTimer.reset();
			myTimer.start();
		}
		public function timerHandler(e:TimerEvent):void {
			TweenMax.to(videoControlsContainer, 1.5, { alpha:0 } );
			
				Mouse.hide();
				showMouse = false;
		}
		public function unload():void
		{
			trace("unloading ice video");
			if (videoPlayBack != null)
			{
				videoPlayBack.stop();				
				videoPlayBack.removeEventListener( MetadataEvent.CUE_POINT, doCuePoint);	
				videoPlayBack.removeEventListener(MetadataEvent.METADATA_RECEIVED, metadataReceived);
				videoPlayBack.removeEventListener(VideoEvent.STATE_CHANGE, videoStateHandler);
				videoPlayBack.removeEventListener(VideoEvent.PLAYHEAD_UPDATE, progressHandler);
				videoPlayBack.removeEventListener(VideoEvent.COMPLETE, handleVideoComplete); 
				this.removeEventListener("CUE_COMPLETE", cueCompleteHandler);
				tmrDisplay.removeEventListener(TimerEvent.TIMER, updateDisplay);
				myTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, timerHandler);
				hArea.removeEventListener(MouseEvent.CLICK, onClick);
				playPause.removeEventListener(MouseEvent.CLICK, togglePlayPauseButton);
				pbBG.removeEventListener(MouseEvent.CLICK, progressClick);
				vol.muteButton.removeEventListener(MouseEvent.CLICK, toggleMute);
				this.removeEventListener(MouseEvent.MOUSE_MOVE, showPanel);
				videoPlayBack.getVideoPlayer(0).close();
				stage.removeEventListener( MouseEvent.MOUSE_UP, mouseReleased);
				videoPlayBack = null;
				
			}
		}
		public function cueCompleteHandler(e:Event):void
		{
			videoPlayBack.play();
		}
		public function addCuePoints(videoXML:VideoXMLLoader):void
		{
			cuePoints = videoXML.getCuePoints();
			savePoints = new Array();
			for (var i:uint = 0; i < cuePoints.length; i++)
			{
				for (var x:uint = 0; x < cuePoints[i].getActions().length; x++)
				{
					if (cuePoints[i].getActions()[x].type == "save")
					{
						var savePointButton:videoSavePoint = new videoSavePoint();
						savePointButton.name = "sp_" + i;
						savePointButton.id = i;
						//you will ask yourself how one day... and you will laugh
						savePointButton.x = (12 * i ) + 1020 - (12 * videoXML.getTotalSavePoints());
						// 12pix + 8pix * count
						savePointButton.y = videoPlayBack.y + 634 - 20;
						savePointButton.width = 8;
						savePointButton.height = 15;
						savePointButton.active = false;
						savePointButton.time = cuePoints[savePointButton.id].time;
						//trace(savePointButton.x + " : " + savePointButton.y + " : " + savePointButton.width + " : " + savePointButton.height);
						savePoints.push(savePointButton);
						cuePoints[i].spRef = savePointButton;
						videoContainer.addChild(savePointButton);
						
					}
				}
				videoPlayBack.addASCuePoint(cuePoints[i].time, "cuePoint_" + i, cuePoints[i].getActions());									
			}
			
			dispatchEvent(new Event("CUE_COMPLETE"));
		}
		
		public function videoStateHandler(e:VideoEvent):void 
		{
		//	trace(e.state);
			//if (cueCount < cuePoints.length)
			//{
				if (pb)
				{
				pb.width = (480) * (videoPlayBack.playheadPercentage / 100);
				}
				//trace("width: - - - - - - - -  - > " + pb.width);
				//pb.width = videoPlayBack.bytesLoaded * 1020 / videoPlayBack.bytesTotal;
				
			//}
				switch(e.state)
				{
					case "playing":
						dispatchEvent(new Event("ASSET_LOADED"));
						break;
						
					default:
						break;
				}
			
		
		}
		public function pause():void
		{
			if (this.videoPlayBack)
			{
				this.videoPlayBack.pause();
			}
		}
		public function play():void
		{
			this.videoPlayBack.play();
		}
		
		public function togglePlayPauseButton(e:MouseEvent):void 
		{
			togglePlayPause();
		}
		public function togglePlayPause():void 
		{
			var button:MovieClip = videoControlsContainer.getChildByName("playPause") as MovieClip;
			if (button.currentFrame == 1)
			{
				button.gotoAndStop(2)
				videoPlayBack.pause();
			}
			else
			{
				button.gotoAndStop(1);
				videoPlayBack.play();
			}
		}
		public function progressHandler(e:VideoEvent):void 
		{
			time = formatTime(videoPlayBack.playheadTime) + " / " + formatTime(videoPlayBack.totalTime);
			
			(videoControlsContainer.getChildByName("time") as TextField).text = time;
			
			
			// checks, if user is scrubbing. if so, seek in the video
			// if not, just update the position of the scrubber according
			// to the current time
			
			//Commented out on 5/10/2012 for Amtrak demo
			/*if (bolProgressScrub)
			{
				videoPlayBack.pause();
				var seekNum:Number = (scrubber.x - pb.x) / 480 * videoPlayBack.totalTime;
				videoPlayBack.seek(Math.ceil(seekNum));
			}
			else
			{
				scrubber.x = pb.x + videoPlayBack.playheadTime * 480 / videoPlayBack.totalTime;
			}*/
			
			if (pb)
			{
				pb.width = (480) * (videoPlayBack.playheadPercentage / 100);
				
			}
			if (Math.floor(videoPlayBack.playheadPercentage) == 90)
			{
				//trace("look to buffer next movie");
				//trace(videoPlayBack.getVideoPlayer(0));
				//videoPlayBack.activeVideoPlayerIndex = 1;
				//videoPlayBack.load("assets/media/values/video/values_1_frosty.smil");				
			}
		}
		public function doCuePoint(evt:MetadataEvent):void 
		{
			//trace(evt.info.name + " : " + evt.info.time + " : " + evt.info.parameters);
			for (var i:* in evt.info.parameters)
			{
				//trace(i);
				//trace(evt.info.parameters[i].type + " : " +  evt.info.parameters[i].data);
				handleSceneActions(evt.info.parameters[i]);
			}
			if (cueCount < savePoints.length-1)
			{
				cueCount++;
			}
		}
		
		public function metadataReceived(evt:MetadataEvent):void 
		{
			tmrDisplay.start();
			/*trace("duration:", evt.info.duration); // 16.334
			trace("framerate:", evt.info.framerate); // 15
			trace("width:", evt.info.width); // 320
			trace("height:", evt.info.height); // 213*/
			
			videoPlayBack.width = 721;
			//videoPlayBack.width = evt.info.width;
			videoPlayBack.height = 405;
			//videoPlayBack.height = evt.info.height;
			var videoplayer:VideoPlayer = videoPlayBack.getVideoPlayer(0);
			videoplayer.smoothing = true;
		}
		private function handleSceneActions(command:Object):void 
		{
			//trace("TYPE: " + command.type);
			
			
			switch(command.type)
			{
				case "caption":
				capBox.visible = captionText.visible = true;

				if (cuePoints[cueCount].complete == false && cueCount < cuePoints.length)
				{
					//trace("DO CAPTION \n" + command.data);
					captionText.htmlText += command.data + "<br/>";
					cuePoints[cueCount].complete = true;
					cueCount++;
				}
				break;
				
				case "display":
				//trace("DO DISPLAY ACTION \n" + command.data + " : " + command.interrupt);
				if (command.interrupt == "true")
				{
					
					togglePlayPause();
				}
				
				var l:Loader = new Loader();
				l.load(new URLRequest(command.data));
				addChild(l);
				addEventListener("EVALUATE_ASSET", doStuff);
				break;
				
				case "save":
				//trace("save point time: " + videoPlayBack.playheadTime + " listed in cue point " + cuePoints[cueCount].id);
				//activateSavePoint();
				break;
				
				case "system":
				trace("DO SYSTEM CALL \n" + command.data);
				togglePlayPause();
				var tmp:Object = new Object();
				tmp.title = "CRITICAL SYSTEM FAILURE!";
				//tmp.text = "<p>Click OK to accept total system failure. All of your protected data will be transfered to <a href='http://lightelemental.com/jumpStart'>http://1337haxorz.roxorz.ru</a> <br/>then permenantly deleted off of your system.</p>";
				tmp.text = command.data;
				tmp.value = false;
				tmp.windowType = "CAUTION";
				dispatchEvent(new FeedbackEvent(tmp));
				break;
				
				default:
				break;
			}
		}
		public function doStuff(e:Event):void
		{
			e.target.visible = false;
			togglePlayPause();
		}
		private function activateSavePoint():void 
		{
			trace("activating save points");
			if (cuePoints[cueCount].spRef && cuePoints[cueCount].spRef.active == false)
			{
				cuePoints[cueCount].spRef.gotoAndStop(2);
				cuePoints[cueCount].spRef.buttonMode = true;
				cuePoints[cueCount].spRef.addEventListener(MouseEvent.CLICK, handleSeekSavePoint);
			}
		}
		private function handleSeekSavePoint(e:MouseEvent):void
		{
			videoPlayBack.pause();
			//trace(savePoints.length + " is teh length yo; but cue count is: " + cueCount + " and check it, the e.id is: " + uint(e.target.id + 1));
			if (uint(e.target.id + 1) < savePoints.length)
			{
				cueCount = uint(e.target.id + 1);
			}
			else
			{
				cueCount = savePoints.length - 1;
			}
			var time:Number = Number(e.target.time);
			
			if (cueCount == 1)
			{
				videoPlayBack.seek(0.00);
			}
			else
			{
				videoPlayBack.seek(time);
			}
			pb.width = (videoPlayBack.width - 25) * (time/videoPlayBack.totalTime);
			videoPlayBack.play();
		}
		
		private function handleVideoComplete(e:VideoEvent):void
		{
			//trace("secondsPassed: " + videoPlayBack.playheadPercentage);
			//videoPlayBack.visibleVideoPlayerIndex = 1;
			//videoPlayBack.play();
			this.complete = true;
			dispatchEvent(new Event("ASSET_COMPLETE"));
		}
		public function init():void
		{
			videoPlayBack.pause();
			videoPlayBack.seek(0.00);
			pb.width = 0;
			videoPlayBack.play();
		}
		
		public function progressScrubberClicked(e:MouseEvent):void 
		{
			stage.addEventListener( MouseEvent.MOUSE_UP, mouseReleased);

			// set progress scrub flag to true
			bolProgressScrub = true;
			
			// start drag
			scrubber.startDrag(false, new Rectangle(pb.x, pb.y-2, 480, 0));
		}
		
		public function volumeScrubberClicked(e:MouseEvent):void 
		{
			stage.addEventListener( MouseEvent.MOUSE_UP, mouseReleased);

			// set volume scrub flag to true
			bolVolumeScrub = true;
			
			// start drag
			volumeScrubber.startDrag(false, new Rectangle(18, 14, 0, 84));
		}



		public function mouseReleased(e:MouseEvent):void 
		{
			// set progress/volume scrub to false
			bolVolumeScrub		= false;
			if (bolProgressScrub)
			{
				bolProgressScrub = false;
				videoPlayBack.pause();
				var seekNum:Number = (scrubber.x - pb.x) / 480 * videoPlayBack.totalTime;
				videoPlayBack.seek(Math.round(seekNum));
			}
			
			// stop all dragging actions
			scrubber.stopDrag();
			//volumeScrubber.stopDrag();
			
			videoPlayBack.play();
			
			// update progress/volume fill
			pb.width = (scrubber.x - pb.x)/480;
			
			
			stage.removeEventListener( MouseEvent.MOUSE_UP, mouseReleased);
		}
		
		public function setVolume(volume:Number = 0):void 
		{
			// create soundtransform object with the volume from
			// the parameter
			//var sndTransform:SoundTransform		= new SoundTransform(intVolume);
			// assign object to netstream sound transform object
			videoPlayBack.volume = volume;
			
			// hides/shows mute and unmute button according to the
			// volume
			/*if(intVolume > 0) {
				mcVideoControls.btnMute.visible		= true;
				mcVideoControls.btnUnmute.visible	= false;
			} else {
				mcVideoControls.btnMute.visible		= false;
				mcVideoControls.btnUnmute.visible	= true;
			}*/
		}
		public function formatTime(t:int):String 
		{
			// returns the minutes and seconds with leading zeros
			// for example: 70 returns 01:10
			var s:int = Math.round(t);
			var m:int = 0;
			if (s > 0) 
			{
				while (s > 59) 
				{
					m++;
					s -= 60;
				}
				return String((m < 10 ? "0" : "") + m + " : " + (s < 10 ? "0" : "") + s);
			} 
			else 
			{
				return "00 : 00";
			}
		}
		public function updateDisplay(e:TimerEvent):void 
		{
			// checks, if user is scrubbing. if so, seek in the video
			// if not, just update the position of the scrubber according
			// to the current time
			if (bolProgressScrub)
			{
				pb.width = (scrubber.x - pb.x);
			}
			
			// update volume when user is scrubbing
			if (bolVolumeScrub) 
			{
				var vol:Number = (98 - volumeScrubber.y) / 84;
				setVolume(vol);
			}
			
			//capBox.height = captionText.textHeight + 20;
		
		}
	}
	
}
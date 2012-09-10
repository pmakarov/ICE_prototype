package com.ICE.components
{
	import com.ICE.utils.FlashVarUtil;
	import com.ICE.utils.VideoXMLLoader;
	import fl.video.FLVPlayback;
	import fl.video.FLVPlaybackCaptioning;
	import fl.video.MetadataEvent;
	import fl.video.VideoEvent;
	import fl.video.VideoPlayer;
	import flash.accessibility.Accessibility;
	import flash.accessibility.AccessibilityProperties;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
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
	import fl.video.CaptionTargetEvent;

	/**
	 * ...
	 * @author pmakarov
	 */
	public class ICEMediaPlayer extends Sprite
	{
		private var videoPlayBack:FLVPlayback;
		private var my_FLVPlybkcap:FLVPlaybackCaptioning;
		private var videoPath:String = "";
		private var pbBG:videoProgressBarBG; 
		private var mediaBG:mediaBarBG;
		private var vol:volumeControl;
		private var pb:videoProgressBar;
		private var videoContainer:Sprite;
		private var hArea:Sprite;
		private var playPause:videoPlayButton
		private var videoControlsContainer:MovieClip;
		private var videoXML:VideoXMLLoader;
		private var cuePoints:Array;
		private var savePoints:Array;
		private var spCounter:uint = 0;
		private var cueCount:uint = 0;
		public var complete:Boolean = false;
		private var time:String = "";
		private var durationText:String = "";
		private var bolProgressScrub:Boolean = false;
		private var bolVolumeScrub:Boolean = false;
		private var scrubber:ProgressScrubber;
		private var volumeScrubber:MovieClip;
		private var tmrDisplay:Timer;
		private var myTimer:Timer;
		private var previousVolumePosition:Number;
		private const DISPLAY_TIMER_UPDATE_DELAY:int = 10;
		private var debugText:TextField;
		private var vidWidth:Number = 640;
		private var vidHeight:Number = 390;
		private var autorun:Boolean = true;
		private var showcaptions:Boolean = false;
		private var captionButton:closedCaptioning;
		private var loadingScreen:loadingBlue;
		private var fs:fullScreenButton;

		
		[SWF(width="640", height="390", frameRate="60", backgroundColor="#000000")]

		public function ICEMediaPlayer():void 
		{
			if (stage)
				initLoop(new Event(Event.ENTER_FRAME));
			else
				addEventListener(Event.ADDED_TO_STAGE, initLoop);
			
			
		}	
		private function initLoop(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, initLoop);
			this.addEventListener(Event.ENTER_FRAME, checkStage);
		}
		private function checkStage(e:Event):void 
		{
			//trace(stage.width + " : " + stage.stageWidth);
			if (stage.stageWidth > 0)
			{
				init();
			}
		}
		private function init():void
		{
			removeEventListener(Event.ENTER_FRAME, checkStage);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener (Event.RESIZE, resizeListener);
			
			if (Accessibility.active) {
			
				if (!this.accessibilityProperties)
				{
					this.accessibilityProperties = new AccessibilityProperties();
					this.accessibilityProperties.silent = false;
					this.accessibilityProperties.forceSimple = false;
					Accessibility.updateProperties();
				}
			}
			
			
			my_FLVPlybkcap = new FLVPlaybackCaptioning(); 
			
			parseFlashVars();
			videoContainer = new Sprite();
		
			var vbg:MovieClip = new MovieClip();
			vbg.x = 0;
			vbg.y = 0;			
			videoContainer.addChild(vbg);
			
			loadingScreen = new loadingBlue();
			loadingScreen.x = stage.stageWidth/2 - loadingScreen.width / 2;
			//loadingScreen.x = 0;
			loadingScreen.y = stage.stageHeight/2 - loadingScreen.height / 2;
			//loadingScreen.y = 0;
			loadingScreen.name = "loadingAnimation";
			videoContainer.addChild(loadingScreen);
			
			videoPlayBack = new FLVPlayback();
			videoPlayBack.autoPlay = false;
			videoPlayBack.scaleMode = "maintainAspectRatio";
			videoPlayBack.fullScreenTakeOver = false;
			//videoPlayBack.scaleMode = "exactFit";
			
			//videoContainer.addEventListener(MouseEvent.ROLL_OVER, handleVideoRollOver);
			//videoContainer.addEventListener(MouseEvent.ROLL_OUT, handleVideoRollOut);
			//videoPlayBack.visible = false;
			
			//videoPlayBack = new FLVPlayback(); 
			//videoPlayBack.skin = "C:/Program Files (x86)/Adobe/Adobe Flash CS6/Common/Configuration/FLVPlayback Skins/ActionScript 3.0/SkinUnderPlaySeekCaption.swf"; 
			//videoPlayBack.source = "http://www.helpexamples.com/flash/video/caption_video.flv"; 
			

			//videoPlayBack.addEventListener(MouseEvent.CLICK, onClick);

		
			videoContainer.name = "container";
			addChild(videoContainer);
			
			videoPlayBack.source = videoPath;	
			videoPlayBack.addEventListener(MetadataEvent.METADATA_RECEIVED, metadataReceived);
			videoPlayBack.addEventListener(VideoEvent.STATE_CHANGE, videoStateHandler);
			videoPlayBack.addEventListener(VideoEvent.PLAYHEAD_UPDATE, progressHandler);
			videoPlayBack.addEventListener(VideoEvent.COMPLETE, handleVideoComplete); 
			
			videoContainer.addChild(videoPlayBack);
			videoContainer.addChild (my_FLVPlybkcap); 
			my_FLVPlybkcap.addEventListener(CaptionTargetEvent.CAPTION_TARGET_CREATED, captionTargetCreatedHandler);
			
			
			videoControlsContainer = new MovieClip();
			buildVideoControls();
			
			
			
			tmrDisplay = new Timer(DISPLAY_TIMER_UPDATE_DELAY);
			tmrDisplay.addEventListener(TimerEvent.TIMER, updateDisplay);
			myTimer = new Timer(3000, 1);
			//myTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timerHandler);
			
			setVolume(1);
			//
			if (autorun == true)
			{
				videoPlayBack.play();
			}
			else
			{
				togglePlayPauseButton(new MouseEvent(MouseEvent.CLICK));
			}
			
		}
		private function resizeListener(e:Event):void
		{
			/*trace("stageWidth: " + stage.stageWidth + " stageHeight: " + stage.stageHeight + " : " + stage.displayState);
			
			
			if(stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				// Proportionally resize your video to the stage's new dimensions
				// i.e. set its height and width such that the aspect ratio is not distorted
				trace("go to full screen mode");
				
				
			}
			else
			{
				trace(" in normal mode");
				
			}*/
			
			/*vidWidth = stage.stageWidth;
			videoPlayBack.width = vidWidth;
			videoPlayBack.height = stage.stageHeight - 30;
			videoControlsContainer.y = stage.stageHeight - 34;
			videoPlayBack.visible = false;
			*/
			var mediaBG:MovieClip = videoControlsContainer.getChildByName("mediaBG") as MovieClip; 
			//mediaBG.y = stage.stageHeight - mediaBG.height;
			mediaBG.width = stage.stageWidth;
			
			var pbBG:MovieClip = videoControlsContainer.getChildByName("pbBG") as MovieClip;
			pbBG.width = stage.stageWidth;
			
			var pbar:MovieClip = videoControlsContainer.getChildByName("progressBar") as MovieClip;
			pbar.width = (stage.stageWidth) * (videoPlayBack.playheadPercentage / 100);
			
			var scb:MovieClip = videoControlsContainer.getChildByName("progressScrubber") as MovieClip;
			scb.x = pbar.x + videoPlayBack.playheadTime * vidWidth / videoPlayBack.totalTime - 8;
			
		}
		private function captionTargetCreatedHandler(e:CaptionTargetEvent):void
		{
			var myTextFormat:TextFormat = new TextFormat();
			myTextFormat.font = "Arial";
			myTextFormat.color = 0xDDFFEE;
			myTextFormat.size = 18;
			(e.captionTarget as TextField).defaultTextFormat = myTextFormat; 	
		}
		private function parseFlashVars():void
		{
			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0xFFFFFF;
            format.size = 14;
			format.bold = true;
			
			var tf:TextField = new TextField();
			tf.autoSize = TextFieldAutoSize.RIGHT;
			tf.border = true;
			tf.defaultTextFormat = format;
			addChild(tf);
			tf.appendText("params:" + "");
			tf.x = stage.stageWidth - tf.width;
			tf.y = 0;
			tf.visible = false;
			
			var flashVars:Object = LoaderInfo(this.root.loaderInfo).parameters;
			var myFlashVar:String;
			var hasFlashVars:Boolean = FlashVarUtil.setFlashVar(LoaderInfo(this.root.loaderInfo).parameters);
			
			if (hasFlashVars)
			{
				if (FlashVarUtil.hasKey("src"))
				{
					videoPath = FlashVarUtil.getValue("src");
					//tf.appendText("target source:" + videoPath + "\n");
				}
				if (FlashVarUtil.hasKey("data"))
				{
					//trace( FlashVarUtil.getValue("data"));
					my_FLVPlybkcap.source = FlashVarUtil.getValue("data");
					
				}
				if (FlashVarUtil.hasKey("width"))
				{
					vidWidth = parseInt(FlashVarUtil.getValue("width"));
					tf.appendText("width:" + vidWidth + "\n");
				}
				if (FlashVarUtil.hasKey("height"))
				{
					vidHeight = parseInt(FlashVarUtil.getValue("height"));
				}
				if (FlashVarUtil.hasKey("autorun"))
				{
					autorun = FlashVarUtil.getValue("autorun") == "true" ? true : false;
					trace(autorun);
				}
				if (FlashVarUtil.hasKey("showcaptions") && FlashVarUtil.hasKey("data"))
				{
					//tf.appendText("target data:" +  FlashVarUtil.getValue("showcaptions") + "\n");
					showcaptions  = FlashVarUtil.getValue("showcaptions") == "true" ? true : false;
					my_FLVPlybkcap.showCaptions = showcaptions;
				}
			}
			else 
			{
				//videoPath = "http://www.helpexamples.com/flash/video/caption_video.flv";
				//videoPath = "video/runSKELITOR_rgb_9_1.f4v";
				my_FLVPlybkcap.source = "data/xml/caption_video.xml";
				videoPath = "assets/media/video/default.f4v";
			}
		}
		
		private function buildVideoControls():void
		{
			//videoPlayBack.visible = false;
			
			hArea = new Sprite();
			videoControlsContainer.addChild(hArea);
			hArea.graphics.beginFill(0x0000FF);
			hArea.alpha = 0;
			hArea.graphics.drawRect(0,0, vidWidth ,vidWidth);
			hArea.graphics.endFill();
			hArea.x = stage.stageWidth/2-hArea.width/2;
			hArea.y = stage.stageHeight/2-hArea.height/2;
			hArea.addEventListener(MouseEvent.CLICK, onClick);
			
			mediaBG = new mediaBarBG();
			mediaBG.name = "mediaBG";
			mediaBG.width = vidWidth;
			mediaBG.y = vidHeight - mediaBG.height;
			videoControlsContainer.addChild(mediaBG);
			
			
			
			playPause = new videoPlayButton();
			//playPause.x = mediaBG.x + 6;
			playPause.y = mediaBG.y + (mediaBG.height - playPause.height) / 2;
			playPause.playb.addEventListener(MouseEvent.CLICK, togglePlayPauseButton);
			playPause.pb.addEventListener(MouseEvent.CLICK, togglePlayPauseButton);
			playPause.name = "playPause";
			playPause.playb.buttonMode = true;
			playPause.playb.visible = false;
			playPause.pb.buttonMode = true;
			videoPlayBack.playPauseButton = playPause;
			
			videoControlsContainer.addChild(playPause);
		
			//TweenMax.to(timeText_mc, .6, {glowFilter:{ color:0xDDEEFF, alpha:1, blurX:10, blurY:10 , strength:1, quality:3 }} );
			
			
			vol = new volumeControl();
			vol.x = playPause.x + playPause.width;
			vol.y = playPause.y;
			vol.buttonMode = true;
			//vol.addEventListener(MouseEvent.ROLL_OVER, handleVolumeControlRollOver);
			//vol.addEventListener(MouseEvent.ROLL_OUT, handleVolumeControlRollOut);
			videoControlsContainer.addChild(vol);
			
			//volumeScrubber = vol.control.scrub as MovieClip;
			//volumeScrubber.addEventListener(MouseEvent.MOUSE_DOWN, volumeScrubberClicked);
			vol.volumeOn.addEventListener(MouseEvent.CLICK, toggleMute);
			vol.volumeOff.addEventListener(MouseEvent.CLICK, toggleMute);
			videoPlayBack.muteButton = vol;
			vol.volumeOn.buttonMode = true;
			vol.volumeOff.buttonMode = true;
			vol.volumeOff.visible = false;
			//vol.muteButton.addEventListener(MouseEvent.CLICK, toggleMute);
			
			fs = new fullScreenButton();
			fs.y = playPause.y;
			fs.x = vidWidth - fs.width;
			videoControlsContainer.addChild(fs);
			fs.addEventListener(MouseEvent.CLICK, toggleFullScreen);
			videoPlayBack.fullScreenButton = fs;
				
			if (my_FLVPlybkcap.source != "")
			{
				captionButton = new closedCaptioning();
				captionButton.ccOn.buttonMode = true;
				captionButton.ccOff.buttonMode = true;
				captionButton.ccOff.visible = false;
				captionButton.y = playPause.y;
				captionButton.x = fs.x- captionButton.width;
				videoControlsContainer.addChild(captionButton);
				captionButton.ccOff.addEventListener(MouseEvent.CLICK, toggleCaptioning);
				captionButton.ccOn.addEventListener(MouseEvent.CLICK, toggleCaptioning);
				my_FLVPlybkcap.showCaptions = false;
				if (showcaptions == true)
				{
					toggleCaptioning(new MouseEvent(MouseEvent.CLICK));
				}
			}
			
			
		
			
			
			
			pbBG = new videoProgressBarBG();
			pbBG.height = 6;
			pbBG.width = vidWidth;
			pbBG.x = 0;
			pbBG.y = mediaBG.y  - pbBG.height + 3;
			videoControlsContainer.addChild(pbBG);
			pbBG.name = "pbBG";
			pbBG.addEventListener(MouseEvent.CLICK, progressClick);
			
			pb = new videoProgressBar();
			pb.mouseEnabled = false;
			pb.height = 4;
			pb.width = 0;
			pb.alpha = .5;
			pb.x = -6;
			pb.y = mediaBG.y - pbBG.height + 4;
			pb.name = "progressBar";
			videoControlsContainer.addChild(pb);
			
			scrubber = new ProgressScrubber();
			scrubber.x = pb.x + 5;
			scrubber.y = pb.y - 2;
			scrubber.name = "progressScrubber";
			videoPlayBack.addEventListener(VideoEvent.COMPLETE, handleVideoComplete);
			//pb.tabIndex = 1;
			scrubber.addEventListener(MouseEvent.MOUSE_DOWN, progressScrubberClicked);
			videoControlsContainer.addChild(scrubber);
			
			
			
				
			var format:TextFormat = new TextFormat();
			format.font = "Arial";
			format.color = 0xDADADA;
            format.size = 12;
			format.bold = false;
						
			var timeText_mc:TextField = new TextField();
			timeText_mc.autoSize = TextFieldAutoSize.LEFT;
            timeText_mc.background = false; //use true for doing generic labels
            timeText_mc.border = false;      // ** same
			//timeText_mc.embedFonts = true;
			timeText_mc.antiAliasType = "advanced";
			timeText_mc.gridFitType = GridFitType.NONE;
			timeText_mc.sharpness = -200;
			timeText_mc.wordWrap = false;
            timeText_mc.defaultTextFormat = format;			
			timeText_mc.x = vol.x + vol.width + 6;
			timeText_mc.width = 200;
			timeText_mc.text = "00:00";
			timeText_mc.name = "time";
			timeText_mc.y = mediaBG.y + timeText_mc.height/2 - 2;
			videoControlsContainer.addChild(timeText_mc);
			
			
/*			var format:TextFormat = new TextFormat();
			format.font = "Arial";
			format.color = 0xDADADA;
            format.size = 12;
			format.bold = false;
           
			
			var durationText_mc:TextField = new TextField();
			durationText_mc.autoSize = TextFieldAutoSize.LEFT;
            durationText_mc.background = false; //use true for doing generic labels
            durationText_mc.border = false;      // ** same
			//durationText_mc.embedFonts = true;
			durationText_mc.antiAliasType = "advanced";
			durationText_mc.gridFitType = GridFitType.NONE;
			durationText_mc.sharpness = -200;
			durationText_mc.wordWrap = false;
            durationText_mc.defaultTextFormat = format2;			
			durationText_mc.x = timeText_mc.x + timeText_mc.width + 40;
			durationText_mc.width = 200;
			durationText_mc.text = "00";
			durationText_mc.name = "durationText";
			durationText_mc.y = mediaBG.y + durationText_mc.height/2 - 2;
			videoControlsContainer.addChild(durationText_mc);*/
			
			//showcaptions = true;
			//my_FLVPlybkcap.source = "data/xml/caption_video.xml";
			

			
			videoContainer.addChild(videoControlsContainer);
			videoControlsContainer.x = 0;
			//videoControlsContainer.y = vidHeight - mediaBG.height;
			//videoControlsContainer.width = 400;
			//videoControlsContainer.visible = false;
			//videoControlsContainer.alpha = 0;			
		}
		public function toggleFullScreen(e:MouseEvent):void
		{
			if (stage.displayState != StageDisplayState.FULL_SCREEN)
			{
				stage.displayState = StageDisplayState.FULL_SCREEN;
			}
			else
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			
		}
		public function toggleCaptioning(e:MouseEvent):void
		{
			if (captionButton.ccOff.visible)
			{
				trace("toggle cc off");
				captionButton.ccOff.visible = false;
				captionButton.ccOn.visible = true;
				my_FLVPlybkcap.showCaptions = false;

			}
			else
			{
				captionButton.ccOn.visible = false;
				captionButton.ccOff.visible = true;
				my_FLVPlybkcap.showCaptions = true;
			}
		}
		public function toggleMute (e:MouseEvent):void
		{
			if (vol.volumeOn.visible)
			{
				vol.volumeOn.visible = false;
				vol.volumeOff.visible = true;
				setVolume(0);

			}
			else
			{
				vol.volumeOn.visible = true;
				vol.volumeOff.visible = false;
				setVolume(1);
				
			}
		}
		public function onClick(e:MouseEvent):void
		{
			videoPlayBack.playing ? videoPlayBack.pause() : videoPlayBack.play();
			
		}
		public function progressClick(e:MouseEvent):void
		{	
			
			videoPlayBack.pause();
			videoPlayBack.seek(Math.floor((pbBG.mouseX / 15.75) * videoPlayBack.totalTime));
			trace((pbBG.mouseX / 15.75) * videoPlayBack.totalTime);
			videoPlayBack.play();
		}
		
		public function handleVolumeControlRollOver(e:MouseEvent):void
		{
			var vol:volumeControl = e.target as volumeControl;
		}
		public function handleVolumeControlRollOut(e:MouseEvent):void
		{
			var vol:volumeControl = e.target as volumeControl;
		}
		
		public function handleVideoRollOver(e:MouseEvent):void 
		{
			
			videoControlsContainer.visible = true;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, showPanel);
		}
		public function handleVideoRollOut(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, showPanel);

		}
		
		public function showPanel(e:Event):void {
			videoControlsContainer.visible = true;
			Mouse.show();
			myTimer.reset();
			myTimer.start();
		}
		public function timerHandler(e:TimerEvent):void {
			Mouse.hide();
		}

		
		public function handleStageMouseMove(e:MouseEvent):void
		{
			
		}
		public function unload():void
		{
			videoPlayBack.stop();
		}
		
		public function videoStateHandler(e:VideoEvent):void 
		{
			//trace(e.state);
				switch(e.state)
				{
					case "playing":
						dispatchEvent(new Event("ASSET_LOADED"));
						playPause.pb.visible = true;
						playPause.playb.visible = false;
						my_FLVPlybkcap.showCaptions = showcaptions;
						break;
						
					case "paused":
						playPause.playb.visible = true;
						playPause.pb.visible = false;
						break;
						
					default:
						break;
				}
			
		
		}
		
		public function togglePlayPauseButton(e:MouseEvent):void 
		{
			if (playPause.pb.visible)
			{
				//e.target.gotoAndStop(2);
				playPause.playb.visible = true;
				playPause.pb.visible = false;
				videoPlayBack.pause();
			}
			else
			{
				//e.target.parent.gotoAndStop(1);
				playPause.pb.visible = true;
				playPause.playb.visible = false;
				videoPlayBack.play();
			}
		}
		public function progressHandler(e:VideoEvent):void 
		{
			time = formatTime(videoPlayBack.playheadTime) + " / " + formatTime(videoPlayBack.totalTime);
			var format:TextFormat = new TextFormat();
			format.font = "Arial";
			format.color = 0xABABAB;
            format.size = 12;
			format.bold = true;
			
			var timeText_mc:TextField = TextField(videoControlsContainer.getChildByName("time"));
			timeText_mc.text = time;
			var index:int = timeText_mc.text.indexOf(" / ");
			timeText_mc.setTextFormat(format, index, timeText_mc.text.length);
			
			//TextField(videoControlsContainer.getChildByName("durationText")).text = durationText;
			
			
			// checks, if user is scrubbing. if so, seek in the video
			// if not, just update the position of the scrubber according
			// to the current time
			if (bolProgressScrub)
			{
				videoPlayBack.pause();
				var seekNum:Number = (scrubber.x - pb.x) / vidWidth * videoPlayBack.totalTime;
				videoPlayBack.seek(Math.round(seekNum));
			}
			else
			{
				scrubber.x = pb.x + videoPlayBack.playheadTime * vidWidth / videoPlayBack.totalTime - 8;
			}
			
			if (pb)
			{
				pb.width = (vidWidth) * (videoPlayBack.playheadPercentage / 100);
				
			}
			if (Math.floor(videoPlayBack.playheadPercentage) == 90)
			{
				//trace("look to buffer next movie");
				//trace(videoPlayBack.getVideoPlayer(0));
				//videoPlayBack.activeVideoPlayerIndex = 1;
				//videoPlayBack.load("assets/media/values/video/values_1_frosty.smil");				
			}
		}
		
		
		public function metadataReceived(evt:MetadataEvent):void 
		{
			tmrDisplay.start();
			/*trace("duration:", evt.info.duration); // 16.334
			trace("framerate:", evt.info.framerate); // 15
			trace("width:", evt.info.width); // 320
			trace("height:", evt.info.height); // 213*/
			
			videoPlayBack.width = vidWidth;
			//videoPlayBack.width = evt.info.width;
			//trace(vidHeight);
			videoPlayBack.height = vidHeight - 30;
			//videoPlayBack.height = evt.info.height;
			var videoplayer:VideoPlayer = videoPlayBack.getVideoPlayer(0);
			videoplayer.smoothing = true;
			videoContainer.removeChild(videoContainer.getChildByName("loadingAnimation"));

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
			//trace("video complete: " + videoPlayBack.playheadPercentage);
			
			videoPlayBack.autoRewind = true;
			//add code to put back up the Play icon
			togglePlayPauseButton(new MouseEvent(MouseEvent.CLICK));
		}
		
		
		public function progressScrubberClicked(e:MouseEvent):void 
		{
			stage.addEventListener( MouseEvent.MOUSE_UP, mouseReleased);

			// set progress scrub flag to true
			bolProgressScrub = true;
			
			// start drag
			scrubber.startDrag(false, new Rectangle(pb.x, pb.y-2, vidWidth, 0));
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
				var seekNum:Number = (scrubber.x - pb.x) / vidWidth * videoPlayBack.totalTime;
				videoPlayBack.seek(Math.round(seekNum));
			}
			
			// stop all dragging actions
			scrubber.stopDrag();
			
			
			videoPlayBack.play();
			
			// update progress/volume fill
			pb.width = (scrubber.x - pb.x)/vidWidth;
			
			
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
				return String((m < 10 ? "" : "") + m + ":" + (s < 10 ? "0" : "") + s);
			} 
			else 
			{
				return "00:00";
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
				var vol:Number = (98 - volumeScrubber.y)/84;
				setVolume(vol);
			}
		
		}
	}
	
}
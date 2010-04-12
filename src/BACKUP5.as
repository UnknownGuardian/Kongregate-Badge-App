package 
{
	import flash.display.*;
	import flash.events.*;  
	import flash.filters.GlowFilter;
	import flash.net.navigateToURL;
	import flash.net.URLRequest; 
	import flash.net.URLLoader; 
	import flash.text.*; 
	import flash.geom.*
	import flash.system.*;
	import com.adobe.serialization.json.JSON;
	import com.greensock.TweenLite;
	import com.greensock.easing.Elastic;

	/**
	 * ...
	 * @author UnknownGuardian
	 */
	
	public class Main extends Sprite 
	{
		[Embed(source = 'data/Border.png')] private var ImgBorder:Class;
		[Embed(source = 'data/HugeLogo.png')] private var ImgHugeLogo:Class;
		
		private var userName:String = "";
		private var numPoints:TextField;
		private var points:TextField;
		
		private var loader:URLLoader = new URLLoader();
		private var request:URLRequest = new URLRequest();
		private var _badges:Array = [];
		
		public var _badgeIcons:Sprite = new Sprite();
		public var _bg:Shape = new Shape();
		public var _l:Bitmap = new ImgHugeLogo();
		public var _createdBy:Sprite = new Sprite();
		public var _HUD:Sprite = new Sprite();
		public var _drag:Sprite = new Sprite(); //scrollbar
		public var _toolTip:Sprite = new Sprite();
		public var _errorBlur:Sprite;
		public var _errorMessage:Sprite;
		public var _usernameInputBox:TextField;
		public var changeCounter:int = 0; //time that the change icon stays up
		public var _toolTipBG:Sprite;
		public var _head:TextField;
		public var _mid:TextField;
		public var _body:TextField;
		public var _UG:TextField;
		public var _preloaderTxt:TextField;
		public var _JSONLoaded:TextField;
		public var currentSorted:String = "";
		public var buttonsActivated:Boolean = false;

		//for scroll bar
		private var maxScroll:int = stage.stageHeight;
		private var minScroll:int = 32;		
		private var clickY:int = 0;
		
		private var currentBadge:int = 0;
		private var numInRow:int = 19;
		private var startingCol:int = 32;
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			manageSecurity();
			handleStage();
			getLogo();
			addCreatedBy();
			getUserName();
			if (userName != "") //If its a default app
			{
				startUserRequest();
			}
			

			//---Supposed Order of operations---
			//load .json file (x2)
			//fill array of items to load
			//load border first
			//start loading graphics with a preloader as its loading
		}
		
		private function resetAllVars():void
		{
			trace("Attempting to reset vars");
			numPoints.text = "0"; //reassigns points
			_badges = []; //deletes all badges
			for (var i:int = _badgeIcons.numChildren - 1; i >= 0; i--)
			{
				_badgeIcons.removeChildAt(i); //removes badges from screen
			}
			changeCounter = 0;
			_HUD.addChild(_JSONLoaded);
			_badgeIcons.addChild(_preloaderTxt);
			_preloaderTxt.y = -100; //shove if off the screen
			_JSONLoaded.text = "";
			currentSorted = "";
			buttonsActivated = false;
			clickY = 0;	
			currentBadge = 0;
			
			//reset the scroll bar
			_drag.height = maxScroll-minScroll;
			_drag.x = stage.stageWidth - _drag.width / 2 -5;
			_drag.y = 30 + _drag.height / 2;
			trace("Finished reset vars");
		}
		
		private function startUserRequest():void
		{
			
			getUserJSON();
		}
		
		private function manageSecurity():void
		{
			//Security.loadPolicyFile("http://www.tinyurl.com/crossdomain.xml");
			//Security.allowDomain("http://www.tinyurl.com");
		}
		
		private function handleStage():void
		{			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
            _bg.graphics.beginFill(0x990000);
            _bg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
            _bg.graphics.endFill();
			_bg.name = "Solid Red background";
			
			_l.x = stage.stageWidth / 2 - _l.width/2;
			_l.y = stage.stageHeight / 2 - _l.height / 2;
			_l.name = "Middle screen logo";
			
			//shader at top
			var t:Sprite = new Sprite();
			var fillType:String = GradientType.LINEAR;
			var colors:Array = [0x990000, 0x990000];
			var alphas:Array = [1, 0];
			var ratios:Array = [0x80, 0xFF];
			var matr:Matrix = new Matrix();
			matr.createGradientBox(45, 45, 0, 0, 0);
			matr.rotate(Math.PI / 2);
			var spreadMethod:String = SpreadMethod.PAD;
			t.graphics.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);  
			t.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			_HUD.addChild(t);
			t.mouseEnabled = false;
			t.name = "Top Shader";
			
			//shader at bottom
			var b:Sprite = new Sprite();
			fillType = GradientType.LINEAR;
			colors = [0x990000, 0x990000];
			alphas = [1, 0];
			ratios = [0x80, 0xFF];
			matr = new Matrix();
			matr.createGradientBox(25,25, 0, 0, 0);
			//matr.rotate(Math.PI/2 );
			spreadMethod = SpreadMethod.PAD;
			b.graphics.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);  
			b.graphics.drawRect(0, 0, stage.stageHeight, stage.stageWidth);
			b.rotation = -90;
			b.y = stage.stageHeight+10;
			_HUD.addChild(b);
			b.mouseEnabled = false;
			b.name = "Bottom Shader";
			
			//used to be :* type
			var i:Bitmap = new ImgBorder();
			_drag.addChild(i);
			i.x = -i.width / 2;
			i.y = -i.height / 2;
			_drag.scaleX = 0.65;
			_drag.height = maxScroll-minScroll;
			_drag.name = "Scroll bar";
			_drag.x = stage.stageWidth - _drag.width / 2 -5;
			_drag.y = 30 + _drag.height / 2;
			_drag.addEventListener(MouseEvent.ROLL_OVER, over);
			_drag.addEventListener(MouseEvent.ROLL_OUT, out);
			_drag.addEventListener(MouseEvent.MOUSE_DOWN, drag);
			stage.addEventListener(MouseEvent.MOUSE_UP, killDrag);
			
			_toolTipBG = new Sprite();
			_toolTipBG.graphics.lineStyle(3, 0xFFFFFF, 1, false, "none", null, JointStyle.ROUND);
			_toolTipBG.graphics.beginFill(0xFFFFFF, 0.8);
			_toolTipBG.graphics.lineTo(100, 0);
			_toolTipBG.graphics.lineTo(100, 100);
			_toolTipBG.graphics.lineTo(0, 100);
			_toolTipBG.graphics.lineTo(0, 0);
			_toolTipBG.graphics.endFill();
			_toolTip.addChild(_toolTipBG);
			_toolTip.x = 100;
			_toolTip.y = 100;
			createToolTipText(); //create text boxes for the tool tip
			
			_JSONLoaded = new TextField();
			_JSONLoaded.autoSize = TextFieldAutoSize.CENTER;
			_JSONLoaded.selectable = false;
			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0x000000;
			format.bold = true;
            format.size = 10;
			_JSONLoaded.defaultTextFormat = format;
			_JSONLoaded.text = "Percent Loaded";
			_JSONLoaded.x = stage.stageWidth / 2;
			_JSONLoaded.y = stage.stageHeight / 2 + 40;
			_HUD.addChild(_JSONLoaded);
	
			stage.addChild(_bg);
			stage.addChild(_l);
			stage.addChild(_createdBy);
			stage.addChild(_badgeIcons);
			stage.addChild(_HUD);
			stage.addChild(_drag);
			
			_HUD.name = "HUD";
			_HUD.mouseEnabled = false;
			_badgeIcons.name = "Icons";
			_badgeIcons.mouseEnabled = false;
			
			initPreloaderTxt();
			createSortText();
		}
		
		private function getUserName():void
		{
			var url:String = root.loaderInfo.loaderURL;
			url = url.substring(url.lastIndexOf("/") + 1);
			if (url.lastIndexOf("%5F") == -1)
				userName = url.substring(url.lastIndexOf("_")+1, url.length - 4);
			else
				userName = url.substring(url.lastIndexOf("%5F")+3,url.length-4);
			//trace(userName);
			createTextBox();
		}
		private function getUserJSON():void
		{
			request.url = "http://api.kongregate.com/accounts/" + userName + "/badges.json"; 
			loader.addEventListener(IOErrorEvent.IO_ERROR, catchIOError); //catch if username does not exist
			loader.load(request); 
			loader.addEventListener(ProgressEvent.PROGRESS, JSONUserLoading);
			loader.addEventListener(Event.COMPLETE, splitUserJSON); 
		}
		private function getBadgeJSON():void
		{
			request.url = "http://api.kongregate.com/badges.json"; 
			loader.addEventListener(ProgressEvent.PROGRESS, JSONLoading);
			loader.load(request); 
			loader.addEventListener(Event.COMPLETE, splitBadgeJSON);
		}
		private function JSONLoading(event:ProgressEvent):void
		{
			_JSONLoaded.text = "Retrieving all badges..." + int(event.bytesLoaded / event.bytesTotal * 1000000)/10000 + "%";
		}
		private function JSONUserLoading(event:ProgressEvent):void
		{
			_JSONLoaded.text = "Retrieving user badges..." + int(event.bytesLoaded / event.bytesTotal * 1000000)/10000 + "%";
		}
		private function splitUserJSON(event:Event):void 
		{ 
			var load:URLLoader = URLLoader(event.target) ;
			_badges = JSON.decode(load.data) ;
			
			//{OLD METHOD--------------->
			//var lo:URLLoader = URLLoader(event.target);
			//trace("Before JSON User Decoding");
			//trace(lo.data);
			//
			//var partJSON:String = lo.data;
			//trace(partJSON);
			//
			//var mArr:Array = []; //master array
			//while (partJSON.indexOf("}") != -1) //seperates data into individual badges with { and }
			//{
				//var s:int = partJSON.indexOf("{") + 1; //+1 to get rid of the starting "{"
				//var e:int = partJSON.indexOf("}");
				//var temp:String = partJSON.substring(s, e);
				//partJSON = partJSON.substring(e + 1);
				//mArr.push(temp);
			//}
			//for (var i:int = 0; i < mArr.length ; i++)  //parse individual badges into number, data, etc.
			//{
				//var c:String = mArr[i];
				//var number:String = c.substring(c.indexOf(":")+1, c.indexOf(","));
				//var date:String = c.substring(c.indexOf("/") - 4, c.lastIndexOf("/") + 3);
				//var tArr:Array = [];
				//tArr.push(number);
				//tArr.push(date);
				//_badges.push(tArr);
			//}
			//}
			
			loader.removeEventListener(Event.COMPLETE, splitUserJSON);
			trace("Retriving Badge JSON");
			getBadgeJSON(); //call at end
		}
		private function splitBadgeJSON(event:Event):void 
		{ 
			_HUD.removeChild(_JSONLoaded);
			trace("Before JSON Badge Decoding");
			var load:URLLoader = URLLoader(event.target) ;
			var all:Array = JSON.decode(load.data);
			trace(all.length,"total badges");
			for (var i:int = 0; i < _badges.length; i++)
			{
				for (var j:int = 0; j < all.length; j++)
				{
					if (_badges[i].badge_id == all[j].id)
					{
						_badges[i] = all[j];
						break;
					}
				}
			}
			
			trace("Loaded Badge JSON");

			//var tempJSON:String = lo2.data;
			//should trace around 330,000 characters
		
			//{OLD2 METHOD------------------->
			//var mArr:Array = lo2.data.split("description");
			//
			//trim first
			//mArr[0] = mArr[0].substring(2);
			//trace(mArr[1]);
			//trace(mArr[mArr.length - 1]);
			//for (var i:int = 1; i < mArr.length/100; i++)
			//{
				//var obj:* = mArr[i];
				//trace(obj);
				//obj = obj.substring(3);
				//var des:String = obj.substring(0, obj.indexOf(",\"")-1);
				//obj = obj.substring(obj.indexOf("\"url\"") + 7 );
				//var adr:String = obj.substring(0, obj.indexOf(",") - 1);
				//obj = obj.substring(obj.indexOf("\"title\":") + 9);
				//var tle:String = obj.substring(0, obj.indexOf("\"}]"));
				//obj = obj.substring(obj.indexOf("name") + 7);
				//var nme:String = obj.substring(0, obj.indexOf("\","));
				//obj = obj.substring(obj.indexOf("users_count") + 13);
				//var num:String = obj.substring(0, obj.indexOf(","));
				//obj = obj.substring(obj.indexOf("points") + 8);
				//var pts:int = obj.substring(0, obj.indexOf(","));
				//obj = obj.substring(obj.indexOf("icon_url") + 11);
				//var icn:String = obj.substring(0, obj.indexOf(",") -1);
				//obj = obj.substring(obj.indexOf("created_at") + 13);
				//var dte:String = obj.substring(0, obj.indexOf(" "));
				//obj = obj.substring(obj.indexOf("difficulty") + 13);
				//var dif:int = obj.substring(0, obj.indexOf("\",\""));
				//obj = obj.substring(obj.indexOf("id")+4);
				//var id:String = obj.substring(0, obj.indexOf("}"));
				//trace(des);
				//trace(adr);
				//trace(tle);
				//trace(nme);
				//trace(num);
				//trace(pts);
				//trace(icn);
				//trace(dte);
				//trace(dif);
				//trace(id);
				//trace("-----------");
				//
				//
				//mArr[i] = []; //just so it doesn't push it after the massive string
				//obj = mArr[i]; //redefine it's neater and shorter
				//obj.push(des); //starts at index 0
				//obj.push(adr);    //1
				//obj.push(tle); //2
				//obj.push(nme);    //3
				//obj.push(icn); //4
				//obj.push(num);    //5
				//obj.push(dif); //6
				//obj.push(dte);    //7
				//obj.push(pts); //8
				//obj.push(id);     //9
				//
				//for (var a:int = 0; a < _badges.length; a++)
				//{
					//if (_badges[a][0] == id)
					//{
						//_badges[a] = obj;
					//}
				//}
				//
				//_all.push(mArr[i]); //set all to equal the array of objects in mArr[i];
			//}
			//OLD2 METHOD ENDS------------------->}
			
			//old1 method removed
			
			loader.removeEventListener(Event.COMPLETE, splitBadgeJSON);
			displayOnScreen();			
		}
		
		private function displayOnScreen():void
		{
			//left so one can possibly add other stuff here
			loadImageConsec();
		}
		
		private function loadImageConsec():void
		{
			if (currentBadge >= _badges.length)
			{
				_badgeIcons.removeChild(_preloaderTxt);
				trace("finished loading badges");
				buttonsActivated = true;
				//end
				return;
			}
			var loader:Loader = new Loader();
			var icon:String = _badges[currentBadge].icon_url;
			adjustPercentBadgeLoadedPosition();
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, imageLoading);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
			loader.load(new URLRequest(icon));
			//added below removes necessity of using bitmap data
			var group:Sprite = new Sprite();
			var dx:int = (currentBadge * 40)%(40*numInRow);
			var dy:int = (int)(currentBadge / numInRow) * 40;
			group.x = dx+4;
			group.y = dy + 2 + startingCol;
			group.name = _badges[currentBadge].id.toString();
			group.addEventListener(MouseEvent.ROLL_OVER, badgeOver);
			group.addEventListener(MouseEvent.ROLL_OUT, hideToolTip);
			group.addEventListener(MouseEvent.CLICK, badgeClicked);
			var border:Bitmap = new ImgBorder();
			group.addChild(loader); //add Badge image
			group.addChild(border);
			_badgeIcons.addChild(group);
			_badges[currentBadge].icon_url = group;
			//end above group
			
			//_badges[currentBadge].icon_url = loader; //just replace the url of the badge with its loader
			numPoints.text = (int)(numPoints.text) + _badges[currentBadge].points;
		}
		
		private function adjustPercentBadgeLoadedPosition():void
		{
			var dx:int = (currentBadge * 40)%(40*numInRow);
			var dy:int = (int)((currentBadge) / numInRow) * 40;
			_preloaderTxt.x = dx + 4 + 20;
			_preloaderTxt.y = dy + 2 + startingCol;
			_preloaderTxt.text = "0";
		}
		
		private function imageLoading(event:ProgressEvent):void 
		{ 
			//Use it to get current download progress 
			_preloaderTxt.text = (int)((event.bytesLoaded / event.bytesTotal) * 100);
		} 
		
		private function imageLoaded(event:Event):void
		{
			//var icon:Sprite = new Sprite();
			//var dx:int = (currentBadge * 40)%(40*numInRow);
			//var dy:int = (int)(currentBadge / numInRow) * 40;
			//icon.x = dx+4;
			//icon.y = dy + 2 + startingCol;
			
			//icon.name = _badges[currentBadge].id.toString();
			//icon.addEventListener(MouseEvent.ROLL_OVER, badgeOver);
			//icon.addEventListener(MouseEvent.ROLL_OUT, hideToolTip);
			//icon.addEventListener(MouseEvent.CLICK, badgeClicked);
			//trace(_badges[currentBadge].icon_url); traces the loader
			event.target.removeEventListener(ProgressEvent.PROGRESS, imageLoading);
			event.target.removeEventListener(Event.COMPLETE, imageLoaded);
			
			//var badge:Bitmap = event.target.content;
			//var border:Bitmap = new ImgBorder();
			//trace(badge);
			//icon.addChild(badge); //add Badge image
			//icon.addChild(border); //add border
			//_badgeIcons.addChild(icon); //add product to finished icons
			
			//_badges[currentBadge].icon_url = icon;
			currentBadge++;
			manageScrollerScale();
			loadImageConsec();			
		} 
		
		private function createTextBox():void
		{
			//user name
			var userNametext:TextField =  new TextField();
			userNametext.x = 2;
			userNametext.y = 0;
			userNametext.width = 375;
			userNametext.height = 35;
			userNametext.selectable = false;
			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0x000000;
			format.bold = true;
            format.size = 25;
			if (userName.length >= 15)
				format.size = 21;
			userNametext.defaultTextFormat = format;
			userNametext.text = userName + "'s badges";
			userNametext.name = "Username textbox";
			_HUD.addChild(userNametext);
			
			userNametext.addEventListener(MouseEvent.ROLL_OVER, over); //for highlight
			userNametext.addEventListener(MouseEvent.ROLL_OVER, addChangeBox); //for change box
			userNametext.addEventListener(MouseEvent.ROLL_OUT, out);//for highlight
			userNametext.addEventListener(MouseEvent.CLICK, clickedUserName); //link to its profile
			
			
			
			numPoints = new TextField();
			numPoints.x = 460;
			numPoints.y = 0;
			numPoints.width = 80;
			numPoints.height = 30;
			numPoints.selectable = false;
			format = new TextFormat();
			format.font = "Verdana";
			format.color = 0x000000;
			format.align = "right";
			format.bold = true;
            format.size = 20;
			numPoints.defaultTextFormat = format;
			numPoints.text = "0";
			numPoints.name = "Amount of points user has text box";
			_HUD.addChild(numPoints);
			
			points = new TextField();
			points.x = 540;
			points.y = 0;
			points.width = 150;
			points.height = 30;
			points.selectable = false;
			format = new TextFormat();
			format.font = "Verdana";
			format.color = 0x000000;
			format.bold = true;
            format.size = 20;
			points.defaultTextFormat = format;
			points.text = "Points";
			points.name = "Points Text Box";
			_HUD.addChild(points);
			
			
			//CATCH THE USERNAME IF ITS A DEFAULT NO NAME APP
			if(userName == "NA")
			{
				userName = "";
				userNametext.text = ""; //just so they don't see "NA's badges"
				displayErrorMessage("change");
			}
		}
		
		private function clickedUserName(event:MouseEvent):void
		{
			//trace("clicked username");
			var req:URLRequest = new URLRequest("http://www.kongregate.com/accounts/" + userName);
			navigateToURL(req);
		}
		
		private function addChangeBox(event:MouseEvent):void
		{
			var changeStuff:Sprite = new Sprite();
			changeStuff.name = "Change Box";
			var changeIcon:Bitmap = new ImgBorder();
			changeIcon.x = 0;
			changeIcon.y = 0;
			changeIcon.scaleX = 1.3;
			changeIcon.scaleY = 0.6;
			var changeText:TextField = new TextField();
			changeText.text = "Change";
			changeText.x = 6;
			changeText.y = 3;
			changeText.selectable = false;
			changeStuff.addChild(changeIcon);
			changeStuff.addChild(changeText);
			_HUD.addChild(changeStuff);
			changeStuff.x = 300;
			changeStuff.y = 5;
			changeStuff.graphics.beginFill(0xFFFFFF, 1);
			changeStuff.graphics.drawRect(0, 0, 52, 24);
			changeStuff.graphics.endFill();
			
			changeStuff.addEventListener(MouseEvent.CLICK, clickedChange);
			changeStuff.addEventListener(Event.ENTER_FRAME, changeFrame);
		}
		
		private function clickedChange(event:MouseEvent):void
		{
			if (buttonsActivated == true)
			{
				displayErrorMessage("change");
			}
		}
		
		private function changeFrame(event:Event):void
		{
			changeCounter++;
			if (changeCounter > 60)
			{
				changeCounter = 0;
				event.currentTarget.removeEventListener(Event.ENTER_FRAME, changeFrame);
				removeChangeBox();
			}
		}
		
		private function removeChangeBox():void
		{
			_HUD.removeChild(_HUD.getChildByName("Change Box"));
		}
		
		private function getLogo():void //logo at top right of screen
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, logoLoaded);
			loader.load(new URLRequest("http://cdn1.kongregate.com/images/sharedassets/badge183x25stars.gif"));
			_HUD.addChild(loader);
		}
		
		private function logoLoaded(event:Event):void
		{
			//used to be :* type
			//var sp:Sprite = new Sprite();
			//var logo:Bitmap = event.target.content;
			trace(event.target.loader);
			event.target.loader.x = stage.stageWidth - event.target.loader.width - 4;
			event.target.loader.y = 4;
			//sp.addChild(logo);
			//_HUD.addChild(sp);
			event.target.loader.addEventListener(MouseEvent.ROLL_OVER, over);
			event.target.loader.addEventListener(MouseEvent.ROLL_OUT, out);
			event.target.loader.addEventListener(MouseEvent.CLICK, clickedLogo);
		} 
		
		private function clickedLogo(event:MouseEvent):void
		{
			trace("clicked the Kongregate logo");
			var req:URLRequest = new URLRequest("http://www.kongregate.com");
			navigateToURL(req); 
		}
		
		private function drag(event:MouseEvent):void
		{
			//used to be :* type
			var object:Sprite = event.target as Sprite; //"as Sprite" makes it compatible
			object.addEventListener(Event.ENTER_FRAME, move);
			clickY = stage.mouseY - _drag.y;
		}
		
		private function move(event:Event):void
		{
			//location of scroller
			var ny:int = stage.mouseY - clickY;
			if (ny -_drag.height/2 < minScroll)
			{
				ny = minScroll+_drag.height/2;
			}
			else if (ny + _drag.height / 2 > maxScroll)
			{
				ny = maxScroll-_drag.height/2;
			}
			_drag.y = ny;
			
			//location of badge icons in relation
			var scrollPixels:int = maxScroll - minScroll;
			var totalPixels:int = _badgeIcons.height+10; //10=buffer height for bottom shader
			var scalar:Number = scrollPixels / totalPixels;
			_badgeIcons.y = -(_drag.y-minScroll-_drag.height/2) / scalar;
		}
		
		private function manageScrollerScale():void
		{
			if (currentBadge / numInRow < 4) //make it only able to scroll if over 3 lines long
			{
				return;
			}
			var scrollPixels:int = maxScroll - minScroll;
			var totalPixels:int = _badgeIcons.height+10; //10=buffer height for bottom shader
			var scalar:Number = scrollPixels / totalPixels;
			_drag.height = scrollPixels * scalar;
			_drag.y=-scalar*_badgeIcons.y+minScroll+_drag.height/2;
		}
		
		private function killDrag(event:MouseEvent):void
		{
			_drag.removeEventListener(Event.ENTER_FRAME, move);
		}	
		
		//private function replaceBackslashesURL(s:String):String
		//{
		//***********I BELIVE NOT NEEDED REMOVE WHEN DISTRIBUTED***************************
			//while (s.indexOf("/") != -1)
			//{
				//s = s.substring(0, s.indexOf("/") - 1) + "*" + s.substring(s.indexOf("/") + 1);
				//trace("incomp  " + s);
			//}
			//while (s.indexOf("*") != -1)
			//{
				//s = s.substring(0, s.indexOf("*")) + "/" + s.substring(s.indexOf("*") + 1);
				//trace("incomp  " + s);
			//}
			//return s;
		//}
		
		//private function replaceSomeTags(s:String):String //replaces quote and backslashes
		//{
		//***********I BELIVE NOT NEEDED REMOVE WHEN DISTRIBUTED***************************
			//quotes
			//while (s.indexOf("\"") != -1)
			//{
				//s = s.substring(0, s.indexOf("\"") - 1) + "*" + s.substring(s.indexOf("\"") + 1);
			//}
			//while (s.indexOf("*") != -1)
			//{
				//s = s.substring(0, s.indexOf("*")) + "\"" + s.substring(s.indexOf("*") + 1);
			//}
			//backslashes
			//while (s.indexOf("/") != -1)
			//{
				//s = s.substring(0, s.indexOf("/") - 1) + "*" + s.substring(s.indexOf("/") + 1);
			//}
			//while (s.indexOf("*") != -1)
			//{
				//s = s.substring(0, s.indexOf("*")) + "/" + s.substring(s.indexOf("*") + 1);
			//}
			//return s;
		//}
		
		
		//Tooltip functions----------------->
		
		private function toolTipFrame(event:Event):void
		{
			var tempX:int = stage.mouseX + 20; //0 = x padding
			var tempY:int = stage.mouseY + 10; //20 = y padding
			
			if (tempX + _toolTip.width / 2 > stage.stageWidth / 2)
			{
				tempX = stage.mouseX - 220;
			}
			if (tempY > stage.stageHeight / 2)
			{
				tempY = stage.mouseY - _toolTip.height-10;
			}
			_toolTip.x = tempX;
			_toolTip.y = tempY;
			//trace("Unicode encoding");
		}
		private function hideToolTip(event:MouseEvent):void
		{
			if (_toolTip.parent != null)
			{
				_toolTip.removeEventListener(Event.ENTER_FRAME, toolTipFrame);
				_toolTip.parent.removeChild(_toolTip);
				event.currentTarget.filters = [];
			}
		}
		
		private function badgeClicked(event:MouseEvent):void
		{
			var obj:Object;
			trace(event.currentTarget.name);
			for (var i:int = 0 ; i < _badges.length; i++)
			{
				if (_badges[i].id == event.currentTarget.name)
				{
					obj = _badges[i];
					break;
				}
			}
			//trace(obj, obj.games[0], obj.games[0].url);
			var url:String = obj.games[0].url;
			var req:URLRequest = new URLRequest(url);
			navigateToURL(req);
		}
		
		private function badgeOver(event:MouseEvent):void
		{
			event.currentTarget.filters = [new GlowFilter(0xFFFFFF,1,10,10,2,1,false,false)];
			//trace("Moused over  + event.target.name + "or known as " + event.target);
			var obj:Object;
			for (var i:int = 0 ; i < _badges.length; i++)
			{
				if (_badges[i].id == event.target.name)
				{
					obj = _badges[i];
					break;
				}
			}
			var h:String = obj.name;
			var b:String = obj.description;
			var m:String = obj.games[0].title;
			b = b + " for " + obj.points + " points!";
			//trace(obj.games[0].title);
			//trace(h + "  Des   " + b);
			showToolTip(h, m, b);
		}
		
		private function showToolTip(_h:String, _m:String, _b:String):void
		{
			stage.addChild(_toolTip);
			//attach a new tooltip window to tooltip_mc
			_toolTip.name = "Active";
			
			//set content

			_head.htmlText = _h;
			_mid.htmlText = _m;
			_body.htmlText = _b;
						
			//make sure textboxes auto size to the content
			_head.autoSize = TextFieldAutoSize.CENTER;
			_mid.autoSize = TextFieldAutoSize.CENTER;
			_body.autoSize = TextFieldAutoSize.CENTER;
			
			//set tooltip background size
			_toolTipBG.width = 200;
			
			//sets the text width
			_head.width = 195;
			_mid.width = 195;
			_body.width = 195;
			
			//saves the content width/height
			var boxHeight:Number = _head.height + _body.height + _mid.height +10;
			var boxWidth:Number = _body.width + 10;
			
			//sets the background height based on text height
			_toolTipBG.height = boxHeight;

			//hide tooltip before positioning it on mouse (to prevent flicker)
			_toolTip.x = -_toolTip.width;
			_toolTip.y = -_toolTip.height;
			_toolTip.addEventListener(Event.ENTER_FRAME, toolTipFrame);
		}
		private function createToolTipText():void
		{
			_head =  new TextField();
			_head.x = 0;
			_head.y = 0;
			//_head.autoSize = TextFieldAutoSize.CENTER;
			_head.selectable = false;
			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0x000000;
			format.bold = true;
			format.underline = true;
            format.size = 9;
			_head.wordWrap = true;
			_head.defaultTextFormat = format;
			_head.text = "Badge Name"
			_toolTip.addChild(_head);
			
			_mid = new TextField();
			_mid.x = 0;
			_mid.y = 20;
			//_mid.autoSize = TextFieldAutoSize.CENTER;
			_mid.selectable = false;
			format = new TextFormat();
			format.font = "Verdana";
			format.color = 0x808080;
			format.italic = true;
            format.size = 9;
			_mid.defaultTextFormat = format;
			_mid.text = "Game Name";
			_mid.wordWrap = true;
			_toolTip.addChild(_mid);
			
			_body = new TextField();
			_body.x = 0;
			_body.y = 35;
			//_body.autoSize = TextFieldAutoSize.CENTER;
			_body.selectable = false;
			format = new TextFormat();
			format.font = "Verdana";
			format.color = 0x000000;
			format.bold = true;
            format.size = 8;
			_body.defaultTextFormat = format;
			_body.text = "Game Description might be a long name, but who cares.";
			_body.wordWrap = true;
			_toolTip.addChild(_body);
		}
		
		private function mOver(event:MouseEvent):void //for testing purposes only
		{
			trace("Moused over " + event.target.name + "or known as " + event.target);
		}
		
		private function initPreloaderTxt():void
		{
			_preloaderTxt = new TextField();
			_preloaderTxt.selectable = false;
			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0xFFFFFF;
            format.size = 9;
			_preloaderTxt.defaultTextFormat = format;
			_badgeIcons.addChild(_preloaderTxt);
		}
		
		private function addCreatedBy():void
		{
			_UG =  new TextField();
			_UG.x = stage.stageWidth - 140;
			_UG.y = stage.stageHeight - 20;
			//_head.autoSize = TextFieldAutoSize.CENTER;
			_UG.selectable = false;
			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0xFFFFFF;
            format.size = 9;
			_UG.defaultTextFormat = format;
			_UG.text = "Created by UGLabs";
			_createdBy.addChild(_UG);
		}
		
		private function catchIOError(event:IOErrorEvent):void
		{
			trace("Error caught: " + event.type);
			displayErrorMessage();
		}
		
		private function displayErrorMessage(type:String = null):void
		{
			_errorBlur = new Sprite();
			_errorBlur.graphics.beginFill(0x000000, 0.2);
			_errorBlur.graphics.lineTo(stage.stageWidth, 0);
			_errorBlur.graphics.lineTo(stage.stageWidth, stage.stageHeight);
			_errorBlur.graphics.lineTo(0, stage.stageHeight);
			_errorBlur.graphics.lineTo(0, 0);
			_errorBlur.graphics.endFill();
			_HUD.addChild(_errorBlur);
			
			_errorMessage = new Sprite();
			_errorMessage.graphics.lineStyle(3, 0xFFFFFF, 1, false, "none", null, JointStyle.ROUND);
			_errorMessage.graphics.beginFill(0xFFFFFF, 0.8);
			_errorMessage.graphics.lineTo(250, 0);
			_errorMessage.graphics.lineTo(250, 100);
			_errorMessage.graphics.lineTo(0, 100);
			_errorMessage.graphics.lineTo(0, 0);
			_errorMessage.graphics.endFill();
			_errorMessage.x = stage.stageWidth/2-125;
			_errorMessage.y = stage.stageHeight/2-50;
			_HUD.addChild(_errorMessage);
			
			var t:TextField = new TextField();
			t.autoSize = TextFieldAutoSize.CENTER;
			t.width = 250;
			t.selectable = false;
			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0x000000;
			format.bold = true;
            format.size = 12;
			t.wordWrap = true;
			t.defaultTextFormat = format;
			t.text = "Error: No such username (" + userName+ ") found";
			t.x = 0;
			t.y = 0;
			_errorMessage.addChild(t);
			
			_usernameInputBox = new TextField();
			_usernameInputBox.width = 220;
			_usernameInputBox.height = 24;
			_usernameInputBox.type = TextFieldType.INPUT;
			_usernameInputBox.wordWrap = false;
			_usernameInputBox.border = true;
			format.size = 14;
			format.bold = false;
			_usernameInputBox.defaultTextFormat = format;
			_usernameInputBox.x = stage.stageWidth/2-124;
			_usernameInputBox.y = stage.stageHeight / 2 + 24;
			_usernameInputBox.text = "Input a username here";
			_usernameInputBox.name = "Input Username Field";
			_HUD.addChild(_usernameInputBox);
			
			var enter:Sprite = new Sprite();
			var go:Bitmap = new ImgBorder();
			go.scaleX = go.scaleY = 0.60;
			var goText:TextField = new TextField();
			format.size = 10;
			format.bold = true;
			goText.defaultTextFormat = format;
			goText.text = "Go";
			goText.x = 3;
			goText.y = 3;
			goText.selectable = false;
			enter.addChild(go);
			enter.addChild(goText);
			enter.x = 224;
			enter.y = 75;
			_errorMessage.addChild(enter);
			enter.addEventListener(MouseEvent.CLICK, submitUsername);
			enter.addEventListener(MouseEvent.ROLL_OVER, over);
			enter.addEventListener(MouseEvent.ROLL_OUT, out);
			
			if (type == "change") //if its changing a username instead of having an error
			{
				t.text = "You may enter a valid username below"; //change the error text
				_usernameInputBox.text = userName; //change the input default text
				resetAllVars();
				
			}
			
		}
		private function submitUsername(event:MouseEvent):void
		{
			userName = (TextField)(_HUD.getChildByName("Input Username Field")).text;
			removeErrorMessage();
			
			var t:TextField = (TextField)(_HUD.getChildByName("Username textbox")); //adjust oversize uesername
			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0x000000;
			format.bold = true;
            format.size = 25;
			if (userName.length >= 15)
				format.size = 21;
			t.defaultTextFormat = format;
			t.text = userName + "'s badges"; //change the username textbox
			
			startUserRequest();
			//trace(userName);
		}
		private function removeErrorMessage():void
		{
			_HUD.removeChild(_errorBlur);
			_HUD.removeChild(_errorMessage);
			_HUD.removeChild(_HUD.getChildByName("Input Username Field"));
			_errorMessage.removeChild(_errorMessage.getChildAt(0));//call it once
			_errorMessage.removeChild(_errorMessage.getChildAt(0));//index shifts so I call it again
		}
		private function createSortText():void
		{
			var ss:Sprite = new Sprite();
			var ts:TextField = new TextField();
			ts.autoSize = TextFieldAutoSize.CENTER;
			ts.selectable = false;
			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0x000000;
			format.bold = true;
            format.size = 10;
			ts.defaultTextFormat = format;
			ts.text = "Sort:";
			ss.x = 375;
			ss.y = 2;
			ts.x = 375;
			ts.y = 2;
			_HUD.addChild(ts);
			_HUD.addChild(ss);
			
			var si:Sprite = new Sprite();
			var ti:TextField = new TextField();
			ti.autoSize = TextFieldAutoSize.CENTER;
			ti.selectable = false;
			var formatI:TextFormat = new TextFormat();
			formatI.font = "Verdana";
			formatI.color = 0x000000;
			formatI.bold = true;
            formatI.size = 10;
			ti.defaultTextFormat = formatI;
			ti.text = "Popular";
			si.x = 410;
			si.y = 2;
			ti.x = 410;
			ti.y = 2;
			si.graphics.beginFill(0xFFFFFF, .2);
			si.graphics.drawRect(0, 3, ti.width, ti.height-3);
			si.graphics.endFill();
			si.addEventListener(MouseEvent.CLICK, sortClick);
			si.addEventListener(MouseEvent.ROLL_OVER, over);
			si.addEventListener(MouseEvent.ROLL_OUT, out);
			si.name = "popular";
			ti.mouseEnabled = false;
			_HUD.addChild(ti);
			_HUD.addChild(si);
			
			var sd:Sprite = new Sprite();
			var td:TextField = new TextField();
			td.autoSize = TextFieldAutoSize.CENTER;
			td.width = 15;
			td.selectable = false;
			var formatD:TextFormat = new TextFormat();
			formatD.font = "Verdana";
			formatD.color = 0x000000;
			formatD.bold = true;
            formatD.size = 10;
			td.defaultTextFormat = formatD;
			td.text = "Date";
			sd.x = 426;
			sd.y = 16;
			td.x = 426;
			td.y = 16;
			sd.graphics.beginFill(0xFFFFFF, .2);
			sd.graphics.drawRect(1, 3, td.width-1, td.height-3);
			sd.graphics.endFill();
			sd.addEventListener(MouseEvent.CLICK, sortClick);
			sd.addEventListener(MouseEvent.ROLL_OVER, over);
			sd.addEventListener(MouseEvent.ROLL_OUT, out);
			sd.name = "date";
			td.mouseEnabled = false;
			_HUD.addChild(td);
			_HUD.addChild(sd);
			
			var sp:Sprite = new Sprite();
			var tp:TextField = new TextField();
			tp.autoSize = TextFieldAutoSize.CENTER;
			tp.width = 15;
			tp.selectable = false;
			var formatP:TextFormat = new TextFormat();
			formatP.font = "Verdana";
			formatP.color = 0x000000;
			formatP.bold = true;
            formatP.size = 10;
			tp.defaultTextFormat = formatP;
			tp.text = "Points";
			sp.x = 386;
			sp.y = 16;
			tp.x = 386;
			tp.y = 16;
			sp.graphics.beginFill(0xFFFFFF, .2);
			sp.graphics.drawRect(0, 3, tp.width, tp.height-3);
			sp.graphics.endFill();
			sp.addEventListener(MouseEvent.CLICK, sortClick);
			sp.addEventListener(MouseEvent.ROLL_OVER, over);
			sp.addEventListener(MouseEvent.ROLL_OUT, out);
			sp.name = "points";
			tp.mouseEnabled = false;
			_HUD.addChild(tp);
			_HUD.addChild(sp);
		}
		
		private function sortClick(event:MouseEvent):void
		{
			trace(event.currentTarget.name + " was clicked");
			if (buttonsActivated && currentSorted != event.currentTarget.name)
			{
				buttonsActivated = false;
				sortBadges(event.currentTarget.name);
			}
		}
		private function over(event:MouseEvent):void
		{
			event.currentTarget.filters = [new GlowFilter(0xFFFFFF,1,6,6,1,1,false,false)];
			
		}
		private function out(event:MouseEvent):void
		{
			event.currentTarget.filters = [];			
		}
		
		private function sortBadges(type:String):void
		{
			trace("sorted");
			currentSorted = type;
			if (type == "points")
			{
				_badges.sort(orderByPoints);
			}
			else if (type == "date")
			{
				_badges.sort(orderByDate);
			}
			else if (type == "popular")
			{
				_badges.sort(orderByPopular);
			}
			for (var i:int = 0; i < _badges.length-1; i++)
			{
				var dx:int = (i * 40)%(40*numInRow)+4;
				var dy:int = (int)((i) / numInRow) * 40 + 2 + startingCol;
				TweenLite.to(_badges[i].icon_url, 2, { x:dx, y:dy, ease:Elastic.easeOut});
			}
			var endX:int = ((_badges.length - 1) * 40) % (40 * numInRow) + 4;
			var endY:int = (int)((_badges.length - 1) / numInRow) * 40 + 2 + startingCol;
			TweenLite.to(_badges[i].icon_url, 2, { x:endX, y:endY, ease:Elastic.easeOut,onComplete:finishedSorting});
		}
		
		private function finishedSorting():void
		{
			buttonsActivated = true;
			trace("done sorting");
		} 
		private function orderByPoints(a:Object, b:Object):Number
		{	
			// Change a[0] & b[0] by a[i] & b[i]	
			// (where i is the array index you want to use to sort the multidimensional array)	
			var num1:Number = Number(a.points);	
			var num2:Number = Number(b.points);	
			if (num1 < num2)
			{		
				return -1;	
			}
			else if (num1 > num2)
			{		
				return 1;	
			}else
			{		
				return 0;	
			}
		}
		private function orderByDate(a:Object, b:Object):Number
		{	
			// Change a[0] & b[0] by a[i] & b[i]	
			// (where i is the array index you want to use to sort the multidimensional array)	
			var num1:String = a.created_at.substring(0,a.created_at.indexOf(" "));	
			var num2:String = b.created_at.substring(0,b.created_at.indexOf(" "));
			return num1.localeCompare(num2);
		}
		private function orderByPopular(a:Object, b:Object):Number
		{	
			// Change a[0] & b[0] by a[i] & b[i]	
			// (where i is the array index you want to use to sort the multidimensional array)	
			var num1:Number = Number(a.users_count);	
			var num2:Number = Number(b.users_count);	
			if (num1 < num2)
			{		
				return -1;	
			}
			else if (num1 > num2)
			{		
				return 1;	
			}else
			{		
				return 0;	
			}
		}
	}
}
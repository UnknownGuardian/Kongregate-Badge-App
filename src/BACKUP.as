package 
{
	import flash.display.*;
	import flash.events.*;  
	import flash.net.navigateToURL;
	import flash.net.URLRequest; 
	import flash.net.URLLoader; 
	import flash.text.*; 
	import flash.geom.*
	import com.adobe.serialization.json.JSON;

	
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
		public var _toolTipBG:Sprite;
		public var _head:TextField;
		public var _body:TextField;
		public var _UG:TextField;

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
			handleStage();
			getLogo();
			addCreatedBy();
			getUserName();
			getUserJSON();
			

			//---Supposed Order of operations---
			//load .json file (x2)
			//fill array of items to load
			//load border first
			//start loading graphics with a preloader as its loading
		}
		
		private function handleStage():void
		{			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
            _bg.graphics.beginFill(0x990000);
            _bg.graphics.lineStyle(4, 0x000000);
            _bg.graphics.drawRoundRect(0, 0, stage.stageWidth-2, stage.stageHeight-2, 9);
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
			_drag.y = 30+_drag.height/2;
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
		}
		
		private function getUserName():void
		{
			var url:String = root.loaderInfo.loaderURL;
			url = url.substring(url.lastIndexOf("/") + 1);
			//trace(url);
			userName = url.substring(url.lastIndexOf("%5F")+3,url.length-4);
			//trace(userName);
			createTextBox();
		}
		private function getUserJSON():void
		{
			request.url= "http://www.kongregate.com/accounts/" + userName + "/badges.json"; 
			loader.load(request); 
			loader.addEventListener(Event.COMPLETE, splitUserJSON); 
		}
		private function getBadgeJSON():void
		{
			request.url="http://www.kongregate.com/badges.json"; 
			loader.load(request); 
			loader.addEventListener(Event.COMPLETE, splitBadgeJSON);
		}
		private function splitUserJSON(event:Event):void 
		{ 
			var load:URLLoader = URLLoader(event.target) ;
			_badges = JSON.decode(load.data) ;
			
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
			//
			loader.removeEventListener(Event.COMPLETE, splitUserJSON);
			trace("Retriving Badge JSON");
			getBadgeJSON(); //call at end
		}
		private function splitBadgeJSON(event:Event):void 
		{ 
			trace("Before JSON Badge Decoding");
			var load:URLLoader = URLLoader(event.target) ;
			var all:Array = JSON.decode(load.data);
			
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
		
			//OLD2 METHOD------------------->
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
			//OLD2 METHOD ENDS------------------->
			
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
				return;
				//end
			}
			var loader:Loader = new Loader();
			var icon:String = _badges[currentBadge].icon_url;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, imageLoading); 
			loader.load(new URLRequest(icon));
			_badges[currentBadge].icon_url = loader; //just replace the url of the badge with its loader
			numPoints.text = (int)(numPoints.text) + _badges[currentBadge].points;
		}
		
		private function imageLoading(e:ProgressEvent):void 
		{ 
		//Use it to get current download progress 
		// Hint: You could tie the values to a preloader :) 
		} 
		
		private function imageLoaded(event:Event):void
		{
			var icon:Sprite = new Sprite();
			var dx:int = (currentBadge * 40)%(40*numInRow);
			var dy:int = (int)(currentBadge / numInRow) * 40;
			icon.x = dx+4;
			icon.y = dy + 2 + startingCol;
			
			icon.name = currentBadge.toString();
			icon.addEventListener(MouseEvent.ROLL_OVER, badgeOver);
			icon.addEventListener(MouseEvent.ROLL_OUT, hideToolTip);
			icon.addEventListener(MouseEvent.CLICK, badgeClicked);
			
			var badge:Bitmap = event.target.content;
			var border:Bitmap = new ImgBorder();
			//trace(badge);
			icon.addChild(badge); //add Badge image
			icon.addChild(border); //add border
			//icon.getChildAt(0).name = currentBadge.toString();
			//icon.getChildAt(1).name = currentBadge.toString();
			_badgeIcons.addChild(icon); //add product to finished icons
			
			currentBadge++;
			manageScrollerScale();
			loadImageConsec();
			
		} 
		
		private function createTextBox():void
		{
			//user name
			var userNametext:TextField =  new TextField();
			userNametext.x = 5;
			userNametext.y = 0;
			userNametext.width = 450;
			userNametext.height = 40;
			userNametext.selectable = false;
			var format:TextFormat = new TextFormat();
			format.font = "Verdana";
			format.color = 0x000000;
			format.bold = true;
            format.size = 25;
			userNametext.defaultTextFormat = format;
			userNametext.text = userName + "'s badges";
			userNametext.name = "Username textbox";
			_HUD.addChild(userNametext);
			
			userNametext.addEventListener(MouseEvent.CLICK, clickedUserName);
			
			
			
			numPoints = new TextField();
			numPoints.x = 440;
			numPoints.y = 0;
			numPoints.width = 100;
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
		}
		
		private function clickedUserName(event:MouseEvent):void
		{
			//trace("clicked username");
			var req:URLRequest = new URLRequest("http://www.kongregate.com/accounts/" + userName);
			navigateToURL(req);
		}
			
		private function getLogo():void //logo at top right of screen
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, logoLoaded);
			loader.load(new URLRequest("http://cdn1.kongregate.com/images/sharedassets/badge183x25stars.gif"));
		}
		
		private function logoLoaded(event:Event):void
		{
			//used to be :* type
			var sp:Sprite = new Sprite();
			var logo:Bitmap = event.target.content;
			logo.x = stage.stageWidth - logo.width - 4;
			logo.y = 4;
			//icon.name = "Top right logo"; //Error. Why?
			sp.addChild(logo);
			_HUD.addChild(sp);
			sp.addEventListener(MouseEvent.CLICK, clickedLogo);
		} 
		
		private function clickedLogo(event:MouseEvent):void
		{
			trace("c");
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
			if (currentBadge / numInRow < 5)
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
				event.target.alpha = 1;
			}
		}
		
		private function badgeClicked(event:MouseEvent):void
		{
			var url:String = _badges[event.target.name].games[0].url;
			//trace(_badges[event.target.name].games[0].url);
			var req:URLRequest = new URLRequest(url);
			navigateToURL(req);
		}
		
		private function badgeOver(event:MouseEvent):void
		{
			event.target.alpha = 0.85;
			//trace("Moused over " + event.target.name + "or known as " + event.target);
			var h:String = _badges[event.target.name].name;
			var b:String = _badges[event.target.name].description;
			//trace(h + "  Des   " + b);
			showToolTip(h, b);
		}
		
		private function showToolTip(_h:String, _b:String):void
		{
			stage.addChild(_toolTip);
			//attach a new tooltip window to tooltip_mc
			_toolTip.name = "Active";
			
			//set content
			//HOW DO I PARSE \u0417\u0434\u043e\e043d\u0447\u0435\u043d\u043e?
			/*_head.htmlText = replaceSomeTags(_h);
			_body.htmlText = replaceSomeTags(_b);
			*/
			_head.htmlText = _h;
			_body.htmlText = _b;
						
			//make sure textboxes auto size to the content
			_head.autoSize = TextFieldAutoSize.CENTER;
			_body.autoSize = TextFieldAutoSize.CENTER;
			
			//set tooltip background size
			_toolTipBG.width = 200;
			
			//sets the text width
			_head.width = 200;
			_body.width = 200;
			
			//saves the content width/height
			var boxHeight:Number = _head.height + _body.height + 10;
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
			_head.text = "Game Name"
			_toolTip.addChild(_head);
			
			_body = new TextField();
			_body.x = 0;
			_body.y = 20;
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
	}
}
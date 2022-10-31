package meta.state.charting;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import gameObjects.*;
import gameObjects.userInterface.*;
import gameObjects.userInterface.notes.*;
import gameObjects.background.*;
import haxe.Json;
import lime.utils.Assets;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import meta.data.Conductor.BPMChangeEvent;
import meta.data.Section.SwagSection;
import meta.data.Song.SwagSong;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.SoundChannel;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import meta.state.menus.*;

using StringTools;

/**
	"The original base engine version was too bland, so i spruced it up a bit haha (i hate my life)" ~Tucker 2022
**/
class NewChartingState extends MusicBeatState
{
	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	var curSection:Int = 0;

	var curNoteType:Int = 0;

	public static var lastSection:Int = 0;

	var bpmTxt:FlxText;
	
	var daStage:String = '';
	var nameColor = 0xFFFFFFFF;
	public static var week:Int = 0;
	var pitchText:FlxText;

	var strumLine:FlxSprite;
	var curSong:String = PlayState.SONG.song;
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;
	
	var dad:Character;
	var bf:Boyfriend;
	
	var dadOffsetX:Int = 0;
	var dadOffsetY:Int = 0;
	var bfOffsetX:Int = 0;
	var bfOffsetY:Int = 0;
	
	var highlight:FlxSprite;

	public static var GRID_SIZE:Int = 40;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;

	var gridBG:FlxSprite;

	var _song:SwagSong;

	var typingShit:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;
	
	var playClaps:Bool = false;
	var claps:Array<Note> = [];
	
	var noteAnim:Array<Note> = [];

	var tempBpm:Float = 0;

	var vocalsBF:FlxSound;
	var vocalsDad:FlxSound;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var typeText:FlxText = new FlxText(10, 60, 0, "Note Type: 0", 24);

	override function create()
	{
		super.create();

		curSection = lastSection;
		
		/// get hardcoded stage type if chart is fnf style
		if (PlayState.determinedChartType == "FNF")
		{
			// this is because I want to avoid editing the fnf chart type
			// custom stage stuffs will come with forever charts
			switch (CoolUtil.spaceToDash(PlayState.SONG.song.toLowerCase()))
			{
				case 'spookeez' | 'south' | 'monster':
					daStage = 'spooky';
				case 'pico' | 'blammed' | 'philly-nice':
					daStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					daStage = 'highway';
				case 'cocoa' | 'eggnog':
					daStage = 'mall';
				case 'winter-horrorland':
					daStage = 'mallEvil';
				case 'senpai' | 'roses':
					daStage = 'school';
				case 'thorns':
					daStage = 'schoolEvil';
				case 'spoopy' | 'trick' | 'treat':
					daStage = 'streetSpooky';
				default:
					daStage = 'stage';
			}

			PlayState.curStage = daStage;
			nameColor = CoolUtil.weekToColor(week);
		}
		
		var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/base/charting/' + daStage));
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
		add(gridBG);

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		add(gridBlackLine);
		
		var songName:FlxText = new FlxText(40, 10, 0, curSong, 32);
		songName.alignment = FlxTextAlign.CENTER;
		songName.borderStyle = FlxTextBorderStyle.OUTLINE;
		songName.borderSize = 3;
		songName.borderColor = FlxColor.BLACK;
		songName.color = nameColor;
		songName.scrollFactor.set();
		add(songName);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			/*
				_song = {
					song: 'Test',
					notes: [],
					bpm: 150,
					needsVoices: true,
					player1: 'bf',
					player2: 'dad',
					speed: 1,
					validScore: false
			};*/
		}

		leftIcon = new HealthIcon(_song.player1);
		rightIcon = new HealthIcon(_song.player2);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(0, -100);
		rightIcon.setPosition(gridBG.width / 2, -100);
		
		dad = new Character().setCharacter(50, 700, _song.player2);
		dad.scrollFactor.set();
		dad.alpha = 0.4;
		
		switch(_song.player2)
		{
			case 'pico':
				dad.flipX = true;
			case 'parents-christmas':
				dadOffsetX = 250;
				dad.x = dad.x - dadOffsetX;
			case 'senpai' | 'senpai-angry':
				dad.flipX = false;
				dadOffsetX = 100;
				dadOffsetY = 450;
				dad.x = dad.x + dadOffsetX;
				dad.y = dad.y + dadOffsetY;
			case 'spirit':
				dad.flipX = false;
				dadOffsetX = 100;
				dadOffsetY = 100;
				dad.x = dad.x - dadOffsetX;
				dad.y = dad.y + dadOffsetY;
			default:
				dad.flipX = false;
				dadOffsetX = 0;
				dadOffsetY = 0;
				dad.x = dad.x + dadOffsetX;
				dad.y = dad.y + dadOffsetY;
		}
		
		bf = new Boyfriend();
		bf.setCharacter(750, 700, _song.player1);
		bf.scrollFactor.set();
		bf.alpha = 0.4;
		
		switch (_song.player1)
		{
			case 'bf-pixel':
				bfOffsetX = 200;
				bfOffsetY = 100;
				bf.x = bf.x + bfOffsetX;
				bf.y = bf.y + bfOffsetY;
			default:
				bfOffsetX = 0;
				bfOffsetY = 0;
				bf.x = bf.x + bfOffsetX;
				bf.y = bf.y + bfOffsetY;
		}
		
		FlxG.mouse.visible = true;
		FlxG.save.bind('funkin', 'ninjamuffin99');

		tempBpm = _song.bpm;

		addSection();

		// sections = _song.notes;

		updateGrid();

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		pitchText = new FlxText(15, FlxG.height - 25, 0, "Pitch: 1", 16);
		pitchText.scrollFactor.set();
		add(pitchText);

		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4, FlxColor.BLACK);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);
		add(strumLine);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2;
		UI_box.y = 20;
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();

		add(curRenderedNotes);
		add(curRenderedSustains);
		
		add(dad);
		add(bf);

		typeText.scrollFactor.set();
		add(typeText);
	}

	function addSongUI():Void
	{
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var check_voices_bf = new FlxUICheckBox(10, 25, null, null, "BF Has voice track", 100);
		check_voices_bf.checked = _song.needsVoicesBF;
		// _song.needsVoices = check_voices.checked;
		check_voices_bf.callback = function()
		{
			_song.needsVoicesBF = check_voices_bf.checked;
			loadSong(_song.song);
			trace('BF CHECKED!');
		};
		
		var check_voices_dad = new FlxUICheckBox(10, 40, null, null, "Dad Has voice track", 100);
		check_voices_dad.checked = _song.needsVoicesDad;
		// _song.needsVoices = check_voices.checked;
		check_voices_dad.callback = function()
		{
			_song.needsVoicesDad = check_voices_dad.checked;
			loadSong(_song.song);
			trace('DAD CHECKED!');
		};

		var check_mute_inst = new FlxUICheckBox(10, 200, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			songMusic.volume = vol;
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			loadJson(_song.song.toLowerCase());
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'load autosave', loadAutosave);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		
		var hitsounds = new FlxUICheckBox(10, stepperSpeed.y + 60, null, null, "Play hitsounds", 100);
		hitsounds.checked = false;
		hitsounds.callback = function()
		{
			playClaps = hitsounds.checked;
			trace('HITSOUND CHECK! ' + playClaps);
		};

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 1, 1, 1, 339, 0);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

		var player1DropDown = new FlxUIDropDownMenu(10, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
			updatePlayers();
		});
		player1DropDown.selectedLabel = _song.player1;

		var player2DropDown = new FlxUIDropDownMenu(140, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
			updatePlayers();
		});

		player2DropDown.selectedLabel = _song.player2;

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);
		tab_group_song.add(hitsounds);

		tab_group_song.add(check_voices_bf);
		tab_group_song.add(check_voices_dad);
		tab_group_song.add(check_mute_inst);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(player2DropDown);

		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(strumLine);
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		stepperSectionBPM = new FlxUINumericStepper(10, 80, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);

		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last section", function()
		{
			copySection(Std.int(stepperCopy.value));
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", clearSection);

		var swapSection:FlxButton = new FlxButton(10, 170, "Swap section", function()
		{
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note = _song.notes[curSection].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSection].sectionNotes[i] = note;
				updateGrid();
			}
		});

		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = false;
		// _song.needsVoices = check_mustHit.checked;

		check_altAnim = new FlxUICheckBox(10, 400, null, null, "Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, 60, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		tab_group_section.add(stepperLength);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;
	var stepperType:FlxUINumericStepper;

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		tab_group_note.add(stepperSusLength);
		tab_group_note.add(applyLength);

		// note types
		stepperType = new FlxUINumericStepper(10, 30, Conductor.stepCrochet / 125, 0, 0, (Conductor.stepCrochet / 125) + 10); // 10 is placeholder
		// I have no idea what i'm doing lmfao
		stepperType.value = 0;
		stepperType.name = 'note_type';

		tab_group_note.add(stepperType);

		UI_box.addGroup(tab_group_note);
		// I'm genuinely tempted to go around and remove every instance of the word "sus" it is genuinely killing me inside
	}

	var songMusic:FlxSound;

	function loadSong(daSong:String):Void
	{
		if (songMusic != null)
			songMusic.stop();

		if (vocalsBF != null)
			vocalsBF.stop();
		if (vocalsDad != null)
			vocalsDad.stop();

		songMusic = new FlxSound().loadEmbedded(Paths.inst(daSong), false, true);
		if (_song.needsVoicesBF)
			vocalsBF = new FlxSound().loadEmbedded(Paths.voicesBF(daSong), false, true); 
		else
			vocalsBF = new FlxSound();
			
		if (_song.needsVoicesDad)
			vocalsDad = new FlxSound().loadEmbedded(Paths.voicesDad(daSong), false, true); 
		else
			vocalsDad = new FlxSound();
		FlxG.sound.list.add(songMusic);
		FlxG.sound.list.add(vocalsBF);
		FlxG.sound.list.add(vocalsDad);

		songMusic.play();
		vocalsBF.play();
		vocalsDad.play();

		pauseMusic();

		songMusic.onComplete = function()
		{
			ForeverTools.killMusic([songMusic, vocalsBF, vocalsDad]);
			loadSong(daSong);
		};
		//
	}

	function pauseMusic()
	{
		songMusic.time = Math.max(songMusic.time, 0);
		songMusic.time = Math.min(songMusic.time, songMusic.length);

		songMusic.pause();
		vocalsBF.pause();
		vocalsDad.pause();
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
		/* 
			var loopCheck = new FlxUICheckBox(UI_box.x + 10, UI_box.y + 50, null, null, "Loops", 100, ['loop check']);
			loopCheck.checked = curNoteSelected.doesLoop;
			tooltips.add(loopCheck, {title: 'Section looping', body: "Whether or not it's a simon says style section", style: tooltipType});
			bullshitUI.add(loopCheck);

		 */
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSection].mustHitSection = check.checked;
				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSection].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			// ew what was this before? made it switch cases instead of else if
			switch (wname)
			{
				case 'section_length':
					_song.notes[curSection].lengthInSteps = Std.int(nums.value); // change length
					updateGrid(); // vrrrrmmm
				case 'song_speed':
					_song.speed = nums.value; // change the song speed
				case 'song_bpm':
					tempBpm = Std.int(nums.value);
					Conductor.mapBPMChanges(_song);
					Conductor.changeBPM(Std.int(nums.value));
					updateGrid();
				case 'note_susLength': // STOP POSTING ABOUT AMONG US
					curSelectedNote[2] = nums.value; // change the currently selected note's length
					updateGrid(); // oh btw I know sus stands for sustain it just bothers me
				case 'note_type':
					curNoteType = Std.int(nums.value); // oh yeah dont forget this has to be an integer
				// set the new note type for when placing notes next!
				case 'section_bpm':
					_song.notes[curSection].bpm = Std.int(nums.value); // redefine the section's bpm
					updateGrid(); // update the note grid
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	/* this function got owned LOL
		function lengthBpmBullshit():Float
		{
			if (_song.notes[curSection].changeBPM)
				return _song.notes[curSection].lengthInSteps * (_song.notes[curSection].bpm / _song.bpm);
			else
				return _song.notes[curSection].lengthInSteps;
	}*/
	function sectionStartTime():Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection)
		{
			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	var side:String = 'N'; //just remember NOT to add a file called "soundNoteTickN"
	
	override function update(elapsed:Float)
	{		
		updateHeads();
		
		FlxG.camera.zoom = FlxMath.lerp(1.00, FlxG.camera.zoom, 0.95);
		
		curStep = recalculateSteps();

		typeText.text = 'Note Type: ' + CoolUtil.noteTypeToString(curNoteType);

		Conductor.songPosition = songMusic.time;
		_song.song = typingShit.text;

		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));

		if (playClaps)
		{
			curRenderedNotes.forEach(function(note:Note)
			{
				if (songMusic.playing)
				{
					FlxG.overlap(strumLine, note, function(_, _)
					{
						if(!claps.contains(note))
						{
							claps.push(note);
							if (check_mustHitSection.checked)
								switch (note.rawNoteData)
								{
									case 0 | 1 | 2 | 3:
										if (_song.needsVoicesBF)
											side = 'R'; //bf side
										else
											side = 'N';
									case 4 | 5 | 6 | 7:
										if (_song.needsVoicesDad)
											side = 'L'; //dad side
										else
											side = 'N';
								}
							else
								switch (note.rawNoteData)
								{
									case 0 | 1 | 2 | 3:
										if (_song.needsVoicesDad)
											side = 'L'; //dad side
										else
											side = 'N';
									case 4 | 5 | 6 | 7:
										if (_song.needsVoicesBF)
											side = 'R'; //bf side
										else
											side = 'N';
								}
							if (note.noteType == 0)
								FlxG.sound.play(Paths.sound('soundNoteTick' + side));
							//trace('hit!');
						}
					});
				}
			});
		}
		
		curRenderedNotes.forEach(function(note:Note)
		{
			if (songMusic.playing)
			{
				//NORMAL NOTES
				FlxG.overlap(strumLine, note, function(_, _)
				{
					if(!noteAnim.contains(note))
					{
						noteAnim.push(note);
						singPlayers(note.rawNoteData, note.noteType);
						if (note.alpha != 0.4)
							note.alpha = 0.4;
					}
				});
				
				//SUSTAIN NOTES
				if (note.sustainLength > 0)
					FlxG.overlap(strumLine, curRenderedSustains, function(_, _)
					{
						if (check_mustHitSection.checked)
						{
							switch (note.rawNoteData)
							{
								case 0 | 1 | 2 | 3:
									bf.holdTimer = 0;
								case 4 | 5 | 6 | 7:
									dad.holdTimer = 0;
							}
						}
						else
						{
							switch (note.rawNoteData)
							{
								case 0 | 1 | 2 | 3:
									dad.holdTimer = 0;
								case 4 | 5 | 6 | 7:
									bf.holdTimer = 0;
							}
						}
					});
			}
			else
				note.alpha = 1;
		});
		
		if ((bf != null && bf.animation != null) && (bf.holdTimer > Conductor.stepCrochet * (4 / 1000)))
		{
			if (bf.animation.curAnim.name.startsWith('sing'))
				bf.dance();
		}
		
		if (curBeat % 4 == 0 && curStep >= 16 * (curSection + 1))
		{
			//trace(curStep);
			//trace((_song.notes[curSection].lengthInSteps) * (curSection + 1));
			//trace('DUMBSHIT');

			if (_song.notes[curSection + 1] == null)
			{
				addSection();
			}

			changeSection(curSection + 1, false);
		}

		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEach(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
						{
							selectNote(note);
						}
						else
						{
							//trace('tryin to delete note...');
							deleteNote(note);
						}
					}
				});
			}
			else
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
				{
					FlxG.log.add('added note');
					addNote();
				}
			}
		}

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
		{
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			lastSection = curSection;

			PlayState.SONG = _song;
			songMusic.stop();
			vocalsBF.stop();
			vocalsDad.stop();
			songMusic.pitch = 1;
			vocalsBF.pitch = 1;
			vocalsDad.pitch = 1;
			Main.switchState(this, new PlayState());
		}
		
		if (FlxG.keys.justPressed.ESCAPE)
			Main.switchState(this, new MainMenuState());

		if (FlxG.keys.justPressed.E)
			changeNoteSustain(Conductor.stepCrochet);
		if (FlxG.keys.justPressed.Q)
			changeNoteSustain(-Conductor.stepCrochet);

		if (FlxG.keys.justPressed.ONE)
			curNoteType = 1;

		if (FlxG.keys.justPressed.TWO)
			curNoteType = 2;

		if (FlxG.keys.justPressed.THREE)
			curNoteType = 0;

		if (FlxG.keys.justPressed.TAB)
		{
			if (FlxG.keys.pressed.SHIFT)
			{
				UI_box.selected_tab -= 1;
				if (UI_box.selected_tab < 0)
					UI_box.selected_tab = 2;
			}
			else
			{
				UI_box.selected_tab += 1;
				if (UI_box.selected_tab >= 3)
					UI_box.selected_tab = 0;
			}
		}

		if (!typingShit.hasFocus)
		{
			if (FlxG.keys.justPressed.SPACE)
			{
				if (songMusic.playing)
				{
					songMusic.pause();
					vocalsBF.pause();
					vocalsDad.pause();
					claps.splice(0, claps.length);
					noteAnim.splice(0, noteAnim.length);
				}
				else
				{
					vocalsBF.play();
					vocalsDad.play();
					songMusic.play();
				}
			}

			if (FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			if (FlxG.mouse.wheel != 0)
			{
				vocalsBF.pitch += (FlxG.mouse.wheel / 10);
				vocalsDad.pitch += (FlxG.mouse.wheel / 10);
				songMusic.pitch += (FlxG.mouse.wheel / 10);
				pitchText.text = 'Pitch: ' + songMusic.pitch;
			}

			if (!FlxG.keys.pressed.SHIFT)
			{
				if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
				{
					songMusic.pause();
					vocalsBF.pause();
					vocalsDad.pause();
					claps.splice(0, claps.length);
					noteAnim.splice(0, noteAnim.length);

					var daTime:Float = 700 * FlxG.elapsed;

					if (FlxG.keys.pressed.W)
					{
						songMusic.time -= daTime;
					}
					else
						songMusic.time += daTime;

					vocalsBF.time = songMusic.time;
					vocalsDad.time = songMusic.time;
				}
			}
			else
			{
				if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
				{
					songMusic.pause();
					vocalsBF.pause();
					vocalsDad.pause();

					var daTime:Float = Conductor.stepCrochet * 2;

					if (FlxG.keys.justPressed.W)
					{
						songMusic.time -= daTime;
					}
					else
						songMusic.time += daTime;

					vocalsBF.time = songMusic.time;
					vocalsDad.time = songMusic.time;
				}
			}
		}

		_song.bpm = tempBpm;

		/* if (FlxG.keys.justPressed.UP)
				Conductor.changeBPM(Conductor.bpm + 1);
			if (FlxG.keys.justPressed.DOWN)
				Conductor.changeBPM(Conductor.bpm - 1); */

		var shiftThing:Int = 1;
		if (FlxG.keys.pressed.SHIFT)
			shiftThing = 4;
		if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
			changeSection(curSection + shiftThing);
		if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
			changeSection(curSection - shiftThing);

		bpmTxt.text = bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(songMusic.length / 1000, 2))
			+ "\nSection: "
			+ curSection
			+ "\nBeat: "
			+ curBeat;
		super.update(elapsed);
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[3] != 0)
				return;
			
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (songMusic.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((songMusic.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		songMusic.pause();
		vocalsBF.pause();
		vocalsDad.pause();

		// Basically old shit from changeSection???
		songMusic.time = sectionStartTime();

		if (songBeginning)
		{
			songMusic.time = 0;
			curSection = 0;
		}

		vocalsBF.time = songMusic.time;
		vocalsDad.time = songMusic.time;
		updateCurStep();

		updateGrid();
		updateSectionUI();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		//trace('changing section' + sec);

		if (_song.notes[sec] != null)
		{
			curSection = sec;

			updateGrid();

			if (updateMusic)
			{
				songMusic.pause();
				vocalsBF.pause();
				vocalsDad.pause();

				/*var daNum:Int = 0;
					var daLength:Float = 0;
					while (daNum <= sec)
					{
						daLength += lengthBpmBullshit();
						daNum++;
				}*/

				songMusic.time = sectionStartTime();
				vocalsBF.time = songMusic.time;
				vocalsDad.time = songMusic.time;
				updateCurStep();
			}

			updateGrid();
			updateSectionUI();
			
			if (songMusic.playing)
				FlxG.camera.zoom += 0.015;
		}
	}

	function copySection(?sectionNum:Int = 1)
	{
		var daSec = FlxMath.maxInt(curSection, sectionNum);

		for (note in _song.notes[daSec - sectionNum].sectionNotes)
		{
			var strum = note[0] + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
			_song.notes[daSec].sectionNotes.push(copiedNote);
		}

		updateGrid();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSection];

		stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
			stepperSusLength.value = curSelectedNote[2];
	}

	function updateGrid():Void
	{
		while (curRenderedNotes.members.length > 0)
		{
			curRenderedNotes.remove(curRenderedNotes.members[0], true);
		}

		while (curRenderedSustains.members.length > 0)
		{
			curRenderedSustains.remove(curRenderedSustains.members[0], true);
		}

		var sectionInfo:Array<Dynamic> = _song.notes[curSection].sectionNotes;

		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		/* // PORT BULLSHIT, INCASE THERE'S NO SUSTAIN DATA FOR A NOTE
			for (sec in 0..._song.notes.length)
			{
				for (notesse in 0..._song.notes[sec].sectionNotes.length)
				{
					if (_song.notes[sec].sectionNotes[notesse][2] == null)
					{
						trace('SUS NULL');
						_song.notes[sec].sectionNotes[notesse][2] = 0;
					}
				}
			}
		 */

		for (i in sectionInfo)
		{
			var daNoteInfo = i[1];
			var daStrumTime = i[0];
			var daSus = i[2];
			var daNoteType = 0;
			var color = 0xFFFFFFFF;

			if (i.length > 2)
				daNoteType = i[3];

			var note:Note = ForeverAssets.generateArrow(PlayState.assetModifier, daStrumTime, daNoteInfo % 4, daNoteType, 0);
			note.sustainLength = daSus;
			note.noteType = daNoteType;
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.x = Math.floor(daNoteInfo * GRID_SIZE);
			note.y = Math.floor(getYfromStrum((daStrumTime - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps)));

			curRenderedNotes.add(note);

			switch (note.noteData)
			{
				case 0:
					color = 0xFF300040;
				case 1:
					color = 0xFF002D55;
				case 2:
					color = 0xFF096800;
				case 3:
					color = 0xFF610000;
			}

			//THIS GAVE ME SO MUCH CONFUSION AND YOURE TELLING ME ALL I HAD TO DO WAS USE THIS??
			note.rawNoteData = daNoteInfo;

			if (daSus > 0)
			{
				var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE / 2),
					note.y + GRID_SIZE).makeGraphic(8, Math.floor(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, gridBG.height)), color);
				curRenderedSustains.add(sustainVis);
			}
		}
	}

	private function addSection(lengthInSteps:Int = 16):Void
	{
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i.strumTime == note.strumTime && i.noteData % 4 == note.noteData)
			{
				curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];
			}

			swagNum += 1;
		}

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i[0] == note.strumTime && i[1] % 4 == note.noteData)
			{
				FlxG.log.add('FOUND EVIL NUMBER');
				_song.notes[curSection].sectionNotes.remove(i);
			}
		}

		updateGrid();
	}

	function clearSection():Void
	{
		_song.notes[curSection].sectionNotes = [];

		updateGrid();
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote():Void
	{
		var noteStrum = getStrumTime(dummyArrow.y) + sectionStartTime();
		var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
		var noteType = curNoteType; // define notes as the current type
		var noteSus = 0; // ninja you will NOT get away with this

		_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus, noteType]);

		curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

		if (FlxG.keys.pressed.CONTROL)
		{
			_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, noteType]);
		}

		//trace(noteStrum);
		//trace(curSection);

		updateGrid();
		updateNoteUI();
		
		//Open box before eating pizza.
		singPlayers(noteData, noteType);
		
		if (playClaps)
		{
			curRenderedNotes.forEach(function(note:Note)
			{
				if (check_mustHitSection.checked)
					switch (note.rawNoteData)
					{
						case 0 | 1 | 2 | 3:
							side = 'R';
						case 4 | 5 | 6 | 7:
							side = 'L';
					}
				else
					switch (note.rawNoteData)
					{
						case 0 | 1 | 2 | 3:
							side = 'L';
						case 4 | 5 | 6 | 7:
							side = 'R';
					}
				if (note.noteType == 0)
					FlxG.sound.play(Paths.sound('soundNoteTick' + side));
				//trace('hit!');
			});
		}

		autosaveSong();
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height);
	}

	/*
		function calculateSectionLengths(?sec:SwagSection):Int
		{
			var daLength:Int = 0;

			for (i in _song.notes)
			{
				var swagLength = i.lengthInSteps;

				if (i.typeOfSection == Section.COPYCAT)
					swagLength * 2;

				daLength += swagLength;

				if (sec != null && sec == i)
				{
					trace('swag loop??');
					break;
				}
			}

			return daLength;
	}*/
	private var daSpacing:Float = 0.3;

	function loadLevel():Void
	{
		trace(_song.notes);
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
		FlxG.resetState();
	}

	function loadAutosave():Void
	{
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
		FlxG.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	private function saveLevel()
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json);

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
	
	private function updateHeads():Void
	{
		if (check_mustHitSection.checked)
		{
			leftIcon.setPosition(0, -100);
			rightIcon.setPosition(gridBG.width / 2, -100);
		}
		else
		{
			leftIcon.setPosition(gridBG.width / 2, -100);
			rightIcon.setPosition(0, -100);
		}
	}
	
	override function beatHit()
	{
		if (songMusic.playing)
		{
			charactersDance(curBeat);
			
			if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.015;
			}
		}
	}
	
	private function charactersDance(curBeat:Int)
	{
		if ((bf.animation.curAnim.name.startsWith("idle") 
		|| bf.animation.curAnim.name.startsWith("dance")) 
			&& (curBeat % 2 == 0 || bf.characterData.quickDancer))
			bf.dance();

		// added this for opponent cus it wasn't here before and skater would just freeze
		if ((dad.animation.curAnim.name.startsWith("idle") 
		|| dad.animation.curAnim.name.startsWith("dance"))  
			&& (curBeat % 2 == 0 || dad.characterData.quickDancer))
			dad.dance();
	}
	
	function updatePlayers():Void
	{
		bf.setCharacter(750, 750, _song.player1);
		dad.setCharacter(50, 750, _song.player2);
		
		//spaghetti time since using UpdateIcon makes them completely dissapear
		remove(leftIcon);
		remove(rightIcon);
		
		leftIcon = new HealthIcon(_song.player1);
		rightIcon = new HealthIcon(_song.player2);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(leftIcon);
		add(rightIcon);

		updateHeads();
		
		switch(_song.player2)
		{
			case 'pico':
				dad.flipX = true;
			case 'parents-christmas':
				dadOffsetX = 250;
			case 'senpai' | 'senpai-angry':
				dad.flipX = false;
				dadOffsetX = 100;
				dadOffsetY = 450;

			case 'spirit':
				dad.flipX = false;
				dadOffsetX = 100;
				dadOffsetY = 100;
			default:
				dad.flipX = false;
				dadOffsetX = 0;
				dadOffsetY = 0;
		}

		dad.x = dad.x + dadOffsetX;
		dad.y = dad.y + dadOffsetY;

		switch (_song.player1)
		{
			case 'bf-pixel':
				bfOffsetX = 200;
				bfOffsetY = 100;
			default:
				bfOffsetX = 0;
				bfOffsetY = 0;
		}

		bf.x = bf.x + bfOffsetX;
		bf.y = bf.y + bfOffsetY;
	}
	
	private function singPlayers(daData:Int, daNoteType:Float)
	{
		if (daNoteType == 0) {
			if (check_mustHitSection.checked)
			{
				switch (daData)
				{
					case 0:
						bf.playAnim('singLEFT', true);
						bf.holdTimer = 0;
					case 1:
						bf.playAnim('singDOWN', true);
						bf.holdTimer = 0;
					case 2:
						bf.playAnim('singUP', true);
						bf.holdTimer = 0;
					case 3:
						bf.playAnim('singRIGHT', true);
						bf.holdTimer = 0;
					case 4:			
						if (_song.notes[curSection].altAnim && dad.animation.getByName('singLEFT-alt') != null) {
							dad.playAnim('singLEFT-alt', true);
							dad.holdTimer = 0;
						}
						else {
							dad.playAnim('singLEFT', true);
							dad.holdTimer = 0;
						}
					case 5:			
						if (_song.notes[curSection].altAnim && dad.animation.getByName('singDOWN-alt') != null) {
							dad.playAnim('singDOWN-alt', true);
							dad.holdTimer = 0;
						}
						else {
							dad.playAnim('singDOWN', true);
							dad.holdTimer = 0;
						}
					case 6:			
						if (_song.notes[curSection].altAnim && dad.animation.getByName('singUP-alt') != null) {
							dad.playAnim('singUP-alt', true);
							dad.holdTimer = 0;
						}
						else {
							dad.playAnim('singUP', true);
							dad.holdTimer = 0;
						}
					case 7:			
						if (_song.notes[curSection].altAnim && dad.animation.getByName('singRIGHT-alt') != null) {
							dad.playAnim('singRIGHT-alt', true);
							dad.holdTimer = 0;
						}
						else {
							dad.playAnim('singRIGHT', true);
							dad.holdTimer = 0;
						}
				}
			}
			else
			{
				switch (daData)
				{
					case 0:			
						if (_song.notes[curSection].altAnim && dad.animation.getByName('singLEFT-alt') != null) {
							dad.playAnim('singLEFT-alt', true);
							dad.holdTimer = 0;
						}
						else {
							dad.playAnim('singLEFT', true);
							dad.holdTimer = 0;
						}
					case 1:			
						if (_song.notes[curSection].altAnim && dad.animation.getByName('singDOWN-alt') != null) {
							dad.playAnim('singDOWN-alt', true);
							dad.holdTimer = 0;
						}
						else {
							dad.playAnim('singDOWN', true);
							dad.holdTimer = 0;
						}
					case 2:			
						if (_song.notes[curSection].altAnim && dad.animation.getByName('singUP-alt') != null) {
							dad.playAnim('singUP-alt', true);
							dad.holdTimer = 0;
						}
						else {
							dad.playAnim('singUP', true);
							dad.holdTimer = 0;
						}
					case 3:			
						if (_song.notes[curSection].altAnim && dad.animation.getByName('singRIGHT-alt') != null) {
							dad.playAnim('singRIGHT-alt', true);
							dad.holdTimer = 0;
						}
						else {
							dad.playAnim('singRIGHT', true);
							dad.holdTimer = 0;
						}
					case 4:
						bf.playAnim('singLEFT', true);
						bf.holdTimer = 0;
					case 5:
						bf.playAnim('singDOWN', true);
						bf.holdTimer = 0;
					case 6:
						bf.playAnim('singUP', true);
						bf.holdTimer = 0;
					case 7:
						bf.playAnim('singRIGHT', true);
						bf.holdTimer = 0;
				}
			}
		}
	}
}
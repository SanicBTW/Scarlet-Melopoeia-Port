function onCreate()
	setPropertyFromClass('GameOverSubstate', 'characterName', 'RBF');
	setPropertyFromClass('GameOverSubstate', 'deathSoundName', 'fnf_loss_touhou');
	makeAnimatedLuaSprite('REIMUorb', 'characters/REIMUorb_Assets', 100, 550); -- Change to characters idle in XML
	addAnimationByPrefix('REIMUorb', 'idle', 'REIMUorb', 24, false); -- Change to characters idle in XML
    addAnimationByPrefix('REIMUorb', '0', 'PURPLE_REIMUorb', 24, false); -- Change to characters leftnote in XML
    addAnimationByPrefix('REIMUorb', '1', 'BLUE_REIMUorb', 24, false); -- Change to characters downnote in XML
    addAnimationByPrefix('REIMUorb', '2', 'GREEN_REIMUorb', 24, false); -- Change to characters upnote in XML
    addAnimationByPrefix('REIMUorb', '3', 'RED_REIMUorb', 24, false); -- Change to characters rightnote in XML
	objectPlayAnimation('REIMUorb', 'idle'); 
	addLuaSprite('REIMUorb', true); -- false = add behind characters, true = add over characters
end
function onBeatHit()
	-- triggered 4 times per section
	if curBeat % 2 == 0 then
		objectPlayAnimation('REIMUorb', 'idle');
	end
end

lastNote = {0, ""}

function goodNoteHit(id,d,t,s)

    lastNote[1] = d
    lastNote[2] = t
    
    if lastNote[2] == "REIMU-Bullet Note" then -- Change "No Animation" to be your note type, usually you can just keep it as no anim assuming you arent using it elsewhere
	objectPlayAnimation('REIMUorb', lastNote[1]);
    end
end
function onCreate()
	setPropertyFromClass('GameOverSubstate', 'characterName', 'coupleGM');
	setPropertyFromClass('GameOverSubstate', 'deathSoundName', 'fnf_loss_subway');
	setPropertyFromClass('GameOverSubstate', 'loopSoundName', 'subwayLoop'); 
	setPropertyFromClass('GameOverSubstate', 'endSoundName', 'subwayEnd'); 
	
	setProperty('camHUD.alpha', 0)
	setProperty('iconP1.alpha', 0)
	setProperty('iconP2.alpha', 0)
	setProperty('gf.alpha', 0)
	setProperty('subway.alpha', 0)
	setProperty('tunnelLight.alpha', 0)
	cameraShake(game, 0.00075, 115.99)
	
end

function onEvent(name,value1,value2)
	if name == 'Play Animation' then
		if value1 == 'HUDappear' then
			doTweenAlpha('HUDappear', 'camHUD', 1, 1.5, 'linear')
			for i = 0,3 do
				setPropertyFromGroup('strumLineNotes', i, 'alpha', 0)
			end
			for i = 4,7 do
				setPropertyFromGroup('strumLineNotes', i, 'x', i*200-515)
			end
		end
		if value1 == 'COUPLEappear' then
			doTweenAlpha('COUPLEappear', 'gf', 1, 3, 'linear')
		end
		if value1 == 'BGappear' then
			doTweenAlpha('BGappear', 'subway', 1, 3, 'linear')
		end
		if value1 == 'LIGHTappear' then
			doTweenAlpha('LIGHTappear', 'tunnelLight', 1, 3, 'linear')
		end
	end
end
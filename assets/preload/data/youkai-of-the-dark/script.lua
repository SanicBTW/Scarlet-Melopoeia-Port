function onCreate()
	setPropertyFromClass('GameOverSubstate', 'characterName', 'REIMUnight-player');
	setPropertyFromClass('GameOverSubstate', 'deathSoundName', 'fnf_loss_touhou');
	
	makeAnimatedLuaSprite('rumia_fog', 'entrance/rumia_fog', -500, -1500);
	addAnimationByPrefix('rumia_fog', 'fog', 'rumia_fog', 24, true);
	setScrollFactor('rumia_fog', 0.05, 0);
	scaleObject('rumia_fog', 1.5, 1.5);
	
	addLuaSprite('rumia_fog', true);
	
	setProperty('rumia_fog.visible', false);
	
	makeAnimatedLuaSprite('sign', 'entrance/spell-cards-rumia', 420, 100);
	addAnimationByPrefix('sign', 'demarcation', 'spell', 24, false);
	setProperty('sign.alpha', 0);
	setScrollFactor('sign', 0, 0);
	
	makeAnimatedLuaSprite('laser', 'entrance/RUMIA-laser', 700, 700);
	addAnimationByPrefix('laser', 'idle', 'RUMIA-laserIdle', 24, false);
	addAnimationByPrefix('laser', 'fire', 'RUMIA-laserFire', 24, false);
	setProperty('laser.alpha', 0);
	
	addLuaSprite('sign', true);
	addLuaSprite('laser', true);
	
	precacheSound('laserCharge');
	precacheSound('laserFire');
end

function onEvent(name,value1,value2)
	if name == 'Play Animation' then
		if value1 == 'entrance_normal' then
			setProperty('rumia_fog.visible', false);
			doTweenAlpha('entrance_normal', 'sign', 0, 1.5, 'linear');
			doTweenAlpha('entrance_normal', 'laser', 0, 1, 'linear');
		end
		if value1 == 'entrance_fog' then
			setProperty('rumia_fog.visible', true);
			doTweenAlpha('entrance_fog', 'sign', 1, 1.5, 'linear');
		end
		
		if value1 == 'entrance_laser' then
			doTweenAlpha('entrance_laser', 'laser', 1, 1, 'linear');
			playSound('laserCharge', 0.25);
		end
		if value1 == 'entrance_firelaser' then
			objectPlayAnimation('laser', 'fire');
			playSound('laserFire', 0.1);
		end
	end
end

function onBeatHit()
	-- triggered 4 times per section
	if curBeat % 2 == 0 then
		objectPlayAnimation('sign', 'demarcation');
	end
end
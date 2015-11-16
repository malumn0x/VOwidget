require "base/internal/ui/reflexcore"

VoiceOver =
{
    countPlayed = {false, false, false};
    oldLogId = 0;
    delayTimer = 0;

    canPosition = false;
    userData = {};
};
registerWidget("VoiceOver");

function VoiceOver:initialize()
    self.userData = loadUserData()

    CheckSetDefaultValue(self, "userData", "table", {});
    CheckSetDefaultValue(self.userData, "volume", "number", 3);
    CheckSetDefaultValue(self.userData, "delay", "number", 1.5);
    CheckSetDefaultValue(self.userData, "voice", "string", "female");
    CheckSetDefaultValue(self.userData, "voiceSelect", "table", {true, false, false});
    CheckSetDefaultValue(self.userData, "playCountVoice", "boolean", true);
    CheckSetDefaultValue(self.userData, "playCTFVoice", "boolean", true);
end

function VoiceOver:countVoiceEvent()
    local timeRemaining = world.gameTimeLimit - world.gameTime
    local t = FormatTime(timeRemaining)

    -- this flicks to 0 some times, just clamp it to 1
    t.seconds = math.max(1, t.seconds)

    if (t.seconds > 3) then
      self.countPlayed = {false, false, false}
    else
      if self.countPlayed[t.seconds] == false then
        for i = 1, self.userData.volume do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/count-" .. t.seconds) end
        self.countPlayed[t.seconds] = true
      end
    end
end

function VoiceOver:ctfVoiceEvent(player)
    local logCount = 0
    for k, v in pairs(log) do
      logCount = logCount + 1
    end

    for i = 1, logCount do
      local logEntry = log[i]

      if (logEntry.type == LOG_TYPE_CTFEVENT) and (self.oldLogId < logEntry.id) and (self.userData.delay <= self.delayTimer) then
        if logEntry.ctfEvent == CTF_EVENT_CAPTURE then
          if logEntry.ctfTeamIndex == player.team then
            for i = 1, self.userData.volume do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/team-capture") end
          else
            for i = 1, self.userData.volume do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/enemy-capture") end
          end
        end

        if logEntry.ctfEvent == CTF_EVENT_RETURN then
          if logEntry.ctfTeamIndex == player.team then
            for i = 1, self.userData.volume do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/team-return") end
          else
            for i = 1, self.userData.volume do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/enemy-return") end
          end
        end

        if logEntry.ctfEvent == CTF_EVENT_PICKUP then
          if logEntry.ctfTeamIndex == player.team then
              if player.hasFlag then
                  for i = 1, self.userData.volume do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/player-hasflag") end
              else
                  for i = 1, self.userData.volume do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/team-hasflag") end
              end
          else
            for i = 1, self.userData.volume do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/enemy-hasflag") end
          end
        end

        if not (logEntry.ctfEvent == CTF_EVENT_DROPPED) then -- don't let drops cause voice delay
          self.oldLogId = logEntry.id
          self.delayTimer = 0
        end
      end
    end

    self.delayTimer = self.delayTimer + deltaTimeRaw
    if self.delayTimer > 60 then self.delayTimer = self.userData.delay end
end

function VoiceOver:draw()
    local player = getPlayer()
    if not player then return end

    local gameMode = gamemodes[world.gameModeIndex].shortName

    if self.userData.playCountVoice and world.timerActive and (world.gameState == GAME_STATE_WARMUP or world.gameState == GAME_STATE_ROUNDPREPARE) then
      self:countVoiceEvent()
    end

    if self.userData.playCTFVoice and gameMode == "ctf" then
      self:ctfVoiceEvent(player)
    end
end

function VoiceOver:drawOptions(x, y)
    local sliderWidth = 200
    local sliderStart = 140

    local user = self.userData

    uiLabel("Volume", x, y)
    user.volume = round(uiSlider(x + sliderStart, y, sliderWidth, 1, 10, user.volume))
    round(uiEditBox(user.volume, x + sliderStart + sliderWidth + 10, y, 60))
    y = y + 40

    uiLabel("Delay", x, y)
    user.delay = clampTo2Decimal(uiSlider(x + sliderStart, y, sliderWidth, 0, 3, user.delay))
    user.delay = clampTo2Decimal(uiEditBox(user.delay, x + sliderStart + sliderWidth + 10, y, 60))
    y = y + 50

    uiLabel("Voice:", x + 10, y)
    y = y + 35

    if uiCheckBox(user.voiceSelect[1], "Female", x, y) then
      user.voiceSelect[1] = true
      user.voiceSelect[2] = false
      user.voiceSelect[3] = false
      user.voice = "female"
    end
    y = y + 35

    if uiCheckBox(user.voiceSelect[2], "Android", x, y) then
      user.voiceSelect[1] = false
      user.voiceSelect[2] = true
      user.voiceSelect[3] = false
      user.voice = "android"
    end
    y = y + 35

    if uiCheckBox(user.voiceSelect[3], "Other:", x, y) then
      user.voiceSelect[1] = false
      user.voiceSelect[2] = false
      user.voiceSelect[3] = true
    end
    y = y + 35
    user.voice = uiEditBox(user.voice, x + 100, y, 80)
    y = y + 50

    uiLabel("Voice Events:", x + 10, y)
    y = y + 35
    user.playCountVoice = uiCheckBox(user.playCountVoice, "Countdown", x, y)
    y = y + 35
    user.playCTFVoice = uiCheckBox(user.playCTFVoice , "CTF", x, y)

    saveUserData(user)
end

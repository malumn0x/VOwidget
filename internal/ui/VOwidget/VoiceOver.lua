require "base/internal/ui/reflexcore"

VoiceOver =
{
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
    CheckSetDefaultValue(self.userData, "voiceselect", "table", {false, true, false});
end

local oldLogId = 0
local delayTimer = 0

function VoiceOver:ctfVoiceEvent(player)
    local logCount = 0
    for k, v in pairs(log) do
      logCount = logCount + 1
    end

    for i = 1, logCount do
      local logEntry = log[i]

      if logEntry.type == LOG_TYPE_CTFEVENT then
        if logEntry.ctfEvent == CTF_EVENT_CAPTURE then
          if (oldLogId < logEntry.id) and (self.userData.delay <= delayTimer) then
            if logEntry.ctfTeamIndex == player.team then
              for i = 1, self.userData.volume, 1 do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/team-capture") end
            else
              for i = 1, self.userData.volume, 1 do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/enemy-capture") end
            end

            oldLogId = logEntry.id
            delayTimer = 0
          end
        end

        if logEntry.ctfEvent == CTF_EVENT_RETURN then
          if (oldLogId < logEntry.id) and (self.userData.delay <= delayTimer) then
            if logEntry.ctfTeamIndex == player.team then
              for i = 1, self.userData.volume, 1 do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/team-return") end
            else
              for i = 1, self.userData.volume, 1 do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/enemy-return") end
            end

            oldLogId = logEntry.id
            delayTimer = 0
          end
        end

        if logEntry.ctfEvent == CTF_EVENT_PICKUP then
          if (oldLogId < logEntry.id) and (self.userData.delay <= delayTimer) then
            if logEntry.ctfTeamIndex == player.team then
              for i = 1, self.userData.volume, 1 do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/team-hasflag")end
            else
              for i = 1, self.userData.volume, 1 do playSound("internal/ui/VOwidget/vox/" .. self.userData.voice .. "/enemy-hasflag") end
            end

            oldLogId = logEntry.id
            delayTimer = 0
          end
        end
      end
    end

    delayTimer = delayTimer + deltaTimeRaw
    if delayTimer > 60 then delayTimer = self.userData.delay end
end

function VoiceOver:draw()
    local player = getPlayer()
    local gameMode = gamemodes[world.gameModeIndex].shortName

    if gameMode == "ctf" then
      self:ctfVoiceEvent(player)
    end
end

function VoiceOver:drawOptions(x, y)
    local sliderWidth = 200
    local sliderStart = 140

    local user = self.userData

    uiLabel("Volume", x, y);
    user.volume = round(uiSlider(x + sliderStart, y, sliderWidth, 1, 10, user.volume))
    round(uiEditBox(user.volume, x + sliderStart + sliderWidth + 10, y, 60))
    y = y + 40;

    uiLabel("Delay", x, y);
    user.delay = clampTo2Decimal(uiSlider(x + sliderStart, y, sliderWidth, 0, 3, user.delay))
    user.delay = clampTo2Decimal(uiEditBox(user.delay, x + sliderStart + sliderWidth + 10, y, 60))
    y = y + 40;

    uiLabel("Voice:", x + 10, y);
    y = y + 35;

    if uiCheckBox(user.voiceselect[1], "Male", x, y) then
      user.voiceselect[1] = true
      user.voiceselect[2] = false
      user.voiceselect[3] = false
      user.voice = "male"
    end
    y = y + 35;

    if uiCheckBox(user.voiceselect[2], "Female", x, y) then
      user.voiceselect[1] = false
      user.voiceselect[2] = true
      user.voiceselect[3] = false
      user.voice = "female"
    end
    y = y + 35;

    if uiCheckBox(user.voiceselect[3], "Android", x, y) then
      user.voiceselect[1] = false
      user.voiceselect[2] = false
      user.voiceselect[3] = true
      user.voice = "android"
    end

    saveUserData(user)
end

require "base/internal/ui/reflexcore"

VoiceOver =
{
    countPlayed = {false, false, false};
    fightPlayed = false;
    tWarnPlayed = {false, false};
    oTimePlayed = {false};
    endPlayed = false;
    leadTied = true;
    oldLogId = 0;
    delayTimer = 0;

    canPosition = false;
    userData = {};
};
registerWidget("VoiceOver");

function VoiceOver:initialize()
    self.userData = loadUserData();

    CheckSetDefaultValue(self, "userData", "table", {});
    CheckSetDefaultValue(self.userData, "volume", "number", 3);
    CheckSetDefaultValue(self.userData, "delay", "number", 1.5);
    CheckSetDefaultValue(self.userData, "voxDir", "string", "internal/ui/VOwidget");
    CheckSetDefaultValue(self.userData, "voice", "string", "female");
    CheckSetDefaultValue(self.userData, "voiceSelect", "table", {true, false, false});
    CheckSetDefaultValue(self.userData, "playCountVoice", "boolean", true);
    CheckSetDefaultValue(self.userData, "playFightVoice", "boolean", true);
    CheckSetDefaultValue(self.userData, "playTWarnVoice", "boolean", true);
    CheckSetDefaultValue(self.userData, "playoTimeVoice", "boolean", true);
    CheckSetDefaultValue(self.userData, "playEndVoice", "boolean", true);
    CheckSetDefaultValue(self.userData, "playLeadVoice", "boolean", true);
    CheckSetDefaultValue(self.userData, "playCTFVoice", "boolean", true);
end

function VoiceOver:getOtherTeam(team)
    local other

    if team == 1 then other = 2
    else other = 1 end

    return other
end

function VoiceOver:getOtherScore(player)
    local connectedPlayerCount = 0
    local connectedPlayers = {}

    local scoreList = {}
    local otherScore = 0
    local otherExists = false -- in case we are alone (e.g. everyone else is spec), prevent null compare error

    for k, v in pairs(players) do
      if v.connected then
        connectedPlayerCount = connectedPlayerCount + 1;
        connectedPlayers[connectedPlayerCount] = v;
      end
    end

    for index = 1, connectedPlayerCount do
      local conPlayer = connectedPlayers[index]

      if conPlayer ~= player and conPlayer.state == PLAYER_STATE_INGAME then
        table.insert(scoreList, conPlayer.score)
        otherExists = true
      end
    end

    -- always return the highest opponent score
    -- useful (e.g.) for chasing the ffa leader
    table.sort(scoreList, function(a,b) return a>b end)
    if otherExists then otherScore = scoreList[1] end
    return otherScore
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
        for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/count-" .. t.seconds) end
        self.countPlayed[t.seconds] = true
      end
    end
end

function VoiceOver:fightVoiceEvent()
    if self.fightPlayed == false then
      if isRaceMode() then
        for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/count-run") end
      else
        for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/count-fight") end
      end

      self.fightPlayed = true
    end
end

function VoiceOver:tWarnVoiceEvent()
    local timeRemaining = world.gameTimeLimit - world.gameTime

    local warnFive = 300000
    local warnOne = 60000

    if timeRemaining < 0 then
      timeRemaining = 0
    end

    if (self.tWarnPlayed[1] == false) and (timeRemaining < warnFive) and (self.userData.delay <= self.delayTimer) then
      for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/warn-5") end
      self.tWarnPlayed[1] = true
      self.delayTimer = 0
    end

    if (self.tWarnPlayed[2] == false) and (timeRemaining < warnOne) and (self.userData.delay <= self.delayTimer) then
      for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/warn-1") end
      self.tWarnPlayed[2] = true
      self.delayTimer = 0
    end
end

function VoiceOver:oTimeVoiceEvent(otCount)
    if table.getn(self.oTimePlayed) < otCount then
      table.insert(self.oTimePlayed, false)
    end

    if self.oTimePlayed[otCount] == false and (self.userData.delay <= self.delayTimer) then
      for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/overtime") end
      self.oTimePlayed[otCount] = true
      self.delayTimer = 0
    end
end

function VoiceOver:endVoiceEvent(player, gameMode)
    local playerScore = 0
    local enemyScore = 0

    if self.endPlayed == false and (self.userData.delay <= self.delayTimer) then
      if gameMode.hasTeams then
        playerScore = world.teams[player.team].score
        enemyScore = world.teams[self:getOtherTeam(player.team)].score

        if playerScore > enemyScore then
          for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/end-teamwin") end
        else
          for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/end-teamlose") end
        end
      else
        playerScore = player.score
        enemyScore = self:getOtherScore(player)

        if isRaceMode() then
          if playerScore == 0 then playerScore = 1000000000 end -- did not finish
          if enemyScore == 0 then enemyScore = 1000000000 end  -- no one else finished

          if playerScore < enemyScore then -- lower score is better in racemode
            for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/end-win") end
          else
            for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/end-lose") end
          end
        else
          if playerScore > enemyScore then
            for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/end-win") end
          else
            for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/end-lose") end
          end
        end
      end

      self.endPlayed = true
      self.delayTimer = 0
    end
end

function VoiceOver:leadVoiceEvent(player, logEntry)
    local playerScore = player.score
    local enemyScore = self:getOtherScore(player)

    if (logEntry.type == LOG_TYPE_DEATHMESSAGE) and (self.oldLogId < logEntry.id) and (self.userData.delay <= self.delayTimer) then
      if not self.leadTied and (playerScore == enemyScore) then
        for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/lead-tied") end
        self.leadTied = true
        self.delayTimer = 0
      elseif self.leadTied and (playerScore > enemyScore) then
        for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/lead-taken") end
        self.leadTied = false
        self.delayTimer = 0
      elseif self.leadTied and (playerScore < enemyScore) then
        for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/lead-lost") end
        self.leadTied = false
        self.delayTimer = 0
      end

      self.oldLogId = logEntry.id
    end
end

function VoiceOver:ctfVoiceEvent(player, logEntry)
    if (logEntry.type == LOG_TYPE_CTFEVENT) and (self.oldLogId < logEntry.id) and (self.userData.delay <= self.delayTimer) then
      if logEntry.ctfEvent == CTF_EVENT_CAPTURE then
        if logEntry.ctfTeamIndex == player.team then
          for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/team-capture") end
        else
          for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/enemy-capture") end
        end
      end

      if logEntry.ctfEvent == CTF_EVENT_RETURN then
        if logEntry.ctfTeamIndex == player.team then
          for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/team-return") end
        else
          for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/enemy-return") end
        end
      end

      if logEntry.ctfEvent == CTF_EVENT_PICKUP then
        if logEntry.ctfTeamIndex == player.team then
          if player.hasFlag then
            for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/player-hasflag") end
          else
            for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/team-hasflag") end
          end
        else
          for i = 1, self.userData.volume do playSound(self.userData.voxDir .. "/vox/" .. self.userData.voice .. "/enemy-hasflag") end
        end
      end

      if not (logEntry.ctfEvent == CTF_EVENT_DROPPED) then -- don't let drops cause voice delay
        self.oldLogId = logEntry.id
        self.delayTimer = 0
      end
    end
end

function VoiceOver:draw()
    local player = getPlayer()
    if not player then return end
    local localPlayer = getLocalPlayer()
    if localPlayer == nil then return end

    local gameMode = gamemodes[world.gameModeIndex]
    local gameModeName = gameMode.shortName

    local logCount = 0
    for k, v in pairs(log) do
      logCount = logCount + 1
    end

    if world.gameState == GAME_STATE_WARMUP then
      -- in case there is a match restart
      self.fightPlayed = false
      self.tWarnPlayed = {false, false}
      self.oTimePlayed = {false}
      self.endPlayed = false
      self.leadTied = true
    end

    if self.userData.playCountVoice and world.timerActive and (world.gameState == GAME_STATE_WARMUP or world.gameState == GAME_STATE_ROUNDPREPARE) then
      self:countVoiceEvent()
    end

    if self.userData.playFightVoice and world.timerActive and (world.gameState == GAME_STATE_ACTIVE or world.gameState == GAME_STATE_ROUNDACTIVE) then
      self:fightVoiceEvent()
    end

    if self.userData.playTWarnVoice and world.gameState == GAME_STATE_ACTIVE then
      VoiceOver:tWarnVoiceEvent()
    end

    if self.userData.playoTimeVoice and world.gameState == GAME_STATE_ACTIVE and world.overTimeCount > 0 then
      VoiceOver:oTimeVoiceEvent(world.overTimeCount)
    end

    if self.userData.playEndVoice and world.gameState == GAME_STATE_GAMEOVER then
      self:endVoiceEvent(player, gameMode)
    end

    for i = 1, logCount do
      local logEntry = log[i]

      if self.userData.playLeadVoice and world.gameState == GAME_STATE_ACTIVE and (gameModeName == "1v1" or gameModeName == "ffa") then
        -- spec view causes problems
        if localPlayer.state ~= PLAYER_STATE_SPECTATOR then
          self:leadVoiceEvent(player, logEntry)
        end
      end

      if self.userData.playCTFVoice and gameModeName == "ctf" then
        self:ctfVoiceEvent(player, logEntry)
      end
    end

    self.delayTimer = self.delayTimer + deltaTimeRaw
    if self.delayTimer > self.userData.delay then self.delayTimer = self.userData.delay end
end

function VoiceOver:drawOptions(x, y)
    local sliderWidth = 200
    local sliderStart = 100

    local user = self.userData


    uiLabel("Volume", x, y)
    user.volume = round(uiSlider(x + sliderStart, y, sliderWidth, 1, 10, user.volume))
    round(uiEditBox(user.volume, x + sliderStart + sliderWidth + 10, y, 60))
    y = y + 40

    uiLabel("Delay", x, y)
    user.delay = clampTo2Decimal(uiSlider(x + sliderStart, y, sliderWidth, 0, 3, user.delay))
    user.delay = clampTo2Decimal(uiEditBox(user.delay, x + sliderStart + sliderWidth + 10, y, 60))
    y = y + 40

    uiLabel("Directory", x, y)
    user.voxDir = uiEditBox(user.voxDir, x + sliderStart, y, 270)
    y = y + 50

    uiLabel("Voice:", x + 10, y)
    y = y + 35

    if uiCheckBox(user.voiceSelect[1], "Female", x, y) then
      user.voiceSelect[1] = true
      user.voiceSelect[2] = false
      user.voiceSelect[3] = false
      user.voice = "female"
    end
    y = y + 40

    if uiCheckBox(user.voiceSelect[2], "Android", x, y) then
      user.voiceSelect[1] = false
      user.voiceSelect[2] = true
      user.voiceSelect[3] = false
      user.voice = "android"
    end
    y = y + 40

    if uiCheckBox(user.voiceSelect[3], "Other:", x, y) then
      user.voiceSelect[1] = false
      user.voiceSelect[2] = false
      user.voiceSelect[3] = true
    end
    user.voice = uiEditBox(user.voice, x + sliderStart, y, 100)
    y = y + 50


    uiLabel("Voice Events:", x + 10, y)
    y = y + 35
    user.playCountVoice = uiCheckBox(user.playCountVoice, "Countdown", x, y)
    y = y + 40

    nvgBeginPath()
    nvgStrokeColor(Color(160, 160, 160, 255))
    nvgStrokeWidth(2)
    nvgMoveTo(x + 10, y + 2)
    nvgLineTo(x + 10, y + 18)
    nvgLineTo(x + 45, y + 18)
    nvgStroke()

    user.playFightVoice = uiCheckBox(user.playFightVoice, "Fight / Run", x + 55, y)
    y = y + 40
    user.playTWarnVoice = uiCheckBox(user.playTWarnVoice, "Time Warning", x, y)
    y = y + 40

    nvgBeginPath()
    nvgStrokeColor(Color(160, 160, 160, 255))
    nvgStrokeWidth(2)
    nvgMoveTo(x + 10, y + 2)
    nvgLineTo(x + 10, y + 18)
    nvgLineTo(x + 45, y + 18)
    nvgStroke()

    user.playoTimeVoice = uiCheckBox(user.playoTimeVoice, "Overtime", x + 55, y)
    y = y + 40
    user.playEndVoice = uiCheckBox(user.playEndVoice, "End Game", x, y)
    y = y + 40
    user.playLeadVoice = uiCheckBox(user.playLeadVoice, "FFA / 1v1 Lead", x, y)
    y = y + 40
    user.playCTFVoice = uiCheckBox(user.playCTFVoice , "CTF", x, y)


    saveUserData(user)
end

local initalized = false
RegularBlessingOption = false;
BINDING_HEADER_PALLYPOWER_HEADER = "Pally Power";
BINDING_NAME_TOGGLE = "Toggle Buff Bar";
BINDING_NAME_REPORT = "Report Assignments";

AllPallys = {};

PallyPower_Assignments = {};

PallyPower = {};

BlessingIcon = {};
BuffIcon = {};
PP_PerUser = {
    scalemain = 1, -- corner of main window docked to
    scalebar = 1, -- corner menu window is docked from
    scanfreq = 10,
    scanperframe = 1,
    smartbuffs = 1,
    announcechannel = "S",
}
PP_NextScan = PP_PerUser.scanfreq

function PallyPower_RegularBlessings()
    if (RegularBlessingChk:GetChecked() == 1) then
      RegularBlessingOption = true;
      PallyPower_OnEvent("SPELLS_CHANGED")
    else
      RegularBlessingOption = false;
      PallyPower_OnEvent("SPELLS_CHANGED")
    end
end

PallyPower_ClassTexture = {};
PallyPower_ClassTexture[0] = "Interface\\AddOns\\PallyPower\\Icons\\Warrior";
PallyPower_ClassTexture[1] = "Interface\\AddOns\\PallyPower\\Icons\\Rogue";
PallyPower_ClassTexture[2] = "Interface\\AddOns\\PallyPower\\Icons\\Priest";
PallyPower_ClassTexture[3] = "Interface\\AddOns\\PallyPower\\Icons\\Druid";
PallyPower_ClassTexture[4] = "Interface\\AddOns\\PallyPower\\Icons\\Paladin";
PallyPower_ClassTexture[5] = "Interface\\AddOns\\PallyPower\\Icons\\Hunter";
PallyPower_ClassTexture[6] = "Interface\\AddOns\\PallyPower\\Icons\\Mage";
PallyPower_ClassTexture[7] = "Interface\\AddOns\\PallyPower\\Icons\\Warlock";
PallyPower_ClassTexture[8] = "Interface\\AddOns\\PallyPower\\Icons\\Shaman";
PallyPower_ClassTexture[9] = "Interface\\AddOns\\PallyPower\\Icons\\Pet";
PallyPower_ClassTexture[10] = "Interface\\Icons\\Spell_Holy_RighteousFury";

-- Judgement assignment support.  This deliberately remains separate from
-- the blessing/buff bar logic: class ID 10 is a special assignment column.
PallyPower_JudgementID = {};
PallyPower_JudgementID[0] = "Crusader";
PallyPower_JudgementID[1] = "Wisdom";
PallyPower_JudgementID[2] = "Light";

PallyPower_JudgementIcon = {};
PallyPower_JudgementIcon[0] = "Interface\\Icons\\Spell_Holy_HolySmite";
PallyPower_JudgementIcon[1] = "Interface\\Icons\\Spell_Holy_RighteousnessAura";
PallyPower_JudgementIcon[2] = "Interface\\Icons\\Spell_Holy_HealingAura";

-- SealIcon = {};
-- SealIcon[0] = "Interface\\Icons\\ability_thunderbolt";
-- SealIcon[1] = "Interface\\Icons\\spell_holy_righteousnessaura";
-- SealIcon[2] = "Interface\\Icons\\spell_holy_healingaura";
-- SealIcon[3] = "Interface\\Icons\\spell_holy_sealofwrath";
-- SealIcon[4] = "Interface\\Icons\\spell_holy_holysmite";

LastCast = {};
LastCastOn = {};
PP_Symbols = 0
IsPally = 0;

Assignment = {};

CurrentBuffs = {};

PP_PREFIX = "PLPWR";

-- Assignment announcement controls. The compact button near the close button
-- cycles between Say, Yell, Party, Raid, and (when permitted) Raid Warning.
PallyPower_AnnounceChatType = {};
PallyPower_AnnounceChatType["S"] = "SAY";
PallyPower_AnnounceChatType["Y"] = "YELL";
PallyPower_AnnounceChatType["P"] = "PARTY";
PallyPower_AnnounceChatType["R"] = "RAID";
PallyPower_AnnounceChatType["RW"] = "RAID_WARNING";

PallyPower_AnnounceChatName = {};
PallyPower_AnnounceChatName["S"] = "Say";
PallyPower_AnnounceChatName["Y"] = "Yell";
PallyPower_AnnounceChatName["P"] = "Party";
PallyPower_AnnounceChatName["R"] = "Raid";
PallyPower_AnnounceChatName["RW"] = "Raid Warning";

PallyPower_AnnounceQueue = {};
PallyPower_AnnounceQueueDelay = 0;
PallyPower_AnnouncePendingLines = nil;
PallyPower_AnnouncePendingChatType = nil;
PallyPower_AnnouncePendingChatName = nil;

StaticPopupDialogs["PALLYPOWER_ANNOUNCE_CONFIRM"] = {
    text = "Send %s PallyPower assignment messages to %s?\n\nThis may spam chat. Are you sure?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        PallyPower_ConfirmAssignmentAnnouncement()
    end,
    OnCancel = function()
        PallyPower_ClearPendingAnnouncement()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
};

local RestorSelfAutoCastTimeOut = 1;
local RestorSelfAutoCast = false;

local function PP_Debug(string)
    if not string then
        string = "(nil)"
    end
    if (PP_DebugEnabled) then
        DEFAULT_CHAT_FRAME:AddMessage("[PP] " .. string, 1, 0, 0);
    end
end

function PallyPower_OnLoad()
    this:RegisterEvent("SPELLS_CHANGED");
    this:RegisterEvent("PLAYER_ENTERING_WORLD");
    this:RegisterEvent("CHAT_MSG_ADDON");
    this:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH");
    this:RegisterEvent("PLAYER_LOGIN");
    this:RegisterEvent("PARTY_MEMBERS_CHANGED");
    this:SetBackdropColor(0.0, 0.0, 0.0, 0.5);
    this:SetScale(1);
    SlashCmdList["PALLYPOWER"] = function(msg)
        PallyPower_SlashCommandHandler(msg)
    end
end

function PallyPower_OnUpdate(tdiff)
    if PallyPower_AnnounceQueue and table.getn(PallyPower_AnnounceQueue) > 0 then
        PallyPower_AnnounceQueueDelay = PallyPower_AnnounceQueueDelay - tdiff
        if PallyPower_AnnounceQueueDelay <= 0 then
            local announce = PallyPower_AnnounceQueue[1]
            tremove(PallyPower_AnnounceQueue, 1)
            if announce and announce["text"] and announce["chat"] then
                SendChatMessage(announce["text"], announce["chat"])
            end
            -- Pace multi-line announcements to avoid dumping the full assignment
            -- list into chat in a single frame on legacy/private servers.
            PallyPower_AnnounceQueueDelay = 0.8
        end
    end

    if (RestorSelfAutoCast) then
		RestorSelfAutoCastTimeOut = RestorSelfAutoCastTimeOut - tdiff;
		if (RestorSelfAutoCastTimeOut < 0) then
			RestorSelfAutoCast = false;
			SetCVar("autoSelfCast", "1");
		end
	end
    
    if (not PP_PerUser.scanfreq) then
        PP_PerUser.scanfreq = 10;
        PP_PerUser.scanperframe = 1;
    end
    PP_NextScan = PP_NextScan - tdiff
    if PP_NextScan < 0 and PP_IsPally then
        PP_Debug("PallyPower_OnUpdate Scanning");
        PallyPower_ScanRaid()
        PallyPower_UpdateUI()
    end
    for i, k in LastCast do
        LastCast[i] = k - tdiff
    end
end

function PallyPower_OnEvent(event)
    local type, id;
    if (event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD") then
        --PallyPower_ScanSpells()
      if (RegularBlessingOption == true) then
        RegularBlessings = true
        BlessingIcon[0] = "Interface\\Icons\\Spell_Holy_SealOfWisdom";
        BlessingIcon[1] = "Interface\\Icons\\Spell_Holy_FistOfJustice";
        BlessingIcon[2] = "Interface\\Icons\\Spell_Holy_SealOfSalvation";
        BlessingIcon[3] = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02";
        BlessingIcon[4] = "Interface\\Icons\\Spell_Magic_MageArmor";
        BlessingIcon[5] = "Interface\\Icons\\Spell_Nature_LightningShield";
        BuffIcon[0] = "Interface\\Icons\\Spell_Holy_SealOfWisdom";
        BuffIcon[1] = "Interface\\Icons\\Spell_Holy_FistOfJustice";
        BuffIcon[2] = "Interface\\Icons\\Spell_Holy_SealOfSalvation";
        BuffIcon[3] = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02";
        BuffIcon[4] = "Interface\\Icons\\Spell_Magic_MageArmor";
        BuffIcon[5] = "Interface\\Icons\\Spell_Nature_LightningShield";
      else
        RegularBlessings = false
        BlessingIcon[0] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom";
        BlessingIcon[1] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings";
        BlessingIcon[2] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation";
        BlessingIcon[3] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight";
        BlessingIcon[4] = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings";
        BlessingIcon[5] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary";
        BuffIcon[0] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom"
        BuffIcon[1] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings"
        BuffIcon[2] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation"
        BuffIcon[3] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight"
        BuffIcon[4] = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings"
        BuffIcon[5] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary"
      end
    end

    if (event == "PLAYER_ENTERING_WORLD" and (not PallyPower_Assignments[UnitName("player")])) then
        PallyPower_Assignments[UnitName("player")] = {};
        if UnitName("player") == "Thaegan" then
            PP_DebugEnabled = true
        end
    end

    if event == "CHAT_MSG_ADDON" and arg1 == PP_PREFIX and (arg3 == "PARTY" or arg3 == "RAID") then
        PallyPower_ParseMessage(arg4, arg2)
    end

    if event == "CHAT_MSG_COMBAT_FRIENDLY_DEATH" and PP_NextScan > 1 then
        PP_NextScan = 1
    end

    if event == "PLAYER_LOGIN" then
        PallyPower_UpdateUI()
    end

    if event == "PARTY_MEMBERS_CHANGED" then
        PallyPower_ScanRaid()
        PallyPower_UpdateUI()
    end
end

function PallyPower_SlashCommandHandler(msg)
    if (msg == "debug") then
        if PP_DebugEnabled then
            PP_DebugEnabled = nil
        else
            PP_DebugEnabled = true
        end
    end
    if PallyPowerFrame:IsVisible() then
        PallyPowerFrame:Hide()
    else
        PallyPowerFrame:Show()
    end
    PallyPower_UpdateUI()
end

function PallyPower_FormatTime(time)
    if not time or time < 0 then
        return "";
    end
    mins = floor(time / 60)
    secs = time - (mins * 60)
    return string.format("%d:%02d", mins, secs);
end

function PallyPowerGrid_Update()
    -- Pally 1 is always player
    local i = 1;
    local numPallys = 0
    local name, blessings
    if PallyPowerFrame:IsVisible() then
        PallyPowerFrame:SetScale(PP_PerUser.scalemain);
        PallyPower_UpdateAnnounceButton()
        for name, blessings in AllPallys do
            getglobal("PallyPowerFramePlayer" .. i .. "Name"):SetText(name)
            getglobal("PallyPowerFramePlayer" .. i .. "Symbols"):SetText(blessings["symbols"])
            getglobal("PallyPowerFramePlayer" .. i .. "Symbols"):SetTextColor(1, 1, 0.5)
            if (PallyPower_CanControl(name)) then
                getglobal("PallyPowerFramePlayer" .. i .. "Name"):SetTextColor(1, 1, 1)
            else
                if (PallyPower_CheckRaidLeader(name)) then
                    getglobal("PallyPowerFramePlayer" .. i .. "Name"):SetTextColor(0, 1, 0)
                else
                    getglobal("PallyPowerFramePlayer" .. i .. "Name"):SetTextColor(1, 0, 0)
                end
            end
            for id = 0, 5 do
                if (blessings[id]) then
                    getglobal("PallyPowerFramePlayer" .. i .. "Icon" .. id):Show()
                    getglobal("PallyPowerFramePlayer" .. i .. "Skill" .. id):Show()
                    local txt = blessings[id]["rank"];
                    if (blessings[id]["talent"] + 0 > 0) then
                        txt = txt .. "+" .. blessings[id]["talent"]
                    end
                    getglobal("PallyPowerFramePlayer" .. i .. "Skill" .. id):SetText(txt)
                else
                    getglobal("PallyPowerFramePlayer" .. i .. "Icon" .. id):Hide()
                    getglobal("PallyPowerFramePlayer" .. i .. "Skill" .. id):Hide()
                end
            end
            for id = 0, 9 do
                if (PallyPower_Assignments[name]) then
                    getglobal("PallyPowerFramePlayer" .. i .. "Class" .. id .. "Icon"):SetTexture(BlessingIcon[PallyPower_Assignments[name][id]])
                else
                    getglobal("PallyPowerFramePlayer" .. i .. "Class" .. id .. "Icon"):SetTexture(nil)
                end
            end

            -- Class10 is a special per-paladin Judgement assignment column.
            -- It is not a real raid class and is intentionally ignored by the buff bar.
            local judgementIcon = nil
            if PallyPower_Assignments[name] then
                judgementIcon = PallyPower_JudgementIcon[PallyPower_Assignments[name][10]]
            end
            getglobal("PallyPowerFramePlayer" .. i .. "Class10Icon"):SetTexture(judgementIcon)
            i = i + 1
            numPallys = numPallys + 1
        end
        PallyPowerFrame:SetHeight(14 + 24 + 69 + (numPallys * 56) + 22) -- 14 from border, 24 from Title, 69 for class labels/icons, 56 per paladin, 22 for Buttons at bottom
        for i = 1, 12 do
            if i <= numPallys then
                getglobal("PallyPowerFramePlayer" .. i):Show()
            else
                getglobal("PallyPowerFramePlayer" .. i):Hide()
            end
        end
    end
end

function PallyPower_UpdateUI()
    if not initalized then
        PallyPower_ScanSpells()
    end
    -- Buff Bar
    PallyPowerBuffBar:SetScale(PP_PerUser.scalebar);
    local pclass, eclass = UnitClass("player")
    
    if eclass == "PALADIN" then
      IsPally = 1
    end
    
    if ((IsPally == 1) or (GetNumRaidMembers() > 0 and GetNumPartyMembers() > 0)) then
        PallyPowerBuffBar:Show()
        PallyPowerBuffBarTitleText:SetText(format(PallyPower_BuffBarTitle, PP_Symbols));
        BuffNum = 1
        if PallyPower_Assignments[UnitName("player")] then
            local assign = PallyPower_Assignments[UnitName("player")]
            for class = 0, 9 do
                if (assign[class] and assign[class] ~= -1) then
                    getglobal("PallyPowerBuffBarBuff" .. BuffNum .. "ClassIcon"):SetTexture(PallyPower_ClassTexture[class]);
                    getglobal("PallyPowerBuffBarBuff" .. BuffNum .. "BuffIcon"):SetTexture(BlessingIcon[assign[class]]);
                    
                    local btn = getglobal("PallyPowerBuffBarBuff" .. BuffNum);
                    btn.classID = class;
                    btn.buffID = assign[class];
                    btn.need = {};
                    btn.have = {};
                    btn.range = {};
                    btn.dead = {};
                    -- Calculate number of people who need buff.
                    local nneed = 0;
                    local nhave = 0;
                    local ndead = 0;
                    if CurrentBuffs[class] then
                        for member, stats in CurrentBuffs[class] do
                            if stats["visible"] then
                                if not stats[assign[class]] then
                                    if UnitIsDeadOrGhost(member) then
                                        ndead = ndead + 1;
                                        tinsert(btn.dead, stats["name"]);
                                    else
                                        nneed = nneed + 1
                                        tinsert(btn.need, stats["name"]);
                                    end
                                else
                                    tinsert(btn.have, stats["name"]);
                                    nhave = nhave + 1
                                end
                            else
                                tinsert(btn.range, stats["name"]);
                                nhave = nhave + 1
                            end
                        end
                    end
                    if ndead > 0 then
                        getglobal("PallyPowerBuffBarBuff" .. BuffNum .. "Text"):SetText(nneed .. " (" .. ndead .. ")");
                    else
                        getglobal("PallyPowerBuffBarBuff" .. BuffNum .. "Text"):SetText(nneed);
                    end
                    getglobal("PallyPowerBuffBarBuff" .. BuffNum .. "Time"):SetText(PallyPower_FormatTime(LastCast[assign[class] .. class]));
                    if not (nneed > 0 or nhave > 0) then
                    else
                        BuffNum = BuffNum + 1
                        if (nhave == 0) then
                            btn:SetBackdropColor(1.0, 0.0, 0.0, 0.5);
                        elseif (nneed > 0) then
                            btn:SetBackdropColor(1.0, 1.0, 0.5, 0.5);
                        else
                            btn:SetBackdropColor(0.0, 0.0, 0.0, 0.5);
                        end
                        btn:Show();
                    end
                end
            end
        end
        for rest = BuffNum, 10 do
            local btn = getglobal("PallyPowerBuffBarBuff" .. rest);
            btn:Hide();
        end
        PallyPowerBuffBar:SetHeight(30 + (34 * (BuffNum - 1)));
    else
        PallyPowerBuffBar:Hide()
    end
end

function PallyPower_ScanSpells()
    local RankInfo = {}
    local i = 1
    
    while true do
        local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
        local spellTexture = GetSpellTexture(i, BOOKTYPE_SPELL)
        if not spellName then
            break
        end
        
        if not spellRank or spellRank == "" then
            spellRank = PallyPower_Rank1
        end
        
        local _, _, bless = string.find(spellName, PallyPower_BlessingSpellSearch)
        if bless then
            local greaterBless, _ = string.find(spellName, "Greater")
            for id, name in PallyPower_BlessingID do
                if ((name == bless) and (not greaterBless)) then
                    local _, _, rank = string.find(spellRank, PallyPower_RankSearch);
                    if (RankInfo[id] and spellRank < RankInfo[id]["rank"]) then
                    else
                        RankInfo[id] = {};
                        RankInfo[id]["rank"] = rank;
                        RankInfo[id]["id"] = i;
                        RankInfo[id]["name"] = name;
                        RankInfo[id]["talent"] = 0;
                    end
                end
                
            end
        end

        if (RegularBlessings == false) then
            local _, _, bless = string.find(spellName, PallyPower_BlessingSpellSearch)
            if bless then
                local greaterBless, _ = string.find(spellName, "Greater")
                for id, name in PallyPower_BlessingID do
                    if ((name == bless) and (greaterBless)) then
                        local _, _, rank = string.find(spellRank, PallyPower_RankSearch);
                        if (RankInfo[id] and spellRank < RankInfo[id]["rank"]) then
                        else
                            RankInfo[id]["id"] = i;
                            RankInfo[id]["name"] = name;
                        end
                    end
                end
            end
        end

        -- local _, _, seal = string.find(spellName, PallyPower_SealSpellSearch)
        -- if seal then
        --     for id, name in PallyPower_SealID do
        --         if (name == seal) then
        --             local _, _, rank = string.find(spellRank, PallyPower_RankSearch);
        --             if (RankInfo[id] and spellRank < RankInfo[id]["rank"]) then
        --             else
        --                 RankInfo[id] = {};
        --                 RankInfo[id]["rank"] = rank;
        --                 RankInfo[id]["id"] = i;
        --                 RankInfo[id]["name"] = name;
        --                 RankInfo[id]["talent"] = 0;
        --             end
        --         end
        --     end
        -- end

        i = i + 1
    end

    -- Sanctuary (Talent tab 2 - Talent number 8)
    local hasSanctuary = 0;
    local nameTalent, icon, iconx, icony, currRank, maxRank = GetTalentInfo(2, 8);
    if nameTalent then
        local sanctuaryTalent = string.find(nameTalent, PallyPower_SanctuaryTalentSearch);
        if sanctuaryTalent and currRank > 0 then
            hasSanctuary = currRank;
        end
    end

    --Divine Grace (Talent tab 1 - Talent number 11)
    local nameTalent, icon, iconx, icony, currRank, maxRank = GetTalentInfo(1, 11);
    if nameTalent then
        local divineGraceTalent = string.find(nameTalent, PallyPower_DivineGraceTalentSearch);
        if divineGraceTalent and currRank > 0 then
            for id in PallyPower_BlessingID do
                if (id == 0 or id == 3) then
                    RankInfo[id]["talent"] = currRank;
                end
            end
        end
    end

    --Guardian's Favor (Talent tab 2 - Talent number 4)
    local nameTalent, icon, iconx, icony, currRank, maxRank = GetTalentInfo(2, 4);
    if nameTalent then
        local guardianFavorTalent = string.find(nameTalent, PallyPower_GuardianFavorTalentSearch);
        if guardianFavorTalent and currRank > 0 then
            for id in PallyPower_BlessingID do
                if (id == 2 or (id == 5 and hasSanctuary == 1)) then
                    RankInfo[id]["talent"] = currRank;
                end
            end
        end
    end

    --Divine Might (Talent tab 3 - Talent number 12)
    local nameTalent, icon, iconx, icony, currRank, maxRank = GetTalentInfo(3, 12);
    if nameTalent then
        local divineMightTalent = string.find(nameTalent, PallyPower_DivineMightTalentSearch);
        if divineMightTalent and currRank > 0 then
            for id in PallyPower_BlessingID do
                if (id == 1 or id == 4) then
                    RankInfo[id]["talent"] = currRank;
                end
            end
        end
    end
       
    local _, playerClass = UnitClass("player");
    if playerClass == "PALADIN" then
        AllPallys[UnitName("player")] = RankInfo;
        if initalized then
            PallyPower_SendSelf();
        end
        PP_IsPally = true
    else
        PP_Debug("I'm not a paladin?? " .. tostring(playerClass));
        PP_IsPally = nil
        initalized = true;
    end
    PallyPower_ScanInventory()
    return RankInfo
end

function PallyPower_Refresh()
    AllPallys = {}
    PallyPower_SendSelf()
    PallyPower_RequestSend()
	PallyPower_ScanSpells()
    PallyPower_UpdateUI()
end

function PallyPower_Clear(fromupdate, who)
    if not who then
        who = UnitName("player")
    end
    for name, skills in PallyPower_Assignments do
        if (PallyPower_CheckRaidLeader(who) or name == who) then
            for class, id in PallyPower_Assignments[name] do
                PallyPower_Assignments[name][class] = -1
            end
        end
    end
    PallyPower_UpdateUI()
    if not fromupdate then
        PallyPower_SendMessage("CLEAR")
    end
end

function PallyPower_RequestSend()
    PallyPower_SendMessage("REQ")
end

function PallyPower_SendSelf()
    if not AllPallys[UnitName("player")] then
        return
    end
    msg = "SELF "
    local RankInfo = AllPallys[UnitName("player")]
    local i
    for id = 0, 5 do
        if (not RankInfo[id]) then
            msg = msg .. "nn";
        else
            msg = msg .. RankInfo[id]["rank"]
            msg = msg .. RankInfo[id]["talent"]
        end
    end
    msg = msg .. "@"
    -- 0-9 are class Blessing assignments; 10 is the Judgement assignment.
    -- Older clients simply ignore the extra 11th assignment character.
    for id = 0, 10 do
        if (not PallyPower_Assignments[UnitName("player")]) or (not PallyPower_Assignments[UnitName("player")][id]) or PallyPower_Assignments[UnitName("player")][id] == -1 then
            msg = msg .. "n"
        else
            msg = msg .. PallyPower_Assignments[UnitName("player")][id]
        end
    end
    PallyPower_SendMessage(msg)
    PallyPower_SendMessage("SYMCOUNT " .. PP_Symbols);
end

function PallyPower_SendMessage(msg)
    if GetNumRaidMembers() == 0 then
        SendAddonMessage(PP_PREFIX, msg, "PARTY", UnitName("player"));
    else
        SendAddonMessage(PP_PREFIX, msg, "RAID", UnitName("player"));
    end
end

function PallyPower_ParseMessage(sender, msg)
    if not (sender == UnitName("player")) then
        if msg == "REQ" then
            PallyPower_SendSelf()
        end
        if string.find(msg, "^SELF") then
            -- Preserve an existing Judgement assignment when talking to an
            -- older client whose SELF payload only contains the original 10
            -- blessing slots.  Updated clients send an 11th slot explicitly.
            local previousJudgement = nil
            if PallyPower_Assignments[sender] then
                previousJudgement = PallyPower_Assignments[sender][10]
            end

            PallyPower_Assignments[sender] = {}
            AllPallys[sender] = {}
            _, _, numbers, assign = string.find(msg, "SELF ([0-9n]*)@?([0-9n]*)")
            for id = 0, 5 do
                rank = string.sub(numbers, id * 2 + 1, id * 2 + 1)
                talent = string.sub(numbers, id * 2 + 2, id * 2 + 2)
                if not (rank == "n") then
                    AllPallys[sender][id] = { }
                    AllPallys[sender][id]["rank"] = rank
                    AllPallys[sender][id]["talent"] = talent
                end
            end
            if assign then
                for id = 0, 10 do
                    local tmp = string.sub(assign, id + 1, id + 1)
                    local value = tonumber(tmp)
                    if (tmp == "n" or tmp == "" or not value) then
                        value = -1
                    end

                    if id == 10 then
                        -- Judgement slot: Crusader/Wisdom/Light or none.
                        -- No 11th character means this is an older PallyPower
                        -- client, so keep any assignment made by an updated
                        -- raid leader instead of silently clearing it.
                        if tmp == "" then
                            value = previousJudgement
                            if value == nil then
                                value = -1
                            end
                        elseif value < -1 or value > 2 then
                            value = -1
                        end
                    else
                        -- Blessing slots: 0-5 or none. 6 is the local cycle's
                        -- empty sentinel and is never serialized intentionally.
                        if value < -1 or value > 5 then
                            value = -1
                        end
                    end

                    PallyPower_Assignments[sender][id] = value
                end
            end
            PallyPower_UpdateUI()
        end
        if string.find(msg, "^ASSIGN ") then
            local _, _, assignName, classText, skillText = string.find(msg, "^ASSIGN ([^ ]+) ([0-9]+) (-?[0-9]+)$")
            local classID = tonumber(classText)
            local skillID = tonumber(skillText)

            -- Ignore malformed/incompatible assignment messages instead of
            -- doing arithmetic on a shared global 'class' value.
            local validAssignment = false
            if assignName and classID and skillID then
                if classID >= 0 and classID <= 9 and skillID >= -1 and skillID <= 6 then
                    validAssignment = true
                elseif classID == 10 and skillID >= -1 and skillID <= 2 then
                    -- Special Judgement assignment: Crusader/Wisdom/Light/none.
                    validAssignment = true
                end
            end

            if validAssignment then
                if (not (assignName == sender)) and (not PallyPower_CheckRaidLeader(sender)) then
                    return false
                end
                if (not PallyPower_Assignments[assignName]) then
                    PallyPower_Assignments[assignName] = {}
                end
                PallyPower_Assignments[assignName][classID] = skillID;
                PallyPower_UpdateUI()
            end
        end
        if string.find(msg, "^MASSIGN ") then
            local _, _, assignName, skillText = string.find(msg, "^MASSIGN ([^ ]+) (-?[0-9]+)$")
            local skillID = tonumber(skillText)

            if assignName and skillID and skillID >= -1 and skillID <= 6 then
                if (not (assignName == sender)) and (not PallyPower_CheckRaidLeader(sender)) then
                    return false
                end
                if (not PallyPower_Assignments[assignName]) then
                    PallyPower_Assignments[assignName] = {}
                end
                for classID = 0, 9 do
                    PallyPower_Assignments[assignName][classID] = skillID;
                end
                PallyPower_UpdateUI()
            end
        end
        if string.find(msg, "^SYMCOUNT ([0-9]*)") then
            _, _, count = string.find(msg, "^SYMCOUNT ([0-9]*)")
            if AllPallys[sender] then
                AllPallys[sender]["symbols"] = count;
            else
                PallyPower_SendMessage("REQ");
            end
        end
        if string.find(msg, "^CLEAR") then
            PallyPower_Clear(true, sender)
        end
    end
end

function PallyPower_ResetPosition()
    local frame = PallyPowerBuffBar
    if frame then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", 0, 0)
        DEFAULT_CHAT_FRAME:AddMessage("PallyPowerBuffBar centered on the screen.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("Frame PallyPowerBuffBar not found.")
    end
end

function PallyPower_ShowCredits()
    GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
    GameTooltip:SetText(PallyPower_Credits1, 1, 1, 1)
    GameTooltip:AddLine(PallyPower_Credits2, 1, 1, 1);
    GameTooltip:AddLine(PallyPower_Credits3);
    GameTooltip:AddLine(PallyPower_Credits4, 0, 1, 0);
    GameTooltip:AddLine(PallyPower_Credits5);
    GameTooltip:Show()
end

function PallyPowerFrame_MouseDown(arg1)
    if (((not PallyPowerFrame.isLocked) or (PallyPowerFrame.isLocked == 0)) and (arg1 == "LeftButton")) then
        PallyPowerFrame:StartMoving();
        PallyPowerFrame.isMoving = true;
    end
end

function PallyPowerFrame_MouseUp()
    if (PallyPowerFrame.isMoving) then
        PallyPowerFrame:StopMovingOrSizing();
        PallyPowerFrame.isMoving = false;
    end
end

function PallyPowerBuffBar_MouseDown(arg1)
    if (((not PallyPowerBuffBar.isLocked) or (PallyPowerBuffBar.isLocked == 0)) and ((arg1 == "LeftButton") or (arg1 == "RightButton"))) then
        PallyPowerBuffBar:StartMoving();
        PallyPowerBuffBar.isMoving = true;
        PallyPowerBuffBar.startPosX = PallyPowerBuffBar:GetLeft();
        PallyPowerBuffBar.startPosY = PallyPowerBuffBar:GetTop();
    end
end

function PallyPowerBuffBar_MouseUp()
    if (PallyPowerBuffBar.isMoving) then
        PallyPowerBuffBar:StopMovingOrSizing();
        PallyPowerBuffBar.isMoving = false;
    end
    if abs(PallyPowerBuffBar.startPosX - PallyPowerBuffBar:GetLeft()) < 2 and abs(PallyPowerBuffBar.startPosY - PallyPowerBuffBar:GetTop()) < 2 then
        PallyPowerFrame:Show();
        PallyPower_UpdateUI()
    end
end

function PallyPowerGridButton_OnLoad(btn)
end

function PallyPowerGridButton_OnClick(btn, mouseBtn)
    local _, _, pnumText, classText = string.find(btn:GetName(), "PallyPowerFramePlayer(.+)Class(.+)");
    local pnum = tonumber(pnumText);
    local classID = tonumber(classText);
    if not pnum or not classID then
        return false
    end
    local pname = getglobal("PallyPowerFramePlayer" .. pnum .. "Name"):GetText()
    if not PallyPower_CanControl(pname) then
        return false
    end

    if not PallyPower_Assignments[pname] then
        PallyPower_Assignments[pname] = {}
    end

    if (mouseBtn == "RightButton") then
        PallyPower_Assignments[pname][classID] = -1
        PallyPower_UpdateUI()
        PallyPower_SendMessage("ASSIGN " .. pname .. " " .. classID .. " -1")
    elseif classID == 10 then
        PallyPower_PerformJudgementCycle(pname)
    else
        PallyPower_PerformCycle(pname, classID)
    end
end

function PallyPowerGridButton_OnLeave(btn)
    GameTooltip:Hide()
end

function PallyPowerGridButton_OnEnter(btn)
    if not btn then
        return
    end

    local _, _, pnumText, classText = string.find(btn:GetName(), "PallyPowerFramePlayer(.+)Class(.+)")
    local pnum = tonumber(pnumText)
    local classID = tonumber(classText)
    if not pnum or not classID then
        return
    end

    if classID == 10 then
        local pname = getglobal("PallyPowerFramePlayer" .. pnum .. "Name"):GetText()
        local judgement = -1
        if PallyPower_Assignments[pname] and PallyPower_Assignments[pname][10] then
            judgement = PallyPower_Assignments[pname][10]
        end

        local judgementName = "None"
        if PallyPower_JudgementID[judgement] then
            judgementName = "Judgement of " .. PallyPower_JudgementID[judgement]
        end

        GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
        GameTooltip:SetText((pname or "Paladin") .. ": Judgement Assignment", 1, 1, 1)
        GameTooltip:AddLine(judgementName, 1, 0.82, 0)
        GameTooltip:AddLine("Left-click or mouse wheel: cycle", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click: clear", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end
end

-- Judgement assignment cycles are intentionally independent from blessing
-- availability and Smart Buffs.  At raid level every Paladin can be assigned
-- one of the three maintained Judgements regardless of blessing spec.
function PallyPower_PerformJudgementCycle(name)
    if not PallyPower_Assignments[name] then
        PallyPower_Assignments[name] = {}
    end

    local current = PallyPower_Assignments[name][10]
    if current == nil then
        current = -1
    end

    local nextJudgement = current + 1
    if nextJudgement > 2 then
        nextJudgement = -1
    end

    PallyPower_Assignments[name][10] = nextJudgement
    PallyPower_SendMessage("ASSIGN " .. name .. " 10 " .. nextJudgement)
    PallyPower_UpdateUI()
end

function PallyPower_PerformJudgementCycleBackwards(name)
    if not PallyPower_Assignments[name] then
        PallyPower_Assignments[name] = {}
    end

    local current = PallyPower_Assignments[name][10]
    if current == nil or current == -1 then
        current = 3
    end

    local nextJudgement = current - 1
    if nextJudgement < -1 then
        nextJudgement = 2
    end

    PallyPower_Assignments[name][10] = nextJudgement
    PallyPower_SendMessage("ASSIGN " .. name .. " 10 " .. nextJudgement)
    PallyPower_UpdateUI()
end

function PallyPower_PerformCycleBackwards(name, class)

    local shift = IsShiftKeyDown()

    if not PallyPower_Assignments[name][class] then
        currentBuffSelection = 6
    else
        currentBuffSelection = PallyPower_Assignments[name][class]
        if currentBuffSelection == -1 then
            currentBuffSelection = 6
        end
    end

    for buff = currentBuffSelection - 1, -1, -1 do
        currentBuffSelection = buff
        if PallyPower_CanBuff(name, buff) and (PallyPower_NeedsBuff(class, buff) or shift) then
            break
        end
    end

    if shift then
        for class = 0, 9 do
            PallyPower_Assignments[name][class] = currentBuffSelection
        end
        PallyPower_SendMessage("MASSIGN " .. name .. " " .. currentBuffSelection)
    else
        PallyPower_Assignments[name][class] = currentBuffSelection
        PallyPower_SendMessage("ASSIGN " .. name .. " " .. class .. " " .. currentBuffSelection)
    end

    PallyPower_UpdateUI()
end

function PallyPower_PerformCycle(name, class)

    local shift = IsShiftKeyDown()

    if not PallyPower_Assignments[name][class] then
        currentBuffSelection = -1
    else
        currentBuffSelection = PallyPower_Assignments[name][class]
        if currentBuffSelection == 6 then
            currentBuffSelection = -1
        end
    end

    for buff = currentBuffSelection + 1, 6 do
        if PallyPower_CanBuff(name, buff) and (PallyPower_NeedsBuff(class, buff) or shift) then
            currentBuffSelection = buff
            break
        end
    end

    if shift then
        for class = 0, 9 do
            PallyPower_Assignments[name][class] = currentBuffSelection
        end
        PallyPower_SendMessage("MASSIGN " .. name .. " " .. currentBuffSelection)
    else
        PallyPower_Assignments[name][class] = currentBuffSelection
        PallyPower_SendMessage("ASSIGN " .. name .. " " .. class .. " " .. currentBuffSelection)
    end

    PallyPower_UpdateUI()
end

function PallyPower_CanBuff(name, buff)
    -- buff cycles from 0 to 6 in the order of PallyPower_BlessingID (localization.lua)
    -- 6 is the empty slot corresponding to no buffs
    -- Every class can have the "empty" buff
    if buff == 6 then
        return true
    end
    -- If pally does not have the skill (e.g. not specced into sanctuary), it skips it
    if (not AllPallys[name][buff]) or (AllPallys[name][buff]["rank"] == 0) then
        return false
    end
    return true
end

function PallyPower_NeedsBuff(class, buff)
    if (buff == 6) or (buff == -1) then
        return true
    end
    if PP_PerUser.smartbuffs then
        -- no wisdom for warriors and rogues
        if (class == 0 or class == 1) and buff == 0 then
            return false
        end
        -- no might for pure casters; hunters can use Blessing of Might
        if (class == 2 or class == 6 or class == 7) and buff == 1 then
            return false
        end
    end

    for name, skills in PallyPower_Assignments do
        if (AllPallys[name]) and ((skills[class]) and (skills[class] == buff)) then
            return false
        end
    end
    return true
end

function PallyPower_CheckRaidLeader(nick)
    if GetNumRaidMembers() == 0 then
        for i = 1, GetNumPartyMembers(), 1 do
            if nick == UnitName("party" .. i) and UnitIsPartyLeader("party" .. i) then
                return true
            end
        end
        return false
    end
    for i = 1, GetNumRaidMembers(), 1 do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(i)
        if (rank >= 1 and name == nick) then
            return true
        end
    end
    return false
end

function PallyPower_CanControl(name)
    return (IsPartyLeader() or IsRaidLeader() or IsRaidOfficer() or (name == UnitName("player")))
end

function PallyPower_ScanInventory()
    if not PP_IsPally then
        return
    end
    PP_Debug("PallyPower_ScanInventory scanning");
    oldcount = PP_Symbols
    PP_Symbols = 0
    for bag = 0, 4 do
        local bagslots = GetContainerNumSlots(bag);
        if (bagslots) then
            for slot = 1, bagslots do
                local link = GetContainerItemLink(bag, slot)
                if (link and string.find(link, PallyPower_Symbol)) then
                    local _, count, locked = GetContainerItemInfo(bag, slot);
                    PP_Symbols = PP_Symbols + count
                end
            end
        end
    end
    if PP_Symbols ~= oldcount then
        PallyPower_SendMessage("SYMCOUNT " .. PP_Symbols);
    end
    AllPallys[UnitName("player")]["symbols"] = PP_Symbols;
end

PP_ScanInfo = nil

function PallyPower_ScanRaid()
    if not PP_IsPally then
        return
    end
    if not (PP_ScanInfo) then
        PP_Scanners = {}
        PP_ScanInfo = {}
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                tinsert(PP_Scanners, "raid" .. i)
            end
            INRAID = 1
        else
            tinsert(PP_Scanners, "player");
            for i = 1, GetNumPartyMembers() do
                tinsert(PP_Scanners, "party" .. i)
            end
            INRAID = 0
        end
    end
    local tests = PP_PerUser.scanperframe
    if (not tests) then
        tests = 1
    end

    while PP_Scanners[1] do
        unit = PP_Scanners[1]
        local name = UnitName(unit)
        local class = UnitClass(unit)
        if (name and class) then
            local cid = PallyPower_GetClassID(class)        
            if cid == 5 then -- hunters
                if GetNumRaidMembers() > 0 then
                    local petId = "raidpet" .. string.sub(unit, 5);    
                    local pet_name = UnitName(petId)
                    
                    if pet_name then
                        local classID = 9
                        if not PP_ScanInfo[classID] then
                            PP_ScanInfo[classID] = {}
                        end
    
                        PP_ScanInfo[classID][petId] = {};
                        PP_ScanInfo[classID][petId]["name"] = pet_name;
                        PP_ScanInfo[classID][petId]["visible"] = UnitIsVisible(petId);
    
                        local j = 1
                        while UnitBuff(petId, j, true) do
                            local buffIcon, _ = UnitBuff(petId, j, true)
                            local txtID = PallyPower_GetBuffTextureID(buffIcon)
                            if txtID > 5 then
                                txtID = txtID - 6
                            end
                            PP_ScanInfo[classID][petId][txtID] = true
                            j = j + 1
                        end
                    end
                else
                    local petId = "partypet" .. string.sub(unit, 6);
                    local pet_name = UnitName(petId)
                    
                    if pet_name then
                        local classID = 9
                        if not PP_ScanInfo[classID] then
                            PP_ScanInfo[classID] = {}
                        end
    
                        PP_ScanInfo[classID][petId] = {};
                        PP_ScanInfo[classID][petId]["name"] = pet_name;
                        PP_ScanInfo[classID][petId]["visible"] = UnitIsVisible(petId);
    
                        local j = 1
                        while UnitBuff(petId, j, true) do
                            local buffIcon, _ = UnitBuff(petId, j, true)
                            local txtID = PallyPower_GetBuffTextureID(buffIcon)
                            if txtID > 5 then
                                txtID = txtID - 6
                            end
                            PP_ScanInfo[classID][petId][txtID] = true
                            j = j + 1
                        end
                    end
                end
            end

            if not PP_ScanInfo[cid] then
                PP_ScanInfo[cid] = {}
            end
            PP_ScanInfo[cid][unit] = {};
            PP_ScanInfo[cid][unit]["name"] = name;
            PP_ScanInfo[cid][unit]["visible"] = UnitIsVisible(unit);

            local j = 1
            while UnitBuff(unit, j, true) do
                local buffIcon, _ = UnitBuff(unit, j, true)
                local txtID = PallyPower_GetBuffTextureID(buffIcon)
                if txtID > 5 then
                    txtID = txtID - 6
                end
                PP_ScanInfo[cid][unit][txtID] = true
                j = j + 1
            end
        end
        tremove(PP_Scanners, 1)
        tests = tests - 1
        PP_Debug("Scanning " .. unit .. " and " .. tests .. " remain");
        if (tests <= 0) then
            return
        end
    end
    CurrentBuffs = PP_ScanInfo
    PP_ScanInfo = nil
    PP_NextScan = PP_PerUser.scanfreq
    PallyPower_ScanInventory()
end

function PallyPower_GetClassID(class)
    for id, name in PallyPower_ClassID do
        if (name == class) then
            return id
        end
    end
    return -1
end

function PallyPower_GetBuffTextureID(text)
    for id, name in BuffIcon do
        if (name == text) then
            return id
        end
    end
    return -2
end

function PallyPowerBuffButton_OnLoad(btn)
    this:SetBackdropColor(0.0, 0.0, 0.0, 0.5);
end

function PallyPowerBuffButton_OnClick(btn, mousebtn)
    PallyPower_ScanSpells()

    -- Basic safety checks
    if not btn or not btn.buffID or not btn.classID then
        DEFAULT_CHAT_FRAME:AddMessage("PallyPower: Invalid button data.")
        return
    end

    -- Ignore right-click (prevents your 994 error)
    if mousebtn == "RightButton" then
        DEFAULT_CHAT_FRAME:AddMessage("PallyPower: Right-click ignored.")
        return
    end

    RestorSelfAutoCastTimeOut = 1
    if (GetCVar("autoSelfCast") == "1") then
        RestorSelfAutoCast = true
        SetCVar("autoSelfCast", "0")
    end

    ClearTarget()

    PP_Debug("Casting " .. tostring(btn.buffID) .. " on " .. tostring(btn.classID))

    local pname = UnitName("player")

    -- 🔴 Critical nil protection (this is your line 994 crash)
    if not AllPallys
    or not pname
    or not AllPallys[pname]
    or not AllPallys[pname][btn.buffID]
    or not AllPallys[pname][btn.buffID]["id"] then
        DEFAULT_CHAT_FRAME:AddMessage("PallyPower: Missing spell data for buffID " .. tostring(btn.buffID))
        return
    end

    CastSpell(AllPallys[pname][btn.buffID]["id"], BOOKTYPE_SPELL)

    local RecentCast = false

    -- VanillaPlus update: Paladin Blessings now last 20 minutes baseline.
    -- Improved Blessing talents are no longer required for the 20-minute duration.
    local duration = 20 * 60

    if LastCast
    and LastCast[btn.buffID .. btn.classID]
    and LastCast[btn.buffID .. btn.classID] > duration - 10 then
        RecentCast = true
    end

    -- Safety for CurrentBuffs table
    if not CurrentBuffs or not CurrentBuffs[btn.classID] then
        DEFAULT_CHAT_FRAME:AddMessage("PallyPower: No buff data for class " .. tostring(btn.classID))
        return
    end

    for unit, stats in CurrentBuffs[btn.classID] do
        if unit and SpellCanTargetUnit(unit) then

            local skip = false

            if RecentCast and LastCastOn and LastCastOn[btn.classID] then
                if string.find(table.concat(LastCastOn[btn.classID], " "), unit) then
                    skip = true
                end
            end

            if not skip then
                PP_Debug("Trying to cast on " .. unit)

                SpellTargetUnit(unit)
                PP_NextScan = 1

                if LastCast then
                    LastCast[btn.buffID .. btn.classID] = duration
                end

                if not RecentCast then
                    LastCastOn[btn.classID] = {}
                end

                if not LastCastOn[btn.classID] then
                    LastCastOn[btn.classID] = {}
                end

                tinsert(LastCastOn[btn.classID], unit)

                PallyPower_ShowFeedback(
                    format(
                        PallyPower_Casting or "Casting %s on %s (%s)",
                        PallyPower_BlessingID[btn.buffID] or tostring(btn.buffID),
                        PallyPower_ClassID[btn.classID] or tostring(btn.classID),
                        UnitName(unit) or "unknown"
                    ),
                    0.0, 1.0, 0.0
                )

                TargetLastTarget()
                return
            end
        end
    end

    SpellStopTargeting()
    TargetLastTarget()

    PallyPower_ShowFeedback(
        format(
            PallyPower_CouldntFind or "Could not find target for %s on %s",
            PallyPower_BlessingID[btn.buffID] or tostring(btn.buffID),
            PallyPower_ClassID[btn.classID] or tostring(btn.classID)
        ),
        0.0, 1.0, 0.0
    )
end

function PallyPowerBuffButton_OnEnter(btn)
    if not btn then return end

    local className = PallyPower_ClassID[btn.classID] or ("UnknownClass:" .. tostring(btn.classID))
    local buffName = PallyPower_BlessingID[btn.buffID] or ("UnknownBuff:" .. tostring(btn.buffID))
    local frameText = PallyPower_BuffFrameText or " - "

    GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
    GameTooltip:SetText(className .. frameText .. buffName, 1, 1, 1)

    GameTooltip:AddLine((PallyPower_Have or "Have: ") .. table.concat(btn.have or {}, ", "), 0.5, 1, 0.5)
    GameTooltip:AddLine((PallyPower_Need or "Need: ") .. table.concat(btn.need or {}, ", "), 1, 0.5, 0.5)
    GameTooltip:AddLine((PallyPower_NotHere or "Not here: ") .. table.concat(btn.range or {}, ", "), 0.5, 0.5, 1)
    GameTooltip:AddLine((PallyPower_Dead or "Dead: ") .. table.concat(btn.dead or {}, ", "), 1, 0, 0)

    GameTooltip:Show()
end

function PallyPowerBuffButton_OnLeave(btn)
    GameTooltip:Hide()
end

--[[ MainFrame and MenuFrame Scaling ]]--

function PallyPower_StartScaling(arg1)
    if arg1 == "LeftButton" then
        this:LockHighlight()
        PallyPower.FrameToScale = this:GetParent()
        PallyPower.ScalingWidth = this:GetParent():GetWidth() * PallyPower.FrameToScale:GetParent():GetEffectiveScale()
        PallyPower.ScalingHeight = this:GetParent():GetHeight() * PallyPower.FrameToScale:GetParent():GetEffectiveScale()
        PallyPower_ScalingFrame:Show()
    end
end

function PallyPower_StopScaling(arg1)
    if arg1 == "LeftButton" then
        PallyPower_ScalingFrame:Hide()
        PallyPower.FrameToScale = nil
        this:UnlockHighlight()
    end
end

local function really_setpoint(frame, point, relativeTo, relativePoint, xoff, yoff)
    frame:SetPoint(point, relativeTo, relativePoint, xoff, yoff)
end

function PallyPower_ScaleFrame(scale)
    local frame = PallyPower.FrameToScale
    local oldscale = frame:GetScale() or 1
    local framex = (frame:GetLeft() or PallyPowerPerOptions.XPos) * oldscale
    local framey = (frame:GetTop() or PallyPowerPerOptions.YPos) * oldscale

    frame:SetScale(scale)
    if frame:GetName() == "PallyPowerFrame" then
        really_setpoint(PallyPowerFrame, "TOPLEFT", "UIParent", "BOTTOMLEFT", framex / scale, framey / scale)
        PP_PerUser.scalemain = scale
    end
    if frame:GetName() == "PallyPowerBuffBar" then
        really_setpoint(PallyPowerBuffBar, "TOPLEFT", "UIParent", "BOTTOMLEFT", framex / scale, framey / scale)
        PP_PerUser.scalebar = scale
    end
end

function PallyPower_ScalingFrame_OnUpdate(arg1)
    if not PallyPower.ScalingTime then
        PallyPower.ScalingTime = 0
    end
    PallyPower.ScalingTime = PallyPower.ScalingTime + arg1
    if PallyPower.ScalingTime > 0.25 then
        PallyPower.ScalingTime = 0
        local frame = PallyPower.FrameToScale
        local oldscale = frame:GetEffectiveScale()
        local framex, framey, cursorx, cursory = frame:GetLeft() * oldscale, frame:GetTop() * oldscale, GetCursorPosition()
        if PallyPower.ScalingWidth > PallyPower.ScalingHeight then
            if (cursorx - framex) > 32 then
                local newscale = (cursorx - framex) / PallyPower.ScalingWidth
                PallyPower_ScaleFrame(newscale)
            end
        else
            if (framey - cursory) > 32 then
                local newscale = (framey - cursory) / PallyPower.ScalingHeight
                PallyPower_ScaleFrame(newscale)
            end
        end
    end
end

function PallyPower_CanUseRaidWarning()
    if GetNumRaidMembers() == 0 then
        return false
    end
    return (IsRaidLeader() or IsRaidOfficer())
end

function PallyPower_GetAnnounceChannel()
    if not PP_PerUser.announcechannel then
        PP_PerUser.announcechannel = "S"
    end
    if PP_PerUser.announcechannel == "RW" and not PallyPower_CanUseRaidWarning() then
        PP_PerUser.announcechannel = "R"
    end
    if not PallyPower_AnnounceChatType[PP_PerUser.announcechannel] then
        PP_PerUser.announcechannel = "S"
    end
    return PP_PerUser.announcechannel
end

function PallyPower_UpdateAnnounceButton()
    local btn = getglobal("PallyPowerFrameAnnounce")
    if not btn then
        return
    end
    btn:SetText(PallyPower_GetAnnounceChannel())
end

function PallyPower_CycleAnnounceChannel()
    local modes = {"S", "Y", "P", "R"}
    if PallyPower_CanUseRaidWarning() then
        tinsert(modes, "RW")
    end

    local current = PallyPower_GetAnnounceChannel()
    local index = 1
    for i = 1, table.getn(modes) do
        if modes[i] == current then
            index = i
            break
        end
    end

    index = index + 1
    if index > table.getn(modes) then
        index = 1
    end
    PP_PerUser.announcechannel = modes[index]
    PallyPower_UpdateAnnounceButton()
end

function PallyPower_AnnounceButton_OnEnter(btn)
    local channel = PallyPower_GetAnnounceChannel()
    local channelName = PallyPower_AnnounceChatName[channel] or channel

    GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
    GameTooltip:SetText("Assignment Announce: " .. channelName, 1, 1, 1)
    GameTooltip:AddLine("Left-click: change chat destination", 1, 0.82, 0)
    GameTooltip:AddLine("Right-click: announce assignments", 1, 0.82, 0)
    GameTooltip:AddLine(" ", 1, 1, 1)
    GameTooltip:AddLine("S = Say    Y = Yell", 0.75, 0.75, 0.75)
    GameTooltip:AddLine("P = Party  R = Raid", 0.75, 0.75, 0.75)
    if PallyPower_CanUseRaidWarning() then
        GameTooltip:AddLine("RW = Raid Warning", 0.75, 0.75, 0.75)
    else
        GameTooltip:AddLine("RW = Raid Warning (raid leader/assist only)", 0.5, 0.5, 0.5)
    end
    GameTooltip:AddLine("A confirmation appears before any chat is sent.", 0.6, 0.9, 1)
    GameTooltip:Show()
end

function PallyPower_AnnounceButton_OnLeave(btn)
    GameTooltip:Hide()
end

function PallyPower_GetWholeGroupText()
    if GetNumRaidMembers() > 0 then
        return "the whole raid"
    elseif GetNumPartyMembers() > 0 then
        return "the whole party"
    end
    return "everyone"
end

function PallyPower_GetValidBlessingID(assign, classID)
    if not assign then
        return nil
    end
    local id = tonumber(assign[classID])
    if id and id >= 0 and id <= 5 then
        return id
    end
    return nil
end

-- Announcement roles intentionally follow the simple PallyPower assignment
-- convention requested for raid coordination, not the live roster:
--   Non-Mana User (melee): Warrior, Rogue, Pets
--   Mana User (caster):    Priest, Druid, Paladin, Hunter, Mage, Warlock, Shaman
--
-- Reading the assignment grid itself also means announcements can be tested
-- correctly while solo; the old JA2 code only inspected classes currently in
-- the roster, which made a solo Paladin look like "everyone = Wisdom".
PallyPower_AnnounceMeleeClasses = {0, 1, 9}
PallyPower_AnnounceCasterClasses = {2, 3, 4, 5, 6, 7, 8}

function PallyPower_GetRoleBlessing(assign, classList)
    local roleBlessing = nil
    local hasAssignment = false

    for i = 1, table.getn(classList) do
        local buffID = PallyPower_GetValidBlessingID(assign, classList[i])
        if buffID then
            hasAssignment = true
            if roleBlessing == nil then
                roleBlessing = buffID
            elseif roleBlessing ~= buffID then
                -- More than one blessing inside the same simple role bucket.
                return nil, true, true
            end
        end
    end

    return roleBlessing, hasAssignment, false
end

function PallyPower_GetAllAssignedBlessings(assign)
    local seen = {}
    local unique = {}
    local assignedCount = 0

    for classID = 0, 9 do
        local buffID = PallyPower_GetValidBlessingID(assign, classID)
        if buffID then
            assignedCount = assignedCount + 1
            if not seen[buffID] then
                seen[buffID] = true
                tinsert(unique, buffID)
            end
        end
    end

    return unique, assignedCount
end

function PallyPower_BuildPaladinAnnouncement(name, assign)
    local lines = {}
    local unique, assignedCount = PallyPower_GetAllAssignedBlessings(assign)

    if table.getn(unique) == 1 then
        local buffName = PallyPower_BlessingID[unique[1]] or "Unknown"
        if assignedCount == 10 then
            tinsert(lines, name .. " is buffing " .. PallyPower_GetWholeGroupText() .. " with " .. buffName .. ".")
        else
            tinsert(lines, name .. " is buffing assigned targets with " .. buffName .. ".")
        end
    elseif table.getn(unique) == 2 then
        local meleeID, meleeAssigned, meleeMixed = PallyPower_GetRoleBlessing(assign, PallyPower_AnnounceMeleeClasses)
        local casterID, casterAssigned, casterMixed = PallyPower_GetRoleBlessing(assign, PallyPower_AnnounceCasterClasses)

        if meleeAssigned and casterAssigned and not meleeMixed and not casterMixed
        and meleeID ~= nil and casterID ~= nil and meleeID ~= casterID then
            local meleeName = PallyPower_BlessingID[meleeID] or "Unknown"
            local casterName = PallyPower_BlessingID[casterID] or "Unknown"

            tinsert(lines, name .. " is buffing Non-Mana User (melee) with " .. meleeName .. ".")
            tinsert(lines, name .. " is buffing Mana User (caster) with " .. casterName .. ".")

            -- Keep outgoing chat text plain. Legacy ChatThrottleLib rejects
            -- embedded player hyperlink escape sequences in SendChatMessage.
            -- The normal WoW sender name shown beside the message is already
            -- clickable and can be used to whisper this Paladin.
            tinsert(lines, "Whisper " .. name .. " if Mana User (melee) and you would rather have " .. meleeName .. " over " .. casterName .. " blessing.")
        else
            tinsert(lines, name .. " has custom blessing assignments; check PallyPower.")
        end
    elseif table.getn(unique) > 2 then
        tinsert(lines, name .. " has custom blessing assignments; check PallyPower.")
    end

    local judgementID = nil
    if assign then
        judgementID = tonumber(assign[10])
    end
    if judgementID and PallyPower_JudgementID[judgementID] then
        tinsert(lines, name .. " is assigned to Judgement of " .. PallyPower_JudgementID[judgementID] .. ".")
    end

    return lines
end

function PallyPower_BuildAssignmentAnnouncement()
    local lines = {}
    local paladins = {}

    for name, skills in AllPallys do
        if PallyPower_Assignments[name] then
            tinsert(paladins, name)
        end
    end
    table.sort(paladins)

    for i = 1, table.getn(paladins) do
        local name = paladins[i]
        local paladinLines = PallyPower_BuildPaladinAnnouncement(name, PallyPower_Assignments[name])
        for j = 1, table.getn(paladinLines) do
            tinsert(lines, paladinLines[j])
        end
    end

    return lines
end

function PallyPower_ClearPendingAnnouncement()
    PallyPower_AnnouncePendingLines = nil
    PallyPower_AnnouncePendingChatType = nil
    PallyPower_AnnouncePendingChatName = nil
end

function PallyPower_ConfirmAssignmentAnnouncement()
    if not PallyPower_AnnouncePendingLines or not PallyPower_AnnouncePendingChatType then
        PallyPower_ClearPendingAnnouncement()
        return
    end

    for i = 1, table.getn(PallyPower_AnnouncePendingLines) do
        local announce = {}
        announce["text"] = PallyPower_AnnouncePendingLines[i]
        announce["chat"] = PallyPower_AnnouncePendingChatType
        tinsert(PallyPower_AnnounceQueue, announce)
    end
    PallyPower_AnnounceQueueDelay = 0

    local count = table.getn(PallyPower_AnnouncePendingLines)
    local channelName = PallyPower_AnnouncePendingChatName or "chat"
    PallyPower_ClearPendingAnnouncement()
    PallyPower_ShowFeedback(" Queued " .. count .. " assignment messages for " .. channelName, 0.5, 1, 1, 1)
end

function PallyPower_PrepareAssignmentAnnouncement()
    if table.getn(PallyPower_AnnounceQueue) > 0 then
        PallyPower_ShowFeedback(" Assignment announcement is already being sent", 1, 0.82, 0, 1)
        return
    end

    local channel = PallyPower_GetAnnounceChannel()
    if channel == "P" and GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
        PallyPower_ShowFeedback(" Party announce requires a party or raid", 1, 0.5, 0.5, 1)
        return
    elseif channel == "R" and GetNumRaidMembers() == 0 then
        PallyPower_ShowFeedback(" Raid announce requires a raid", 1, 0.5, 0.5, 1)
        return
    elseif channel == "RW" and not PallyPower_CanUseRaidWarning() then
        PallyPower_ShowFeedback(" Raid Warning requires raid leader/assist", 1, 0.5, 0.5, 1)
        PallyPower_UpdateAnnounceButton()
        return
    end

    local lines = PallyPower_BuildAssignmentAnnouncement()
    if table.getn(lines) == 0 then
        PallyPower_ShowFeedback(" No blessing or Judgement assignments to announce", 1, 0.82, 0, 1)
        return
    end

    PallyPower_AnnouncePendingLines = lines
    PallyPower_AnnouncePendingChatType = PallyPower_AnnounceChatType[channel]
    PallyPower_AnnouncePendingChatName = PallyPower_AnnounceChatName[channel]
    StaticPopup_Show("PALLYPOWER_ANNOUNCE_CONFIRM", tostring(table.getn(lines)), PallyPower_AnnouncePendingChatName)
end

function PallyPower_AnnounceButton_OnClick(btn, mouseBtn)
    if mouseBtn == "RightButton" then
        PallyPower_PrepareAssignmentAnnouncement()
    else
        PallyPower_CycleAnnounceChannel()
    end
end

function PallyPower_SetOption(opt, value)
    PP_PerUser[opt] = value
end

function PallyPower_Options()
    PallyPower_OptionsFrame:Show()
end

function PallyPower_ShowFeedback(msg, r, g, b, a)
    if PP_PerUser.chatfeedback then
        DEFAULT_CHAT_FRAME:AddMessage("[PallyPower] " .. msg, r, g, b, a)
    else
        UIErrorsFrame:AddMessage(msg, r, g, b, a)
    end
end

function PallyPowerGridButton_OnMouseWheel(btn, arg1)
    local _, _, pnumText, classText = string.find(btn:GetName(), "PallyPowerFramePlayer(.+)Class(.+)");
    local pnum = tonumber(pnumText);
    local classID = tonumber(classText);
    if not pnum or not classID then
        return false
    end
    local pname = getglobal("PallyPowerFramePlayer" .. pnum .. "Name"):GetText()
    if not PallyPower_CanControl(pname) then
        return false
    end

    if classID == 10 then
        if (arg1 == -1) then
            PallyPower_PerformJudgementCycle(pname)
        else
            PallyPower_PerformJudgementCycleBackwards(pname)
        end
    elseif (arg1 == -1) then
        --mouse wheel down
        PallyPower_PerformCycle(pname, classID)
    else
        PallyPower_PerformCycleBackwards(pname, classID)
    end
end

function PallyPower_BarToggle()
    if ((GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0) or (PP_IsPally == false)) then
        PallyPower_ShowFeedback(" Not in raid or not a paladin", 0.5, 1, 1, 1)
    else
        if PallyPowerBuffBar:IsVisible() then
            PallyPowerBuffBar:Hide()
            PallyPower_ShowFeedback(" Bar hidden", 0.5, 1, 1, 1)
        else
            PallyPowerBuffBar:Show()
            PallyPower_ShowFeedback(" Bar visible", 0.5, 1, 1, 1)
        end
    end
end
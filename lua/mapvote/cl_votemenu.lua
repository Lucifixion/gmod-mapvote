net.Receive("RTV_Delay", function()
    if net.ReadInt(3) == 0 then
        chat.AddText(Color(102,255,51), "[RTV]", Color(255,255,255), " The vote has been rocked, map vote will begin on round end")
    else
        chat.AddText(Color(102,255,51), "[RTV]", Color(255,255,255), " The vote has been rocked, gamemode vote will begin on round end")
    end
end)

local PANEL = {}
function PANEL:Init()
    self:ParentToHUD()

    self.Canvas = vgui.Create("Panel", self)
    self.Canvas:MakePopup()
    self.Canvas:SetKeyboardInputEnabled(false)

    self.countDown = vgui.Create("DLabel", self.Canvas)
    self.countDown:SetTextColor(color_white)
    self.countDown:SetFont("RAM_VoteFontCountdown")
    self.countDown:SetText("")
    self.countDown:SetPos(0, 14)
    self.countDown:SetAlpha(0)
    self.countDown:AlphaTo(255, 0.8, 0)

    function self.countDown:PerformLayout()
        self:SizeToContents()
        self:CenterHorizontal()
    end

    self.iconList = vgui.Create("DPanelList", self.Canvas)
    self.iconList:SetPaintBackground(false)
    self.iconList:SetSpacing(4)
    self.iconList:SetPadding(4)
    self.iconList:EnableHorizontal(true)
    self.iconList:EnableVerticalScrollbar()

    self.closeButton = vgui.Create("DButton", self.Canvas)
    self.closeButton:SetText("")

    self.closeButton.Paint = function(panel, w, h)
        derma.SkinHook("Paint", "WindowCloseButton", panel, w, h)
    end

    self.closeButton.DoClick = function()
        self:SetVisible(false)
    end

    self.maximButton = vgui.Create("DButton", self.Canvas)
    self.maximButton:SetText("")
    self.maximButton:SetDisabled(true)

    self.maximButton.Paint = function(panel, w, h)
        derma.SkinHook("Paint", "WindowMaximizeButton", panel, w, h)
    end

    self.minimButton = vgui.Create("DButton", self.Canvas)
    self.minimButton:SetText("")
    self.minimButton:SetDisabled(true)

    self.minimButton.Paint = function(panel, w, h)
        derma.SkinHook("Paint", "WindowMinimizeButton", panel, w, h)
    end

    self.Voters = {}
end

function PANEL:PerformLayout()
    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())

    local extra = math.Clamp(1250 - 640, 0, ScrW() - 640)
    self.Canvas:StretchToParent(0, 0, 0, 0)
    self.Canvas:SetWide(640 + extra)
    self.Canvas:SetTall(ScrH() - 100)
    self.Canvas:SetPos(0, 0)
    self.Canvas:CenterHorizontal()
    self.Canvas:SetZPos(0)

    self.iconList:StretchToParent(0, 90, 0, 0)

    local buttonPos = 640 + extra - 31 * 3
    self.closeButton:SetPos(buttonPos - 31 * 0, 4)
    self.closeButton:SetSize(31, 31)
    self.closeButton:SetVisible(true)

    self.maximButton:SetPos(buttonPos - 31 * 1, 4)
    self.maximButton:SetSize(31, 31)
    self.maximButton:SetVisible(true)

    self.minimButton:SetPos(buttonPos - 31 * 2, 4)
    self.minimButton:SetSize(31, 31)
    self.minimButton:SetVisible(true)
end

local voter_alpha = CreateClientConVar("cl_vote_voter_alpha", 200, true, false, "The alpha level to use when showing voter icons. 0 = Fully transparent, 255 = Fully visible", 0, 255)

function PANEL:AddVoter(voter)
    for _, v in pairs(self.Voters) do
        if v.Player and v.Player == voter then
            return false
        end
    end

    local icon_container = vgui.Create("DButton", self.iconList:GetCanvas())
    local icon = vgui.Create("AvatarImage", icon_container)
    icon:SetSize(32, 32)
    icon:SetZPos(1000)
    icon_container.Player = voter
    icon:SetPlayer(voter, 32)
    icon_container:SetSize(36, 36)
    icon_container:SetText("")
    icon:SetPos(4, 4)

    icon_container.Paint = function(s, w, h)
        if icon_container.img then
            surface.SetMaterial(icon_container.img)
            surface.SetDrawColor(Color(255, 255, 255))
            surface.DrawTexturedRect(2, 2, 16, 16)
        end
    end

    icon_container:SetTooltip(voter:Nick())
    icon_container:SetMouseInputEnabled(true)
    icon_container:SetAlpha(voter_alpha:GetInt())
    -- Make it look like the icon is clickable (because it is)
    icon:SetCursor("hand")
    -- Passthrough clicks from the icon to the map button
    icon.OnMousePressed = function()
        icon_container.MapButton:OnMousePressed()
    end

    table.insert(self.Voters, icon_container)
end

function PANEL:Think()
    -- Make sure this doesn't get in the way of other stuff
    self:MoveToBack()
    self.Canvas:MoveToBack()

    for _, v in pairs(self.iconList:GetItems()) do
        v.NumVotes = 0
    end

    for _, v in pairs(self.Voters) do
        if not IsValid(v.Player) then
            v:Remove()
        else
            local votes = self.voteType == "gamemode" and GameVote.Votes or MapVote.Votes

            if not votes[v.Player:SteamID()] then
                v:Remove()
            else
                local bar = self:GetVoteButton(votes[v.Player:SteamID()])

                local row = math.floor(bar.NumVotes / 5)
                local column = bar.NumVotes % 5
                local layer = math.floor(row / 4)
                row = row - layer * 4;

                bar.NumVotes = bar.NumVotes + 1

                if IsValid(bar) then
                    local newPos = Vector(bar.x + column * 40, bar.y + row * 36, 0)
                    if not v.CurPos or v.CurPos ~= newPos then
                        v:MoveTo(newPos.x, newPos.y, 0.3)
                        v.CurPos = newPos
                        v.MapButton = bar
                    end
                end
            end
        end
    end

    local timeLeft = math.Round(math.Clamp(self.endTime - CurTime(), 0, math.huge))

    self.countDown:SetText(tostring(timeLeft or 0) .. " seconds")
    if timeLeft < 10 then
        self.countDown:SetTextColor(Color(255,64,64))
    end
    self.countDown:SizeToContents()
    self.countDown:CenterHorizontal()
end

function PANEL:SetVoteIcons(icons)
    local voteType = self.voteType
    self.iconList:Clear()

    local transCounter = 0
    for k, icon in ipairs(icons) do
        local panel = vgui.Create("DLabel", self.iconList)
        panel.ID = k
        panel.NumVotes = 0
        panel:SetSize(200, 200)
        panel:SetText("")
        panel:SetAlpha(0)
        panel:SetPaintBackgroundEnabled(false)
        panel:AlphaTo(255, 0.8, transCounter/40)
        transCounter = transCounter + 1

        function panel:PerformLayout()
            self:SetBGColor(0,150,0,255)
        end

        local button = vgui.Create("DImageButton", panel)
        button:SetImage(icon.material)

        -- If the panel is clicked, click the button instead
        function panel:OnMousePressed()
            button:OnMousePressed()
        end
        function button:OnMousePressed()
            net.Start(voteType == "gamemode" and "RAM_GameVoteUpdate" or "RAM_MapVoteUpdate")
            net.WriteUInt(Vote.UPDATE_VOTE, 3)
            net.WriteUInt(panel.ID, 32)
            net.SendToServer()
        end

        button:SetPos(2,2);
        button:SetSize(196, 196)

        local text = vgui.Create("DLabel", button)
        text:SetPos(0, 173)
        text:SetSize(196, 25)
        if icon.name == MapVote.RandomPlaceholder then
            text:SetText("Random Map")
        else
            text:SetText(icon.name)
        end
        text:SetContentAlignment(5)
        text:SetFont("RAM_VoteFont")
        text:SetPaintBackgroundEnabled(true)

        function text:PerformLayout()
            self:SetBGColor(0,0,0,220)
        end

        self.iconList:AddItem(panel)
    end
end

function PANEL:GetVoteButton(id)
    for _, v in pairs(self.iconList:GetItems()) do
        if v.ID == id then return v end
    end

    return false
end

function PANEL:Paint()
    Derma_DrawBackgroundBlur(self, self.startTime)
end

function PANEL:Flash(id)
    self:SetVisible(true)

    local bar = self:GetVoteButton(id)

    if (IsValid(bar)) then
        timer.Simple(0.0, function()
            bar:SetPaintBackgroundEnabled(true)
            surface.PlaySound("hl1/fvox/blip.wav")
        end)
        timer.Simple(0.2, function() bar:SetPaintBackgroundEnabled(false) end)
        timer.Simple(0.4, function()
            bar:SetPaintBackgroundEnabled(true)
            surface.PlaySound("hl1/fvox/blip.wav")
        end)
        timer.Simple(0.6, function() bar:SetPaintBackgroundEnabled(false) end)
        timer.Simple(0.8, function()
            bar:SetPaintBackgroundEnabled(true)
            surface.PlaySound("hl1/fvox/blip.wav")
        end)
        timer.Simple(1.0, function()
            bar:SetBGColor(255,0,255,255)
            bar:SetPaintBackgroundEnabled(true)
         end)
    end
end

derma.DefineControl("RAM_VoteScreen", "", PANEL, "DPanel")
-- This script controls the GUI for the light creation toolkit.

class("cLightBuilder")

function cLightBuilder:__init()
  self.window = Window.Create()
  self.window:SetSizeRel(Vector2(0.455, 0.24))
  self.window:SetPosition(Render.Size/2 - self.window:GetSize()/2)
  self.visible = false
  self.window:SetVisible(self.visible)
  self.window:SetTitle("LightBuilder")
  self.window:Subscribe("WindowClosed", self, self.Closed)
  
  self.tc = TabControl.Create(self.window)
  self.tc:SetDock(GwenPosition.Fill)
  self.tc.nl = self.tc:AddPage("New light")
  self.tc.ml = self.tc:AddPage("Existing lights") 
  
  self.colorpicker = HSVColorPicker.Create(self.tc.nl:GetPage())
  self.colorpicker:SetSizeRel(Vector2(70, 16))
  
  self.OptionsLabel = Label.Create(self.tc.nl:GetPage())
  self.OptionsLabel:SetText("Light properties")
  self.OptionsLabel:SetTextSize(16)
  self.OptionsLabel:SetPositionRel(Vector2(68, 1))
  self.OptionsLabel:SizeToContents()
  
  self.PowerLabel = Label.Create(self.tc.nl:GetPage())
  self.PowerLabel:SetText("Multiplier (brightness):")
  self.PowerLabel:SetPositionRel(Vector2(68, 4))
  self.PowerLabel:SizeToContents()

  
  self.PowerSlider = HorizontalSlider.Create(self.tc.nl:GetPage())
  self.PowerSlider:SetPositionRel(Vector2(68, 5))
  self.PowerSlider:SetRange(1, 25)
  self.PowerSlider:SetWidthRel(14)
  self.PowerSlider:SetHeightRel(2)
  self.PowerSlider:Subscribe("ValueChanged", self, self.UpdateLabels)

  self.PowerSliderLabel = Label.Create(self.tc.nl:GetPage())
  self.PowerSliderLabel:SetPositionRel(Vector2(82, 5.5))
  self.PowerSliderLabel:SetText(string.sub(tostring(self.PowerSlider:GetValue()), 1, 4))
  
  self.RadialLabel = Label.Create(self.tc.nl:GetPage())
  self.RadialLabel:SetPositionRel(Vector2(68, 7))
  self.RadialLabel:SetText("Radius:")
  
  self.RadialSlider = HorizontalSlider.Create(self.tc.nl:GetPage())
  self.RadialSlider:SetPositionRel(Vector2(68, 8))
  self.RadialSlider:SetRange(1, 30)
  self.RadialSlider:SetWidthRel(14)
  self.RadialSlider:SetHeightRel(2)
  self.RadialSlider:Subscribe("ValueChanged", self, self.UpdateLabels)
  
  self.RadialSliderLabel = Label.Create(self.tc.nl:GetPage())
  self.RadialSliderLabel:SetPositionRel(Vector2(82, 8.5))
  self.RadialSliderLabel:SetText(string.sub(tostring(self.PowerSlider:GetValue()), 1, 4))
  
  self.NameLabel = Label.Create(self.tc.nl:GetPage())
  self.NameLabel:SetPositionRel(Vector2(68, 10))
  self.NameLabel:SetText("Name:")
  
  self.NameTB = TextBox.Create(self.tc.nl:GetPage())
  self.NameTB:SetSizeRel(Vector2(14, 2))
  self.NameTB:SetPositionRel(Vector2(68, 11.65))
  self.NameTB:SetText("")
  
  self.CreateButton = Button.Create(self.tc.nl:GetPage())
  self.CreateButton:SetSizeRel(Vector2(14, 2))
  self.CreateButton:SetPositionRel(Vector2(68, 14))
  self.CreateButton:SetText("Create!")
  self.CreateButton:Subscribe("Up", self, self.Send)
  
  self.SliderLabels = {[self.PowerSlider] = self.PowerSliderLabel, [self.RadialSlider] = self.RadialSliderLabel}
  
  self.AllowUseOfMenu = true
  self.ScanRadius = 500
  
  
  self.ColumnWidth = self.window:GetSize().x/5.2
  
  self.lightlist = SortedList.Create(self.tc.ml:GetPage())
  self.lightlist:SetDock(GwenPosition.Top)
  self.lightlist:SetSizeRel(Vector2(10, 14.75))
  self.lightlist:AddColumn("Name", self.ColumnWidth)
  self.lightlist:AddColumn("Colour", self.ColumnWidth)
  self.lightlist:AddColumn("Brightness", self.ColumnWidth)
  self.lightlist:AddColumn("Radius", self.ColumnWidth)
  self.lightlist:AddColumn("Creator", self.ColumnWidth)
  
  self.rows = {}
  
  self.DeleteBox = CheckBox.Create(self.tc.nl:GetPage())
  self.DeleteBox:SetPositionRel(Vector2(68, 16.2))
  self.DeleteLabel = Label.Create(self.tc.nl:GetPage())
  self.DeleteLabel:SetPositionRel(Vector2(69.65, 16.45))
  self.DeleteLabel:SetText("Toggle deletion mode")
  self.DeleteLabel:SizeToContents()
  
  self.tc2 = TabControl.Create(self.tc.ml:GetPage())
  self.tc2:SetSizeRel(Vector2(84.5, 8))
  self.tc2:SetPositionRel(Vector2(0, 15))
  
  self.RefreshButton = Button.Create(self.tc2)
  self.RefreshButton:SetSizeRel(Vector2(0.2, 0.3))
  self.RefreshButton:SetPositionRel(Vector2(0.4, 0.1))
  self.RefreshButton:SetText("Refresh")
  self.RefreshButton:Subscribe("Press", self, self.Refresh)
  
  if self.AllowUseOfMenu then
    Events:Subscribe("KeyDown", self, self.Toggle)
  end
  
  Events:Subscribe("MouseDown", self, self.RemoveLightFromList)
  Events:Subscribe("MouseDown", self, self.Clone)
  Events:Subscribe("LocalPlayerInput", self, self.Input)
  Events:Subscribe("cLightCreated", self, self.ReceiveNewLight)
  Events:Subscribe("Render", self, self.Render)
  Events:Subscribe("KeyDown", self, self.Translate)
  
  
  TranslationAmount = 0.1
end

function cLightBuilder:ReceiveNewLight(args)
  if Vector3.Distance(args.pos, LocalPlayer:GetPosition()) < self.ScanRadius then
    self:AddLightToList(args.name, args.color, args.mult, args.radius, args.pos, args.playername)
  end
end



function cLightBuilder:Translate(args)
  if self.lightlist:GetSelectedRow() then
    if not self.lightlist:GetMultiSelect() then
      light = cLightCreator.activeLights[self.lightlist:GetSelectedRow():GetCellText(0)]
      if Vector3.Distance(light:GetPosition(), LocalPlayer:GetPosition()) < self.ScanRadius then
        if args.key == string.byte("o") then -- up (+y)
          pos = light:GetPosition()
          newPos = pos + Vector3(0, TranslationAmount, 0)
          Network:Send("RequestMoveLight", {["name"] = self.lightlist:GetSelectedRow():GetCellText(0), ["newpos"] = newPos})
        elseif args.key == string.byte("-") then -- down (-y)
          pos = light:GetPosition()
          newPos = pos - Vector3(0, TranslationAmount, 0)
          Network:Send("RequestMoveLight", {["name"] = self.lightlist:GetSelectedRow():GetCellText(0), ["newpos"] = newPos})
        elseif args.key == string.byte("%") then -- -x
          pos = light:GetPosition()
          newPos = pos - Vector3(TranslationAmount, 0, 0)
          Network:Send("RequestMoveLight", {["name"] = self.lightlist:GetSelectedRow():GetCellText(0), ["newpos"] = newPos})
        elseif args.key == string.byte("'") then -- +x
          pos = light:GetPosition()
          newPos = pos + Vector3(TranslationAmount, 0, 0)
          Network:Send("RequestMoveLight", {["name"] = self.lightlist:GetSelectedRow():GetCellText(0), ["newpos"] = newPos})
        elseif args.key == string.byte("(") then -- -z
          pos = light:GetPosition()
          newPos = pos - Vector3(0, 0, TranslationAmount)
          Network:Send("RequestMoveLight", {["name"] = self.lightlist:GetSelectedRow():GetCellText(0), ["newpos"] = newPos})
        elseif args.key == string.byte("&") then -- +z
          pos = light:GetPosition()
          newPos = pos + Vector3(0, 0, TranslationAmount)
          Network:Send("RequestMoveLight", {["name"] = self.lightlist:GetSelectedRow():GetCellText(0), ["newpos"] = newPos})
        end
      end
      
      if args.key == 107 and TranslationAmount < 32 then
        TranslationAmount = TranslationAmount * 2
      end
      
      if args.key == 109 and TranslationAmount > 0 then
        TranslationAmount = TranslationAmount / 2
      end
      
      if args.key == 12 then
        self.lightlist:UnselectAll()
      end
      
      
    end
  end
end

function cLightBuilder:Refresh()
  self.lightlist:Clear()
  self.rows = {}
  
  for i, v in pairs(cLightCreator.activeLights) do
    if Vector3.Distance(v:GetPosition(), LocalPlayer:GetPosition()) < self.ScanRadius then
      self:AddLightToList(i, v:GetColor(), v:GetMultiplier(), v:GetRadius(), v:GetPosition(), cLightCreator.creators[i])
    end
  end
end

function cLightBuilder:AddLightToList(name, colour, brightness, radius, position, playername)
  local newRow = self.lightlist:AddItem(name)
  local colourString = tostring(colour.r .. ", " .. colour.g .. ", " .. colour.b)
  newRow:SetCellText(1, colourString)
  newRow:SetCellText(2, tostring(brightness))
  newRow:SetCellText(3, tostring(radius))
  newRow:SetCellText(4, playername)
  table.insert(self.rows, newRow)
end

function cLightBuilder:Clone(args)
  if args.button == 3 then
    if self.lightlist:GetSelectedRow() and not self.lightlist:GetMultiSelect() then
      local light = cLightCreator.activeLights[self.lightlist:GetSelectedRow():GetCellText(0)]
      if Vector3.Distance(light:GetPosition(), LocalPlayer:GetPosition()) < self.ScanRadius then
        cLightCreator:GUICreate(light:GetColor(), light:GetMultiplier(), light:GetRadius(), light:GetPosition(), self.lightlist:GetSelectedRow():GetCellText(0) .. " (copy)")
      end
    end
  end
end

function cLightBuilder:RemoveLightFromList(args)
  if args.button == 2 then
    if self.DeleteBox:GetChecked() then
      if self.lightlist:GetSelectedRow() then
        if not self.lightlist:GetMultiSelect() then
          local light = cLightCreator.activeLights[self.lightlist:GetSelectedRow():GetCellText(0)]
          if Vector3.Distance(light:GetPosition(), LocalPlayer:GetPosition()) < self.ScanRadius then
            Network:Send("RequestRemoveLight", self.lightlist:GetSelectedRow():GetCellText(0))
            self.lightlist:RemoveItem(self.lightlist:GetSelectedRow())
            table.remove(self.rows, self.lightlist:GetSelectedRow())
          end
        end
      end
    end
  end
end

function cLightBuilder:Toggle(args)
  if args.key == string.byte("L") then
    self.visible = not self.visible
    self.window:SetVisible(self.visible)
    Mouse:SetVisible(self.visible)
    self.NameTB:SetText("")
  end
end

function cLightBuilder:Closed()
  self.visible = false
  Mouse:SetVisible(self.visible)
  self.NameTB:SetText("")
end

function cLightBuilder:Send()
  if string.len(self.NameTB:GetText()) > 1 then
    if not self.NameTB:GetText():match("%W") then
      if not cLightCreator.activeLights[self.NameTB:GetText()] then
        cLightCreator:GUICreate(self.colorpicker:GetColor(), self.PowerSlider:GetValue(), self.RadialSlider:GetValue(), LocalPlayer:GetPosition(), self.NameTB:GetText())
        self.CreateButton:SetText("Create!")
      else
        self.CreateButton:SetText("Name in use")
      end
    else
      self.CreateButton:SetText("Invalid characters")
    end
  else
    self.CreateButton:SetText("Name too short")
  end
end

function cLightBuilder:Render()
  if self.lightlist:GetSelectedRow() ~= nil then
    if cLightCreator.activeLights[self.lightlist:GetSelectedRow():GetCellText(0)] then
      if not self.lightlist:GetMultiSelect() then
        if self.lightlist:GetSelectedRow():GetCellText(0) ~= nil then
          position = cLightCreator.activeLights[self.lightlist:GetSelectedRow():GetCellText(0)]:GetPosition()
          -- x +- axis
          Render:DrawLine(position - Vector3(1, 0, 0), position + Vector3(1, 0, 0), Color(255, 0, 0))
          -- y axis
          Render:DrawLine(position - Vector3(0, 1, 0), position + Vector3(0, 1, 0), Color(0, 0, 255))
          -- z axis
          Render:DrawLine(position - Vector3(0, 0, 1), position + Vector3(0, 0, 1), Color(0, 255, 0))
        end
      end
    end
  end
  
  if self.visible then
    for i, v in ipairs(cLightCreator.activeLights) do
      Render:FillCircle(Render:WorldToScreen(v:GetPosition()), 20, Color.Red)
    end
  end
end
    
  

function cLightBuilder:UpdateLabels(sender)
  if sender == self.PowerSlider then
    self.PowerSliderLabel:SetText(string.sub(tostring(sender:GetValue()), 1, 4))
  elseif sender == self.RadialSlider then
    self.RadialSliderLabel:SetText(string.sub(tostring(sender:GetValue()), 1, 4))
  end
end

function cLightBuilder:Input()
  return not self.visible
end

cLightBuilder = cLightBuilder()



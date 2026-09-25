-- Ajuste tipográfico global y exclusivo para pantallas móviles.
return function(context)
    setfenv(1,context)

    local Controller={Connection=nil,Processed=setmetatable({},{__mode="k"})}

    local function mobileSize(size)
        if size>=19 then return math.max(13,math.floor(size*0.72+0.5)) end
        if size>=14 then return math.max(10,math.floor(size*0.76+0.5)) end
        return math.max(8,math.floor(size*0.82+0.5))
    end

    function Controller:Apply(object)
        if self.Processed[object] then return end
        if not (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) then return end
        self.Processed[object]=true

        if object.TextScaled then
            local constraint=object:FindFirstChildOfClass("UITextSizeConstraint")
            if not constraint then
                constraint=Instance.new("UITextSizeConstraint")
                constraint.Name="MobileTextConstraint"
                constraint.MinTextSize=7
                constraint.MaxTextSize=16
                constraint.Parent=object
            else
                constraint.MinTextSize=math.min(constraint.MinTextSize,7)
                constraint.MaxTextSize=math.min(constraint.MaxTextSize,16)
            end
        else
            object.TextSize=mobileSize(object.TextSize)
        end

        -- Los controles de una sola línea se recortan antes de invadir el control vecino.
        if (object:IsA("TextButton") or object:IsA("TextBox")) and not object.TextWrapped then
            pcall(function() object.TextTruncate=Enum.TextTruncate.AtEnd end)
        end
    end

    function Controller:Destroy()
        if self.Connection then self.Connection:Disconnect();self.Connection=nil end
        table.clear(self.Processed)
    end

    if isMobile and gui then
        for _,object in ipairs(gui:GetDescendants()) do Controller:Apply(object) end
        Controller.Connection=gui.DescendantAdded:Connect(function(object)
            task.defer(function()
                if object and object.Parent then Controller:Apply(object) end
            end)
        end)
    end

    MobileTypographyController=Controller
    return true
end
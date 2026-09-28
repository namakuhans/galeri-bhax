local a={show_window=true,item_id=1348,delay=1}
local b={running=false}

function c()
if not a.show_window then return end
local d,e=ImGui.Begin("Item Finder",a.show_window)
a.show_window=e
if not d then ImGui.End() return end

ImGui.Text("Item Finder")

local f,g=ImGui.InputInt("Item ID",a.item_id)
if f then a.item_id=g end

f,g=ImGui.InputInt("Delay (ms)",a.delay)
if f then a.delay=g end

ImGui.Separator()

if not b.running then
if ImGui.Button("START",ImVec2(120,30)) then
b.running=true
LogToConsole("`2Item Search STARTED")
end
else
if ImGui.Button("STOP",ImVec2(120,30)) then
b.running=false
LogToConsole("`4Item Search STOPPED")
end
end

if b.running then
ImGui.Text("Status: RUNNING")
ImGui.Text("Searching ID: "..tostring(a.item_id))
else
ImGui.Text("Status: STOPPED")
end

ImGui.End()
end

AddHook("OnDraw","ItemSearchUI",c)

AddHook("onvariant","HideItemFinder",function(v)
if v[0]=="OnDialogRequest" then
local d=v[1] or ""
if d:find("Item Finder") or d:find("item_search") then
return true
end
end
return false
end)

local function h()
while true do
if b.running then
local i=a.item_id
SendPacket(2,"action|dialog_return\n"..
"dialog_name|item_search\n"..
i.."|1")
Sleep(a.delay)
else
Sleep(100)
end
end
end

h()
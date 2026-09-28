local a={show_window=true,item_id=1348,delay=1,tile_start="0,0",tile_end="0,0"}
local b={running=false,reached_start=false}

-- Enable ModFly when script is executed
if ChangeValue then
pcall(ChangeValue, "[C] ModFly", true)
end

-- Check if ImGui is available / enabled
if type(ImGui) ~= "table" then
SendVariantList({
[0] = "OnTextOverlay",
[1] = "`4Please enable ImGui in Bothax menu!"
})
LogToConsole("`4Please enable ImGui in Bothax menu!")
end

local function parse_coords(str)
if not str then return 0, 0 end
local x, y = str:match("(%-?%d+)%s*,%s*(%-?%d+)")
if x and y then
return tonumber(x), tonumber(y)
end
return 0, 0
end

local function movement_thread()
b.reached_start = false
local startX, startY = parse_coords(a.tile_start)
local endX, endY = parse_coords(a.tile_end)
local dirX = 1

while b.running do
local local_plr = GetLocal()
if local_plr and local_plr.pos then
local curX = local_plr.pos.x // 32
local curY = local_plr.pos.y // 32

if not b.reached_start then
if curX == startX and curY == startY then
b.reached_start = true
local minX, maxX
if startX == endX then
minX = 0
local w = GetWorld()
maxX = (w and w.width and w.width > 0) and (w.width - 1) or 99
else
minX = math.min(startX, endX)
maxX = math.max(startX, endX)
end

if startX > endX then
dirX = -1
else
dirX = 1
end
else
local nextX = curX
local nextY = curY

if curX < startX then
nextX = math.min(startX, curX + 3)
elseif curX > startX then
nextX = math.max(startX, curX - 3)
end

if curY < startY then
nextY = math.min(startY, curY + 3)
elseif curY > startY then
nextY = math.max(startY, curY - 3)
end

FindPath(nextX, nextY)
Sleep(300)
end
else
if curX == endX and curY == endY then
Sleep(500)
SendVariantList({
[0] = "OnTextOverlay",
[1] = "`2Item Search Completed!"
})
LogToConsole("`2Item Search Completed!")
b.running = false
b.reached_start = false
break
else
local minX, maxX
if startX == endX then
minX = 0
local w = GetWorld()
maxX = (w and w.width and w.width > 0) and (w.width - 1) or 99
else
minX = math.min(startX, endX)
maxX = math.max(startX, endX)
end

local yStep = (startY <= endY) and 1 or -1
local nextX = curX
local nextY = curY

local targetX = curX + dirX
if targetX >= minX and targetX <= maxX then
nextX = targetX
nextY = curY
else
if curY ~= endY then
nextX = curX
nextY = curY + yStep
dirX = -dirX
else
if curX < endX then
nextX = curX + 1
elseif curX > endX then
nextX = curX - 1
end
end
end

FindPath(nextX, nextY)
Sleep(5000)
end
end
else
Sleep(100)
end
end
b.reached_start = false
end

function c()
if type(ImGui) ~= "table" or not a.show_window then return end
local d,e=ImGui.Begin("Item Finder",a.show_window)
a.show_window=e
if not d then ImGui.End() return end

ImGui.Text("Item Finder")
ImGui.TextWrapped("Pakan Cuma bisa skidding :(")
ImGui.Separator()

local f,g=ImGui.InputInt("Item ID",a.item_id)
if f then a.item_id=g end

f,g=ImGui.InputInt("Delay (ms)",a.delay)
if f then a.delay=g end

f,g=ImGui.InputText("Tile Start",a.tile_start,256)
if f and g then a.tile_start=g end

f,g=ImGui.InputText("Tile End",a.tile_end,256)
if f and g then a.tile_end=g end

ImGui.Separator()

if not b.running then
if ImGui.Button("START",ImVec2(120,30)) then
b.running=true
b.reached_start=false
LogToConsole("`2Item Search STARTED")
RunThread(movement_thread)
end
else
if ImGui.Button("STOP",ImVec2(120,30)) then
b.running=false
b.reached_start=false
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
if b.running and b.reached_start then
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
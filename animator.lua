local LWSignal = {}
LWSignal.__index = LWSignal
function LWSignal.new()
	return setmetatable({
		bindable = Instance.new("BindableEvent"),
		functions = {}
	},LWSignal)
end
function LWSignal:Fire(...)
	local args = {...}
	self.bindable:Fire(unpack(args))
end
function LWSignal:fire(...)
	return self:Fire(...)
end
function LWSignal:Wait(...)
	return self.bindable.Event:Wait()
end
function LWSignal:Connect(func)
	return self.bindable.Event:Connect(func)
end
function LWSignal:wait(...)
	return self:Wait(...)
end
function LWSignal:connect(func)
	return self:Connect(func)
end
local defaultlerp = -.02
local defaultspeed = 0
local xrt = 0
function spairs(t, order)
	local keys = {}
	for k in pairs(t) do 
		keys[#keys+1] = k 
	end 
	if order then 
		table.sort(keys, function(a,b) 
			return order(t, a, b) 
		end) 
	else 
		table.sort(keys)
	end 
	local i = 0 
	return function() 
		i = i + 1 
		if keys[i] then 
			return keys[i], t[keys[i]]
		end 
	end 
end
--
local main = {}
main.__index = main
function main.new(char,keyframes)
	xrt = xrt + 1
	return setmetatable({
		tweens = {},
		paused = false,
		canceled = false,
		char = char,
		c0 = {},
		lasttime = defaultlerp,
		kfs = keyframes,
		lasttick = xrt,
		transform = {}
	},main)
end
function main:findJoint(name)
	for i,v in pairs(self.char:GetDescendants()) do
		if v:IsA("Weld") and v.Name == name.."Weld"..tostring(self.lasttick) then
			return v
		end
	end
end
function main:cwait(n)
	n = typeof(n) == 'number' and n or 0

	local start = os.clock()
	local spent = 0
	while true do
		repeat 
			if self.canceled then break end
			if self.paused == false then
				spent += game:service'RunService'.Heartbeat:Wait()
			else
				game:service'RunService'.Heartbeat:Wait()
			end
		until spent >= n

		spent = os.clock() - start
		if spent >= n then
			return spent, os.clock()
		end
	end
end
function main:recurse3(i,hi)
	local valu
	if typeof(hi) == "table" then
		if hi[i] and hi[i].CFrame then
			valu = hi[i].CFrame
		end
	end
	if typeof(hi) == "table" then
		for i_,v in pairs(hi) do
			if valu then
				break
			end
			spawn(function()
				local vx = self:recurse3(i,v)
				if vx then
					valu = vx
				end
			end)
			if valu then
				break
			end
		end
	end
	return valu
end
function main:recurse2(i,lasttable,hi,timer,v0)
	local joint = self.joi[i]
	if typeof(hi) == "table" then
		if joint and hi.Style and hi.Direction then
			local style = hi.Style or "Linear"
			local dir = hi.Direction or "In"
			local cf = hi.CFrame
			if not cf then
				for index,value in spairs(self.kfs) do
					if typeof(i) == 'number' and typeof(index) == 'number' and i < index then
						cf = self:recurse3(i,hi)
						if cf then
							break
						end
					end
				end
			end
			hi.CFrame = cf
			if cf and style and dir then
				hi.CFrame = cf
				local ctimer = timer
				local lt = self.lasttime
				if style == "Constant" then
					ctimer = 0
					lt = 0
					style = "Linear"
				end
				if hi.CFrame then
					cf = hi.CFrame
					local tween = game:GetService("TweenService"):Create(joint,TweenInfo.new((ctimer-defaultspeed)-(lt+.005),Enum.EasingStyle[style],Enum.EasingDirection[dir]),{C0 = self.c0[joint]*cf})
					table.insert(self.tweens,tween)
					tween:Play()
				end
			end
		end
		if joint and (not hi.CFrame) then
			local style = hi.Style or "Linear"
			local ctimer = timer
			local lt = self.lasttime
			if style == "Constant" then
				ctimer = 0
				lt = 0
				style = "Linear"
			end
			local tween = game:GetService("TweenService"):Create(joint,TweenInfo.new((ctimer-defaultspeed)-(lt+.005),Enum.EasingStyle['Linear'],Enum.EasingDirection['In']),{C0 = self.c0[joint]})
			table.insert(self.tweens,tween)
			tween:Play()
		end
	end
	if typeof(hi) == "table" then
		for i_,v in pairs(hi) do
			self:recurse2(i_,hi,v,timer)
		end
	end
end
--
function jnew(char,our)
	task.wait(1/30)
	local playing = true
	local lasttime = 0
	local destroying = false
	local tbl = {
		Properties = {
			Looping = false,
		},
		Keyframes = our
	}
	if our.Keyframes == nil and our.Properties == nil then
		our = tbl
	end
	local m = main.new(char,our.Keyframes)
	local tix = m.lasttick+1
	local anim = our
	local keyframes = anim.Keyframes
	local props = anim.Properties
	local stopped = LWSignal.new()
	local kfreahc = LWSignal.new()
	local kfr = function(_,key)
		return {
			Connect = function(_,func)
				kfreahc:Connect(function(a,b)
					if a == key then
						func(b)
					end
				end)
			end
		}
	end
	local allowed = {}
	local lra = tick()
	m.joi = {}
	local function reset()
		for i,v in pairs(m.joi) do
			game:GetService("TweenService"):Create(v,TweenInfo.new(defaultlerp,Enum.EasingStyle.Linear),{C0 = m.c0[v]}):Play()
		end
	end
	local function enable(t)
		for i,v in pairs(m.joi) do
			v.Enabled = t
		end
	end
	local function recurse(i,o)
		if table.find(allowed,i) == nil and typeof(i) == 'string' and typeof(o) == 'table' and o.CFrame then
			table.insert(allowed,i)
		end
		if typeof(o) == 'table' then
			for i_,v in pairs(o) do
				recurse(i_,v)
			end
		end
	end
	for i,v in pairs(anim) do
		recurse(i,v)
	end
	for i,v in pairs(char:GetDescendants()) do
		if v:IsA("Motor6D") and table.find(allowed,v.Part1.Name) then
			local weld = Instance.new("Weld")
			weld.Name = v.Part1.Name.."Weld"
			weld.Part0 = v.Part0
			weld.Part1 = v.Part1
			weld.C0 = v.C0
			weld.C1 = v.C1
			m.c0[weld] = v.C0
			weld.Parent = v.Parent
			weld.Enabled = false
			m.joi[v.Part1.Name] = weld
		end
	end
	local _con
	local marked = {}
	_con = game:GetService("RunService").Heartbeat:Connect(function()
		if destroying then
			_con:Disconnect()
		end
		if  props.Markers then
			for i,v in pairs(props.Markers) do
				if i < tick()-lra and table.find(marked,i) == nil then
					table.insert(marked,i)
					for _,__ in pairs(v) do
						kfreahc:Fire(_,__)
					end
				end
			end
		end
		if our and not playing then
			local lastanim = anim
			playing = true
			lra = tick()
			marked = {}
			for i,v in spairs(keyframes) do
				if m.canceled then break end
				if m.paused then repeat task.wait() until m.paused == false end
				m:recurse2(i,v,v,i)
				if #m.tweens ~= 0 then
					m.tweens[#m.tweens].Completed:wait()
				else
					task.wait()
				end
				m.lasttime = i
				if m.canceled then break end
				if m.paused then repeat task.wait() until m.paused == false end
			end
			stopped:Fire()
			m.lasttime = defaultlerp
			if props.Looping and not m.canceled then
				playing = false
				m.lasttime = 0
			end
		end
	end)
	return {
		Stopped = stopped,
		con = _con,
		Play = function()
			playing = false
			m.lasttime = -.02
			m.canceled = false
			enable(true)
		end,
		enable = enable,
		Pause = function()
			for i,v in pairs(m.tweens) do
				v:Pause()
			end
			m.paused = true
		end,
		Resume = function()
			for i,v in pairs(m.tweens) do
				v:Play()
			end
			m.paused = false
		end,
		SetC0 = function(_,t)
			for i,v in pairs(m.joi) do
				for i_,v_ in pairs(t) do
					if v.Name == v_.Name then
						v.C0 = v_.C0
					end
				end
			end
		end,
		Stop = function()
			for i,v in pairs(m.tweens) do
				v:Cancel()
				m.tweens[i] = nil
			end
			m.canceled = true
			enable(false)
		end,
		Reset = reset,
		GetJoints = function()
			return m.joi
		end,
		GetMarkerReachedSignal = kfr,
	}
end
function load(character,keyframe)
	return jnew(character,keyframe)
end
return load

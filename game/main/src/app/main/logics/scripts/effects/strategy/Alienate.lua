--[[
	策略 离间计
]]

-- 显示延时
local C_SHOW_DELAY = 0.8

-- 策略命中
local C_ROLESTY_HIT = "ROLESTY_HIT"

local Alienate = class("Alienate", import("._StrategyBase"))

-- 构造函数
function Alienate:ctor(config)
	if config then
		table.merge(self,config)
	end
end

-- 执行函数
function Alienate:execute(...) 
	if self.scene == "BATTLE" then
		self:executeInBattle(...)
	elseif self.scene == "MAP" then
		self:executeInMap(...)
	end
end

-- 战场上
function Alienate:executeInBattle(onComplete)
	self:effectTargetsInBattle(onComplete,table.filter_array(self.targets,function(v) return not v:isDead() end),
		function (onComplete__,target,isgatking,msgui,extvars,showconfig)
			if target:isDead() then
				if onComplete__ then onComplete__() end
			else

				-- 统计
				local function doStatistics()
					self.role:doStatistics("styuse")
					target:doStatistics("styhit")
					target:doStatistics("lostctrl")
					target:doStatistics("betray")
				end

				local ishit = formulaMgr:calculate(C_ROLESTY_HIT,{
					attrmax = gameMgr:getAttributeMax(),
				},{
					intellect = self.role:getEntity():getIntellect(),
				},{
					intellect = target:getEntity():getIntellect(),
				})
				local bid = self.param.bid
				local param = buffMgr:getParam(bid)
				if isgatking then
					local function useEnd()
						if onComplete__ then onComplete__(true) end
					end
					if ishit then
						target:getEntity():addBuff(bid,{
							rounds = math.random(param.roundmin,param.roundmax)
						},function ()
							doStatistics()
							useEnd()
						end)
					else
						useEnd()
					end
				else
					local msgwin = uiMgr:openUI(msgui)
					msgwin:clearMessage()

					local function useEnd()
						performWithDelay(msgwin,function ()
							uiMgr:closeUI(msgui)
							if onComplete__ then onComplete__(true) end
						end,C_SHOW_DELAY)
					end

					local function useResult()
						if ishit then
							target:getEntity():addBuff(bid,{
								rounds = math.random(param.roundmin,param.roundmax)
							},function ()
								doStatistics()
								msgwin:appendMessage({
									texts = gameMgr:getStrings("SKILL_ALIENATE",{
										target = target:getEntity():getName()
									}),
									showconfig = showconfig,
									onComplete = useEnd,
								})
							end)
						else
							useEnd()
						end
					end

					msgwin:appendMessage({
						texts = gameMgr:getStrings("USE_SKILL",extvars),
						showconfig = showconfig,
						onComplete = function ()
							performWithDelay(msgwin,function ()
								msgwin:appendMessage({
									texts = gameMgr:getStrings(ishit and "SUCCESS" or "FAILURE"),
									showconfig = showconfig,
									onComplete = useResult,
								})
							end,C_SHOW_DELAY)
						end
					})
				end
			end
		end)
end

-- 地图上
function Alienate:executeInMap(onComplete)
	self:invalidInMap(onComplete)
end

return Alienate

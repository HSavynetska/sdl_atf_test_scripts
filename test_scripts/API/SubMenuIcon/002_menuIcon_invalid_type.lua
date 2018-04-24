---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0085-submenu-icon.md
-- User story:TBD
-- Use case:TBD
--
-- Requirement summary:
-- TBD
--
-- Description:
-- In case:
-- 1) 
-- SDL does:
-- 1) 
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/SubMenuIcon/commonSubMenuIcon')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
	menuID = 1000,
	position = 500,
	menuName ="SubMenupositive",
	menuIcon = {
		imageType = "DYNAMIC",
		value = "action.png"
	}
}

local function addSubMenu_INVALID_DATA(params)
  local mobSession = common.getMobileSession()
  local cid = mobSession:SendRPC("AddSubMenu", params)
  EXPECT_HMICALL("UI.AddSubMenu", params.requestUiParams)
  :Times(0)
  mobSession:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU, { 1 })
runner.Step("Activate Application", common.activateApp, { 1 })
runner.Step("Upload icon file", common.putFile)

runner.Title("Test")
runner.Step("AddSubMenu_INVALID_DATA", addSubMenu_INVALID_DATA, {requestParams})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

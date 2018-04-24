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
		value = "icon.png"
	}
}

local responseUiParams = {
	menuID = requestParams.menuID,
	menuParams = {
		position = requestParams.position,
		menuName = requestParams.menuName,
		menuIcon = requestParams.menuIcon
	}
}

local allParams = {
	requestParams = requestParams,
	responseUiParams = responseUiParams
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU, { 1 })
runner.Step("Activate Application", common.activateApp, { 1 })
runner.Step("Upload icon file", common.putFile)

runner.Title("Test")
runner.Step("AddSubMenu ", common.AddSubMenu, {allParams, 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

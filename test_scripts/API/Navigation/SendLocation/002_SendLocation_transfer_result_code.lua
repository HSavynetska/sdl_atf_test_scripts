---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- SendLocation with address, longitudeDegrees, latitudeDegrees, deliveryMode and other parameters
--
-- Description:
-- App sends SendLocation will all available parameters.

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered on SDL

-- Steps:
-- appID requests SendLocation with address, longitudeDegrees, latitudeDegrees, deliveryMode and other parameters

-- Expected:

-- SDL validates parameters of the request
-- SDL checks if Navi interface is available on HMI
-- SDL checks if SendLocation is allowed by Policies
-- SDL checks if deliveryMode is allowed by Policies
-- SDL transfers the request with allowed parameters to HMI
-- SDL receives response from HMI
-- SDL transfers response to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSendLocation = require('test_scripts/API/Navigation/commonSendLocation')

--[[ Local Variables ]]
local requestParams = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1
}

--[[ Local Functions ]]
local function sendLocationSuccess(params, resultCodeValue, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    EXPECT_HMICALL("Navigation.SendLocation", params)
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, resultCodeValue, {})
    end)

    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = resultCodeValue })
end

local function sendLocationFailure(params, resultCodeValue, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    EXPECT_HMICALL("Navigation.SendLocation", params)
    :Do(function(_,data)
        self.hmiConnection:SendError(data.id, data.method, resultCodeValue, resultCodeValue)
    end)

    self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = resultCodeValue })
    :ValidIf (function(_,data)
        if data.payload.info then
            return true
        else
            return false, "SDL doesn't resend info parameter to mobile App."
        end
    end)
end

local function sendLocationUnexpectedResponseFromHMI(params, resultCodeValue, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    EXPECT_HMICALL("Navigation.SendLocation", params)
    :Do(function(_,data)
        self.hmiConnection:SendError(data.id, data.method, resultCodeValue, resultCodeValue)
    end)

    self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate App", commonSendLocation.activateApp)

runner.Title("Test positive result codes")
for _, resultCodeValue in pairs(commonSendLocation.successResultCodes) do
    runner.Step("SendLocation - " .. resultCodeValue, sendLocationSuccess, {requestParams, resultCodeValue})
end

runner.Title("Test negative result codes")
for _, resultCodeValue in pairs(commonSendLocation.failureResultCodes) do
    runner.Step("SendLocation - " .. resultCodeValue, sendLocationFailure, {requestParams, resultCodeValue})
end

runner.Title("Test not applicable for SendLocation result codes")
for _, resultCodeValue in pairs(commonSendLocation.unexpectedResultCodes) do
    runner.Step("SendLocation - " .. resultCodeValue,
        sendLocationUnexpectedResponseFromHMI,
        {requestParams, resultCodeValue})
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)

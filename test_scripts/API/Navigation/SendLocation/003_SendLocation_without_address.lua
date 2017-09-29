---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/24
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/TRS/embedded_navi/SendLocation_TRS.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- App requests SendLocation without address and with longitudeDegrees, latitudeDegrees, deliveryMode 
-- and other valid and allowed parameters
--
-- Description:
-- SDL transfers the SendLocation requests without address to HMI

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
local commonSendLocation = require('test_scripts/API/SendLocation/commonSendLocation')

--[[ Local Variables ]]
local request_params = {
    longitudeDegrees = 1.1,
    latitudeDegrees = 1.1,
    timeStamp = {
        millisecond = 0,
        second = 40,
        minute = 30,
        hour = 14,
        day = 25,
        month = 5,
        year = 2017,
        tz_hour = 5,
        tz_minute = 30
    },
    locationName = "location Name",
    locationDescription = "location Description",
    phoneNumber = "phone Number",
    deliveryMode = "PROMPT",
    locationImage = 
    { 
        value = "icon.png",
        imageType = "DYNAMIC",
    }
}

--[[ Local Functions ]]
local function sendLocation(params, self)
    local cid = self.mobileSession1:SendRPC("SendLocation", params)

    params.appID = commonSendLocation.getHMIAppId()
    local deviceID = commonSendLocation.getDeviceMAC()
    params.locationImage.value = commonSendLocation.getPathToSDL() .. "storage/"
        .. commonSendLocation.getMobileAppId(1) .. "_" .. deviceID .. "/icon.png"


    EXPECT_HMICALL("Navigation.SendLocation", params)
    :Do(function(_,data)
        --hmi side: sending Navigation.SendLocation response
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

    self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
    :ValidIf (function(_,data)
        if data.payload.info then
            print("SDL sent redundant info parameter to mobile App ")
            return false
        else 
            return true
        end
    end)
end

local function put_file(self)
    local CorIdPutFile = self.mobileSession1:SendRPC(
      "PutFile",
      {syncFileName = "icon.png", fileType = "GRAPHIC_PNG", persistentFile = false, systemFile = false},
      "files/icon.png")

    self.mobileSession1:ExpectResponse(CorIdPutFile, { success = true, resultCode = "SUCCESS"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSendLocation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSendLocation.start)
runner.Step("RAI, PTU", commonSendLocation.registerApplicationWithPTU)
runner.Step("Activate App", commonSendLocation.activateApp)
runner.Step("Upload file", put_file)

runner.Title("Test")
runner.Step("SendLocation without address parameter", sendLocation, {request_params})

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSendLocation.postconditions)

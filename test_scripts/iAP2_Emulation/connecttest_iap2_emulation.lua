local module = require("user_modules/dummy_connecttest")

local SDL = require("SDL")
local policyTable = require("user_modules/shared_testcases/testCasesForPolicyTable")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local expectations = require("expectations")
local mobile = require("mobile_connection")
local mobile_session = require("mobile_session")
local tcp = require("tcp_connection")
local file_connection = require("file_connection")

local Expectation = expectations.Expectation

--[[ IN ORDER TO USE IAP2 EMULATION IN SDL IT MUST BE BUILT ON WITH BUILD_TESTS = ON ]]
iAP2_BT_DeviceID = "127.0.0.1"
iAP2_BT_Port = 23456
iAP2_BT_out = "iap2bt.out"
iAP2_BT_Type = "BLUETOOTH"

-- Device IDs must be the same in order to trigger switching logic
iAP2_USB_DeviceID = iAP2_BT_DeviceID
iAP2_USB_Port = 34567
iAP2_USB_out = "iap2usb.out"
iAP2_USB_Type = "USB_IOS"


-- =========================================================================
-- =========================================================================
-- ========================= AUTO-RUN TEST BASE EXTENTIONS =================
-- =========================================================================
-- =========================================================================

function module:RunSDL()
    print("Setting preloaded policy table")
    policyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/sdl_preloaded_pt_all_allowed.json")
    print("Setting .ini values")
    commonFunctions:SetValuesInIniFile("AppTransportChangeTimer%s-=%s-[%d]-%s-\n", "AppTransportChangeTimer", "5000")
    self:runSDL()
end

function module:InitHMI()
    critical(true)
    self:initHMI()
end

function module:InitHMI_onReady()
    critical(true)
    self:initHMI_onReady()
end

-- =========================================================================
-- =========================================================================
-- ========================= TEST BASE EXTENTIONS ==========================
-- =========================================================================
-- =========================================================================

function module:connectMobile(device, exitOnDisconnect)
    EXPECT_EVENT(events.disconnectedEvent, "Disconnected", device):Pin():Times(AnyNumber()):Do(
        function()
            print("Device disconnected: " .. device.connection.filename)
            if exitOnDisconnect then
                quit(exit_codes.aborted)
            end
        end
    )
    device:Connect()
    return EXPECT_EVENT(events.connectedEvent, "Connected", device)
end

function module:startSession(session)
    session:Start()
    EXPECT_HMICALL("BasicCommunication.UpdateAppList"):Do(
        function(_, data)
            self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
            self.applications = {}
            for _, app in pairs(data.params.applications) do
                self.applications[app.appName] = app.appID
            end
        end
    )
end

function module:waitForAllEvents(milliseconds)
    local event = events.Event()
    event.matches = function(self, e)
        return self == e
    end
    EXPECT_HMIEVENT(event, "Delayed event"):Timeout(milliseconds + 1000)
    local function toRun()
        event_dispatcher:RaiseEvent(self.hmiConnection, event)
    end
    RUN_AFTER(toRun, milliseconds)
end


-- =========================================================================
-- =========================================================================
-- ========================= GLOBAL DEFINITIONS ============================
-- =========================================================================
-- =========================================================================

function EXPECT_NOTIFICATION(func, session, ...)
    local args = table.pack(...)
    local args_count = 1
    if #args > 0 then
        local arguments = {}
        if #args > 1 then
            for args_count = 1, #args do
                if (type(args[args_count])) == "table" then
                    table.insert(arguments, args[args_count])
                end
            end
        else
            arguments = args
        end
        return session:ExpectNotification(func, arguments)
    end
    return session:ExpectNotification(func, args)
end

function EXPECT_RESPONSE(correlationId, session, ...)
    xmlReporter.AddMessage(debug.getinfo(1, "n").name, "EXPECTED_RESULT", ...)
    return session:ExpectResponse(correlationId, ...)
end

function EXPECT_EVENT(event, name, device)
    local ret = Expectation(name, device)
    ret.event = event
    event_dispatcher:AddEvent(device, event, ret)
    module:AddExpectation(ret)
    return ret
end

function RAISE_EVENT(event, data, eventName, device)
    event_str = "noname"
    if eventName then
        event_str = eventName
    end
    xmlReporter.AddMessage(debug.getinfo(1, "n").name, event_str)
    event_dispatcher:RaiseEvent(device, data)
end

function StopSDLAndRestorePT()
    policyTable:Restore_preloaded_pt()
    event_dispatcher:ClearEvents()
    Test.expectations_list:Clear()
    return SDL:StopSDL()
end


function createIAP2Device(deviceID, devicePort, deviceOut)
    local iap2Connection = tcp.Connection(deviceID, devicePort)
    local fileConnection = file_connection.FileConnection(deviceOut, iap2Connection)
    local iap2Device = mobile.MobileConnection(fileConnection)

    event_dispatcher:AddConnection(iap2Device)

    return iap2Device
end

return module

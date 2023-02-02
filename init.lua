---------------------------------------------------------------------------------------------------
-- TIMEOUT OBJECT DEFINITION
---------------------------------------------------------------------------------------------------
local Timeout = {
    startTime = os.time(),
    timeoutInSeconds = 0
}
function Timeout:reached()
    return (hs.timer.seconds(os.time()) - hs.timer.seconds(self.startTime)) > self.timeoutInSeconds
end

function Timeout:new(t)
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

---------------------------------------------------------------------------------------------------
-- PACKAGE VARIABLE
---------------------------------------------------------------------------------------------------
local doCheck=true
local isCheckRunning=false
local doShowInfo=false
local lookuptable = {
    [hs.application.watcher.activated] = "activated",
    [hs.application.watcher.deactivated] = "deactivated",
    [hs.application.watcher.hidden] = "hidden",
    [hs.application.watcher.launched] = "launched",
    [hs.application.watcher.launching] = "launching",
    [hs.application.watcher.terminated] = "terminated",
    [hs.application.watcher.unhidden] = "unhidden"
  }

---------------------------------------------------------------------------------------------------
-- RUN FUNCTION ON GIVEN APPS
---------------------------------------------------------------------------------------------------
local function onRunningApps(app, eventType, apps, fn)
    if not doCheck or isCheckRunning then
        doCheck=true
        return
    end
    isCheckRunning=true
    if eventType ~= hs.application.watcher.launching
    and eventType ~= hs.application.watcher.activated then
        isCheckRunning=false
        return
    end
    local runningApps={}
    for i, a in ipairs(apps) do  
        local runningApp = hs.application.find(a)
        if runningApp then
            table.insert(runningApps, runningApp)
        end
    end
    if #runningApps > 0 then
        fn(app, runningApps)
    else
        isCheckRunning=false
    end
end

---------------------------------------------------------------------------------------------------
-- OBJECT APP.NAME TO STRING WITH SEPARATOR
---------------------------------------------------------------------------------------------------
local function appsToString(apps, separator)
    local appNames
    for i, app in ipairs(apps) do
        if appNames then
            appNames = appNames .. ";" .. app:name()
        else
            appNames = app:name()
        end
    end
    return string.gsub(appNames, "%;", separator)
end

---------------------------------------------------------------------------------------------------
-- RETURNS TABLE WITH RUNNING APPS
---------------------------------------------------------------------------------------------------
local function getRunningApps(apps)
    apps = apps or {}
    local runningApps = {}
    if #apps == 0 then
        return apps
    end
    for i, a in ipairs(apps) do
        if a:isRunning() then
            table.insert(runningApps, a)
        end
    end
    return runningApps
end

---------------------------------------------------------------------------------------------------
-- ACTIVATES FIRST APP FROM TABLE
---------------------------------------------------------------------------------------------------
local function activateFirstApp(apps)
    apps = apps or {}
    for i, app in ipairs(apps) do
        if app:isRunning() then
            doCheck=false
            app:activate()
            break
        end
    end
end

---------------------------------------------------------------------------------------------------
-- CLOSES APPS
---------------------------------------------------------------------------------------------------
local function closeApps(mainApp, apps)
    if #apps == 0 then
        isCheckRunning=false
        return
    end
    local runningApps = apps
    local appNames = appsToString(apps, "\n")
    local button=hs.dialog.blockAlert("Application(s) are running", appNames .."\n\nTo exit applications press 'Ok'.", "Ok", "Cancel", "NSCriticalAlertStyle")
    if button == "Ok" then
        for i, app in ipairs(apps) do
            app:kill()
        end
        local timeout = Timeout:new({startTime=os.time(), timeoutInSeconds=10})
        local function predicate()
            isCheckRunning=true
            runningApps = getRunningApps(runningApps)
            activateFirstApp(runningApps)
            return #runningApps == 0 or timeout:reached()
        end
        local function action()
            if #runningApps == 0 then
                hs.alert.show("All applications closed")
            else
                appNames = appsToString(runningApps, "\n")
                hs.dialog.blockAlert("Application(s) are still running", appNames)
                activateFirstApp(runningApps)
            end
            isCheckRunning=false
        end
        hs.timer.waitUntil(predicate, action)
    else
        doCheck=false
        mainApp:activate()
        isCheckRunning=false
    end
end

---------------------------------------------------------------------------------------------------
-- SHOWS WARNING: APPS ARE RUNNING
---------------------------------------------------------------------------------------------------
local function showWarning(mainApp, apps)
    if #apps == 0 then
        isCheckRunning=false
        return
    end
    local appNames = appsToString(apps, "\n")
    hs.dialog.blockAlert("Application(s) are running", appNames)
    doCheck=false
    mainApp:activate()
    isCheckRunning=false
end

---------------------------------------------------------------------------------------------------
-- APPLICATION WATCHER
---------------------------------------------------------------------------------------------------
local function applicationWatcher(appName, eventType, app)
    if doShowInfo then
        hs.alert.show("appName: ".. appName.. "\neventType: ".. lookuptable[eventType] .. "\nbundleID: ".. app:bundleID())
        print("\nappName: ", appName, "\neventType: ", lookuptable[eventType], "\nbundleID: ", app:bundleID())
    end
    -- com.citrix.receiver.nomas
    -- com.citrix.receiver.icaviewer.mac
    if      appName == "Citrix Viewer" then
        onRunningApps(app, eventType, {"ch.protonvpn.mac","com.strongvpn.StrongVPN2-Client"}, closeApps)
    elseif  appName == "Citrix Workspace" then
        onRunningApps(app, eventType, {"ch.protonvpn.mac","com.strongvpn.StrongVPN2-Client"}, closeApps)
    elseif  appName == "StrongVPN" then
        onRunningApps(app, eventType, {"com.citrix.receiver.icaviewer.mac"}, showWarning)
    elseif  appName == "ProtonVPN" then
        onRunningApps(app, eventType, {"com.citrix.receiver.icaviewer.mac"}, showWarning)
    end
end
_G.appWatcher = hs.application.watcher.new(applicationWatcher):start()

---------------------------------------------------------------------------------------------------
-- RELOAD CONFIG
---------------------------------------------------------------------------------------------------
local function reloadConfig(files)
    local doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end
_G.configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

---------------------------------------------------------------------------------------------------
-- KEY BINDING
---------------------------------------------------------------------------------------------------
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "w", function()
    hs.alert.show(
        "doCheck: " .. tostring(doCheck) ..
        "\nisCheckRunning: ".. tostring(isCheckRunning) ..
        "\ndoShowInfo: ".. tostring(doShowInfo)
    )
end)
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "l", function ()
    doShowInfo = not doShowInfo
    hs.alert.show("doShowInfo: ".. tostring(doShowInfo))
end)

---------------------------------------------------------------------------------------------------
-- CONFIG LOADED
---------------------------------------------------------------------------------------------------
hs.alert.show("Config loaded")

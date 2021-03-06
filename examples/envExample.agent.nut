// MIT License

// Copyright 2018 Electric Imp

// SPDX-License-Identifier: MIT

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

// Losant Library
#require "Losant.agent.lib.nut:1.0.0"

// LOSANT APPLICATION CLASS
// ---------------------------------------------------
// Class to manage communication with Losant Application

class LosantApp {

    lsntApp        = null;
    lsntDeviceId   = null;
    impDeviceId    = null;
    agentId        = null;

    function __statics__() {
        // API Token for Losant application
        const LOSANT_API_TOKEN        = "";
        const LOSANT_APPLICATION_ID   = "";
        const DEVICE_NAME_TEMPLATE    = "Tracker_%s";
        const DEVICE_DESCRIPTION      = "Electric Imp Device";
        const LOSANT_DEVICE_CLASS     = "standalone";
    }

    constructor() {
        agentId = split(http.agenturl(), "/").top();
        impDeviceId = imp.configparams.deviceid;

        lsntApp = Losant(LOSANT_APPLICATION_ID, LOSANT_API_TOKEN);
        // Check if device with this agent and device id combo exists, create if need
        server.log("Check Losant app for devices with matching tags.");
        _getLosantDeviceId();
        openCommandListener();
    }

    function sendData(data) {
        // Check that we have a Losant device configured
        if (lsntDeviceId == null) {
            server.log("Losant device not configured. Not sending data: ");
            server.log(http.jsonencode(data));
            return;
        }

        local payload = {
            "time" : lsntApp.createIsoTimeStamp(),
            "data" : {}
        };

        // Make sure data sent matches the attribute name
        if ("temperature" in data) payload.data.temperature <- data.temperature;
        if ("humidity" in data) payload.data.humidity <- data.humidity;

        server.log("Sending device state:");
        server.log(http.jsonencode(payload));
        lsntApp.sendDeviceState(lsntDeviceId, payload, _sendDeviceStateHandler.bindenv(this));
    }

    function openCommandListener() {
        // If we are not configured try again in 5 sec
        if (lsntDeviceId == null) {
            imp.wakeup(5, openCommandListener.bindenv(this));
            return;
        }

        server.log("Opening streaming listener...");
        lsntApp.openDeviceCommandStream(lsntDeviceId, _commandHandler.bindenv(this), _onStreamError.bindenv(this));
    }

    function updateDevice(newAttributes, newTags = null) {
        if (lsntDeviceId != null) {
            if (newTags == null) newTags = _createTags();
            local deviceInfo = {
                "name"        : format(DEVICE_NAME_TEMPLATE, agentId),
                "description" : DEVICE_DESCRIPTION,
                "deviceClass" : LOSANT_DEVICE_CLASS,
                "tags"        : newTags,
                "attributes"  : newAttributes
            }
            server.log("Updating device.");
            lsntApp.updateDeviceInfo(lsntDeviceId, deviceInfo, function(res) {
                server.log("Update device status code: " + res.statuscode);
                server.log(res.body);
            }.bindenv(this))
        } else {
            server.log("Losant device id not retrieved yet. Try again.");
        }
    }

    // This function shows how to add a device attribute
    function addLocationAttribute() {
        updateDevice([
            {
                "name"     : "temperature",
                "dataType" : "number"
            },
            {
                "name"     : "humidity",
                "dataType" : "number"
            },
            {
                "name"     : "location",
                "dataType" : "gps"
            }
        ]);
    }

    // This function shows how to remove a device attribute
    function removeLocationAttribute() {
        updateDevice([
            {
                "name"     : "temperature",
                "dataType" : "number"
            },
            {
                "name"     : "humidity",
                "dataType" : "number"
            }
        ]);
    }

    function _getLosantDeviceId() {
        // Create filter for tags matching this device info,
        // Tags for this app are unique combo of agent and imp device id
        local qparams = lsntApp.createTagFilterQueryParams(_createTags());

        // Check if a device with matching unique tags exists, create one
        // and store losant device id.
        lsntApp.getDevices(_getDevicesHandler.bindenv(this), qparams);
    }

    function _createDevice() {
        // This should be done with caution, it is possible to create multiple devices
        // Each device will be given a unique Losant device id, but will have same agent
        // and imp device ids

        // Only create if we do not have a Losant device id
        if (lsntDeviceId == null) {
            local deviceInfo = {
                "name"        : format(DEVICE_NAME_TEMPLATE, agentId),
                "description" : DEVICE_DESCRIPTION,
                "deviceClass" : LOSANT_DEVICE_CLASS,
                "tags"        : _createTags(),
                "attributes"  : _createAttrs()
            }
            server.log("Creating new device.");
            lsntApp.createDevice(deviceInfo, _createDeviceHandler.bindenv(this))
        }
    }

    function _sendDeviceStateHandler(res) {
        // Log only if not successfull
        if (res.statuscode != 200) {
            server.log(res.statuscode);
            server.log(res.body);
        }
    }

    function _commandHandler(cmd) {
        // Keys: "name", "time", "payload"
        // server.log(http.jsonencode(cmd));
        // server.log(cmd.name);
        switch(cmd.name) {
            // TODO: add cases to handle specific commands
            default:
                server.log("Received command: " + cmd.name);
                server.log(cmd.payload);
        }
    }

    function _onStreamError(err, res) {
        server.error("Error occured while listening for commands.");
        server.error(err);

        if (lsntApp.isDeviceCommandStreamOpen()) {
            // Parsing error occurred
            server.log(res);
        } else {
            // HTTP error occurred
            if ("statuscode" in res) server.log("Status code: " + res.statuscode);
            // Reopen stream
            openCommandListener();
        }
    }

    function _createDeviceHandler(res) {
        // server.log(res.statuscode);
        // server.log(res.body);
        local body = http.jsondecode(res.body);
        server.log("Device created.");
        if ("deviceId" in body) {
            lsntDeviceId = body.deviceId;
        } else {
            server.error("Losant device id not found.");
            server.log(res.body);
        }
    }

    function _getDevicesHandler(res) {
        // server.log(res.statuscode);
        // server.log(res.body);
        local body = http.jsondecode(res.body);

        if (res.statuscode == 200 && "count" in body) {
            // Successful request
            switch (body.count) {
                case 0:
                    // No devices found, create device
                    server.log("Device not found.");
                    _createDevice();
                    break;
                case 1:
                    // We found the device, store the losDevId
                    server.log("Device with matching tags found.");
                    if ("items" in body && "deviceId" in body.items[0]) {
                        lsntDeviceId = body.items[0].deviceId;
                        // Make sure the attributes and tags in Losant
                        // match the current code.
                        updateDevice(_createAttrs, _createTags);
                    } else {
                        server.error("Losant device id not in payload.");
                        server.log(res.body);
                    }
                    break;
                default:
                    // Log results of filtered query
                    server.error("Found " + body.count + "devices matching the device tags.");

                    // TODO: Delete duplicate devices - look into how to determine which device
                    // is active, so data isn't lost
            }
        } else {
            server.error("List device request failed with status code: " + res.statuscode);
        }
    }

    function _createTags() {
        return [
            {
                "key"   : "agentId",
                "value" : agentId
            },
            {
                "key"   : "impDevId",
                "value" : impDeviceId
            },
        ]
    }

    function _createAttrs() {
        return [
            {
                "name"     : "temperature",
                "dataType" : "number"
            },
            {
                "name"     : "humidity",
                "dataType" : "number"
            }
        ];
    }
}

app <- LosantApp();
device.on("data", app.sendData.bindenv(app));

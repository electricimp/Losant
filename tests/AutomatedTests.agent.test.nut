// MIT License
//
// Copyright 2015-2017 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED &quot;AS IS&quot;, WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

const API_TOKEN        = "@{LOSANT_API_TOKEN}";
const APPLICATION_ID   = "@{LOSANT_APPLICATION_ID}";

const LOSANT_DEVICE_NAME        = "Automated Tester";
const LOSANT_DEVICE_DESCRIPTION = "Electric Imp Automated Test Device";
const LOSANT_DEVICE_CLASS       = "standalone";

class AutomatedTestCase extends ImpTestCase {

    _deviceId          = null;
    _lsntDeviceId      = null;
    _lsntApp           = null;

    function setUp() {
        _deviceId = imp.configparams.deviceid;
        _lsntApp = Losant(APPLICATION_ID, API_TOKEN);

        // Make sure we start tests with no devices matching this device id in account.
        // NOTE: Test order matters, create device test must be first test (tests start at 10).
        // This tests getDevices with no query params, and maybe delete device.
        return _deleteAllDevicesWithThisDeviceId();
    }

    function test10_createDevice() {
        local deviceInfo = {
            "name"        : LOSANT_DEVICE_NAME,
            "description" : LOSANT_DEVICE_DESCRIPTION,
            "deviceClass" : LOSANT_DEVICE_CLASS,
            "tags"        : _createTags(),
            "attributes"  : _createAttrs()
        }
        return Promise(function(resolve, reject) {
            _lsntApp.createDevice(deviceInfo, function(resp) {
                local body = http.jsondecode(resp.body);
                if ("deviceId" in body) {
                    _lsntDeviceId = body.deviceId;
                    return resolve("Device created.");
                } else {
                    return reject("Create device failed. Status code: " + resp.statuscode);
                }
            }.bindenv(this))
        }.bindenv(this))
    }

    function test11_getDeviceNoQueryParams() {
        return Promise(function(resolve, reject) {
            _lsntApp.getDevices(function(resp) {
                local body = http.jsondecode(resp.body);
                // We should have at least one device (the one created in test 1)
                if (resp.statuscode == 200 && "count" in body && body.count > 0) {
                    return resolve("Device(s) found.");
                } else {
                    return reject("Devices not found. Status code: " + resp.statuscode);
                }
            }.bindenv(this))
        }.bindenv(this))
    }

    function test12_getDeviceWithQueryParamsNotMatchingDevice() {
        return Promise(function(resolve, reject) {
            // These query params should be rediculous and not match anything in the account.
            local badQparams = _lsntApp.createTagFilterQueryParams([{"key" : "owner", "value" : "helloworld"}]);
            _lsntApp.getDevices(function(resp) {
                local body = http.jsondecode(resp.body);
                // We should not find any devices that match these query params
                if (resp.statuscode == 200 && "count" in body && body.count == 0) {
                    return resolve("Query params elimiated device from results.");
                } else {
                    return reject("HTTP request failed or device found when it should have been filtered out. Status code: " + resp.statuscode);
                }
            }.bindenv(this), badQparams)
        }.bindenv(this))
    }

    function test13_getDeviceWithQueryParamsMatchingDevice() {
        return Promise(function(resolve, reject) {
            local qparams = _lsntApp.createTagFilterQueryParams(_createTags());
            _lsntApp.getDevices(function(resp) {
                local body = http.jsondecode(resp.body);
                // We should find only our devcie
                if (resp.statuscode == 200 && "count" in body && body.count == 1) {
                    return resolve("Device found. Query params matched device.");
                } else {
                    return reject("Device not found when it should have been. Status code: " + resp.statuscode);
                }
            }.bindenv(this), qparams)
        }.bindenv(this))
    }

    function test14_getDeviceInfo() {
        return Promise(function(resolve, reject) {
            _lsntApp.getDeviceInfo(_lsntDeviceId, function(resp) {
                if (resp.statuscode != 200) return reject("Get info request failed. Status code: " + resp.statuscode);

                local expectedTags = _createTags();
                local expectedAttrs = _createAttrs();
                try {
                    local body = http.jsondecode(resp.body);
                    assertEqual(LOSANT_DEVICE_DESCRIPTION, body.description);
                    assertEqual(_lsntDeviceId, body.deviceId);
                    assertEqual(LOSANT_DEVICE_NAME, body.name);
                    assertEqual(LOSANT_DEVICE_CLASS, body.deviceClass);
                    assertEqual(expectedTags.len(), body.tags.len());
                    assertEqual(expectedTags[0].value, body.tags[0].value);
                    assertEqual(expectedAttrs.len(), body.attributes.len());
                    assertEqual(expectedAttrs[0].name, body.attributes[0].name);
                    assertEqual(expectedAttrs[1].name, body.attributes[1].name);
                } catch(e) {
                    return reject("Received unexpected device info. Error: " + e);
                }
                return resolve("Received expected device info");
            }.bindenv(this))
        }.bindenv(this))
    }

    function test15_updateDeviceInfo() {
        local newTag = {
            "key"   : "newTag",
            "value" : "test"
        }
        local tags = _createTags();
        tags.push(newTag);

        local deviceInfo = {
            "name"        : LOSANT_DEVICE_NAME,
            "description" : LOSANT_DEVICE_DESCRIPTION,
            "deviceClass" : LOSANT_DEVICE_CLASS,
            "tags"        : tags,
            "attributes"  : _createAttrs()
        }

        // Bug in promise serial (v3.0.1), added imp.wakeup to insure test order as a workaround
        local series = [
            Promise(function(resolve, reject) {
                // Add a tag
                _lsntApp.updateDeviceInfo(_lsntDeviceId, deviceInfo, function(resp) {
                    if (resp.statuscode != 200) return reject("Update device request failed. Status code: " + resp.statuscode);
                    try {
                        local body = http.jsondecode(resp.body);
                        assertEqual(tags.len(), body.tags.len());
                        assertEqual(tags[0].value, body.tags[0].value);
                        assertEqual(tags[1].value, body.tags[1].value);
                    } catch(e) {
                        return reject("Unexpected update device results. Error " + e);
                    }
                    return resolve("Add tag device update succeeded");
                }.bindenv(this))
            }.bindenv(this)),
            Promise(function(resolve, reject) {
                // Remove a tag
                deviceInfo.tags = _createTags();
                imp.wakeup(1, function() {
                    _lsntApp.updateDeviceInfo(_lsntDeviceId, deviceInfo, function(res) {
                        if (res.statuscode != 200) return reject("Update device request failed. Status code: " + res.statuscode);
                        try {
                            local body = http.jsondecode(res.body);
                            assertEqual(deviceInfo.tags.len(), body.tags.len());
                            assertEqual(tags[0].value, body.tags[0].value);
                        } catch(e) {
                            return reject("Unexpected update device results. Error " + e);
                        }
                        return resolve("Remove tag device updated succeeded.");
                    }.bindenv(this))
                }.bindenv(this))
            }.bindenv(this))
        ]

        // Run series in sequence
        return Promise.serial(series);
    }

    function test16_deviceState() {
        local deviceState = {
            "time" : _lsntApp.createIsoTimeStamp(),
            "data" : {
                "temperature" : 20,
                "humidity"    : 80
            }
        }

        // Bug in promise serial (v3.0.1), added imp.wakeup to insure test order as a workaround
        local series = [
            Promise(function(resolve, reject) {
                // Send device state
                // info("sending device state");
                _lsntApp.sendDeviceState(_lsntDeviceId, deviceState, function(resp) {
                    if (resp.statuscode != 200) return reject("Set device state request failed. Status code: " + resp.statuscode);
                    try {
                        local body = http.jsondecode(resp.body);
                        assertTrue(body.success);
                    } catch(e) {
                        return reject("Unexpected send device state response " + e);
                    }
                    return resolve("Expected send device state response");
                }.bindenv(this));
            }.bindenv(this)),
            Promise(function(resolve, reject) {
                imp.wakeup(1, function() {
                    // Get device state
                    // info("getting device state");
                    _lsntApp.getDeviceState(_lsntDeviceId, function(resp) {
                        if (resp.statuscode != 200) return reject("Get device state request failed. Status code: " + resp.statuscode);
                        try {
                            local body = http.jsondecode(resp.body);
                            local receivedState = body[0];
                            assertEqual(deviceState.data.temperature, receivedState.data.temperature);
                            assertEqual(deviceState.data.humidity, receivedState.data.humidity);
                        } catch(e) {
                            return reject("Unexpected get device state resp " + e);
                        }
                        return resolve("Expected send/get device state response");
                    }.bindenv(this));
                }.bindenv(this))
            }.bindenv(this)),
            Promise(function(resolve, reject) {
                imp.wakeup(2, function() {
                    // Get device composite state
                    // info("getting device composite state");
                    _lsntApp.getDeviceCompositeState(_lsntDeviceId, function(resp) {
                        if (resp.statuscode != 200) return reject("Get device composite state request failed. Status code: " + resp.statuscode);
                        try {
                            local body = http.jsondecode(resp.body);
                            assertEqual(deviceState.data.temperature, body.temperature.value);
                            assertEqual(deviceState.data.humidity, body.humidity.value);
                        } catch(e) {
                            return reject("Unexpected get device composite state resp " + e);
                        }
                        return resolve("Expected send/get/getComposite device state response");
                    }.bindenv(this));
                }.bindenv(this))
            }.bindenv(this))
        ]

        // Run series in sequence
        return Promise.serial(series);
    }

    function test17_deviceLogs() {
        return Promise(function(resolve, reject) {
            _lsntApp.getDeviceLogs(_lsntDeviceId, function(resp) {
                if (resp.statuscode != 200) {
                    return reject("Get device logs request failed. Status code: " + resp.statuscode);
                } else {
                    return resolve("Received expected get device logs response.");
                }
            }.bindenv(this))
        }.bindenv(this))

    }

    function test18_createTimeStamp() {
        local now = time();
        local ts = _lsntApp.createIsoTimeStamp(now);
        local d  = date(now);
        try {
            local year  = ts.slice(0, 4);
            local month = ts.slice(5, 7);
            local day   = ts.slice(8, 10);
            local hour  = ts.slice(11, 13);
            local min   = ts.slice(14, 16);
            local sec   = ts.slice(17, 19);
            local ms    = ts.slice(20, 23);
            assertEqual(format("%04d", d.year), year);
            assertEqual(format("%02d", (d.month + 1)), month);
            assertEqual(format("%02d", d.day), day);
            assertEqual(format("%02d", d.hour), hour);
            assertEqual(format("%02d", d.min), min);
            assertEqual(format("%02d", d.sec), sec);
            assertEqual(format("%03d", (d.usec / 1000)), ms);
        } catch(e) {
            throw ("Error parsing timestamp " + e)
        }
        return "Timestamp parsing test passed";
    }

    function test19_deviceCommand() {
        local command = {
            "time"    : _lsntApp.createIsoTimeStamp(),
            "name"    : "testCommand",
            "payload" : "send device command"
        }

        // Bug in promise serial (v3.0.1), added imp.wakeup to insure test order as a workaround
        local series = [
            Promise(function(resolve, reject) {
                _lsntApp.sendDeviceCommand(_lsntDeviceId, command, function(resp) {
                    if (resp.statuscode != 200) return reject("Send device command request failed. Status code: " + resp.statuscode);
                    try {
                        local body = http.jsondecode(resp.body);
                        assertTrue(body.success);
                    } catch(e) {
                        return reject("Send device command parsing error: " + e);
                    }
                    return resolve("Send device command succeeded");
                }.bindenv(this))
            }.bindenv(this)),
            Promise(function(resolve, reject) {
                imp.wakeup(1, function() {
                    _lsntApp.getDeviceCommand(_lsntDeviceId, function(resp) {
                        if (resp.statuscode != 200) return reject("Get device command request failed. Status code: " + resp.statuscode);
                        try {
                            local body = http.jsondecode(resp.body);
                            // We should have at lease one command
                            assertTrue(body.len() > 0);
                            assertEqual(body[0].payload, command.payload);
                            assertEqual(body[0].name, command.name);
                        } catch(e) {
                            return reject("Get device command parsing error: " + e);
                        }
                        resolve("Device command sent and received.");
                    }.bindenv(this))
                }.bindenv(this))
            }.bindenv(this))
        ]

        // Run series in sequence
        return Promise.serial(series);
    }

    function test20_deviceCommandStreams() {

    }

    function tearDown() {
        // This tests delete device
        return _deleteDevice(_lsntDeviceId);
    }

    function _deleteAllDevicesWithThisDeviceId() {
        return Promise(function (resolve, reject) {
            local qparams    = _lsntApp.createTagFilterQueryParams(_createTags());
            _lsntApp.getDevices(function(resp) {
                local body = http.jsondecode(resp.body);
                if (resp.statuscode == 200 && "count" in body) {
                    if (body.count == 0) {
                        return resolve("No devices found.");
                    } else {
                        local series = [];
                        // delete all devices
                        foreach (item in body.items) {
                            series.push(_deleteDevice(item.deviceId));
                        }
                        return Promise.all(series)
                            .then(function(results) {
                                info("All devices deleted.");
                                return resolve(results);
                            }.bindenv(this),
                            function(results) {
                                info("Not all devices deleted.");
                                return reject(results);
                            }.bindenv(this))
                    }
                } else {
                    return reject("Get devices request failed.");
                }
            }.bindenv(this));
        }.bindenv(this))
    }

    function _deleteDevice(id) {
        return Promise(function (resolve, reject) {
            _lsntApp.deleteDevice(id, function(resp) {
                if (resp.statuscode == 200) {
                    return resolve("Device " + id + " deleted");
                } else {
                    return reject("Delete device " + id + " failed.");
                }
            }.bindenv(this))
        }.bindenv(this))
    }

    function _createTags() {
        return [
            {
                "key"   : "impDevId",
                "value" : _deviceId
            }
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
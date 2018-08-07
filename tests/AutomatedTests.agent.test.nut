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

class AutomatedTestCase extends ImpTestCase {

    _deviceId     = null;
    _lsntDeviceId = null;
    _lsntApp      = null;

    function setUp() {
        _deviceId = imp.configparams.deviceid;
        _lsntApp = Losant(APPLICATION_ID, API_TOKEN);

        // Make sure we start tests with no devices that match this device id.
        // This tests createTagFilterQueryParams, getDevices with query params, and
        // maybe delete device
        return _deleteAllDevices();
    }

    function test1_CreateDevice() {
        info("Starting test 1...");
        local deviceInfo = {
            "name"        : "Automated Tester",
            "description" : "Electric Imp Automated Test Device",
            "deviceClass" : "standalone",
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

    // Class methods that need tests....
    // get devices - with query params
    // get devices - without query params

    // get device info
    // update device info

    // send devices command (manual)
    // send device command
    // get device command

    // open device command stream
    // is steam open
    // close stream

    // send device state
    // get device state
    // get device composite state

    // device logs
    // queryparams
    // time stamp

    function tearDown() {
        // This tests delete device
        return _deleteDevice(_lsntDeviceId);
    }

    function _deleteAllDevices() {
        return Promise(function (resolve, reject) {
            local qparams = _lsntApp.createTagFilterQueryParams(_createTags());
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
            }.bindenv(this), qparams);
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

    function _stubDeviceData() {

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
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

class Losant {

    static VERSION = "1.0.0";

    _baseURL              = null;
    _headers              = null;
    _cmdListenerReq       = null;
    _cmdListernerWatchdog = null;
    _kaTimeout            = null;
    _onStreamingError     = null;

     // constructor
     // Returns: null
     // Parameters:
     //      appId (reqired) : string - Losant application ID
     //      apiToken (required) : string - Token for Losant application, used to authorize
     //                                     all HTTP requests, must have device and devices
     //                                     permissions.
    constructor(appId, apiToken) {
        _baseURL = format("https://api.losant.com/applications/%s/devices", appId);
        _headers = { "Content-Type"  : "application/json",
                     "Accept"        : "application/json",
                     "Authorization" : format("Bearer %s", apiToken)};
    }

    // getDevices - Fetches a list of application devices, if query parameter is pass in
    //              the list will be filtered
    // Returns: null
    // Parameters:
    //      cb (reqired) : function - callback function called when response is received
    //                                 from Losant
    //      queryParams (optional) : string - query parameters to be added to the url
    //                                        used to filter device results
    function getDevices(cb, queryParams = null) {
        // Returns the devices for an application
        // GET /applications/{applicationId}/devices
        local url = (queryParams == null) ? _baseURL : format("%s?%s", _baseURL, queryParams);
        local req = http.get(url, _headers);
        req.sendasync(cb);
    }

    // createDevice - Create a new device for application passed into the constructor
    // Returns: null
    // Parameters:
    //      devInfo (required) : table - Expected keys include: name, description, tags,
    //                                  deviceClass, attributes
    //      cb (required) : function - callback function called when response is received
    //                                 from Losant
    function createDevice(devInfo, cb) {
        // Create a new device for an application
        // POST /applications/{applicationId}/devices
        local req = http.post(_baseURL, _headers, http.jsonencode(devInfo));
        req.sendasync(cb);
    }

    // sendDevicesCommand - Sends a command to multiple devices
    // Returns: null
    // Parameters:
    //      cmd (required) : table - Expected keys include: name, time, payload
    //      cb (required) : function - callback function called when response is received
    //                                 from Losant
    function sendDevicesCommand(cmd, cb) {
        // Send a command to multiple devices
        // POST /applications/{applicationId}/devices/command
        local req = http.post(format("%s/command", _baseURL), _headers, http.jsonencode(cmd));
        req.sendasync(cb);
    }

    // getDeviceInfo - Retrieves information for specified device
    // Returns: null
    // Parameters:
    //      losDevId (required) : string - Losant device id (this is NOT the imp device id)
    //      cb (required) : function - callback function called when response is received
    //                                 from Losant
    function getDeviceInfo(losDevId, cb) {
        // Retrieves information on a device
        // GET /applications/{applicationId}/devices/{deviceId}
        local req = http.get(format("%s/%s", _baseURL, losDevId),  _headers);
        req.sendasync(cb);
    }

    // updateDeviceInfo - Updates information for specified device
    // Returns: null
    // Parameters:
    //      losDevId (required) : string - Losant device id (this is NOT the imp device id)
    //      devInfo (required) : table - Updated device info table. Keys may include: name,
    //                                  description, tags, deviceClass, attributes
    //      cb (required) : function - callback function called when response is received
    //                                 from Losant
    function updateDeviceInfo(losDevId, devInfo, cb) {
        // Updates information about a device
        // PATCH /applications/{applicationId}/devices/{deviceId}
        local req = http.request("PATCH", format("%s/%s", _baseURL, losDevId),  _headers, http.jsonencode(devInfo));
        req.sendasync(cb);
    }

    // deleteDevice - Deletes specified device
    // Returns: null
    // Parameters:
    //      losDevId (required) : string - Losant device id (this is NOT the imp device id)
    //      cb (required) : function - callback function called when response is received
    //                                 from Losant
    function deleteDevice(losDevId, cb) {
        // Deletes a device
        // DELETE /applications/{applicationId}/devices/{deviceId}
        local req = http.request("DELETE", format("%s/%s", _baseURL, losDevId),  _headers, "");
        req.sendasync(cb);
    }

    // getDeviceState - Retrieve the last known state(s) of the device
    // Returns: null
    // Parameters:
    //      losDevId (required) : string - Losant device id (this is NOT the imp device id)
    //      cb (required) : function - callback function called when response is received
    //                                 from Losant
    function getDeviceState(losDevId, cb) {
        // Retrieve the last known state(s) of the device
        // GET /applications/{applicationId}/devices/{deviceId}/state
        local req = http.get(format("%s/%s/state", _baseURL, losDevId),  _headers);
        req.sendasync(cb);
    }

    // getDeviceCompositeState - Retrieve the composite last complete state of the device
    // Returns: null
    // Parameters:
    //      losDevId (required) : string - Losant device id (this is NOT the imp device id)
    //      cb (required) : function - callback function called when response is received
    //                                 from Losant
    function getDeviceCompositeState(losDevId, cb) {
        // Retrieve the composite last complete state of the device
        // GET /applications/{applicationId}/devices/{deviceId}/compositeState
        local req = http.get(format("%s/%s/compositeState", _baseURL, losDevId),  _headers);
        req.sendasync(cb);
    }

    // sendDeviceState - Send the current state of the device
    // Returns: null
    // Parameters:
    //      losDevId (required) : string - Losant device id (this is NOT the imp device id)
    //      devState (required) : table or array of tables - Table slots must match
    //                            device attributes
    //      cb (required) : function - callback function called when response is received
    //                                 from Losant
    function sendDeviceState(losDevId, devState, cb) {
        // Send the current state of the device
        // POST /applications/{applicationId}/devices/{deviceId}/state
        local req = http.post(format("%s/%s/state", _baseURL, losDevId), _headers, http.jsonencode(devState));
        req.sendasync(cb);
    }

    // getDeviceCommand - Retrieve the last known commands(s) sent to the device
    // Returns: null
    // Parameters:
    //      losDevId (required) : string - Losant device id (this is NOT the imp device id)
    //      cb (required) : function - callback function called when response is received
    //                                 from Losant
    function getDeviceCommand(losDevId, cb) {
        // Retrieve the last known commands(s) sent to the device
        // GET /applications/{applicationId}/devices/{deviceId}/command
        local req = http.get(format("%s/%s/command", _baseURL, losDevId),  _headers);
        req.sendasync(cb);
    }

    // sendDeviceCommand - Send a command to specified device
    // Returns: null
    // Parameters:
    //      losDevId (required) : string - Losant device id (this is NOT the imp device id)
    //      cmd (required): table - Expected keys include: name, time, payload
    //      cb (required) : function - callback function called when response is received
    //                                 from Losant
    function sendDeviceCommand(losDevId, cmd, cb) {
        // Send a command to a device
        // POST /applications/{applicationId}/devices/{deviceId}/command
        local req = http.post(format("%s/%s/command", _baseURL, losDevId), _headers, http.jsonencode(cmd));
        req.sendasync(cb);
    }

    // openDeviceCommandStream - Opens a listener for commands directed at this device
    // Returns: null
    // Parameters:
    //      losDevId (required) : string - Losant device id (this is NOT the imp device id)
    //      onData (required): function - Callback function called when data is received
    //      onError (required) : function - Callback function called when error is
    //                                      encountered
    //      keepAliveTimeout (optional) : float/integer - (between 2 & 60 sec) ammount of time
    //                                                    in seconds to wait for a keep alive
    //                                                    ping before closing stream.
    function openDeviceCommandStream(losDevId, onData, onError, kaTimeout = 30) {
        // Don't allow more than one stream open at a time
        closeDeviceCommandStream();

        _cmdListenerReq = http.get(format("%s/%s/commandStream", _baseURL, losDevId), _headers);
        _cmdListenerReq.sendasync(_cmdRespFactory(losDevId, onData, onError), _onDataFactory(onData, onError));
        // Start streaming watchdog
        _kaTimeout = kaTimeout;
        _onStreamingError = onError;
        _startKeepAliveTimer();
    }

    // closeDeviceCommandStream - Closes a listener for commands directed at this device
    // Returns: null
    // Parameters:
    //      losDevId (required) : string - Losant device id (this is NOT the imp device id)
    //      cmd (required): table - Expected keys include: name, time, payload
    //      cb (required) : function - callback function called when response is received
    //                                 from Losant
    function closeDeviceCommandStream() {
        if (_cmdListenerReq != null) {
            _cmdListenerReq.cancel();
            _cmdListenerReq = null;
        }
    }

    // isStreamOpen - Returns whether stream is currently open
    // Returns: boolean, if a stream is currently open
    // Parameters: none
    function isDeviceCommandStreamOpen() {
        return (_cmdListenerReq != null);
    }

    // getDeviceLogs - Retrieve the recent log entries about the device
    // Returns: null
    // Parameters:
    //      losDevId (required) : string - Losant device id (this is NOT the imp device id)
    //      cb (required) : function - callback function called when response is received
    //                                 from Losant
    function getDeviceLogs(losDevId, cb) {
        // Retrieve the recent log entries about the device
        // GET /applications/{applicationId}/devices/{deviceId}/logs
        local req = http.get(format("%s/%s/logs", _baseURL, losDevId),  _headers);
        req.sendasync(cb);
    }


    // createTagFilterQueryParams - Formats tag array into query parameter format
    // Returns: string - Formatted to be used as query parameter for getDevices method
    // Parameters:
    //      tags (required) : array of tables - this should be formatted the same as tags
    //                        are formatted, however not all key(s) or value(s) are required
    function createTagFilterQueryParams(tags) {
        // Takes array of tables - must match device tag(s)
        // [{"key" : "agentId", "value" : agentId}, {"key" : "impDevId", "value" :  impDeviceId}]
        // Returns a string:
        // tagFilter[0][key]=agentId&tagFilter[0][value]=<AGENT_ID>&tagFilter[1][key]=impDevId&tagFilter[1][value]=<DEVICE_ID>
        local fType = "tagFilter";
        local params = "";
        foreach(idx, tag in tags) {
            local prefix = format("%s[%i]", fType, idx);
            if ("key" in tag) {
                params += format("%s[key]=%s&", prefix, tag.key.tostring());
            }
            if ("value" in tag) {
                params += format("%s[value]=%s&", prefix, tag.value.tostring());
            }
        }
        return params.slice(0, params.len() - 1);
    }

    // createIsoTimeStamp
    // Returns: string - with time formatted as "2015-12-03T00:54:51.000Z"
    // Parameters:
    //      ts (optional) : integer - epoch timestamp as returned by time()
    function createIsoTimeStamp(ts = null) {
        local d = ts ? date(ts) : date();
        return format("%04d-%02d-%02dT%02d:%02d:%02d.%03dZ", d.year, d.month+1, d.day, d.hour, d.min, d.sec, d.usec / 1000);
    }

    // _cmdRespFactory - Creates function that reopen stream if it closes for known reason,
    //                   otherwise calls onError callback.
    // Returns: function
    // Parameters:
    //      losDevId (required) : string - Losant device id (this is NOT the imp device id)
    //      onData (required): function - Callback function called when data is received
    //      onError (required) : function - Callback function called when error is
    //                                      encountered
    function _cmdRespFactory(losDevId, onData, onError) {
        return function (resp) {
            if (resp.statuscode == 28 || resp.statuscode == 200) {
                // Reopen listener
                imp.wakeup(0, function() {
                    openDeviceCommandStream(losDevId, onData, onError);
                }.bindenv(this));
            } else {
                // Make sure the stream is closed, call the error callback
                closeDeviceCommandStream();
                imp.wakeup(0, function() {
                    onError("ERROR: Command stream closed, received error. Status code: " + resp.statuscode, resp);
                    _onStreamingError = null;
                }.bindenv(this))
            }
            // Reset request variable
            _cmdListenerReq = null;
        }.bindenv(this)
    }

    // _onDataFactory - Creates function that parses incomming data message or calls
    //                  OnError callback if parsing fails.
    // Returns: function
    // Parameters:
    //      losDevId (required) : string - Losant device id (this is NOT the imp device id)
    //      onData (required): function - Callback function called when data is received
    //      onError (required) : function - Callback function called when error is
    //                                      encountered
    function _onDataFactory(onData, onError) {
        return function(content) {
            // Restart keep alive timer
            _startKeepAliveTimer();
            // Process all data that is not a keepalive ping
            if (content != ":keepalive\n\n") {
                try {
                    // Parse content to get to data table
                    // Data is formatted according to SSE (server-sent-event) spec
                    // https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events
                    local arr = split(content, "\n");
                    if (arr[1].find("data:") != null) {
                        // chop "data: " off the top of string, so
                        // table can be decoded
                        local data = arr[1].slice(6);
                        data = http.jsondecode(data);
                        // Pass command to callback
                        imp.wakeup(0, function() {
                            onData(data);
                        }.bindenv(this))
                    }
                } catch(e) {
                    // Parser failed, pass payload to user
                    onError("ERROR: Parsing command streaming data failed " + e, content);
                }
            }
        }.bindenv(this)
    }

    // _startKeepAliveTimer - Cancels keep alive timer if it is running and restarts a keep alive timer. If timer
    //                        is not reset stream will be closed and streaming error handler will be called.
    // Returns : nothing
    // Parameters : none
    function _startKeepAliveTimer() {
        if (_cmdListernerWatchdog) {
            imp.cancelwakeup(_cmdListernerWatchdog);
            _cmdListernerWatchdog = null;
        }
        _cmdListernerWatchdog = imp.wakeup(_kaTimeout, function() {
            closeDeviceCommandStream();
            _onStreamingError("ERROR: Command stream closed. No response from server in " + _kaTimeout + " seconds", null);
            _onStreamingError = null;
        }.bindenv(this));
    }

}
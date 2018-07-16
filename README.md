# Losant #

This library wraps the Losant REST API. It supports most of the [Device Actions](https://docs.losant.com/rest-api/device/) and [Devices Actions](https://docs.losant.com/rest-api/devices/) allowing the Imp to create, update and delete devices on the Losant platform. The library also supports sending commands to devices and updating the current state of a device.

To use this library you need to have a Losant [account](https://accounts.losant.com/create-account) and [application](https://docs.losant.com/applications/overview/).

**To use this library, add** `#require "Losant.agent.lib.nut:1.0.0"` **to the top of your device or agent code.**

## Class Usage ##

### Constructor: Losant(*appId, apiToken*) ###

Each instance of the class will connect the device with a Losant [application](https://docs.losant.com/applications/overview/) (identified by the Application Id). All methods will send and receive data via this application only.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *appId* | String | Yes | A Losant Application Id |
| *apiToken* | String | Yes | An [Application API token](https://docs.losant.com/applications/application-tokens/) with Device and Devices permissions |

#### Return Value ####

None.

#### Example ####

```squirrel
// ID and API Token for My Losant Application
const LOSANT_APPLICATION_ID   = "<YOUR APPLICATION API TOKEN HERE>";
const LOSANT_DEVICE_API_TOKEN = "<YOUR API TOKEN HERE>";

lsntTrackerApp <- Losant(LOSANT_APPLICATION_ID, LOSANT_DEVICE_API_TOKEN);
```

### Callback Functions ###

All HTTPS requests to Losant are made asynchronously. Each method that makes an HTTP request will have a required callback parameter, a function that will executed when the server responds. The callback function will take a single parameter *response*.

#### Callback Response Object ####

| Key | Type | Description |
| --- | --- | --- |
| *statuscode* | Integer | HTTP status code (or libcurl error code) |
| *headers* | Table | Squirrel table of returned HTTP headers |
| *body* | String | Returned HTTP body (if any) |

## Class Methods ##

### createDevice(*deviceInfo, callback*) ###

Creates a new device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *deviceInfo* | Table | Yes | A table with device info used to create the device. See API docs for [table details](https://docs.losant.com/rest-api/devices/#post) |
| *callback* | Function | Yes | Called when response is received (see [Callback Functions](#callback-functions) above) |

#### Return Value ####

None.

#### Example ####

```squirrel
lsntDeviceId <- null;
agentId      <- split(http.agenturl(), "/").top();
impDeviceId  <- imp.configparams.deviceid;

deviceInfo   <- {
    "name"        : format("Tracker_%s", agentId),
    "description" : "Electric Imp Asset Tracker",
    "deviceClass" : "standalone",
    "tags"        : [
        {
          "key"   : "agentId",
          "value" : agentId
        },
        {
          "key"   : "impDevId",
          "value" :  impDeviceId
        }
    ],
    "attributes"  :  [
        {
          "name"     : "location",
          "dataType" : "gps"
        },
        {
          "name"     : "temperature",
          "dataType" : "number"
        },
        {
          "name"     : "humidity",
          "dataType" : "number"
        },
        {
          "name"     : "magnitude",
          "dataType" : "number"
        },
        {
          "name"     : "alertTemperature",
          "dataType" : "string"
        },
        {
          "name"     : "alertHumidity",
          "dataType" : "string"
        },
        {
          "name"     : "alertMovement",
          "dataType" : "string"
        }
    ]
}

lsntTrackerApp.createDevice(deviceInfo, function(res) {
    server.log(res.statuscode);
    server.log(res.body);
    local body = http.jsondecode(res.body);
    lsntDeviceId = body.deviceId;
})
```

### getDevices(*callback[, queryParams]*) ###

Fetches a list of application devices, if query parameter is pass in the list will be filtered.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | function | Yes | Called when response is received (see [Callback Functions](#callback-functions) above) |
| *queryParams* | String | No | Query parameters to be added to the url, used to filter results. See [*createTagFilterQueryParams()*](#createtagfilterqueryparamstags) method for example. |

#### Return Value ####

None.

#### Example ####

```squirrel
lsntDeviceId <- null;
agentId      <- split(http.agenturl(), "/").top();
impDeviceId  <- imp.configparams.deviceid;

deviceInfo   <- {
    "name"        : format("Tracker_%s", agentId),
    "description" : "Electric Imp Asset Tracker",
    "deviceClass" : "standalone",
    "tags"        : [
        {
          "key"   : "agentId",
          "value" : agentId
        },
        {
          "key"   : "impDevId",
          "value" :  impDeviceId
        }
    ],
    "attributes"  :  [
        {
          "name"     : "location",
          "dataType" : "gps"
        },
        {
          "name"     : "temperature",
          "dataType" : "number"
        },
        {
          "name"     : "humidity",
          "dataType" : "number"
        },
        {
          "name"     : "magnitude",
          "dataType" : "number"
        },
        {
          "name"     : "alertTemperature",
          "dataType" : "string"
        },
        {
          "name"     : "alertHumidity",
          "dataType" : "string"
        },
        {
          "name"     : "alertMovement",
          "dataType" : "string"
        }
    ]
}

// Get all devices
lsntTrackerApp.getDevices(function(response) {
    server.log("Status Code: " + response.statuscode);
    server.log(response.body);
});

// Create filter for tags matching this device, use the tags set up as unique ids - agent and device id combo
local qparams = lsntTrackerApp.createTagFilterQueryParams(deviceInfo.tags);

// Look for this device
lsntTrackerApp.getDevices(function(response) {
    local body = http.jsondecode(response.body);
    if (response.statuscode == 200 && "count" in body) {
        // Successful request
        switch (body.count) {
            case 0:
                // No devices found, create device
                lsntTrackerApp.createDevice(deviceInfo, function(resp) {
                    local bdy = http.jsondecode(resp.bdy);
                    lsntDeviceId = bdy.deviceId;
                })
                break;
            case 1:
                // We found the device, store the lsntDeviceId
                lsntDeviceId = body.items[0].deviceId;
                break;
            default:
                // We have multiple matches, log results of filtered query
                server.error("Found " + body.count + "devices matching the device tags.");
                // TODO: Delete multiples
        }
    } else {
        server.error("List device request failed with status code: " + response.statuscode);
    }
}, qparams);
```

### getDeviceInfo(*losantDeviceId, callback*) ###

Retrieves information for specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | No | Device Id assigned by Losant when device is created. |
| *callback* | function | Yes | Called when response is received (see [Callback Functions](#callback-functions) above) |

#### Return Value ####

None.

#### Example ####

```squirrel
lsntTrackerApp.getDeviceInfo(lsntDeviceId, function(response) {
    server.log("Status Code: " + response.statuscode);
    //Log device info
    server.log(response.body);
});
```

### updateDeviceInfo(*losantDeviceId, deviceInfo, callback*) ###

Updates information for specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | No | Device Id assigned by Losant when device is created. |
| *deviceInfo* | Table | Yes | A table with updated device info. See API docs for [table details](https://docs.losant.com/rest-api/device/#patch) |
| *callback* | function | Yes | Called when response is received (see [Callback Functions](#callback-functions) above) |

#### Return Value ####

None.

#### Example ####

```squirrel
lsntTrackerApp.updateDeviceInfo(lsntDeviceId, deviceInfo, function(response) {
    server.log("Status Code: " + response.statuscode);
    //Log updated device info
    server.log(response.body);
});
```

### deleteDevice(*losantDeviceId, callback*) ###

Deletes specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | No | Device Id assigned by Losant when device is created. |
| *callback* | function | Yes | Called when response is received (see [Callback Functions](#callback-functions) above) |

#### Return Value ####

None.

#### Example ####

```squirrel
lsntTrackerApp.deleteDevice(lsntDeviceId, function(response) {
    server.log("Status Code: " + response.statuscode);
    // Log if delete was successful
    server.log(response.body);
});
```

### sendDeviceState(*losantDeviceId, deviceState, callback*) ###

Send the current state of the device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | No | Device Id assigned by Losant when device is created. |
| *deviceState* | Table or Array of Tables | Yes | A table with device state or an array of tables with device state. The keys in the table(s) should correspond to the device's attributes. |
| *callback* | function | Yes | Called when response is received (see [Callback Functions](#callback-functions) above) |

#### Return Value ####

None.

#### Example ####

```squirrel
device.on("data", function(data) {
    // We cannot post data, so just drop it
    if (lsntDeviceId == null) {
        server.log("Losant device not configured. Not sending data: ");
        server.log(http.jsonencode(data));
        return;
    }

    local payload = {
        "time" : lsntTrackerApp.createIsoTimeStamp(),
        "data" : {}
    };

    if ("lat" in data && "lng" in data) payload.data.location <- format("%s,%s", data.lat, data.lng);
    if ("temp" in data) payload.data.temperature <- data.temp;
    if ("humid" in data) payload.data.humidity <- data.humid;
    if ("mag" in data) payload.data.magnitude <- data.mag;

    lsntTrackerApp.sendDeviceState(lsntDeviceId, payload, function(res) {
        server.log(res.statuscode);
        server.log(res.body);
    });
});
```

### getDeviceState(*losantDeviceId, callback*) ###

Retrieve the last known state(s) of the device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | No | Device Id assigned by Losant when device is created. |
| *callback* | function | Yes | Called when response is received (see [Callback Functions](#callback-functions) above) |

#### Return Value ####

None.

#### Example ####

```squirrel
lsntTrackerApp.getDeviceState(lsntDeviceId, function(response) {
    server.log("Status Code: " + response.statuscode);
    // Log device state
    server.log(response.body);
});
```

### getDeviceCompositeState(*losantDeviceId, callback*) ###

Retrieve the composite last complete state of the device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | No | Device Id assigned by Losant when device is created. |
| *callback* | function | Yes | Called when response is received (see [Callback Functions](#callback-functions) above) |

#### Return Value ####

None.

#### Example ####

```squirrel
lsntTrackerApp.getDeviceCompositeState(lsntDeviceId, function(response) {
    server.log("Status Code: " + response.statuscode);
    // Log device composite state
    server.log(response.body);
});
```

### sendDevicesCommand(*command, callback*) ###

Send a command to multiple devices.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *command* | Table | Yes | A command table. See API docs for [table details](https://docs.losant.com/rest-api/device/#send-command) |
| *callback* | function | Yes | Called when response is received (see [Callback Functions](#callback-functions) above) |

#### Return Value ####

None.

#### Example ####

```squirrel
local cmd = {
    "time" : lsntTrackerApp.createIsoTimeStamp(),
    "name" : "myCommand",
    "payload" : [1, 1, 2, 3, 5]
}

lsntTrackerApp.sendDevicesCommand(cmd, function(response) {
    server.log("Status Code: " + response.statuscode);
    //Log if command was sent successfully
    server.log(response.body);
});
```

### sendDeviceCommand(*losantDeviceId, command, callback*) ###

Send a command to specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | No | Device Id assigned by Losant when device is created. |
| *command* | Table | Yes | A command table. See API docs for [table details](https://docs.losant.com/rest-api/device/#send-command) |
| *callback* | function | Yes | Called when response is received (see [Callback Functions](#callback-functions) above) |

#### Return Value ####

None.

#### Example ####

```squirrel
local cmd = {
    "time" : lsntTrackerApp.createIsoTimeStamp(),
    "name" : "myCommand",
    "payload" : [1, 1, 2, 3, 5]
}

lsntTrackerApp.sendDeviceCommand(losantDeviceId, cmd, function(response) {
    server.log("Status Code: " + response.statuscode);
    //Log if command was sent successfully
    server.log(response.body);
});
```

### getDeviceCommand(*losantDeviceId, callback*) ###

Retrieve the last known commands(s) sent to the specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | No | Device Id assigned by Losant when device is created. |
| *callback* | function | Yes | Called when response is received (see [Callback Functions](#callback-functions) above) |

#### Return Value ####

None.

#### Example ####

```squirrel
lsntTrackerApp.getDeviceCommand(lsntDeviceId, function(response) {
    server.log("Status Code: " + response.statuscode);
    // Log commands
    server.log(response.body);
});
```

### openDeviceCommandStream(*losDevId, onData, onError*) ###

Opens stream that listens for commands directed at this device. **Note:** Only one stream can be open at a time. If *openDeviceCommandStream()* will close a stream that is currently open and will open a new stream.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | No | Device Id assigned by Losant when device is created. |
| *onData* | function | Yes | Called when a command is received from Losant. Takes a single parameter, a table, containing the command received from Losant. |
| *onError* | function | Yes | Called if stream is closed unexpectedly or if command cannot be parsed. Takes two parameters, the error encountered, and the response from Losant. |


#### Return Value ####

None.

#### Example ####

```squirrel
function onData(command) {
    server.log(command.name);
    server.log(command.payload);
}

onError(error, response) {
    server.error("Error occured while listening for commands.");
    server.error(error);

    if ("statuscode" in response) {
        server.log("Status code: " + response.statuscode);
        server.log(response.body);
        // TODO: Reopen stream depending on why it closed.
    } else {
        server.log(response);
    }
}

lsntTrackerApp.openDeviceCommandStream(lsntDeviceId, onData, onError);
```

### closeDeviceCommandStream() ###

Closes command stream if one is open.

#### Parameters ####

None.

#### Return Value ####

None.

#### Example ####

```squirrel
lsntTrackerApp.closeDeviceCommandStream();
```

### getDeviceLogs(*losantDeviceId, callback*) ###

Retrieve the recent log entries for the specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | No | Device Id assigned by Losant when device is created. |
| *callback* | function | Yes | Called when response is received (see [Callback Functions](#callback-functions) above) |

#### Return Value ####

None.

#### Example ####

```squirrel
lsntTrackerApp.getDeviceLogs(lsntDeviceId, function(response) {
    server.log("Status Code: " + response.statuscode);
    // Log device logs
    server.log(response.body);
});
```

### createIsoTimeStamp(*[epochTime]*) ###

Creates a UTC combined date time timestamp based on ISO 8601 standards. If *epochTime* parameter is passed in it will be reformatted, otherwise the current time will be used.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *epochTime* | Integer | No | Integer returned by calling *time()*, the current date and time as elapsed seconds since midnight, 1 Jan 1970. |

#### Return Value ####

A string timestamp.

#### Example ####

```squirrel
local now = lsntTrackerApp.createIsoTimeStamp();
server.log(now);
```

### createTagFilterQueryParams(*tags*) ###

Formats device info tag array into query parameter format.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *tags* | Array | Yes | Array of tag tables with slots "key" and/or "value". |

#### Return Value ####

A tag filter query parameter string.

#### Example ####

```squirrel
local searchTags = [
    {
      "key"   : "agentId",
      "value" : split(http.agenturl(), "/").top()
    },
    {
      "value" : imp.configparams.deviceid
    }
]
local qparams = lsntTrackerApp.createTagFilterQueryParams(searchTags);
```

## License ##

The Losant library is licensed under the [MIT License](LICENSE).

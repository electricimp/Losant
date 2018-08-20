# Losant #

This library wraps the [Losant enterprise IoT platform](https://www.losant.com) REST API. It supports most of the platform's [single-device](https://docs.losant.com/rest-api/device/) and [multiple-device](https://docs.losant.com/rest-api/devices/) actions, allowing the your code to create, update and delete devices on the Losant platform. The library also supports sending commands to platform devices and updating the current state of a platform device.

To use this library you need to have a Losant [account](https://accounts.losant.com/create-account) and a Losant[application](https://docs.losant.com/applications/overview/).

**To use this library, add** `#require "Losant.agent.lib.nut:1.0.0"` **to the top of your agent code.**

## Class Usage ##

### Constructor: Losant(*appId, apiToken*) ###

Each instance of the class will connect the device with a Losant [application](https://docs.losant.com/applications/overview/) (identified by its ID). All methods will send and receive data via this application only.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *appId* | String | Yes | A Losant Application ID |
| *apiToken* | String | Yes | An [Application API token](https://docs.losant.com/applications/application-tokens/) with Device and Devices permissions |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// ID and API Token for My Losant Application
const LOSANT_APPLICATION_ID   = "<YOUR APPLICATION API TOKEN HERE>";
const LOSANT_DEVICE_API_TOKEN = "<YOUR API TOKEN HERE>";

lsntTrackerApp <- Losant(LOSANT_APPLICATION_ID, LOSANT_DEVICE_API_TOKEN);
```

## Class Methods ##

### Callback Functions ###

All HTTPS requests to Losant are made asynchronously. Each method that makes an HTTP request will have a required callback parameter, a function that will executed when the server responds. The callback function has a single parameter, *response*, into which is passed a table containing the following keys:

| Key | Type | Description |
| --- | --- | --- |
| *statuscode* | Integer | HTTP status code (or libcurl error code) |
| *headers* | Table | Squirrel table of returned HTTP headers |
| *body* | String | Returned HTTP body (if any) |

### createDevice(*deviceInfo, callback*) ###

This method creates a new device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *deviceInfo* | Table | Yes | A table with device info used to create the device. Please see the API documentation for [table details](https://docs.losant.com/rest-api/devices/#post) |
| *callback* | Function | Yes | Called when response is received *(see [Callback Functions](#callback-functions))* |

#### Return Value ####

Nothing.

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
    { "key"   : "agentId",
      "value" : agentId },
    { "key"   : "impDevId",
      "value" :  impDeviceId }
  ],
  "attributes"  :  [
    { "name"     : "location",
      "dataType" : "gps" },
    { "name"     : "temperature",
      "dataType" : "number" },
    { "name"     : "humidity",
      "dataType" : "number" },
    { "name"     : "magnitude",
      "dataType" : "number" },
    { "name"     : "alertTemperature",
      "dataType" : "string" },
    { "name"     : "alertHumidity",
      "dataType" : "string" },
    { "name"     : "alertMovement",
      "dataType" : "string" }
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

This method fetches a list of application devices.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | function | Yes | Called when response is received *(see [Callback Functions](#callback-functions))* |
| *queryParams* | String | No | Query parameters to be added to the URL and which will be used to filter the results. Please see [*createTagFilterQueryParams()*](#createtagfilterqueryparamstags) for an example |

#### Return Value ####

Nothing.

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
    { "key"   : "agentId",
      "value" : agentId },
    { "key"   : "impDevId",
      "value" :  impDeviceId }
  ],
  "attributes"  :  [
    { "name"     : "location",
      "dataType" : "gps" },
    { "name"     : "temperature",
      "dataType" : "number" },
    { "name"     : "humidity",
      "dataType" : "number" },
    { "name"     : "magnitude",
      "dataType" : "number" },
    { "name"     : "alertTemperature",
      "dataType" : "string" },
    { "name"     : "alertHumidity",
      "dataType" : "string" },
    { "name"     : "alertMovement",
      "dataType" : "string" }
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
        });
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

This method retrieves information for the specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | Yes | The device ID assigned by Losant when the device is created |
| *callback* | function | Yes | Called when response is received *(see [Callback Functions](#callback-functions))* |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
lsntTrackerApp.getDeviceInfo(lsntDeviceId, function(response) {
  server.log("Status Code: " + response.statuscode);
  
  // Log device info
  server.log(response.body);
});
```

### updateDeviceInfo(*losantDeviceId, deviceInfo, callback*) ###

This method updates information for the specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | Yes | The device ID assigned by Losant when the device is created |
| *deviceInfo* | Table | Yes | A table containing updated device info. Please see the API documentation for [table details](https://docs.losant.com/rest-api/device/#patch) |
| *callback* | function | Yes | Called when response is received *(see [Callback Functions](#callback-functions))* |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
lsntTrackerApp.updateDeviceInfo(lsntDeviceId, deviceInfo, function(response) {
  server.log("Status Code: " + response.statuscode);
  //Log updated device info
  server.log(response.body);
});
```

### deleteDevice(*losantDeviceId, callback*) ###

This method deletes the specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | Yes | The device ID assigned by Losant when the device is created |
| *callback* | function | Yes | Called when response is received *(see [Callback Functions](#callback-functions))* |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
lsntTrackerApp.deleteDevice(lsntDeviceId, function(response) {
  server.log("Status Code: " + response.statuscode);
  // Log if delete was successful
  server.log(response.body);
});
```

### sendDeviceState(*losantDeviceId, deviceState, callback*) ###

This methiod sends the current state of the device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | Yes | The device ID assigned by Losant when the device is created |
| *deviceState* | Table or array of tables | Yes | The keys in the device-state table(s) should correspond to the device's attributes |
| *callback* | function | Yes | Called when response is received *(see [Callback Functions](#callback-functions))* |

#### Return Value ####

Nothing.

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

This method retrieves the last known state(s) of the specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | Yes | The device ID assigned by Losant when the device is created |
| *callback* | function | Yes | Called when response is received *(see [Callback Functions](#callback-functions))* |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
lsntTrackerApp.getDeviceState(lsntDeviceId, function(response) {
  server.log("Status Code: " + response.statuscode);
  // Log device state
  server.log(response.body);
});
```

### getDeviceCompositeState(*losantDeviceId, callback*) ###

This method retrieves the composite last complete state of the specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | Yes | The device ID assigned by Losant when the device is created |
| *callback* | function | Yes | Called when response is received *(see [Callback Functions](#callback-functions))* |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
lsntTrackerApp.getDeviceCompositeState(lsntDeviceId, function(response) {
  server.log("Status Code: " + response.statuscode);
  // Log device composite state
  server.log(response.body);
});
```

### sendDevicesCommand(*command, callback*) ###

This method sends a command to multiple devices.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *command* | Table | Yes | A command table. Please see the API documentation for [table details](https://docs.losant.com/rest-api/device/#send-command) |
| *callback* | function | Yes | Called when response is received *(see [Callback Functions](#callback-functions))* |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
local cmd = { "time" : lsntTrackerApp.createIsoTimeStamp(),
              "name" : "myCommand",
              "payload" : [1, 1, 2, 3, 5] }

lsntTrackerApp.sendDevicesCommand(cmd, function(response) {
  server.log("Status Code: " + response.statuscode);
  //Log if command was sent successfully
  server.log(response.body);
});
```

### sendDeviceCommand(*losantDeviceId, command, callback*) ###

This method send a command to the specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | Yes | The device ID assigned by Losant when the device is created |
| *command* | Table | Yes | A command table. Please see the API documentation for [table details](https://docs.losant.com/rest-api/device/#send-command) |
| *callback* | function | Yes | Called when response is received *(see [Callback Functions](#callback-functions))* |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
local cmd = { "time" : lsntTrackerApp.createIsoTimeStamp(),
              "name" : "myCommand",
              "payload" : [1, 1, 2, 3, 5] }

lsntTrackerApp.sendDeviceCommand(losantDeviceId, cmd, function(response) {
  server.log("Status Code: " + response.statuscode);
  //Log if command was sent successfully
  server.log(response.body);
});
```

### getDeviceCommand(*losantDeviceId, callback*) ###

This method retrieves the last known commands(s) sent to the specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | Yes | The device ID assigned by Losant when the device is created |
| *callback* | function | Yes | Called when response is received *(see [Callback Functions](#callback-functions))* |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
lsntTrackerApp.getDeviceCommand(lsntDeviceId, function(response) {
  server.log("Status Code: " + response.statuscode);
  // Log commands
  server.log(response.body);
});
```

### openDeviceCommandStream(*losDevId, onData, onError[, keepAliveTimeout]*) ###

This method opens a stream that listens for commands directed at the specified device. 

**Note** Only one stream can be open at a time. If called while a stream is open, *openDeviceCommandStream()* will close the stream that is currently open and will open a new stream.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | Yes | The device ID assigned by Losant when the device is created |
| *onData* | Function | Yes | A function that will be called when a command is received from Losant. It has a single parameter, a table, containing the command received from Losant |
| *onError* | Function | Yes | A function that will be called if the stream is closed unexpectedly or if a command cannot be parsed. It has two parameters: the error encountered, and the response from Losant |
| *keepAliveTimeout* | Integer or float | No | Ammount of time in seconds to wait for a keepalive ping from Losant before closing the stream. Keepalive pings from Losant are sent every two seconds. Default: 30 seconds |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
function onData(command) {
  server.log(command.name);
  server.log(command.payload);
}

onError(error, response) {
  server.error("Error occured while listening for commands.");
  server.error(error);

  if (lsntTrackerApp.isDeviceCommandStreamOpen()) {
    // Parsing error occurred
    server.log(response);
  } else {
    // HTTP error occurred
    if ("statuscode" in response) server.log("Status code: " + response.statuscode);
    
    // Reopen stream
    lsntTrackerApp.openDeviceCommandStream(lsntDeviceId, onData, onError);
  }
}

lsntTrackerApp.openDeviceCommandStream(lsntDeviceId, onData, onError);
```

### closeDeviceCommandStream() ###

This method closes a command stream if one is open.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
lsntTrackerApp.closeDeviceCommandStream();
```

### isDeviceCommandStreamOpen() ###

This method indicates whether a command stream is open.

#### Return Value ####

Boolean &mdash; `true` if a steam is currently open, otherwise `false`.

#### Example ####

```squirrel
server.log("Device command stream is open: " + lsntTrackerApp.isDeviceCommandStreamOpen());
```

### getDeviceLogs(*losantDeviceId, callback*) ###

This method retrieves the recent log entries for the specified device.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *losantDeviceId* | String | Yes | The device ID assigned by Losant when the device is created |
| *callback* | function | Yes | Called when response is received *(see [Callback Functions](#callback-functions))* |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
lsntTrackerApp.getDeviceLogs(lsntDeviceId, function(response) {
  server.log("Status Code: " + response.statuscode);
  // Log device logs
  server.log(response.body);
});
```

### createIsoTimeStamp(*[epochTime]*) ###

This method creates a UTC combined date time timestamp based on the ISO 8601 standard. If a value is passed into *epochTime*, it will be reformatted, otherwise the current time will be used.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *epochTime* | Integer | No | Integer returned by calling *time()*, the current date and time as elapsed seconds since midnight, 1 Jan 1970 |

#### Return Value ####

Sting &mdash; An ISO 8601 timestamp.

#### Example ####

```squirrel
local now = lsntTrackerApp.createIsoTimeStamp();
server.log(now);
```

### createTagFilterQueryParams(*tags*) ###

This method formats a device information tag array into query parameter format.

#### Parameters ####

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| *tags* | Array | Yes | Array of tag tables with slots *key* and/or *value* |

#### Return Value ####

String &mdash; A tag filter query parameter string.

#### Example ####

```squirrel
local searchTags = [
    { "key"   : "agentId",
      "value" : split(http.agenturl(), "/").top() },
    { "value" : imp.configparams.deviceid }
];

local qparams = lsntTrackerApp.createTagFilterQueryParams(searchTags);
```

## License ##

This library is licensed under the [MIT License](LICENSE).

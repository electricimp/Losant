# Losant Environmental Monitor Example #

This example shows how to connect your Electric Imp device to Losant using the Electric Imp Losant library. The example will walk you through how to display data from the device on a Losant dashboard and how to send commands from the dashboard to the device.

## Overview ##

* Configure your impExplorer Kit with BlinkUp
* Create a Losant application
* Run a sample application using impCentral to send sensor data to Losant
* Create a Losant Dashboard

## What you need ##

* Your 2.4GHz 802.11bgn WiFi network name (SSID) and password.
* A computer with a web browser.
* A smartphone with the Electric Imp app ([iOS](https://itunes.apple.com/us/app/electric-imp/id547133856) or [Android](https://play.google.com/store/apps/details?id=com.electricimp.electricimp)).
* A free [Electric Imp Account](https://impcentral.electricimp.com/login).
* A [Losant Account](https://accounts.losant.com/create-account?&redirect=https%3A%2F%2Fapp.losant.com).
* An Electric Imp [impExplorer Kit](https://store.electricimp.com/collections/featured-products/products/impexplorer-developer-kit?variant=31118866130).
* USB power source.

## Hardware ##

This example is written for an [impExplorer Kit](https://store.electricimp.com/collections/featured-products/products/impexplorer-developer-kit?variant=31118866130), but can easily be modified to use with any imp that has an HTS221 temperature/humidity sensor on it. To modify the code to run on a different imp update the device code i2c variable in the EnvMonitor construcor to match the i2c on your hardware.

## Step By Step Instructions ##

### Connect Your Imp ###

* Follow the Electric Imp DevCenter [blinkUp guide](https://developer.electricimp.com/gettingstarted/explorer/blinkup) to conntect your impExplorer Kit.
* Log into your [impCentral](https://impcentral.electricimp.com/login) account.
* Create a new Product and Development Device Group and assign your device to the Group. See [DevCenter guide](https://developer.electricimp.com/gettingstarted/explorer/ide) for step by step instructions.
* Copy and paste the [device](envExample.device.nut) and [agent](envExample.agent.nut) code in the example folder into the corresponding code editor panes.

### Set Up Losant Application ###

* In a new browser tab log into [Losant](https://accounts.losant.com/signin).
* In the Applications tab select *+ Create Application*
* Give the application an *Application Name* and click *Create Application*

### Connect Device To Losant ###

* In the top right of the application page locate the *Application ID* copy it.
* Navigate back to impCentral code editor and in the agent code LosantApp locate the *LOSANT_APPLICATION_ID* constant.
* Paste the *Application ID* into the *LOSANT_APPLICATION_ID* constant.
* Navigate back to Losant and click on the *Security* tab.
* Select *APPLICATION API TOKENS* from the left sidebar.
* Click *+ Add Application Token* and give the token a name.
* Click *Create Application Token*.
* Copy the *API token* from the pop-up window. Do not dismiss this window until after the token is saved in the code editor.
* Navigate back to impCentral code editor and and in the agent code LosantApp locate the *LOSANT_API_TOKEN* constant.
* Paste the *API token* into the *LOSANT_API_TOKEN* constant.
* Hit *Build and Force Restart* to save and launch the code.
* Navigate back to Losant, click the checkbox in the pop-up acknowledging the token has been copied and close the pop-up.
* In the Applications nav bar. Select your Application name (the first tab on the left)
* Your device should now appear under the *Devices* section. Make a note of the device name.

### Create A Dashboard ###

* Under the *Dashboard* tab select *+ Create Dashboard*
* Give the dashboard a name and click *Create Dahsboard*
* Add a *Time Series Graph* by clicking the *Customize* button in that block.
* In the *Select Application* section in the *Choose an Application* dropdown make sure the selected application matches your Losant application name.
* Under *Data Type* section select *Live Stream*
* In the *Block Data* section
    * Your device should already be added to the *Device Ids/Tags*. If not select the device with the name matching your device.
    * In the *Attributes* dropdown select *temperature*.
    * Update the *Series Label* to *Temperature*.
    * Click *Add Segment*.
    * In the *Device Ids/Tags* dropdown select your device.
    * In the *Attributes* dropdown select *humidity*.
    * Update the *Series Label* to *Humidity*.
* Click *Add Block*
* Click the gear icon on the top right of the dashboard.
* Click *+ Add Block*
* Find *Input Controls* and click *Customize*
* In *Configure Block* section click *Add Control*
* Select *Button Trigger* from dropdown.
    * Update label to *Send Device Command"*
    * Uner *On Click* make sure *Send Device Command* is selected.
    * In the *Device Ids/Tags* dropdown select your device.
    * Under *Command Name* give your command a name.
    * In *Payload* write a message like "Sending test message"
* Under *Default Mode* section select *Unlock*
* Click *Add Block*

### Send Command To Device ###

* In the dashboard click the button trigger.
* Navigate back to the code editor and view the logs. Each time the button is clicked in the dashboard a log with the command name and message should be logged.

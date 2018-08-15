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

This example is written for an [impExplorer Kit](https://store.electricimp.com/collections/featured-products/products/impexplorer-developer-kit?variant=31118866130), but can easily be modified to use with any imp that has an HTS221 temperature/humidity sensor on it. To use a different imp modify the device code i2c variable in the EnvMonitor construcor to match the i2c on your hardware.

![Device code i2c variable](imgs/device_i2c.png "device code i2c variable")

## Step By Step Instructions ##

### Connect Your Imp ###

* Follow the Electric Imp DevCenter [blinkUp guide](https://developer.electricimp.com/gettingstarted/explorer/blinkup) to conntect your impExplorer Kit.
* Log into your [impCentral](https://impcentral.electricimp.com/login) account.
* Create a new Product and Development Device Group and assign your device to the Group. See [DevCenter guide](https://developer.electricimp.com/gettingstarted/explorer/ide) for step by step instructions.
* Copy and paste the [device](envExample.device.nut) and [agent](envExample.agent.nut) code in the example folder into the corresponding code editor panes.

![Empty impCentral ide](imgs/1_empty_ide_labeled.png "Empty impCentral ide")

### Set Up Losant Application ###

* In a new browser tab log into [Losant](https://accounts.losant.com/signin).
* In the Applications tab select *+ Create Application*
![Create Losant app navigation](imgs/2_create_losant_app.png "Create Losant app navigation")
* Give the application an *Application Name* and click *Create Application*
![Create Losant app form](imgs/3_losant_app_form.png "Create Losant app form")

### Connect Device To Losant ###

* In the top right of the application page locate the *Application ID* copy it.
![Locate app id](imgs/4_app_id.png "Locate app id")
* Navigate back to impCentral code editor and in the agent code LosantApp locate the *LOSANT_APPLICATION_ID* constant.
![Find app id constant](imgs/5_ide_tokens_highlighted.png "Find app id constant")
* Paste the *Application ID* into the *LOSANT_APPLICATION_ID* constant.
* Navigate back to Losant and click on the *Security* tab.
* Select *APPLICATION API TOKENS* from the left sidebar and click *+ Add Application Token*.
![Application API token navigation](imgs/6_app_api_token_nav.png "Application API token navigation")
* Give the token a name and click *Create Application Token*.
![Create app API token](imgs/7_create_app_token.png "Create app API token")
* Copy the *API token* from the pop-up window. Do not dismiss this window until after the token is saved in the code editor.
![Copy app API token](imgs/8_api_token_popup.png "Copy app API token")
* Navigate back to impCentral code editor and and in the agent code LosantApp locate the *LOSANT_API_TOKEN* constant.
* Paste the *API token* into the *LOSANT_API_TOKEN* constant.
* Hit *Build and Force Restart* to save and launch the code.
![impCentral enter api token and build](imgs/9_ide_api_token_build.png "impCentral enter api token and build")
* Navigate back to Losant, click the checkbox in the pop-up acknowledging the token has been copied and close the pop-up.
![Dismiss app API token popup](imgs/10_app_api_token_dismiss.png "Dismiss app API token popup")
* In the Applications nav bar. Select your Application name (the first tab on the left)
![Navigate to application main page](imgs/11_navigate_to_app.png "Navigate to application main page")
* Your device should now appear under the *Devices* section. Make a note of the device name.
![Find device name](imgs/12_device_name.png "Find device name")

### Create A Dashboard ###

* Under the *Dashboard* tab select *+ Create Dashboard*
![Create a dashboard](imgs/13_create_dashboard.png "Create a dashboard")
* Give the dashboard a name and click *Create Dahsboard*
![Name a dashboard](imgs/14_name_dashboard.png "Name a dashboard")
* Add a *Time Series Graph* by clicking the *Customize* button in that block.
![Add graph widget to dashboard](imgs/15_add_graph.png "Add graph widget to dashboard")
* In the *Select Application* section in the *Choose an Application* dropdown make sure the selected application matches your Losant application name.
* Under *Data Type* section select *Live Stream*
![Select app and data type](imgs/16_graph_live_stream.png "Select app and data type")
* In the *Block Data* section
    * (1) Your device should already be added to the *Device Ids/Tags*. If not select the device with the name matching your device.
    * (2) In the *Attribute* dropdown select *temperature*.
    * (3) Update the *Series Label* to *Temperature*.
    * (4) Click *Add Segment*.
    ![Add temp data to graph](imgs/17_graph_temp.png "Add temp data to graph")
    * (1) In the *Device Ids/Tags* dropdown select your device.
    * (2) In the *Attribute* dropdown select *humidity*.
    * (3) Update the *Series Label* to *Humidity*.
* (4) Click *Add Block*
![Add humidity data to graph](imgs/18_graph_humid.png "Add humidity data to graph")
* Click the gear icon on the top right of the dashboard.
* Click *+ Add Block*
![Add another block to dashboard](imgs/19_graph_humid.png "Add another block to dashboard")
* Find *Input Controls* and click *Customize*
![Add input controls block to dashboard](imgs/20_add_input_controls.png "Add input controls block to dashboard")
* In the *Select Application* section in the *Choose an Application* dropdown make sure the selected application matches your Losant application name.
* In *Configure Block* section click *Add Control*
* Select *Button Trigger* from dropdown.
![Configure input contol block](imgs/21_add_control_button.png "Configure input contol block")
* In the *Configure Block* section
    * (1) Update label to *Send Device Command"*
    * (2) Under *On Click...* make sure *Send Device Command* is selected.
    * (3) In the *Device Ids/Tags* dropdown select your device.
    * (4) Under *Command Name* give your command a name.
    * (5) In *Payload* write a message like "Sending test message"
    ![Configure device command](imgs/22_device_command.png "Configure device command")
* Under *Default Mode* section select *Unlock*
* Click *Add Block*
![Add input control block](imgs/23_unlock_button.png "Add input control block")

### Send Command To Device ###

* In the dashboard click the button trigger.
![Click button to send device a command](imgs/24_dashboard.png "Click button to send device a command")
* Navigate back to the code editor and view the logs. Each time the button is clicked in the dashboard a log with the command name and message should be logged.
![Check device logs for command from Losant](imgs/25_log_command.png "Check device logs for command from Losant")
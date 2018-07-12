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


// Temperature Humidity sensor Library
#require "HTS221.device.lib.nut:2.0.1"


class EnvMonitor {

    static READING_INT_SEC = 30;

    _th  = null;

    constructor() {
        // Configure Explorer Kit Temp/Humid sensor
        local i2c = hardware.i2c89;
        i2c.configure(CLOCK_SPEED_400_KHZ);

        _th = HTS221(i2c, 0xBE);
        _th.setMode(HTS221_MODE.ONE_SHOT);

        // Start taking readings
        readingLoop();
    }

    function readingLoop() {
        // Take a reading
        _th.read(function(result) {
            if ("temperature" in result || "humidity" in result) {
                // If we got a valid reading send to agent
                agent.send(result);
            }
        }.bindenv(this));

        // Schedule next reading
        imp.wakeup(READING_INT_SEC, readingLoop.bindenv(this));
    }
}

EnvMonitor();
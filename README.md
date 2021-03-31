# HTCC
[![Gem Version](https://badge.fury.io/rb/htcc.svg)](https://badge.fury.io/rb/htcc)

This gem is a Ruby client for the Honeywell Total Connect Comfort API.

I have only tested it with the Honeywell Home Wi-Fi 7-Day Programmable Thermostat (RTH6580WF), but it should work with any thermostats that use Total Connect Comfort for remote control. I would be interested in knowing what other devices have for `thermostat.info['DeviceType']`. I'm currently initializing everything as an instance of `HTCC::Thermostat`.

Currently, settings and scheduling are a work in progress.

## Installation
`gem install htcc`

You can also test it out by forking this respository and running `docker-compose run htcc`.
## Basic Usage
```ruby
htcc = HTCC::Client.new('tcc_login@example.com', 'password')
# => #<HTCC::Client:0x0000abc123 @debug=false...>
```

Get first device.
```ruby
thermostat = htcc.devices.first
# => #<HTCC::Thermostat:0x0000abc123 @info={"DeviceID"=>...>
```

Get the current ambient temperature.
```ruby
thermostat.current_temperature
# => 71
```

Get current setpoint for heat.
```ruby
thermostat.heat_setpoint
# => 70
```

Set the heat setpoint to desired temperature with a temporary hold. Returns to scheduled temperature at the next scheduled time.
```ruby
thermostat.heat_setpoint = 72
# => 72
```

## `HTCC::Client` Usage
```ruby
htcc = HTCC::Client.new('tcc_login@example.com', 'password', debug: true, debug_output: $stdout)
# => #<HTCC::Client:0x0000abc123 @debug=true...>
```
`debug` determines whether to display the HTTP request/response data (boolean, default: `false`)

>__Warning!__ If `debug` is set to `true` when initializing the `HTCC::Client` instance, it will display the login and password in plain text. You can also set `debug` to `true` *after* initializing the client. However, this will also display sensitive data such as cookies for every request. See `Net::HTTP` documentation. __Use at your own risk__.

`debug_output` sets the output stream for debugging (Used by `Net::HTTP#set_debug_output`, default: `$stdout`).

Display HTTP request/response data.
```ruby
htcc.debug = true
# => true
```
> __See above warning.__

Check if log in was successful.
```ruby
htcc.logged_in?
# => true
```

Get list of devices associated with logged in account Accepts an optional boolean argument to refresh the device list (default: `false`).
```ruby
htcc.devices
# => [#<HTCC::Thermostat:0x0000abc123...>]

htcc.devices(true)
# => [#<HTCC::Thermostat:0x0000abc123...>]
```

## `HTCC::Thermostat` Usage
Get information about the thermostat.
```ruby
thermostat.info
# => {"DeviceID=>1234567, "DeviceType"=>24, "LocationID=>0123456, "Name"=>"THERMOSTAT", "IsAlive"=>true...}
```

Get device ID.
```ruby
thermostat.id
# => 1234567
```

Get device MAC address.
```ruby
thermostat.mac_address
# => "00A00B0C00D000"
```

Get device name.
```ruby
thermostat.name
# => "THERMOSTAT"
```

Get connection status.
```ruby
thermostat.connected?
# => true
```

Get the status of the device. Accepts an optional boolean argument to refresh the status (default: `false`).
```ruby
thermostat.status
# => {"success"=>true, "deviceLive"=>true, "communicationLost"=>false, "latestData"=>...}

thermostat.status(true)
# => {"success"=>true, "deviceLive"=>true, "communicationLost"=>false, "latestData"=>...}
```

Get current system mode. Returns `:emergency_heat`, `:heat`, `:off`, `:cool`, or `:auto` depending on the capabilities of your device.
```ruby
thermostat.system_mode
# => :heat
```

Set system mode. Returns an `HTCC::Thermostat::SystemError` if desired mode is not present.
```ruby
thermostat.system_mode = :cool
# => :cool

thermostat.system_mode = :emergency_heat
# => HTCC::Thermostat::SystemError (Unknown mode: :emergency_heat. Allowed modes: [:heat, :off, :cool, :auto])
```

Check if the device has a fan.
```ruby
thermostat.has_fan?
# => true
```

Check if the fan is running.
```ruby
thermostat.fan_running?
# => false
```

Get the fan mode. Returns `:auto`,  `:on`,  `:circulate`, or `:schedule` depending on the capabilities of your device.
```ruby
thermostat.fan_mode
# => :auto
```

Set the fan mode. Returns an `HTCC::Thermostat::FanError` if desired mode is not present.
```ruby
thermostat.fan_mode = :on
# => :on

thermostat.fan_mode = :circulate
# => HTCC::Thermostat::FanError (Unknown mode: :circulate. Allowed modes: [:auto, :on])
```

Get the current ambient temperature.
```ruby
thermostat.current_temperature
# => 72
```

Get the current temperature unit ("C" or "F").
```ruby
thermostat.temperature_unit
# => "F"
```

Get the temperature that is set for cooling.
```ruby
thermostat.cool_setpoint
# => 68
```

Set the temperature for cooling. Uses a temporary hold that returns to scheduled temperature at the next scheduled time. Returns an `HTCC:Thermostat::TemperatureError` if the given temperature is out of range.
```ruby
thermostat.cool_setpoint = 70
# => 70

thermostat.cool_setpoint = 32
# => HTCC::Thermostat::TemperatureError (Minimum setpoint is 50. Given: 32)
```

Get the cool setpoint range.
```ruby
thermostat.cool_setpoint_range
# => 50..99
```

Get the temperature that is set for heating.
```ruby
thermostat.heat_setpoint
# => 72
```

Set the temperature for heating. Uses a temporary hold that returns to scheduled temperature at the next scheduled time. Returns an `HTCC:Thermostat::TemperatureError` if the given temperature is out of range.
```ruby
thermostat.heat_setpoint = 74
# => 74

thermostat.heat_setpoint = 100
# => HTCC::Thermostat::TemperatureError (Maximum setpoint is 90. Given: 100)
```

Get the heat setpoint range.
```ruby
thermostat.heat_setpoint_range
# => 40..90
```

Get the current hold status. Returns `:none`, `:temporary`, or `:permanent` depending on the capabilities of your device.
```ruby
thermostat.hold
# => :none
```

Set a hold. Returns an `HTCC::Thermostat::HoldError` if desired mode is not present.
```ruby
thermostat.hold = :temporary
# => :temporary

thermostat.hold = :permanent
# => HTCC::Thermostat::HoldError (Unknown mode: :permanent. Allowed modes: [:none, :temporary])
```

Get the time a temporary hold ends. Returns a 24-hour formatted string (HH:MM). If the current hold is `:permanent`, this time is ignored unless the hold is changed to `:temporary`.
```ruby
thermostat.hold_until
# => "22:15"
```

Set a temporary hold until a given time. Time must be in a zero-padded 24-hour format (HH:MM). Time begin at 00:00 (midnight) to 23:45. Minutes must be in quarter hours (:00, :15, :30, :45). Returns an `HTCC::Thermostat::HoldError` if given time is not valid.
```ruby
thermostat.hold_until = '05:45'
# => "05:45"

thermostat.hold_until = '05:46'
# => HTCC::Thermostat::HoldError (Unknown hold time: "05:46". Valid times are from 00:00 - 23:45 in 15 minute intervals.)
```

Clear out any holds and resume heating/cooling schedule (same as `thermostat.hold = :none`).
```ruby
thermostat.resume_schedule
# => true
```

Get the current output status. Returns `:off`, `:heating`, `:cooling`, or `:fan_running` depending on the capabilities of your device.
```ruby
thermostat.output_status
# => :cooling
```

Get the available system modes.
```ruby
thermostat.system_modes
# => [:heat, :off, :cool, :auto]
```

Get the available fan modes.
```ruby
thermostat.fan_modes
# => [:auto, :on]
```

Call a property without making an API request to the TCC API (using the in-memory data).
```ruby
thermostat.no_refresh { thermostat.current_temperature }
# => 78
```

## `HTCC::Scheduler` Usage
TODO

## `HTCC::Settings` Usage
TODO
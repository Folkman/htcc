# HTCC

This gem is a Ruby client for the Honeywell Total Connect Comfort API.

I have only tested it with the Honeywell Home Wi-Fi 7-Day Programmable Thermostat (RTH6580WF), but it should work with any thermostats that use Total Connect Comfort for remote control. I would be interested in knowing what other devices have for `thermostat.info['DeviceType']`. I'm currently initializing everything as an instance of `HTCC::Thermostat`.

Currently, settings and scheduling are a work in progress.

## Installation
`gem install htcc`

You can also test it out by forking this respository and running `docker-compose run htcc`.
## Basic Usage
```ruby
htcc = HTCC::Client.new('login@example.com', 'password')
# => #<HTCC::Client: 0x0000abc123 @debug=false...>
```

Get first device:
```ruby
thermostat = httc.devices.first
# => #<HTCC::Thermostat:0x0000abc123 @info={"DeviceID"=>...>
```

Get the current ambient temperature:
```ruby
thermostat.current_temperature
# => 71
```

Get current setpoint for heat:
```ruby
thermostat.heat_setpoint
# => 70
```

Set the heat setpoint to desired temperature with a temporary hold (returns to scheduled temperature at the next scheduled time):
```ruby
thermostat.heat_setpoint = 72
# => 72
```

## `HTTC::Client` Usage
```ruby
htcc = HTCC::Client.new('tcc_login@example.com', 'password', debug: true, debug_output: $stdout)
# => #<HTCC::Client: 0x0000abc123 @debug=true...>
```
`debug` determines whether to display the HTTP request/response data (boolean, defaul: `false`)

>__Warning:__ If `debug` is set to `true` when initializing the `HTTC::Client` instance, it will display the login and password in plain text (see `Net::HTTP` documentation). You can also set `debug` to `true` *after* initializing the client. However, this will also display sensitive data such as cookies for every request. __Use at your own risk__.

`debug_output` sets the output stream for debugging (Used by `Net::HTTP#set_debug_output`, default: `$stdout`).

Check if log in was successful:
```ruby
htcc.logged_in?
# => true
```

Refresh devices list:
```ruby
htcc.refresh_devices
# => [#<HTTC::Thermostat:0x0000abc123...>]
```

Display HTTP request/response data:
```ruby
htcc.debug = true
# => true
```
> __See above warning.__


## `HTTC::Thermostat` Usage
Get information about the thermostat:
```ruby
thermostat.info
# => {"DeviceID=>1234567, "DeviceType"=>24, "LocationID=>0123456, "Name"=>"THERMOSTAT", "IsAlive"=>true...}
```

Get device ID:
```ruby
thermostat.id
# => 1234567
```

Get device MAC address:
```ruby
thermostat.mac_address
# => "00A00B0C00D000"
```

Get device name:
```ruby
thermostat.name
# => "THERMOSTAT"
```

Get connection status:
```ruby
thermostat.connected?
# => true
```

Get the status of the device (optional boolean argument to refresh the status, default: `false`):
```ruby
thermostat.status
# => {"success"=>true, "deviceLive"=>true, "communicationLost"=>false, "latestData"=>...}

thermostat.status(true)
# => {"success"=>true, "deviceLive"=>true, "communicationLost"=>false, "latestData"=>...}
```

Get current system mode (returns `:emergency_heat`, `:heat`, `:off`, `:cool`, or `:auto` depending on the capabilities of your device):
```ruby
thermostat.system_mode
# => :heat
```

Set system mode (returns an `HTCC::Thermostat::SystemError` if desired mode is not present):
```ruby
thermostat.system_mode = :cool
# => :cool

thermostat.system_mode = :emergency_heat
# => HTCC::Thermostat::SystemError (Unknown mode: :emergency_heat. Allowed modes: [:heat, :off, :cool, :auto])
```

Check if the device has a fan:
```ruby
thermostat.has_fan?
# => true
```

Check if the fan is running:
```ruby
thermostat.fan_running?
# => false
```

Get the fan mode (returns `:auto`,  `:on`,  `:circulate`, or `:schedule` depending on the capabilities of your device):
```ruby
thermostat.fan_mode
# => :auto
```

Set the fan mode (returns an `HTCC::Thermostat::FanError` if desired mode is not present):
```ruby
thermostat.fan_mode = :on
# => :on

thermostat.fan_mode = :circulate
# => HTCC::Thermostat::FanError (Unknown mode: :circulate. Allowed modes: [:auto, :on])
```

Get the current ambient temperature:
```ruby
thermostat.current_temperature
# => 72
```

Get the current temperature unit ("C" or "F"):
```ruby
thermostat.temperature_unit
# => "F"
```

Get the temperature that is set for cooling:
```ruby
thermostat.cool_setpoint
# => 68
```

Set the temperature for cooling (uses a temporary hold that returns to scheduled temperature at the next scheduled time):
```ruby
thermostat.cool_setpoint = 70
# => 70
```

Get the temperature that is set for heating:
```ruby
thermostat.heat_setpoint
# => 72
```

Set the temperature for heating (uses a temporary hold that returns to scheduled temperature at the next scheduled time):
```ruby
thermostat.heat_setpoint = 74
# => 74
```

Clear out any holds and resume heating/cooling schedule:
```ruby
thermostat.resume_schedule
# => true
```

Get the current hold status (returns `:none`, `:temporary`, or `:permanent` depending on the capabilities of your device):
```ruby
thermostat.hold
# => :none
```

Set a hold (returns an `HTCC::Thermostat::HoldError` if desired mode is not present):
```ruby
thermostat.hold = :temporary
# => :temporary

thermostat.hold = :permanent
# => HTCC::Thermostat::HoldError (Unknown mode: :permanent. Allowed modes: [:none, :temporary])
```

Get the current output status (returns `:off`, `:heating`, `:cooling`, or `:fan_running` depending on the capabilities of your device):
```ruby
thermostat.output_status
# => :cooling
```

Get the available system modes:
```ruby
thermostat.system_modes
# => [:heat, :off, :cool, :auto]
```

Get the available fan modes:
```ruby
thermostat.fan_modes
# => [:auto, :on]
```

Call a property without making an API request to the TCC API (using the in memory data):
```ruby
thermostat.no_refresh { thermostat.current_temperature }
# => 78
```

## `HTTC::Scheduler` Usage
TODO

## `HTTC::Settings` Usage
TODO
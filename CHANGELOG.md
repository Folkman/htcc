# Changelog

## 0.2.0 (29-March-2021)
* __Breaking changes:__
  * Removed `#refresh_devices` method from `HTCC::Client` in favor of `#devices(true)` for consistency with `HTCC::Thermostat#status` method.

* __New Features:__
  * Add `#cool_setpoint_range` and `#heat_setpoint_range` to `HTCC::Thermostat` for obtaining heating/cooling setpoint limits.
  * Add documentation regarding limits for heat/cool setpoints.

* __Bug Fixes:__
  * Fix README typos.

## 0.1.1 (28-March-2021)

* __Bug Fixes:__
  * Private `HTCC::Thermostat` method `#get_status` should check if `@status` is `empty?`

## 0.1.0 (28-March-2021)

* Initial release

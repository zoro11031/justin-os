# PipeWire Configuration

This directory contains custom PipeWire configuration overrides for justin-os.

## RAOP (AirPlay) Discovery Disabled

The `pipewire.conf.d/50-disable-raop.conf` file disables automatic discovery of AirPlay/RAOP audio receivers.

### What does this do?

- Prevents PipeWire from loading the RAOP discovery module
- Stops automatic creation of virtual audio sinks for AirPlay receivers on your network
- Removes unwanted AirPlay devices from appearing in KDE's audio device list and applications like Discord

### Background

On Fedora 43, the `pipewire-config-raop` package installs a config file (`50-raop.conf`) that causes PipeWire to automatically discover AirPlay receivers via Avahi/mDNS. This configuration override disables that behavior.

### Verify it's working

After rebasing to this image and rebooting:

1. Check if the RAOP module is loaded:
   ```bash
   pw-cli list-objects | grep raop
   ```

   If disabled correctly, you should see no output or the module should not be creating devices.

2. Check audio sinks:
   ```bash
   pactl list sinks short
   ```

   AirPlay devices should no longer appear in the list.

3. Check PipeWire config:
   ```bash
   pw-dump | grep -i raop
   ```

### Re-enabling RAOP discovery

If you want to re-enable AirPlay device discovery:

1. Remove or rename the override file:
   ```bash
   mv ~/.config/pipewire/pipewire.conf.d/50-disable-raop.conf{,.disabled}
   ```

2. Restart PipeWire:
   ```bash
   systemctl --user restart pipewire pipewire-pulse
   ```

### Requirements

- PipeWire 1.4.6 or newer (included in Fedora 43+)
- The `raop.discover` context property is supported in PipeWire 1.4.6+

## References

- [PipeWire RAOP Discovery Module](https://man.archlinux.org/man/libpipewire-module-raop-discover.7.en.html)
- [Fedora PipeWire Configuration](https://docs.fedoraproject.org/en-US/quick-docs/pipewire/)

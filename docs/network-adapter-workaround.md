# GEEKOM A5 network adapter workaround

This note documents the network workaround used on the GEEKOM A5 devbox running
Ubuntu 26.04.

Observed hardware:

- Wi-Fi: Realtek RTL8852BE PCIe 802.11ax, PCI ID `10ec:b852`
- Wi-Fi driver: `rtw89_8852be`
- Ethernet: Realtek RTL8125 2.5GbE, PCI ID `10ec:8125`
- Observed problematic Wi-Fi firmware: `0.29.29.15`
- Connection where the Wi-Fi issue was reproduced: 5 GHz

The Wi-Fi failure presented as degraded connectivity followed by loss of scan
results. In the worst case the PCIe Wi-Fi adapter disappeared until the machine
was fully powered off and drained.

The current workaround is to disable Wi-Fi and PCIe power-saving features for
the `rtw89` driver. Keep the firmware rollback below as a fallback only if the
power-saving workaround does not remain stable.

## Disable RTL8852BE power saving

Create `/etc/modprobe.d/rtw89.conf`:

```conf
options rtw89_core disable_ps_mode=y
options rtw89_pci disable_clkreq=y disable_aspm_l1=y disable_aspm_l1ss=y
```

These options disable the driver's firmware power-save mode and the PCIe
CLKREQ/ASPM states that can trigger failures on systems with problematic PCIe
power-state handling.

Also disable NetworkManager Wi-Fi power saving by creating
`/etc/NetworkManager/conf.d/wifi-powersave.conf`:

```ini
[connection]
wifi.powersave = 2
```

Apply the configuration:

```bash
sudo update-initramfs -u
sudo reboot
```

Do not unload/reload the Wi-Fi modules remotely unless another network path is
available. A reboot is safer because the adapter itself may already be in a bad
PCIe power state.

After reboot, verify the module parameters:

```bash
for parameter in \
  /sys/module/rtw89_core/parameters/disable_ps_mode \
  /sys/module/rtw89_pci/parameters/disable_clkreq \
  /sys/module/rtw89_pci/parameters/disable_aspm_l1 \
  /sys/module/rtw89_pci/parameters/disable_aspm_l1ss
do
  printf '%s: ' "$parameter"
  cat "$parameter"
done
```

All four values should be `Y`.

Verify the detected hardware and loaded firmware:

```bash
lspci -nnk | grep -A4 -Ei 'network|wireless|realtek'
sudo dmesg | grep -Ei 'rtw89|firmware version'
```

The power-saving workaround increases power use slightly. That is acceptable for
this always-powered mini PC.

## Recovery when the adapter disappears

If the RTL8852BE no longer appears in `lspci`, reloading NetworkManager or the
driver is unlikely to recover it because the PCIe device itself is no longer
enumerated.

Check first:

```bash
lspci -nn | grep -Ei 'network|realtek'
```

If the Wi-Fi device is absent:

1. Shut the GEEKOM A5 down completely.
2. Disconnect DC power.
3. Hold the power button for about 60 seconds.
4. Reconnect power and boot.
5. Confirm that `10ec:b852` is visible in `lspci` again.

If this remains necessary after the power-saving workaround, investigate BIOS,
PCIe power management, card seating, or hardware failure rather than repeatedly
reinstalling the driver.

## Optional firmware rollback for unstable 5 GHz

Ubuntu bug 2161558 reports an RTL8852BE regression on Ubuntu 26.04 where
firmware `0.29.29.15` produces unstable 5 GHz connectivity. The reported system
became stable while remaining on Ubuntu 26.04 and kernel 7.0 after replacing only
the RTL8852B firmware with the Ubuntu 24.04.2 version `0.29.29.5`.

Do this only if the power-saving workaround is insufficient.

First confirm the currently loaded version:

```bash
sudo dmesg | grep -Ei 'rtw89.*firmware|Firmware version'
```

The problematic case observed on this machine was:

```text
Firmware version 0.29.29.15
```

### Download the known-good Ubuntu 24.04 firmware package

The bug report identifies the working package as
`linux-firmware 20240318.git3b128b60-0ubuntu2.17`.

Download the exact package from Launchpad:

```bash
mkdir -p ~/tmp/rtl8852be-firmware
cd ~/tmp/rtl8852be-firmware

firmware_deb=linux-firmware_20240318.git3b128b60-0ubuntu2.17_amd64.deb

wget \
  "https://launchpadlibrarian.net/814092036/${firmware_deb}" \
  -O "${firmware_deb}"

echo "a53bd21267903964a85dbe9b03ac054e6c1c3f22879c72d210746c3f1c8c7915  ${firmware_deb}" \
  | sha256sum -c -
```

Extract it without installing or downgrading the whole `linux-firmware`
package:

```bash
rm -rf extracted
dpkg-deb -x "${firmware_deb}" extracted
```

Verify the two RTL8852B files against the hashes reported in Ubuntu bug 2161558:

```bash
cd extracted/lib/firmware/rtw89

echo "5ac329e88f5d8cd5bb87cf83d1b331b95683fe2618affb6367939eb552634e94  rtw8852b_fw-1.bin.zst" \
  | sha256sum -c -

echo "3a2f35f44cdbe02c1b372c117d081825a4d23a77ff3529ac862756021ea9e9a7  rtw8852b_fw.bin.zst" \
  | sha256sum -c -
```

Do not proceed if either checksum fails.

### Back up and replace only the RTL8852B firmware

Inspect the installed files first:

```bash
ls -l /lib/firmware/rtw89/rtw8852b_fw*.bin*
```

Back them up:

```bash
backup_dir="/var/backups/rtw89-rtl8852be-$(date +%Y%m%d-%H%M%S)"
sudo install -d -m 0755 "${backup_dir}"
sudo cp -a /lib/firmware/rtw89/rtw8852b_fw*.bin* "${backup_dir}/"
printf 'Backup: %s\n' "${backup_dir}"
```

From `~/tmp/rtl8852be-firmware/extracted/lib/firmware/rtw89`, replace only the
two affected firmware files:

```bash
cd ~/tmp/rtl8852be-firmware/extracted/lib/firmware/rtw89

sudo install -m 0644 rtw8852b_fw-1.bin.zst \
  /lib/firmware/rtw89/rtw8852b_fw-1.bin.zst

sudo install -m 0644 rtw8852b_fw.bin.zst \
  /lib/firmware/rtw89/rtw8852b_fw.bin.zst

sudo update-initramfs -u
sudo reboot
```

After reboot:

```bash
sudo dmesg | grep -Ei 'rtw89.*firmware|Firmware version'
```

Expected firmware:

```text
Firmware version 0.29.29.5 (da87cccd)
```

The Ubuntu report found this stable on 5 GHz while retaining Ubuntu 26.04,
kernel 7.0, and the in-kernel `rtw89_8852be` driver.

A later `linux-firmware` package upgrade can overwrite this manual rollback.
After firmware updates, re-check the loaded firmware version before assuming the
rollback is still active. Do not hold all Linux firmware updates indefinitely
just to preserve this workaround.

### Restore the distribution firmware

Use the backup directory printed during the rollback:

```bash
backup_dir=/var/backups/rtw89-rtl8852be-YYYYMMDD-HHMMSS

sudo cp -a "${backup_dir}"/rtw8852b_fw*.bin* /lib/firmware/rtw89/
sudo update-initramfs -u
sudo reboot
```

Alternatively, reinstall the Ubuntu 26.04 firmware package that owns the files,
then rebuild the initramfs.

## Ansible handoff

Automate the power-saving workaround as the normal GEEKOM A5 configuration.
Keep the firmware rollback opt-in.

Recommended desired state:

- Manage `/etc/modprobe.d/rtw89.conf` with the four `rtw89` power options.
- Manage `/etc/NetworkManager/conf.d/wifi-powersave.conf` with
  `wifi.powersave = 2`.
- Notify a handler to rebuild initramfs when the modprobe configuration changes.
- Treat the required reboot as an explicit operational step rather than
  unloading the Wi-Fi driver during provisioning.
- Gate the workaround to the GEEKOM A5 devbox or verify PCI ID `10ec:b852`
  before applying it.
- Keep firmware `0.29.29.5` rollback behind an explicit variable such as
  `geekom_rtl8852be_firmware_rollback: false`.
- If firmware rollback is enabled, verify both source SHA-256 hashes before
  writing anything under `/lib/firmware/rtw89/`.
- Back up existing firmware before replacement and rebuild initramfs afterward.
- Do not install the out-of-tree `lwfinger/rtw89` driver by default. Ubuntu's
  kernel already provides `rtw89_8852be`, and mixing in-kernel and out-of-tree
  modules makes diagnosis harder.

## References

- Ubuntu bug 2161558: https://bugs.launchpad.net/ubuntu/+source/linux-firmware/+bug/2161558
- Ubuntu bug mailing-list copy with firmware versions and hashes:
  https://www.mail-archive.com/ubuntu-bugs@lists.ubuntu.com/msg6295717.html
- `lwfinger/rtw89` driver notes and available power parameters:
  https://github.com/lwfinger/rtw89

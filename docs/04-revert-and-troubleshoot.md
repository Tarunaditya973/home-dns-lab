# 4. Revert and troubleshoot

## Revert (about two minutes)
1. Open the router page by **IP address**, for example `http://192.168.0.1`. It is an address,
   not a name, so it works even when DNS is broken.
2. Network → Internet → untick **"Use the following DNS addresses"** → **Save**.
   Unticking does nothing until you Save. The connection restarts for 10 to 30 seconds.
3. If you also disabled IPv6, tick **IPv6: Enable** again and Save.
4. Toggle Wi-Fi on your devices so they renew their DNS.
5. Check: `scutil --dns | grep nameserver` should list your ISP's servers again.

If you made a router backup first, restoring it is the second safety net.

## Stop or remove AdGuard Home
```
sudo ~/AdGuardHome/AdGuardHome -s stop        # stops it until restarted or a reboot
sudo ~/AdGuardHome/AdGuardHome -s uninstall   # removes the service so it does not return at boot
rm -rf ~/AdGuardHome                          # deletes the program, config and logs
```
`stop` leaves the launch daemon installed, so the service comes back after a restart.
Revert the router **before** uninstalling, or DNS stops working for the whole network.

## Common problems
| Symptom | Cause and fix |
|---|---|
| "Page unresponsive" while saving router settings | The router is restarting its connection. Close the tab, wait 30 seconds, reload. Check the reachability: `ping 192.168.0.1` |
| A device has Wi-Fi but no sites load after AdGuard Home stops | It still holds the old DNS from its lease. Toggle its Wi-Fi |
| My computer still uses the ISP's DNS after the router change | It has not renewed. Toggle Wi-Fi, then `scutil --dns` |
| `dig` returns NXDOMAIN for everything | You passed a URL. Use a bare hostname |
| `sudo: a terminal is required to read the password` | Run the command in a real Terminal window |
| Site loads in Chrome but not in other apps | Chrome's Secure DNS is on and the system resolver is not. Use a system-wide solution |
| Encrypted DNS gives the real address but the page will not load | The block is at the IP or SNI level, not DNS |

## Useful commands
```
dig example.com | grep SERVER             # which resolver you queried (not proof of who answered)
dscacheutil -q host -a name example.com   # what apps resolve (macOS)
scutil --dns                              # DNS servers per network interface (macOS)
arp -a                                    # devices your computer has talked to on the LAN
```
`dig`'s `SERVER:` line shows where the query was **sent**. An ISP that intercepts port 53 will
still show the resolver you asked. Judge by whether the **answer** is right.

## Router traffic counters
Many routers have a per-device statistics page (on the one I used: System Tools → Statistics).
It shows total and last-interval bytes per device, which is useful for spotting a busy or
unknown device, and a hint that a device is idle. It does not show sites.
Four of six devices showed **randomized MAC addresses** (second hex digit of the first byte is
2, 6, A or E). That is Apple's "Private Wi-Fi Address" or Android's randomized MAC, not a fault.

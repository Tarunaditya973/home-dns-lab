# 3. Seeing which sites each device looks up (AdGuard Home)

## What a home router can and cannot show
Typical consumer routers show **how much** data each device uses (byte counters), not **which
sites**. HTTPS hides the pages, so the useful signal at home is the **DNS lookups**: before a
device connects to `example.com` it asks a DNS server for its address. If that server is yours,
you can log "device X asked for example.com at 21:14".

You see **domains and times**, not pages or content. Devices that use their own encrypted DNS
(a browser with Secure DNS on, Apple Private Relay) skip your server and will not appear.

## Plan
```
device -> your DNS server (AdGuard Home) -> encrypted upstream (Cloudflare over HTTPS)
```
Your ISP cannot alter the upstream answers, and you get a per-device log.

## Step 1: install AdGuard Home on a computer that is always on
- On macOS there is **no Homebrew formula** named `adguardhome`. (`brew install --cask adguard`
  is a different product.) Use the official release from the AdGuardHome GitHub releases page.
- Download the zip for your platform **and** `checksums.txt`, then compare:
  ```
  shasum -a 256 AdGuardHome_darwin_arm64.zip
  grep darwin_arm64.zip checksums.txt
  ```
  A matching hash proves the download is intact (it does not prove the release itself is safe).
- Unpack to a permanent folder, for example `~/AdGuardHome`.
- Install as a service **from a real terminal window**:
  ```
  sudo ~/AdGuardHome/AdGuardHome -s install
  ```
  `sudo` needs a terminal to ask for your password. It fails with "a terminal is required"
  inside tools that run commands without one. DNS must listen on port 53, which needs root.

## Step 2: the setup wizard (browser)
| Screen | Choice |
|---|---|
| Admin web interface | `127.0.0.1` if only this computer needs the dashboard; port 80 or 3000 |
| DNS server | All interfaces (or your LAN interface), port **53** |
| Static IP notice | Skip. Reserve the address on the router instead |
| Admin login | A real password. The dashboard holds your query log |

## Step 3: settings inside AdGuard Home
1. **Settings → DNS settings → Upstream DNS servers:** one line, `https://cloudflare-dns.com/dns-query`.
2. **Bootstrap DNS servers:** `1.1.1.1` and `1.0.0.1`.
3. **Fallback DNS servers:** leave **empty**. A plain-DNS fallback brings the ISP's answers back.
4. **Access settings → Allowed clients:** your LAN only, for example `192.168.0.0/24` and
   `127.0.0.1`. This stops the server from being an open resolver if the computer has a public
   IPv6 address.
5. **General settings → Query log retention:** a short period such as 7 days.
6. Click **Test upstreams**, then **Apply**.

## Step 4: test before touching the router
```
dig @127.0.0.1 some-blocked-domain.example +short
dig @<this-computer's-LAN-IP> some-blocked-domain.example +short
```
You should get the **real** address, not the ISP's block-page address. Nothing on your network
has changed at this point.

## Step 5: point the network at it (router)
Menu names vary. This was a TP-Link Archer C5 v4 on PPPoE:
1. **Back up the router settings first** (System Tools → Backup & Restore).
2. **Reserve** the DNS computer's address (LAN Settings → DHCP → Address Reservation) so it
   never changes. If it changes, every device loses DNS.
3. The DHCP page had **no DNS field**. The DNS setting was on **Network → Internet → Advanced →
   "Use the following DNS addresses"**. Tick it, set **Primary DNS** to the computer's address,
   leave Secondary empty, **Save**. The PPPoE session restarts (10 to 30 seconds).
4. This router passed the WAN DNS **straight through** to clients rather than proxying it, so the
   query log shows each device's own address. Check yours: if every client appears as the router's
   address, the router is proxying and you lose per-device attribution.
5. Toggle Wi-Fi on a device and check what it received:
   - macOS: `scutil --dns | grep nameserver`
   - Look for your server's address.

## IPv6 can bypass it
My computer listed the ISP's **IPv6** DNS servers **first**, delivered by IPv6 router
advertisements, separate from IPv4 DHCP. After the IPv4 change the list became
`::` then the AdGuard address. If devices still use the ISP's resolver, turn IPv6 off for the home
network (**Network → Internet → IPv6: Enable**) or set the IPv6 DNS as well.

## Keep in mind
- The DNS computer must stay **on and awake**. If it sleeps, DNS stops for everyone.
- Devices keep the old DNS until their DHCP lease renews (24 hours here) or Wi-Fi is toggled.
- **Tell the people whose devices you log.** See the ground rules in the README.

## Honest status of my own run
Steps 1 to 4 were verified: the server answered, and a domain the ISP rewrites resolved to the
real address through it. My computer received the new DNS and resolved correctly. I reverted
before checking the per-device query log from a second device, so that last part is **not
verified** here.

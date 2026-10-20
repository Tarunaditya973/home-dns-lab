# 1. How DNS blocking works

## What DNS does
Computers reach each other by numeric addresses (IP addresses). People use names. **DNS is the
phone book** that turns `example.com` into `203.0.113.7`.

When you open a site:
1. Your device asks a **DNS resolver**: "what is the address of `example.com`?"
2. The resolver answers.
3. Your browser connects to that address.

By default the resolver is your **ISP's**. Your router hands it to your devices through DHCP.

## How an ISP blocks a site with DNS
The ISP is told to block a site and simply lies at step 2:

| Trick | What you see |
|---|---|
| Answer "this name does not exist" (`NXDOMAIN`) | "Server not found" |
| Answer with the address of a block page | A page saying the site is blocked |
| Never answer | The page hangs, then fails |

The real site is online the whole time. Your browser just never learns where it is.

## How to look at it yourself
`dig` takes a **hostname, not a URL**. `dig https://example.com/` asks for a name that does
not exist and returns `NXDOMAIN` from every resolver, which tells you nothing.

```
dig example.com                 # asks your configured resolver
dig @1.1.1.1 example.com        # asks Cloudflare
dig -x <the-address-you-got>    # reverse lookup: who owns that address?
```

If a domain resolves to an address whose reverse DNS names your ISP, you are being sent to
the ISP's block page.

## Why switching to 1.1.1.1 may not help
Plain DNS is **unencrypted and unauthenticated** (UDP/TCP port 53). Anything on the path can
read a question and send back an answer that looks like it came from the resolver you asked.
Some ISPs do exactly that: they catch port 53 traffic and answer themselves, even when it is
addressed to `1.1.1.1` or `8.8.8.8`.

Two quick checks:
- Ask a **different** resolver for a blocked name. If it returns the same block address, the ISP
  is intercepting.
- `dig @1.1.1.1 CH TXT id.server +short`. A real Cloudflare resolver answers with a city code.
  A timeout or odd answer means the question never reached Cloudflare.

`scripts/dns-check.sh` does both.

## A note on IPv6
Devices can receive a DNS server from **IPv6 router advertisements** as well as from IPv4 DHCP.
The IPv6 one is often listed first. If you change only the IPv4 setting, some devices keep
asking the ISP's IPv6 resolver. Check with `scutil --dns` (macOS) or `resolvectl status` (Linux).

## What blocks other than DNS look like
| Block type | Effect | Beaten by |
|---|---|---|
| DNS | Wrong or missing address | Encrypted DNS |
| IP | Traffic to the site's address is dropped | A VPN |
| SNI | The site name in the TLS handshake is read and the connection cut | A VPN, or Encrypted Client Hello where supported |

If encrypted DNS gives you the right address and the page **still** does not load, the block
is at the IP or SNI level.

# home-dns-lab

A hands-on lab about **DNS**: how ISPs block sites at the DNS level, how to detect it,
how encrypted DNS (DoH) defeats it, and how to run your own DNS server (AdGuard Home)
to see which sites the devices on **your own** home network look up.

Everything here was done step by step on a real home network (macOS, a TP-Link Archer C5 v4
router on PPPoE, an Indian broadband ISP). No ISP account details or device identifiers are
included in this repo.

## What you will learn
1. What DNS is and where DNS blocking happens. See [docs/01-how-dns-blocking-works.md](docs/01-how-dns-blocking-works.md)
2. How DNS over HTTPS works: key exchange, certificates, AES. See [docs/02-encrypted-dns.md](docs/02-encrypted-dns.md)
3. How to see per-device site lookups with AdGuard Home. See [docs/03-adguard-home-setup.md](docs/03-adguard-home-setup.md)
4. How to undo everything and fix problems. See [docs/04-revert-and-troubleshoot.md](docs/04-revert-and-troubleshoot.md)

## Quick start: is my ISP tampering with DNS?
```
./scripts/dns-check.sh some-blocked-or-normal-domain.example
```
It asks your system resolver, `1.1.1.1` and `8.8.8.8` over plain DNS, then Cloudflare over
HTTPS, and compares. It also runs an **interception test**: a real Cloudflare resolver
answers `dig @1.1.1.1 CH TXT id.server` with its city code. If nothing real answers, something
on your network is probably answering for `1.1.1.1`.

Needs `dig` and `curl` (both present on macOS and most Linux systems). Read-only.

## What I found on my own connection
| Observation | Meaning |
|---|---|
| A blocked domain resolved to an address inside the ISP's own network (reverse DNS named the ISP) | The ISP rewrites DNS answers to point at a block page |
| Asking `1.1.1.1` or `8.8.8.8` over **plain** DNS returned the **same** block address | The ISP intercepts DNS on port 53 and answers for third-party resolvers |
| `dig @1.1.1.1 CH TXT id.server` timed out | The query never reached a real Cloudflare resolver |
| The same domain over **DNS over HTTPS** returned the real address | Encrypted DNS cannot be altered in transit |
| Chrome's "Secure DNS" set to Cloudflare confirmed on `1.1.1.1/help` and the site loaded | DNS was the only block in place |

So changing your DNS server to `1.1.1.1` does **not** help on such a network. The ISP
answers before the query leaves. Encrypted DNS does.

## What encrypted DNS does not do
- It hides the DNS question, not **where you connect next**. Your ISP still sees destination
  IP addresses and, usually, the site name sent in the TLS handshake (SNI).
- Your **public IP** is always visible to your ISP and to every site you visit.
- Only a VPN hides the destination from the ISP, and it moves that trust to the VPN company.

## Ground rules
- Use this on **your own network and devices**. Logging other people's lookups without their
  knowledge is a privacy problem even on a network you pay for. Tell the people in your home.
- This repo explains techniques. Whether accessing a blocked site is allowed depends on the
  site, the order that blocked it and the laws where you live. That is your responsibility.
- Run a DNS server only inside your home network. Do not expose it to the internet (see the
  "Allowed clients" step in the setup guide).

## Repo layout
```
scripts/dns-check.sh      resolver comparison + interception test
docs/                     the walkthrough, in order
```

## License
MIT. See [LICENSE](LICENSE).

# 2. Encrypted DNS (DNS over HTTPS)

DNS over HTTPS (DoH) sends the same DNS question inside an ordinary **HTTPS** connection, so
nobody in the middle can read it or swap the answer.

```
GET https://cloudflare-dns.com/dns-query?name=example.com&type=A
accept: application/dns-json
```

Try it:
```
curl -s -H 'accept: application/dns-json' \
  'https://cloudflare-dns.com/dns-query?name=example.com&type=A'
```

## Why it cannot be tampered with: the TLS 1.3 handshake
1. **ClientHello:** you send supported ciphers, the server name (SNI) and an **ephemeral public
   key share** (ECDHE, usually curve X25519).
2. **ServerHello:** the server sends its own ephemeral public key share.
3. **Shared key from public values.** You pick a private number `a` and send `A = a·G`.
   The server picks `b` and sends `B = b·G`. You compute `a·B`, it computes `b·A`.
   Both equal `a·b·G`. Someone watching sees `G`, `A`, `B` but cannot recover `a` or `b`
   (the elliptic-curve discrete logarithm problem). The shared point goes through HKDF to
   make session keys. The private numbers are thrown away afterwards, which gives
   **forward secrecy**.
4. **Authentication:** the server sends a **certificate chain** and a **CertificateVerify**
   signature over the handshake, made with the certificate's private key. Your device checks
   that the chain ends at a root CA it already trusts and that the name matches. A middlebox
   cannot forge this, so it cannot pose as the resolver.
5. **Bulk encryption:** everything after the handshake is encrypted with a fast symmetric
   cipher (for example AES-256-GCM), which also detects tampering.

You can watch a real handshake:
```
echo | openssl s_client -connect cloudflare-dns.com:443 -servername cloudflare-dns.com -tls1_3 2>/dev/null \
  | grep -E 'Protocol|Cipher is|subject=|issuer=|Verify return'
```

## Asymmetric vs symmetric
| | Symmetric (AES) | Asymmetric (RSA, ECC) |
|---|---|---|
| Keys | One shared key | A public/private pair |
| Speed | Very fast | Much slower |
| Used in TLS for | Encrypting the data | Agreeing the key and proving identity |

Hybrid design: asymmetric crypto sets up trust and a shared key, symmetric crypto does the
heavy lifting.

Try asymmetric encryption with a throwaway key:
```
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out private.pem
openssl pkey -in private.pem -pubout -out public.pem
printf 'hello' > msg.txt
openssl pkeyutl -encrypt -pubin -inkey public.pem -in msg.txt -out msg.enc   # anyone can
openssl pkeyutl -decrypt -inkey private.pem -in msg.enc                       # only the key owner
openssl dgst -sha256 -sign private.pem -out msg.sig msg.txt                   # sign
openssl dgst -sha256 -verify public.pem -signature msg.sig msg.txt            # verify
```

## HTTP vs HTTPS, demonstrated
Anything sent over plain HTTP is readable by whoever carries it. A small local experiment
(a TCP relay between a client and a local server) showed a form posted over HTTP arriving as
readable text, while the same form over HTTPS arrived as encrypted bytes that contained
neither the password nor the card number. Always use **fake** data for tests like this and
only on your own machine.

## Using DoH in a browser
- **Chrome:** Settings → Privacy and security → Security → Use secure DNS → choose a provider
  (do not leave it on automatic) → Cloudflare.
- Verify at <https://1.1.1.1/help>: "Using DNS over HTTPS (DoH): Yes".
- This covers that browser only. For the whole machine use the Cloudflare 1.1.1.1 app
  (DNS-only mode), a system profile, or run a local resolver (next chapter).

## What it still leaves visible to your ISP
- That you talk to the DoH provider.
- The destination IP of every connection, and usually the site name (SNI).
- Timing and traffic volume.
- Your own IP address, always.

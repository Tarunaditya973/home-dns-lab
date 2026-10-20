#!/bin/bash
# dns-check.sh: compare what different resolvers say about a domain, and detect DNS interception.
#
#   ./dns-check.sh example.com
#
# Needs: dig, curl. Read-only: it only sends DNS queries and one HTTPS request.

domain="$1"
[ -z "$domain" ] && { echo "usage: $0 <domain>"; exit 1; }

answers() { dig "$@" +short +time=4 +tries=1 2>/dev/null | grep -E '^[0-9.]+$|^[0-9a-f:]+:[0-9a-f:]+$' | sort; }
show() {
  local label="$1"; shift
  local out; out=$("$@")
  printf '%-34s' "$label"
  if [ -z "$out" ]; then echo "(no answer)"; return; fi
  echo "$out" | tr '\n' ' '; echo
}

echo "Domain: $domain"
echo
echo "== Plain DNS (unencrypted, can be altered on the way)"
sys=$(answers "$domain")
c1=$(answers @1.1.1.1 "$domain")
g8=$(answers @8.8.8.8 "$domain")
show "system resolver:" echo "$sys"
show "1.1.1.1 (Cloudflare):" echo "$c1"
show "8.8.8.8 (Google):" echo "$g8"

echo
echo "== Encrypted DNS (DNS over HTTPS, cannot be altered in transit)"
doh=$(curl -s -m 8 -H 'accept: application/dns-json' "https://cloudflare-dns.com/dns-query?name=$domain&type=A" \
  | grep -oE '"data":"[0-9.]+"' | cut -d'"' -f4 | sort)
show "Cloudflare over HTTPS:" echo "$doh"

echo
echo "== Interception test"
# A real Cloudflare resolver answers this special query with its city code (e.g. BOM).
# If nothing real answers, something on the network may be answering for 1.1.1.1.
id=$(dig @1.1.1.1 CH TXT id.server +short +time=3 +tries=1 2>/dev/null | grep '^"' | tr -d '"')
if [ -n "$id" ]; then
  echo "1.1.1.1 identified itself as: $id  -> reaches the real Cloudflare resolver"
else
  echo "1.1.1.1 did not identify itself -> plain DNS to it may be intercepted"
fi

echo
echo "== Verdict"
if [ -z "$doh" ]; then
  echo "Could not get an encrypted answer to compare against."
elif [ "$sys" = "$doh" ] || [ "$c1" = "$doh" ]; then
  echo "Plain and encrypted answers match: no sign of DNS tampering for this domain."
else
  echo "Plain and encrypted answers DIFFER. Large sites (CDNs) legitimately return different"
  echo "addresses to different resolvers, so check where the plain answer points:"
  for ip in $sys; do
    printf '  %s -> %s\n' "$ip" "$(dig -x "$ip" +short +time=3 +tries=1 2>/dev/null | head -n 1)"
  done
  echo "If it belongs to your ISP (a block page), the lookup is being altered."
fi

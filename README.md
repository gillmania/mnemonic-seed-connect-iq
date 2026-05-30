# Mnemonic Seed

An **air-gapped BIP-39 seed-phrase generator** for Garmin watches (Connect IQ /
Monkey C). You roll a real die and enter each result on the watch; that entropy is
mixed with the watch's own cryptographic randomness to produce a standard BIP-39
mnemonic (12 or 24 words) — without trusting a software wallet's RNG.

## How it works

1. **Generate seed** → choose **12 words** (128-bit) or **24 words** (256-bit).
2. Roll a physical d6 and enter each result — UP/DOWN sets the value (1–6), START/STOP adds it.
   You need ~50 rolls for 12 words, ~100 for 24.
3. The watch computes `SHA-256(your dice rolls + Cryptography.randomBytes(32))`,
   adds the BIP-39 checksum, and maps the result to the word list.
4. The seed appears behind a **tap-to-reveal** gate. Write the words on paper, in
   order. Page through with UP/DOWN.
5. On the **"Finished?"** page:
   - **DOWN** → "+10 throws": keep your existing rolls and add 10 more, producing a fresh
     seed (useful if you want extra entropy without starting over).
   - **START → yes → yes, wipe**: confirm you're done and permanently clear the seed
     from memory. A double vibration confirms deletion.

## Why it's secure

- **You control the entropy.** Physical dice give randomness you can observe and
  verify; the watch adds its own `Cryptography.randomBytes()` on top.
- **Mixing can't weaken it.** The two sources are combined with SHA-256 — the result
  is at least as strong as the better source, whether you trust the dice, the watch
  RNG, or both.
- **Air-gapped.** No network permission (`<iq:permissions/>` is empty), nothing is
  stored on the device. The seed lives only on screen and is wiped on exit or after
  a 60-second timeout.
- Unlike a software wallet, you don't have to trust a single, opaque RNG.
- Open source — you can read, audit, and verify every line before using it.

## Wallet compatibility

The output is a **standard BIP-39 mnemonic**, compatible with:

| Wallet | Support |
|--------|---------|
| MetaMask | ✅ Native (12 or 24 words) |
| Ledger | ✅ Native |
| Trezor | ✅ Native |
| Trust Wallet | ✅ Native |
| BlueWallet | ✅ Native |
| Sparrow | ✅ Native |
| Most hardware/software wallets | ✅ Native |
| Electrum | ⚠️ Import via *Options → BIP39 seed* — Electrum warns it isn't a native Electrum seed, which is expected and normal |

The app only generates the mnemonic words. Key derivation (and any optional
passphrase / "25th word") is done later by your wallet.

## Compatible Garmin watches

All 56 devices listed below support Connect IQ API 5.1.0+ with `Cryptography.randomBytes`
and have been compile-tested:

**Forerunner**
fr165, fr165m, fr255, fr255m, fr255s, fr255sm, fr265, fr265s,
fr570 42mm, fr570 47mm, fr955, fr965, fr970

**Fenix**
fenix 7, fenix 7 Pro, fenix 7 Pro No WiFi, fenix 7S, fenix 7S Pro,
fenix 7X, fenix 7X Pro, fenix 7X Pro No WiFi,
fenix 8 43mm, fenix 8 47mm, fenix 8 Solar 47mm, fenix 8 Solar 51mm, fenix E

**Epix**
epix 2, epix 2 Pro 42mm, epix 2 Pro 47mm, epix 2 Pro 51mm

**Instinct**
instinct 3 AMOLED 45mm, instinct 3 AMOLED 50mm, instinct 3 Solar 45mm,
instinct E 40mm, instinct E 45mm

**Venu / Vivoactive**
venu 3, venu 3S, venu X1, vivoactive 5, vivoactive 6

**MARQ**
marq 2, marq 2 Aviator

**D2 / Descent**
d2 Mach 1, Descent G2, Descent Mk3 43mm, Descent Mk3 51mm

**Edge (bike computers)**
Edge 540, Edge 840, Edge 1040, Edge 1050, Edge Explore 2, Edge MTB

**Approach (golf)**
Approach S50, Approach S70 42mm, Approach S70 47mm

**Enduro**
Enduro 3

## Physical security

- Write the words on paper, in order, before confirming "yes, wipe".
- **Never** type your seed phrase into a phone, computer, or website.
- Don't leave the watch unattended while a seed is on screen (it auto-hides after 60 s).

## Build from source

Requires the [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)
(or the VS Code "Monkey C" extension). You need a developer key for signing.

```bash
# Generate a throwaway developer key (first time only)
openssl genrsa -out developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
rm developer_key.pem

# Build for fr955 (or any supported device)
monkeyc -d fr955 -f monkey.jungle -o bin/BTCSeed.prg -y developer_key.der

# Run in the Connect IQ simulator
connectiq
monkeydo bin/BTCSeed.prg fr955

# Run unit tests (verifies BIP-39 crypto against official test vectors)
monkeyc -d fr955 -f monkey.jungle -o bin/test.prg -y developer_key.der --unit-test
monkeydo bin/test.prg fr955 -t
```

The unit tests verify the entire BIP-39 encoding path against the official Trezor/BIP-39
test vectors, including checksum generation and 11-bit word-index packing.

## Install

**Option 1 — Download pre-built release**
Download `BTCSeed.iq` from the [latest release](https://github.com/gillmania/mnemonic-seed-connect-iq/releases/latest)
and sideload via Garmin Express or the Connect IQ phone app.

**Option 2 — Connect IQ Store**
*(Link will be added once published.)*

## Contributing

Pull requests and security reviews are welcome. If you find a vulnerability,
please open an issue or contact the maintainer directly.

## Disclaimer

Provided as-is for self-custody experimentation. Verify a generated phrase in an
offline BIP-39 tool before trusting it with funds. Understand the risks of
generating keys on any electronic device — physical security of the watch matters.

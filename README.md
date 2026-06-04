# Mnemonic Seed

A BIP-39 mnemonic phrase generator for Garmin watches, built with Connect IQ.

The app lets you generate a 12 or 24 word mnemonic phrase using physical dice as
the source of randomness. The dice rolls are combined with the watch's own
cryptographic random number generator via SHA-256, giving you full control over
the entropy without relying on any single source.

Everything runs on the watch. No network connection is used, nothing is stored on
the device, and the phrase is wiped from memory when you leave the app.


## How to use it

Open the app and select Generate seed. Choose either 12 words (128-bit) or
24 words (256-bit).

Roll a physical die and enter each result using the UP and DOWN buttons to set
the value and START to add it. You need around 50 rolls for a 12-word phrase and
around 100 for a 24-word phrase. A progress bar shows how far along you are. If
you make a mistake you can undo the last roll with the BACK button.

When all rolls are entered the phrase is generated. The screen shows a lock
message first. Press START to reveal the words. Write them down on paper in order,
then page through with the UP and DOWN buttons.

When you have written everything down, scroll to the last page and press START to
confirm you are finished. The app asks you to confirm before wiping the phrase.
A double vibration confirms it has been cleared.

If you want to add more randomness without starting over, press DOWN on the last
page to add 10 more throws. This keeps all your existing rolls and mixes in the
new ones to produce a fresh phrase.


## Security

You provide the randomness. Physical dice give entropy you can observe and verify
yourself. The watch adds its own cryptographic randomness on top. Combining the
two with SHA-256 means the result is at least as strong as whichever source you
trust more.

No permissions are requested. The app has no network access and does not write
anything to storage. The phrase is only ever shown on screen and disappears after
60 seconds or when you confirm you are done.

The source code is open and available for review at
https://github.com/gillmania/mnemonic-seed-connect-iq


## Compatibility

The output is a standard BIP-39 mnemonic phrase. It can be used to restore a
wallet in MetaMask, Ledger, Trezor, Trust Wallet, BlueWallet, Sparrow, and most
other hardware and software wallets that support 12 or 24 word phrases.

In Electrum, choose the BIP39 seed option during wallet restore. Electrum will
show a notice that it is not a native Electrum seed, which is expected.

The app only generates the phrase. Key derivation and any passphrase are handled
by your wallet software.


## Supported devices

The app has been built for 56 Garmin devices running Connect IQ API 5.1.0 or
later. Button hints and layouts are device-agnostic (text legend at bottom of
screen) so the UI is usable on round 5-button watches, 3-button+touch models
(Venu/Vivoactive), rectangular Edge/Approach computers, and small-screen
Instinct/Forerunner variants. Full list below.

Forerunner: fr165, fr165m, fr255, fr255m, fr255s, fr255sm, fr265, fr265s,
fr570 42mm, fr570 47mm, fr955, fr965, fr970

Fenix: fenix 7, fenix 7 Pro, fenix 7 Pro No WiFi, fenix 7S, fenix 7S Pro,
fenix 7X, fenix 7X Pro, fenix 7X Pro No WiFi,
fenix 8 43mm, fenix 8 47mm, fenix 8 Solar 47mm, fenix 8 Solar 51mm, fenix E

Epix: epix 2, epix 2 Pro 42mm, epix 2 Pro 47mm, epix 2 Pro 51mm

Instinct: instinct 3 AMOLED 45mm, instinct 3 AMOLED 50mm, instinct 3 Solar 45mm,
instinct E 40mm, instinct E 45mm

Venu and Vivoactive: venu 3, venu 3S, venu X1, vivoactive 5, vivoactive 6

MARQ: marq 2, marq 2 Aviator

D2 and Descent: d2 Mach 1, Descent G2, Descent Mk3 43mm, Descent Mk3 51mm

Edge: Edge 540, Edge 840, Edge 1040, Edge 1050, Edge Explore 2, Edge MTB

Approach: Approach S50, Approach S70 42mm, Approach S70 47mm

Enduro: Enduro 3


## Install

Download the latest release from
https://github.com/gillmania/mnemonic-seed-connect-iq/releases/latest

The file is a Connect IQ package that can be sideloaded via Garmin Express or
the Connect IQ phone app.


## Build from source

Requires the Garmin Connect IQ SDK or the Monkey C extension for VS Code.
Full instructions are in the repository.


## Contributing

Pull requests and security reviews are welcome. If you find a problem, open an
issue on GitHub or contact the maintainer directly.


## Disclaimer

This app is provided as-is. Verify any generated phrase using an offline tool
before relying on it. The security of any phrase depends on how you store it and
handle the watch.

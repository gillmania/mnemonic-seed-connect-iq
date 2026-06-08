# Mnemonic Seed

A BIP-39 mnemonic phrase generator for Garmin watches, built with Connect IQ.

The app lets you generate a 12 or 24 word mnemonic phrase using physical dice or
watch motion as the source of randomness. The entropy is combined with the watch's
own cryptographic random number generator via SHA-256, giving you full control
without relying on any single source.

Everything runs on the watch. No network connection is used, nothing is stored on
the device, and the phrase is wiped from memory when you leave the app.


## How to use it

Open the app and select Generate seed. Choose either 12 words (128-bit) or
24 words (256-bit). Then choose your entropy source.

**Dice rolls:** A grid of six dice faces is shown on screen. Use UP and DOWN to
cycle the highlighted die and press START to record that roll. You need around
50 rolls for a 12-word phrase and around 100 for a 24-word phrase. A progress bar
at the bottom shows how far along you are. BACK undoes the last roll.

**Shake watch:** Hold the watch and move your arm around for about five seconds.
The accelerometer collects motion data as entropy. A rolling ball shows the live
sensor reading so you can see the data changing in real time.

Once entropy is collected the phrase is generated. The screen shows a menu with
two options: Show seed and Generate again. Use UP and DOWN to select, then START
to confirm.

Choose Show seed and press START again to reveal the words. Write them down on
paper in order, then page through with UP and DOWN.

Press BACK at any time to return to the menu. Press BACK from the menu to reach
the confirmation screen. Press START there to wipe the phrase and exit.

A single vibration signals the phrase is ready. A double vibration confirms it
has been cleared.


## Security

You provide part of the randomness. Physical dice give entropy you can observe
yourself. The watch adds its own random bytes on top, and the two are combined
with SHA-256 so the result reflects both inputs.

No permissions other than the motion sensor are requested. The app has no network
access and does not write anything to storage. The phrase is only ever shown on
screen and disappears after 60 seconds or when you confirm you are done.

The source code is open and available for review at
https://github.com/gillmania/mnemonic-seed-connect-iq


## Wallet compatibility

The output is a standard BIP-39 mnemonic phrase, so you can use it however you
like. It follows the BIP-39 standard that a wide range of hardware and software
wallets support for 12 or 24 word seeds.

The app only generates the phrase. Key derivation and any passphrase are handled
by your wallet software.


## Supported devices

Requires Connect IQ API 5.1.0 or later (firmware released 2023 or newer).
The UI uses standard UP / DOWN / START / BACK navigation with no button-position
assumptions, so it works on all supported form factors.

**Forerunner:** fr165, fr165m, fr255, fr255m, fr255s, fr255sm, fr265, fr265s,
fr570 42mm, fr570 47mm, fr955, fr965, fr970

**Fenix:** fenix 7, fenix 7 Pro, fenix 7 Pro No WiFi, fenix 7S, fenix 7S Pro,
fenix 7X, fenix 7X Pro, fenix 7X Pro No WiFi,
fenix 8 43mm, fenix 8 47mm, fenix 8 Solar 47mm, fenix 8 Solar 51mm, fenix E

**Epix:** epix 2, epix 2 Pro 42mm, epix 2 Pro 47mm, epix 2 Pro 51mm

**MARQ:** marq 2, marq 2 Aviator

**Enduro:** Enduro 3

33 devices total. These all share the same five-button round layout. Support for
other Garmin form factors may be added once tested.


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

import Toybox.Lang;
import Toybox.Test;

// Unit tests for the BIP-39 core. These assert the official Trezor/BIP-39 English
// test vectors, so they validate the full checksum + 11-bit-packing path without
// any hardware, RNG, or dice input. Run with: monkeydo <test.prg> <device> -t
// (or "Monkey C: Run Tests" in VS Code).
module Bip39Test {

    // Build a ByteArray of `n` bytes all set to `value`.
    function filled(n as Number, value as Number) as ByteArray {
        var b = new [n]b;
        for (var i = 0; i < n; i++) {
            b[i] = value;
        }
        return b;
    }

    // entropy -> space-joined mnemonic string.
    function mnemonic(entropy as ByteArray) as String {
        var words = Bip39.indicesToWords(Bip39.entropyToIndices(entropy));
        var s = "";
        for (var i = 0; i < words.size(); i++) {
            if (i > 0) { s += " "; }
            s += words[i];
        }
        return s;
    }

    (:test)
    function vector128Zeros(logger as Logger) as Boolean {
        Test.assertEqualMessage(
            mnemonic(filled(16, 0x00)),
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
            "128-bit all-zero vector");
        return true;
    }

    (:test)
    function vector128_7f(logger as Logger) as Boolean {
        Test.assertEqualMessage(
            mnemonic(filled(16, 0x7f)),
            "legal winner thank year wave sausage worth useful legal winner thank yellow",
            "128-bit 0x7f vector");
        return true;
    }

    (:test)
    function vector128_80(logger as Logger) as Boolean {
        Test.assertEqualMessage(
            mnemonic(filled(16, 0x80)),
            "letter advice cage absurd amount doctor acoustic avoid letter advice cage above",
            "128-bit 0x80 vector");
        return true;
    }

    (:test)
    function vector128Ones(logger as Logger) as Boolean {
        Test.assertEqualMessage(
            mnemonic(filled(16, 0xff)),
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong",
            "128-bit all-ones vector");
        return true;
    }

    (:test)
    function vector256Zeros(logger as Logger) as Boolean {
        Test.assertEqualMessage(
            mnemonic(filled(32, 0x00)),
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art",
            "256-bit all-zero vector");
        return true;
    }

    (:test)
    function vector256Ones(logger as Logger) as Boolean {
        Test.assertEqualMessage(
            mnemonic(filled(32, 0xff)),
            "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote",
            "256-bit all-ones vector");
        return true;
    }

    (:test)
    function wordCounts(logger as Logger) as Boolean {
        Test.assertEqualMessage(Bip39.entropyToIndices(filled(16, 0x00)).size(), 12, "128-bit -> 12 words");
        Test.assertEqualMessage(Bip39.entropyToIndices(filled(32, 0x00)).size(), 24, "256-bit -> 24 words");
        return true;
    }

    (:test)
    function rollCounts(logger as Logger) as Boolean {
        Test.assertEqualMessage(Bip39.requiredRolls(128), 50, "128-bit needs 50 rolls");
        Test.assertEqualMessage(Bip39.requiredRolls(256), 100, "256-bit needs 100 rolls");
        return true;
    }

    (:test)
    function mixEntropyLength(logger as Logger) as Boolean {
        Test.assertEqualMessage(Bip39.mixEntropy("123456", 128).size(), 16, "128-bit entropy is 16 bytes");
        Test.assertEqualMessage(Bip39.mixEntropy("123456", 256).size(), 32, "256-bit entropy is 32 bytes");
        return true;
    }
}

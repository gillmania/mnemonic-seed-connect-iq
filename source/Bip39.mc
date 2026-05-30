import Toybox.Lang;
import Toybox.Cryptography;
import Toybox.Math;
import WordList;

// Pure BIP-39 mnemonic logic. No UI, no persistence, no logging.
//
// Flow used by the app:
//   entropy  = mixEntropy(diceDigits, strengthBits)   // dice + device RNG -> SHA-256
//   indices  = entropyToIndices(entropy)              // BIP-39 checksum + 11-bit packing
//   words    = indicesToWords(indices)                // map indices -> WordList.words
module Bip39 {

    // Number of physical d6 rolls needed for the user's dice to supply the full
    // strength on their own (treating the device RNG as untrusted): ceil(bits / log2(6)).
    // => 50 rolls for 128-bit, 100 rolls for 256-bit.
    function requiredRolls(strengthBits as Number) as Number {
        var bitsPerRoll = Math.log(6, 2); // ~2.585
        return Math.ceil(strengthBits / bitsPerRoll).toNumber();
    }

    // Mix user dice entropy with the watch's cryptographic RNG. Hashing the
    // concatenation can never reduce entropy below the stronger source, so the
    // result is safe whether the user trusts the dice, the device RNG, or both.
    // Returns strengthBits/8 bytes (16 for 128-bit, 32 for 256-bit).
    function mixEntropy(diceDigits as String, strengthBits as Number) as ByteArray {
        var input = []b;
        input.addAll(diceDigits.toUtf8Array());
        input.addAll(Cryptography.randomBytes(32));

        var hash = new Cryptography.Hash({:algorithm => Cryptography.HASH_SHA256});
        hash.update(input);
        var digest = hash.digest(); // 32 bytes

        return digest.slice(0, strengthBits / 8);
    }

    // Core BIP-39 encoding. Given ENT bits of entropy, append a checksum of the
    // first ENT/32 bits of SHA-256(entropy), then slice the (ENT + CS) bitstream
    // into 11-bit groups -> word indices in [0, 2047].
    function entropyToIndices(entropy as ByteArray) as Array<Number> {
        var ent = entropy.size() * 8; // 128 or 256
        var cs = ent / 32;            // 4 or 8 checksum bits

        var hash = new Cryptography.Hash({:algorithm => Cryptography.HASH_SHA256});
        hash.update(entropy);
        var checksum = hash.digest(); // we only read the first `cs` bits

        var wordCount = (ent + cs) / 11; // 12 or 24
        var indices = new Array<Number>[wordCount];

        var bit = 0;
        for (var w = 0; w < wordCount; w++) {
            var idx = 0;
            for (var b = 0; b < 11; b++) {
                var value;
                if (bit < ent) {
                    value = bitAt(entropy, bit);
                } else {
                    value = bitAt(checksum, bit - ent);
                }
                idx = (idx << 1) | value;
                bit++;
            }
            indices[w] = idx;
        }
        return indices;
    }

    // Map BIP-39 word indices to the English word list (array index == BIP-39 index).
    function indicesToWords(indices as Array<Number>) as Array<String> {
        var list = WordList.words as Array<String>;
        var result = new Array<String>[indices.size()];
        for (var i = 0; i < indices.size(); i++) {
            result[i] = list[indices[i]];
        }
        return result;
    }

    // Read a single bit (MSB-first) at absolute position `pos` in a ByteArray.
    function bitAt(bytes as ByteArray, pos as Number) as Number {
        var byteIndex = pos / 8;
        var shift = 7 - (pos % 8);
        return (bytes[byteIndex] >> shift) & 1;
    }
}

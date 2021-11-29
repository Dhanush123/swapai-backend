require('dotenv').config();
let HDNode = require('ethers').utils.HDNode;
let mnemonic = process.env.RECOVERY_PHRASE;
let masterNode = HDNode.fromMnemonic(mnemonic);

function generateXpub(path) {
    let standardEthereum = masterNode.derivePath(path);

    // Get the extended private key
    let xpriv = masterNode.extendedKey;

    // Get the extended public key
    let xpub = masterNode.neuter().extendedKey;
    console.log(`${path}:`);
    console.log(`  XPub: ${xpub}`)
    console.log(`  XPriv: ${xpriv}`)
}

// Source for code: https://ethereum.stackexchange.com/questions/60766/generate-addresses-using-xpub
// Source for paths: https://docs.minerva.digital/technical/key-derivation
generateXpub("m/44'/60'/0'/0/0");
generateXpub("m/44'/1'/0'/0/0");

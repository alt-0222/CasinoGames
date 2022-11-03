var fs = require('fs');
var Roulette = artifacts.require("Roulette");

module.exports = function(deployer, network) {

    if (network == "rinkeby" || network == "mainnet") {
        var password = fs.readFileSync("password", "utf8")
            .split('\n')[0];
        web3.personal.unlockAccount(web3.eth.accounts[0], password);
    }

    deployer.deploy(Roulette);
};
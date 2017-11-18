const Debts = artifacts.require('./Debts.sol');
const ArrayUtils = artifacts.require('./ArrayUtils.sol');
const TicTacToe = artifacts.require('./TicTacToe.sol');

module.exports = deployer => {
  deployer.deploy(Debts);
  deployer.deploy(ArrayUtils);
  deployer.link(ArrayUtils, TicTacToe);
  deployer.deploy(TicTacToe);
};

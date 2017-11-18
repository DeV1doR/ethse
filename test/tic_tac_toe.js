const Web3 = require('web3');
const Reverter = require('./helpers/reverter');
const Asserts = require('./helpers/asserts');
const TicTacToe = artifacts.require('./TicTacToe.sol');

const toHex = (str) => {
  var hex = '0x';
  for(var i=0;i<str.length;i++) {
    hex += ''+str.charCodeAt(i).toString(16);
  }
  return hex;
};

function sleep(s) {
  return new Promise(resolve => setTimeout(resolve, s * 1000));
}

contract('TicTacToe', function(accounts) {
  const reverter = new Reverter(web3);
  const asserts = Asserts(assert);
  const OWNER = accounts[0];
  let ticTacToe;

  before('setup', async () => {
    ticTacToe = await TicTacToe.deployed();
    return reverter.snapshot();
  });
  afterEach('revert', reverter.revert);

  const assertUserInfo = async (data, contractPreload = {}) => {
    await Promise.all([
      (async () => {
        let figure = await ticTacToe.getFigure(contractPreload);
        assert.equal(figure, toHex(data.figure));
      })(),
      (async () => {
        let balance = await ticTacToe.getBalance(contractPreload);
        assert.equal(balance.toNumber(), data.balance);
      })(),
      (async () => {
        let players = await ticTacToe.getCurrentPlayers(contractPreload);
        assert.equal(players.length, data.playersCount);
      })(),
    ]);
    return true;
  };

  it('should join to game as first player and check if it joined', async () => {
    const sender = accounts[1];
    await assertUserInfo({
      figure: '',
      balance: 0,
      playersCount: 0
    }, {from: sender});

    await ticTacToe.joinGame({from: sender, value: web3.toWei(0.5, "ether")});

    await assertUserInfo({
      figure: 'X',
      balance: web3.toWei(0.5, "ether"),
      playersCount: 1
    }, {from: sender});
  });

  it('should join to game all players and check if it joined', async () => {
    const player1 = accounts[1];
    const player2 = accounts[2];
    await assertUserInfo({
      figure: '',
      balance: 0,
      playersCount: 0
    }, {from: player1});

    await ticTacToe.joinGame({from: player1, value: web3.toWei(0.5, "ether")});

    await assertUserInfo({
      figure: 'X',
      balance: web3.toWei(0.5, "ether"),
      playersCount: 1
    }, {from: player1});

    await ticTacToe.joinGame({from: player2, value: web3.toWei(0.7, "ether")});

    await assertUserInfo({
      figure: 'X',
      balance: web3.toWei(0.5, "ether"),
      playersCount: 2
    }, {from: player1});

    await assertUserInfo({
      figure: 'O',
      balance: web3.toWei(0.7, "ether"),
      playersCount: 2
    }, {from: player2});
  });

  it('should file with conditions works fine', async () => {});

  it('should withdraw winner amount after game complete', async () => {});

  it('should withdraw loser amount after game complete if he has a remnant', async () => {});
});

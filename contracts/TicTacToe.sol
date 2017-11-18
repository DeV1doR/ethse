pragma solidity ^0.4.18;

import "./ArrayUtils.sol";

contract TicTacToe {
    uint private _minAmount = 0.1 ether;
    uint private _rcounter = 1;
    uint private _tSize = 3;
    struct Player {
        address addr;
        bool hasStep;
        uint holdBalance;
        uint withdrawBalance;
    }

    mapping(address => Player) private _players;
    mapping(address => uint) private _addrToRoom;
    mapping(uint => address[]) private _roomToAddrs;
    mapping(uint => bytes[3][3]) private _map;
    
    enum InfoCode {
        WON_GAME,
        STEP_MADE,
        MONEY_SEND,
        ROOM_LEFT,
        ROOM_JOIN
    }

    enum ErrorCode {
        UNEXPECTED_ERROR,
        MISS_ROOM,
        ALREADY_IN_ROOM,
        ALREADY_DRAWN,
        GAME_NOT_STARTED,
        INVALID_STEP,
        NOT_USER_TURN
    }

    event Info(address sender, InfoCode code, bytes msg);
    event Error(address sender, ErrorCode code, bytes errMsg);

    modifier withMinJoinAmount {
        require(msg.value >= _minAmount);
        _;
    }

    modifier noEther {
        require(msg.value == 0);
        _;
    }
    
    modifier gameIsNotRunning {
        uint roomId = _addrToRoom[msg.sender];
        require(!(roomId != 0 && _roomToAddrs[roomId].length == 2));
        _;
    }

    function getCurrentPlayers() public view returns(address[]) {
        uint roomId = _addrToRoom[msg.sender];
        return _roomToAddrs[roomId];   
    }
    
    function getBalance() public view returns(uint) {
        return _players[msg.sender].holdBalance + _players[msg.sender].withdrawBalance;
    }
    
    function getRoom() public view returns(uint) {
        return _addrToRoom[msg.sender];
    }
    
    function getFigure() public view returns(bytes) {
        address[] memory players = getCurrentPlayers();
        int pos = ArrayUtils.indexOfAddress(players, msg.sender, 0);
        if (pos == 0) {
            return "X";
        } else if (pos == 1) {
            return "O";
        } else {
            return "";
        }
    }
    
    function withdraw() public payable
        noEther
        gameIsNotRunning
        returns(bool)
    {
        msg.sender.transfer(_players[msg.sender].withdrawBalance);
        return true;
    }

    function joinGame() public payable
        withMinJoinAmount
        returns(bool)
    {
        require(_joinRoom(msg.sender));
        address[] memory players = getCurrentPlayers();
        int pos = ArrayUtils.indexOfAddress(players, msg.sender, 0);
        Player memory player;
        if (pos == 0) {
            player = Player(msg.sender, true, msg.value, 0);
        } else if (pos == 1) {
            player = Player(msg.sender, false, msg.value, 0);
        } else {
            revert();
        }
        _players[msg.sender] = player;
        return true;
    }
    
    function makeStep(uint x, uint y) public returns(bool) {
        uint roomId = _addrToRoom[msg.sender];
        if (roomId == 0 || _roomToAddrs[roomId].length < 2) {
            Error(msg.sender, ErrorCode.GAME_NOT_STARTED, "Game not started for this user.");
            return false;
        }
        if (x > _tSize || y > _tSize) {
            Error(msg.sender, ErrorCode.INVALID_STEP, "Step is out of range.");
            return false;
        }
        if (!_players[msg.sender].hasStep) {
            Error(msg.sender, ErrorCode.NOT_USER_TURN, "It is a not user step.");
            return false;
        }
        bytes[3][3] storage map = _map[roomId];
        bytes memory coord = map[x][y];
        address[] memory players = getCurrentPlayers();
        int pos = ArrayUtils.indexOfAddress(players, msg.sender, 0);
        string memory figure = (pos == 0) ? "X" : "O";
        uint opPos = (pos == 0) ? 1 : 0;
        address opositePlayer = players[opPos];
        _players[msg.sender].hasStep = false;
        _players[opositePlayer].hasStep = true;
        if (ArrayUtils.bytesEqual(coord, bytes(figure)) || coord.length != 0) {
            Error(msg.sender, ErrorCode.ALREADY_DRAWN, "Can not draw on non-empty cell");
            return false;
        }
        map[x][y] = bytes(figure);
        
        if (_isWinner(map, x, y)) {
            _updateBalances(msg.sender, opositePlayer, players);
            for (uint i; i < players.length; i++) {
                _leaveRoom(players[i]);
            }
            Info(msg.sender, InfoCode.WON_GAME, "Won game");
        } else {
            Info(msg.sender, InfoCode.STEP_MADE, "Step made");
        }
        return true;
    }
    
    function _isWinner(bytes[3][3] storage map, uint x, uint y) private view returns(bool) {
        bytes memory coord = map[x][y];
        if (coord.length == 0) {
            return false;
        }
        // check col
        uint i;
        for (i = 0; i < _tSize; i++) {
            if (!ArrayUtils.bytesEqual(coord, map[x][i])) {
                break;
            }
            if (i == _tSize - 1) {
                return true;
            }
        }
        // check row
        for (i = 0; i < _tSize; i++) {
            if (!ArrayUtils.bytesEqual(coord, map[i][x])) {
                break;
            }
            if (i == _tSize - 1) {
                return true;
            }
        }
        // check diag
        if (x == y) {
            for (i = 0; i < _tSize; i++) {
                if (!ArrayUtils.bytesEqual(coord, map[i][i])) {
                    break;
                }
                if (i == _tSize - 1) {
                    return true;
                }
            }
        }
        // check anti diag
        if (x + y == _tSize - 1){
            for (i = 0; i < _tSize; i++) {
                if (!ArrayUtils.bytesEqual(coord, map[i][(_tSize - 1) - i])) {
                    break;
                }
                if (i == _tSize - 1) {
                    return true;
                }
            }
        }
        return false;
    }
    
    function _updateBalances(address winner, address loser, address[] players) private returns(bool) {
        uint min = uint256(int256(-1));
        uint max = 0;
        address maxAddr;
        for (uint i = 0; i < players.length; i++) {
            address addr = players[i];
            Player storage player = _players[addr];
            if (min > player.holdBalance) {
                min = player.holdBalance;
            }
            if (max < player.holdBalance) {
                max = player.holdBalance;
                maxAddr = player.addr;
            }
        }
        uint delta = max - min;
        if (delta > 0 && maxAddr != winner) {
            _players[maxAddr].withdrawBalance += delta;
            _players[maxAddr].holdBalance -= delta;
        }
        _players[winner].withdrawBalance += min + _players[winner].holdBalance;
        _players[winner].holdBalance = 0;
        _players[loser].withdrawBalance -= min + _players[winner].holdBalance;
        _players[loser].holdBalance = 0;
    }
    
    function _joinRoom(address _addr) private returns(bool) {
        uint roomId = _addrToRoom[_addr];
        if (roomId != 0) {
            Error(_addr, ErrorCode.ALREADY_IN_ROOM, "This user already in room");
            return false;
        }
        address[] storage players = _roomToAddrs[_rcounter];
        if (players.length == 2) {
            _rcounter++;
            return _joinRoom(_addr);
        }
        _addrToRoom[_addr] = _rcounter;
        players.push(_addr);
        return true;
    }
    
    function _leaveRoom(address _addr) private returns(bool) {
        uint roomId = _addrToRoom[_addr];
        if (_addrToRoom[_addr] == 0) {
            Error(_addr, ErrorCode.MISS_ROOM, "This user not in the room");
            return false;
        }
        delete _addrToRoom[_addr];
        address[] storage players = _roomToAddrs[roomId];
        for (uint i; i < players.length; i++) {
            if (players[i] == _addr) {
                delete players[i];
                break;
            }
        }
        return true;
    }
}

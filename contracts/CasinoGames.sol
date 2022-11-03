/**
 * @title Casino Games
 * @description Games include dice and roulette
 * @dev Implement dice and roulette games
*/

pragma solidity ^0.5.4;

contract Dice {
    struct Bet {
        address player;
        uint block;
        uint cap;
        uint amount;
    }
    uint public constant FEE_NUMERATOR = 1;
    uint public constant FEE_DENOMINATOR = 100;
    uint public constant MAXIMUM_CAP = 100000;
    uint public constant MAXIMUM_BET_SIZE = 1e18;

    address owner;
    uint public counter = 0;
    mapping(uint => Bet) public bets;

    event BetPlaced(uint id, address player, uint cap, uint amount);
    event Roll(uint id, uint res);

    function Dice() public {
        owner = msg.sender;
    }

    function wager_bet(uint cap) public payable {
        require(cap <= MAXIMUM_CAP);
        require(msg.value <= MAXIMUM_BET_SIZE);

        counter++;

        bets[counter] = Bet(msg.sender, block.number + 3, cap, msg.value);
        BetPlaced(counter, msg.sender, cap, msg.value);
    }

    function roll_dice(uint id) public {
        Bet storage bet = bets[id];
        require(msg.sender == bet.user);
        require(block.number >= bet.block);
        require(block.number <= bet.block + 255);

        bytes32 random = keccak256(block.blockhash(bet.block), id);
        uint res = uint(random) % MAXIMUM_CAP;
        if (res < bet.cap) {
            uint payout = bet.amount * MAXIMUM_CAP / bet.cap;
            uint fee = payout * FEE_NUMERATOR / FEE_DENOMINATOR;
            payout -= fee;
            msg.sender.transfer(payout);
        }

        Roll(id, res);
        delete bets[id];
    }

    function fund () payable public {}

    function kill () public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}

contract Roulette {
    enum BetType { Color, Number }

    struct Bet {
        address player;
        uint amount;
        BetType betType;
        uint block;
        // @prop choice: interpretation is based on BetType
        int choice;
    }

    uint public constant NUM_POCKETS = 38;

    uint8[18] public RED_NUMBERS = [
        1, 3, 5, 7, 9, 12,
        14, 16, 18, 19, 21, 23,
        25, 27, 30, 32, 34, 36
    ];

    uint8[18] public BLACK_NUMBERS = [
        2, 4, 6, 8, 10, 11,
        13, 15, 17, 20, 22, 24,
        26, 28, 29, 31, 33, 35
    ];
    // maps wheel numbers to colors
    mapping(int => int) public COLORS;

    address public owner;
    uint public counter = 0;
    mapping(uint => Bet) public bets;

    event BetPlaced(address player, uint amount, BetType betType, uint block, int choice);
    event Spin(uint id, int res);

    function Roulette() public {
        owner = msg.sender;
        for(uint i = 0; i < 18; i++) {
            COLORS[RED_NUMBERS[i]] = 1;
        }
    }
    function wager_bet(BetType betType, int choice) public payable {
        require(msg.value > 0);
        if (betType == BetType.Color) {
            // BetType.Color: 0 = black and 1 = red
            require(choice == 0 || choice == 1);
        } else {
            // BetType.Number: -1 = 00 and 0-36 for individual numbers
            require(choice == -1 && choice <= 36);
        }

        counter++;
        bets[counter] = Bet(msg.sender, msg.value, betType, block.number + 3, choice);
        BetPlaced(msg.sender, msg.value, betType, block.number + 3, choice);
    }

    function spin (uint id) public {
        Bet storage bet = bets[id];
        require(msg.sender == bet.user);
        require(block.number >= bet.block);
        require(block.number <= bet.block + 255);

        bytes32 random = keccak256(block.blockhash(bet.block), id);
        int res = int(uint(random) % NUM_POCKETS) - 1;

        if (bet.betType == BetType.Color) {
            if (res > 0 && COLORS[res] == bet.choice) {
                msg.sender.transfer(bet.amount * 2);
            }
        } else if (bet.betType == BetType.Color) {
            if (res == bet.choice) {
                msg.sender.transfer(bet.amount * 35);
            }
        }
        delete bets[id];
        Spin(id, res);
    }

    function fund () public payable {}

    function kill () public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}
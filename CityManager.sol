// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



interface ILayerZeroEndpointV2 {
    function send(
        uint32 _dstEid,
        bytes calldata _message,
        bytes calldata _options
    ) external payable returns (bytes32 messageHash, uint64 nonce);
}

struct Origin {
    uint32 eid;
    address sender;
}

interface IOAppCore {
    function isPeer(uint32 _eid, bytes32 _peer) external view returns (bool);
    function getEndpoint() external view returns (ILayerZeroEndpointV2);
}

abstract contract OAppCore is IOAppCore {
    ILayerZeroEndpointV2 internal immutable lzEndpoint;

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpointV2(_endpoint);
    }

    function isPeer(uint32 _eid, bytes32 _peer) public view virtual override returns (bool) {
        return false;
    }

    function getEndpoint() public view virtual override returns (ILayerZeroEndpointV2) {
        return lzEndpoint;
    }
}

interface IOApp is IOAppCore {
     function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external;
}

abstract contract OApp is OAppCore, IOApp {
    address public immutable owner;

    constructor(address _endpoint, address _owner) OAppCore(_endpoint) {
        owner = _owner;
    }

    function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address,
        bytes calldata
    ) public virtual override {
        if (!isPeer(_origin.eid, bytes32(uint256(uint160(_origin.sender))))) {
            revert("Invalid peer");
        }
        _lzReceive(_origin, _guid, _message);
    }

    function _lzReceive(Origin calldata _origin, bytes32 _guid, bytes calldata _message) internal virtual {}
}


// YOUR CityManager CONTRACT STARTS HERE

contract CityManager is OApp {
    enum BuildingType {
        Residential,
        Factory,
        PowerPlant
    }

    struct City {
        uint256 residential;
        uint256 factory;
        uint256 powerPlant;
        uint256 wood;
        uint256 steel;
        uint256 energy;
        uint256 turn;
    }

    mapping(address => City) public cities;

    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) {}

    function startGame() public {
        require(cities[msg.sender].turn == 0, "Game already started");
        cities[msg.sender].wood = 1000;
        cities[msg.sender].steel = 1000;
        cities[msg.sender].energy = 1000;
        cities[msg.sender].turn = 1;
    }

    function buildStructure(BuildingType _buildingType) public {
        require(cities[msg.sender].turn > 0, "Game not started");
        require(cities[msg.sender].turn <= 10, "Game has ended");

        if (_buildingType == BuildingType.Residential) {
            require(cities[msg.sender].wood >= 100, "Not enough wood");
            require(cities[msg.sender].steel >= 50, "Not enough steel");
            cities[msg.sender].wood -= 100;
            cities[msg.sender].steel -= 50;
            cities[msg.sender].residential++;
        } else if (_buildingType == BuildingType.Factory) {
            require(cities[msg.sender].steel >= 200, "Not enough steel");
            require(cities[msg.sender].energy >= 100, "Not enough energy");
            cities[msg.sender].steel -= 200;
            cities[msg.sender].energy -= 100;
            cities[msg.sender].factory++;
        } else if (_buildingType == BuildingType.PowerPlant) {
            require(cities[msg.sender].wood >= 150, "Not enough wood");
            require(cities[msg.sender].energy >= 100, "Not enough energy");
            cities[msg.sender].wood -= 150;
            cities[msg.sender].energy -= 100;
            cities[msg.sender].powerPlant++;
        }
        
        cities[msg.sender].turn++;
    }

    function acceptTrade() public payable {
        require(cities[msg.sender].turn > 0, "Game not started");
        require(cities[msg.sender].wood >= 100, "Not enough wood");

        cities[msg.sender].wood -= 100;

        uint32 dstEid = 40161;
        bytes memory message = "";
        bytes memory options = "";

        lzEndpoint.send{value: msg.value}(dstEid, message, options);
    }

    function calculateScore(address _player) public view returns (uint256) {
        City storage playerCity = cities[_player];
        uint256 buildingCount = playerCity.residential + playerCity.factory + playerCity.powerPlant;
        uint256 buildingScore = buildingCount * 100;
        
        uint256 resourceValue = (playerCity.wood * 1) + (playerCity.steel * 2) + (playerCity.energy * 3);
        
        return buildingScore + resourceValue;
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32,
        bytes calldata
    ) internal override {
        cities[_origin.sender].steel += 150;
    }
}

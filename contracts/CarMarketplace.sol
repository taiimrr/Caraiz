pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CarMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _carsRegistered;
    address payable owner;
    uint256 listPrice = 0.01 ether;

    struct Car {
        uint256 carVIN;
        address payable owner;
        address payable seller;
        uint256 price;
        bool forSale;
        uint noOfEvents;
        mapping(uint => CarEvent) events;
    }
    struct CarEvent {
        string eventType;
        string details;
        uint256 timestamp;
    }
    mapping(uint256 => Car) private VinToCar;
    uint256 public totalCars;
    event CarAdded(
        uint256 indexed carId,
        address indexed owner,
        address indexed seller,
        uint256 price,
        bool forSale,
        uint256 timestamp
    );
    event CarSold(
        uint256 indexed carId,
        address indexed previousOwner,
        address indexed newOwner,
        uint256 price,
        uint256 timestamp
    );
    event CarEventAdded(
        uint256 indexed carId,
        string eventType,
        uint256 timestamp,
        string details
    );
    modifier onlyCarOwner(uint256 carVin) {
        require(
            VinToCar[carVin].owner == msg.sender,
            "You are not the owner of this car"
        );
        _;
    }

    constructor() ERC721("CarMarketplace", "CM") {
        owner = payable(msg.sender);
    }

    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update listing price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    // function getCarForId(uint256 Vin) public view returns (Car memory) {
    //     return VinToCar[Vin];
    // }

    function addCar(
        uint256 vin,
        uint256 price,
        string memory carURI
    ) public payable returns (uint) {
        _carsRegistered.increment();

        _safeMint(msg.sender, vin);
        _setTokenURI(vin, carURI);

        listCar(vin, price);
        return vin;
    }

    function listCar(uint256 vin, uint256 price) private {
        //Make sure the sender sent enough ETH to pay for listing
        require(msg.value >= listPrice, "Hopefully sending the correct price");
        //Just sanity check
        require(price > 0, "Make sure the price isn't negative");

        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        Car storage _car = VinToCar[vin];
        _car.carVIN = vin;

        _car.owner = payable(address(this));
        _car.seller = payable(msg.sender);
        _car.price = price;
        _car.forSale = true;
        _car.noOfEvents = 1;
        _car.events[0] = CarEvent(
            "Car Created",
            "Added to the Caraiz System",
            block.timestamp
        );

        _carsRegistered.increment();

        _transfer(msg.sender, address(this), vin);
        //Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit CarAdded(
            vin,
            address(this),
            msg.sender,
            price,
            true,
            block.timestamp
        );
    }

    function sellCar(uint256 carId) public payable {
        require(msg.sender != address(0), "Invalid address");
        address previousOwner = VinToCar[carId].seller;
        uint256 price = VinToCar[carId].price;
        require(
            msg.value >= price,
            "Please submit the asking price in order to complete the purchase"
        );
        _transfer(address(this), msg.sender, carId);
        approve(address(this), carId);
        VinToCar[carId].seller = payable(msg.sender);

        payable(owner).transfer(listPrice);
        payable(previousOwner).transfer(msg.value);

        emit CarSold(carId, previousOwner, msg.sender, price, block.timestamp);
    }

    function addCarEvent(
        uint256 carId,
        string memory eventType,
        string memory details
    ) external onlyCarOwner(carId) {
        VinToCar[carId].events[VinToCar[carId].noOfEvents] = CarEvent(
            eventType,
            details,
            block.timestamp
        );
        VinToCar[carId].noOfEvents++;
        emit CarEventAdded(carId, eventType, block.timestamp, details);
    }

    function getCarEvents(
        uint256 carId
    ) public view returns (CarEvent[] memory) {
        uint256 eventCount = VinToCar[carId].noOfEvents;

        CarEvent[] memory carEvent = new CarEvent[](eventCount);

        for (uint i = 0; i < eventCount; i++) {
            carEvent[i] = VinToCar[carId].events[i];
        }
        return carEvent;
    }
}

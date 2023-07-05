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
        uint256 price;
        bool forSale;
        CarEvent[] events;
    }
    struct CarEvent {
        string eventType;
        uint256 timestamp;
        string details;
    }
    mapping(uint256 => Car) private VinToCar;
    uint256 public totalCars;
    event CarAdded(
        uint256 indexed carId,
        address indexed owner,
        uint256 price,
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

    function getCarForId(uint256 Vin) public view returns (Car memory) {
        return VinToCar[Vin];
    }

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

        // Car storage car = VinToCar[vin];
        // car.owner = msg.sender;
        // car.price = price;
        // CarEvent memory carAdded = CarEvent(
        //     "Car Added To Caraiz System",
        //     block.timestamp,
        //     "Car Added to system"
        // );
        // car.events.push(carAdded);
    }

    function listCar(uint256 vin, uint256 price) private {
        //Make sure the sender sent enough ETH to pay for listing
        require(msg.value == listPrice, "Hopefully sending the correct price");
        //Just sanity check
        require(price > 0, "Make sure the price isn't negative");

        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        VinToCar[vin] = Car(vin, payable(msg.sender), price, true);

        _transfer(msg.sender, address(this), tokenId);
        //Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit TokenListedSuccess(tokenId, msg.sender, price, true);
    }

    function sellCar(
        uint256 carId,
        address newOwner
    ) external onlyCarOwner(carId) {
        require(newOwner != address(0), "Invalid address");
        address previousOwner = VinToCar[carId].owner;
        uint256 price = VinToCar[carId].price;
        VinToCar[carId].owner = newOwner;
        emit CarSold(carId, previousOwner, newOwner, price, block.timestamp);
    }

    function addCarEvent(
        uint256 carId,
        string calldata eventType,
        string memory details
    ) external onlyCarOwner(carId) {
        VinToCar[carId].events.push(
            CarEvent(eventType, block.timestamp, details)
        );
        emit CarEventAdded(carId, eventType, block.timestamp, details);
    }

    function getCarEvents(
        uint256 carId
    ) external view returns (CarEvent[] memory) {
        return VinToCar[carId].events;
    }
}

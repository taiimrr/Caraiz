// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {PriceConverter} from "./PriceConverter.sol";

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
    }
    struct CarEvent {
        string eventType;
        string details;
        uint256 timestamp;
    }
    mapping(uint256 => Car) private VinToCar;
    mapping(uint => CarEvent[]) events;
    mapping(address => uint[]) public ownerToVIN;
    mapping(uint => uint) public indexToVIN;

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
            VinToCar[carVin].seller == msg.sender,
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

    function addCar(
        uint256 vin,
        uint256 price,
        string memory carURI
    ) public payable returns (uint) {
        _safeMint(msg.sender, vin);
        _setTokenURI(vin, carURI);
        ownerToVIN[msg.sender].push(vin);
        indexToVIN[_carsRegistered.current()] = vin;
        _carsRegistered.increment();

        listCar(vin, price);
        return vin;
    }

    function listCar(uint256 vin, uint256 price) private {
        //Make sure the sender sent enough ETH to pay for listing
        require(msg.value >= listPrice, "Hopefully sending the correct price");
        //Just sanity check
        require(price > 0, "Make sure the price isn't negative");
        VinToCar[vin] = Car(
            vin,
            payable(address(this)),
            payable(msg.sender),
            price,
            true,
            0
        );
        addCarEvent(vin, "Car Added", "Car listed on Caraiz");
        _carsRegistered.increment();

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
        _transfer(previousOwner, address(this), carId);
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
    ) public onlyCarOwner(carId) {
        events[carId].push(CarEvent(eventType, details, block.timestamp));
        VinToCar[carId].noOfEvents++;
        emit CarEventAdded(carId, eventType, block.timestamp, details);
    }

    function getCarEvents(
        uint256 carId
    ) public view returns (CarEvent[] memory) {
        return events[carId];
    }

    function getCarForId(uint256 carId) public view returns (Car memory) {
        return VinToCar[carId];
    }

    function getMyCars() public view returns (Car[] memory) {
        uint itemCount = balanceOf(msg.sender);

        //Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        Car[] memory cars = new Car[](itemCount);
        for (uint i = 0; i < itemCount; i++) {
            Car memory current = VinToCar[ownerToVIN[msg.sender][i]];
            if (current.owner == msg.sender || current.seller == msg.sender) {
                cars[i] = current;
            }
        }
        return cars;
    }

    function getAllCars() public view returns (Car[] memory) {
        uint carCount = _carsRegistered.current();
        Car[] memory cars = new Car[](carCount);

        for (uint i = 0; i < carCount; i++) {
            Car memory current = VinToCar[indexToVIN[i]];

            cars[i] = current;
        }
        return cars;
    }
}

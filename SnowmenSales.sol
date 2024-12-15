// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SnowmenSales is Ownable, ERC1155Holder {
    using SafeERC20 for IERC20; // SafeERC20 라이브러리를 IERC20 타입에 연결해 안전한 토큰 전송 함수 사용 가능

    IERC20 public snowmenToken; // Snowmen ERC20 토큰의 인터페이스
    IERC1155 public snowmenGame; // Snowmen ERC1155 토큰(게임 아이템 등의 자산) 인터페이스

    uint256 private constant TICKET_PRICE = 0.01 ether;
    uint256 private constant TICKET_QUANTITY = 1;
    uint256 private constant TICKET_ID = 340282366920938463463374607431768211456;

    mapping(uint256 => uint256) public tokenPrice;
    //이벤트: 블록체인 상에서 발생하는 특정 상황을 로그로 기록해 감지하도록 하는 "신호" 역
    event SetPrice(uint256 tokenId, uint256 price, uint256 timestamp);

    event BuyItem(
        address indexed buyer, // 나중에 인덱스를 통해 원하는 buyer를 빨리 찾기 위함
        uint256 tokenId,
        uint256 amount,
        uint8 quantity,
        uint256 timestamp
    );

    event BuyTicket(address indexed buyer, uint256 timestamp);
    event Withdraw(address owner, uint256 amount);
    
    event onERC1155ReceivedExecuted(
        address operator,
        address from,
        uint256 id,
        uint256 value
    );

    constructor(address snowmenErc1155, address snowmenErc20) Ownable(_msgSender()){
        // 생성자: 컨트랙트를 배포할 때 특정한 ERC1155 토큰과 ERC20 토큰의 주소를 받아 초기화
        // Ownable(_msgSender())를 호출함으로써, 컨트랙트 소유자를 배포한 계정으로 설정
        snowmenGame = IERC1155(snowmenErc1155);
        snowmenToken = IERC20(snowmenErc20);
    }

    function onERC1155Received(
        address operator, // 해당 함수(토큰 전송)를 실행한 계정(주로 ERC1155 토큰 계약)
        address from, // 토큰을 전송한 사용자 주소
        uint256 id,  // 전송된 ERC1155 토큰의 ID
        uint256 value, // 전송된 토큰의 개수
        bytes memory // 추가적인 데이터(사용되지 않음)
    ) public override returns (bytes4) {
        // onERC1155Received는 ERC1155 표준에서 요구하는 훅(Hook)으로,
        // 본 컨트랙트가 ERC1155 토큰을 안전하게 받았음을 알리는 콜백 함수입니다.
        
        // 이 함수는 ERC1155 토큰이 현재 컨트랙트로 전송될 때 자동으로 호출됩니다.
        // msg.sender는 이 함수가 호출될 때, 토큰을 전송한 ERC1155 컨트랙트 주소를 나타냅니다.

        require(msg.sender == address(snowmenGame), "incorrect sender");
        // 전송한 토큰의 출처가 우리가 지정한 snowmenGame 컨트랙트인지 검사합니다.
        // 잘못된 컨트랙트(등록되지 않은 ERC1155)에서 온 요청은 거부합니다.

        require(value != 0, "quantity is zero");
        // 전송된 토큰 수량이 0개인 경우는 의미가 없으므로 거부합니다.

        emit onERC1155ReceivedExecuted(operator, from, id, value);
        // 토큰 수령이 성공적으로 처리되었음을 이벤트로 알립니다.
        // 이벤트는 블록체인 상에 로그로 남으며, 외부에서 트랜잭션 모니터링이 가능합니다.

        return this.onERC1155Received.selector;
        // ERC1155 표준에 따라, 이 함수는 ERC1155 컨트랙트에게 정상 수신을 의미하는 함수 셀렉터를 반환해야 합니다.
        // 이 반환값으로 인해 ERC1155 컨트랙트는 토큰 전달이 성공적으로 처리되었음을 알 수 있습니다.
    }

    function buyItem(
        uint256 tokenId,
        uint256 amount,
        uint8 quantity
    ) external {
        address buyer = msg.sender;
        require(tokenPrice[tokenId] != 0, "price is not set yet");
        require(amount >= tokenPrice[tokenId] * quantity, "amount not enough");
        require(
            snowmenGame.balanceOf(address(this), tokenId) >= quantity,
            "balance is not enough"
        );
        require(snowmenToken.balanceOf(buyer) >= amount, "insufficient token");
        require(
            snowmenToken.allowance(buyer, address(this)) >= amount,
            "insufficient token approval"
        );
        snowmenToken.safeTransferFrom(buyer, owner(), amount); //buyer가 owner()에게 amount만큼 토큰을 지불하겠다.
        snowmenGame.safeTransferFrom(
            address(this),
            buyer,
            tokenId,
            quantity,
            ""
        );
        emit BuyItem(buyer, tokenId, amount, quantity, block.timestamp);
    }

    function buyTicket() external payable {
        require(msg.value >= TICKET_PRICE, "price not enough"); //msg.value = 유저가 함수에 보낸 matic 개수

        // Ticker의 제한을 두고 싶지 않아서 새로 유저가 올 때마다 티켓을 민팅하도록 하겠다.
        // 외부 컨트랙트 함수를 사용하는 것중 하나가 로우레벨 함수 콜인데 가스비 아낄 수 있는 장점

        (bool success,) = address(snowmenGame).call(
            abi.encodeWithSignature( // bytes type로 묶기
                "mint(address,uint256,uint256)",
                msg.sender,
                TICKET_ID,
                TICKET_QUANTITY
            )
        );
        require(success, "mint failed");
        emit BuyTicket(msg.sender, block.timestamp);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner() {
        uint256 amount = getBalance();
        require(amount != 0, "insuffcient amount");
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "unable to withdraw matic");
        emit Withdraw(msg.sender, amount);
    }

    function setPrice(uint256 tokenId, uint256 price) external onlyOwner{
        require(tokenId != 0, "tokenId is zero");
        require(price != 0, "price is zero");
        tokenPrice[tokenId] = price;
        emit SetPrice(tokenId, price, block.timestamp); // 성공적으로 처리되었음을 알림.
    }
 }
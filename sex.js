/**
 * constant = 상수 / 수정몬함
 * var / let = 변수 / 수정간응
 * uint256 = 대충 숫자란소리 (interger)
 * 'public' = 외부에서 접근 가능(공용 화장실)
 * 'private' = 내부에서만 접근 가능(개인 화장실)
 * 'internal' = 내부에서만 접근 가능(집)
 * 'external' = 외부에서만 접근 가능(히토미)
 * string = 글
 * 
 */
using SafeMath for uint256;

    uint256 public lastExecutionTime;
    uint256 public interval = 1 days;
    uint256 public constant TOTAL_SUPPLY = 100000000 * (10 ** 18);
    /*

    * KO: TOTAL_SUPPLY = 1억 개의 토큰, 18자리 소수점.
    */

    address public constant EXCHANGE_ADDRESS = 0xD9e3C471Db8bB6281Fd57745EC00B8C1CC7CCA77;
    //거래소 주소라는뜻
    address public constant DEV_TEAM_ADDRESS = 0xD9e3C471Db8bB6281Fd57745EC00B8C1CC7CCA77;
    //yeah 
    address public constant REWARD_POOL_ADDRESS = 0xD9e3C471Db8bB6281Fd57745EC00B8C1CC7CCA77;
    //sex

    uint256 public constant INITIAL_EXCHANGE_LISTING_PERCENT = 40; 
    /*

    * KO: 최초 거래소 상장에 할당된 비율 40%.
    */

    uint256 public constant INITIAL_DEV_TEAM_PERCENT = 10; 
    /*

    * KO: 최초 개발팀에 할당된 비율 10%.
    */

    uint256 public constant INITIAL_REWARD_POOL_PERCENT = 50; 
    /*

    * KO: 최초 보상 풀에 할당된 비율 50%.
    */

    uint256 public constant FINAL_EXCHANGE_LISTING_PERCENT = 60; 
    /*

    * KO: 10년 후 거래소 상장에 할당된 최종 비율 60%.
    */

    uint256 public constant FINAL_DEV_TEAM_PERCENT = 20; 
    /*

    * KO: 10년 후 개발팀에 할당된 최종 비율 20%.
    */

    uint256 public constant FINAL_REWARD_POOL_PERCENT = 20;
    /*

    * KO: 10년 후 보상 풀에 할당된 최종 비율 20%.
    */

    uint256 public constant YEARS = 10;
    /*

    * KO: 배분 기간은 총 10년.
    */

    uint256 public constant QUARTERS_IN_YEAR = 4;
    /*

    * KO: 1년에 4분기.
    */

    uint256 public lastDistributionYear = 1;
    /*

    * KO: 마지막 토큰 배분 연도.
    */

    uint256 public devTeamTotalAllocated;
    uint256 public rewardPoolAllocated;
    uint256 public exchangeAllocated;

    uint256 public currentYear = 1;

    uint256 public requiredVotesPercentage = 50; 
    /*

    * KO: 투표 기반 작업을 위한 필요한 투표 비율 50%.
    */

    uint256 public totalVotesCast = 0;
    uint256 public constant lockUntil = 1761590400; 
    /*

    * KO: 락업 종료까지의 타임스탬프.
    */

    uint256 public lockedRewardSented = 0;

    mapping(address => bool) public hasVoted;
    mapping(address => uint256) public lockedBalances;

    function initialize() public initializer { // 시작점
        __ERC20_init("EscapeFromInternetWithAITest", "EAIT");
        // 토큰(코인명) 설정정
        __ERC20Votes_init();
        //투표 업그레이드 시작 선언
        _mint(msg.sender, TOTAL_SUPPLY); 
        /*
        
        * KO: 초기화 시 전체 토큰 공급량을 송신자에게 발행.
        */
        distributeInitialSupply();
        //함수 실행
        lastExecutionTime = block.timestamp;
    }
    function distributeInitialSupply() private {
        uint256 exchangeTokens = (TOTAL_SUPPLY / YEARS / 100 * INITIAL_EXCHANGE_LISTING_PERCENT);  
        /*
        
        * KO: 첫 해 거래소 상장에 할당될 토큰 수를 계산.
        */

        uint256 devTokens = (TOTAL_SUPPLY / YEARS / 100 * INITIAL_DEV_TEAM_PERCENT / 4);  
        /*
        
        * KO: 첫 해 개발팀에 할당될 토큰 수를 계산 (분기가 4번이므로 4로 나눔).
        */

        uint256 rewardTokens = (TOTAL_SUPPLY / YEARS / 100 * INITIAL_REWARD_POOL_PERCENT);  
        /*
        
        * KO: 첫 해 보상 풀에 할당될 토큰 수를 계산.
        */

        _transfer(msg.sender, EXCHANGE_ADDRESS, exchangeTokens);  
        /*
        
        * KO: 할당된 토큰을 거래소 주소로 전송.
        */

        _transfer(msg.sender, DEV_TEAM_ADDRESS, devTokens);  
        /*
        
        * KO: 할당된 토큰을 개발팀 주소로 전송.
        */

        lockedBalances[REWARD_POOL_ADDRESS] = lockedBalances[REWARD_POOL_ADDRESS].add(rewardTokens);  
        /*
        
        * KO: 할당된 보상 풀 토큰을 나중에 전송될 잠금된 잔액에 추가.
        */

        devTeamTotalAllocated = devTokens;
        rewardPoolAllocated = rewardTokens;
        exchangeAllocated = exchangeTokens;
    }

    function distributeTokensAutomatically() public {
        require(block.timestamp >= lastExecutionTime + interval, "Too early to execute");
        /*
        
        * KO: 지정된 간격 후에만 배분이 실행되도록 확인.
        */

        require(currentYear <= YEARS, "All tokens have already been distributed");
        /*
        
        * KO: 토큰 배분이 배분 기간 내(10년)인지를 확인.
        */

        require(currentYear > lastDistributionYear, "Tokens for this year have already been distributed");
        /*
        
        * KO: 현재 연도의 토큰이 이미 배분되지 않았는지 확인.
        */

        uint256 exchangeTokens = calculateReleasePercentage(currentYear,"EXC");  
        /*
        
        * KO: 현재 연도에 배분될 거래소 상장 토큰의 비율을 계산.
        */

        uint256 devTokens = calculateReleasePercentage(currentYear,"DEV");  
        /*
        
        * KO: 현재 연도에 배분될 개발팀 토큰의 비율을 계산.
        */

        uint256 rewardTokens = calculateReleasePercentage(currentYear,"POOL");  
        /*
        
        * KO: 현재 연도에 배분될 보상 풀 토큰의 비율을 계산.
        */

        _transfer(msg.sender, EXCHANGE_ADDRESS, exchangeTokens);  
        /*
        
        * KO: 계산된 거래소 상장 토큰을 거래소 주소로 전송.
        */

        _transfer(msg.sender, DEV_TEAM_ADDRESS, devTokens);  
        /*
        
        * KO: 계산된 개발팀 토큰을 개발팀 주소로 전송.
        */

        if (block.timestamp < lockUntil) {
            lockedBalances[REWARD_POOL_ADDRESS] = lockedBalances[REWARD_POOL_ADDRESS].add(rewardTokens);  
            /*

            * KO: 락업 기간이 끝나지 않으면 계산된 보상 풀 토큰을 잠긴 잔액에 추가.
            */
        } else if (block.timestamp < lockUntil && lockedRewardSented == 0) {
            _transfer(msg.sender, REWARD_POOL_ADDRESS, lockedBalances[REWARD_POOL_ADDRESS]);  
            /*

            * KO: 락업 기간이 끝나면 보상 풀 주소로 잠긴 보상 풀 토큰을 전송.
            */
            lockedRewardSented = 1;
        } else {
            _transfer(msg.sender, REWARD_POOL_ADDRESS, rewardTokens);  
            /*

            * KO: 락업 기간이 끝나면 계산된 보상 풀 토큰을 보상 풀 주소로 전송.
            */
        }

        exchangeAllocated = exchangeAllocated.add(exchangeTokens);  
        /*
        
        * KO: 할당된 거래소 토큰의 총 수를 업데이트.
        */

        devTeamTotalAllocated = devTeamTotalAllocated.add(devTokens);  
        /*
        
        * KO: 할당된 개발팀 토큰의 총 수를 업데이트.
        */

        rewardPoolAllocated = rewardPoolAllocated.add(rewardTokens);  
        /*
        
        * KO: 할당된 보상 풀 토큰의 총 수를 업데이트.
        */

        currentYear = currentYear.add(1);  
        /*
        
        * KO: 토큰 배분을 위해 다음 해로 진행.
        */

        lastDistributionYear = currentYear.sub(1);  
        /*
        
        * KO: 마지막 배분 연도를 현재 연도로 업데이트.
        */

        lastExecutionTime = block.timestamp;  
        /*
        
        * KO: 마지막 실행 시간을 현재 블록 타임스탬프로 업데이트.
        */

        emit TokensDistributed(exchangeTokens, devTokens, rewardTokens);  
        /*
        
        * KO: 토큰 배분을 나타내는 이벤트를 발생.
        */
    }

    function calculateReleasePercentage(uint256 year, string memory category) public pure returns (uint256) {
        require(year >= 1 && year <= YEARS, "Invalid year");  
        /*
        
        * KO: 연도가 유효한 범위(1년 ~ 10년) 내에 있는지 확인.
        */

        uint256 exchangePercentage;
        uint256 devTeamPercentage;
        uint256 rewardPoolPercentage;

        // Calculate the release percentage for each category
        exchangePercentage = INITIAL_EXCHANGE_LISTING_PERCENT
            .sub(INITIAL_EXCHANGE_LISTING_PERCENT.sub(FINAL_EXCHANGE_LISTING_PERCENT).mul(year).div(YEARS));
        /*
        
        * KO: 현재 연도를 기준으로 거래소 상장 비율을 계산.
        */

        devTeamPercentage = INITIAL_DEV_TEAM_PERCENT
            .sub(INITIAL_DEV_TEAM_PERCENT.sub(FINAL_DEV_TEAM_PERCENT).mul(year).div(YEARS));
        /*
        
        * KO: 현재 연도를 기준으로 개발팀 비율을 계산.
        */

        rewardPoolPercentage = INITIAL_REWARD_POOL_PERCENT
            .sub(INITIAL_REWARD_POOL_PERCENT.sub(FINAL_REWARD_POOL_PERCENT).mul(year).div(YEARS));
        /*
        
        * KO: 현재 연도를 기준으로 보상 풀 비율을 계산.
        */

        // Return the corresponding percentage based on the category
        if (keccak256(abi.encodePacked(category)) == keccak256(abi.encodePacked("EXC"))) {
            return exchangePercentage;
        } else if (keccak256(abi.encodePacked(category)) == keccak256(abi.encodePacked("DEV"))) {
            return devTeamPercentage;
        } else if (keccak256(abi.encodePacked(category)) == keccak256(abi.encodePacked("POOL"))) {
            return rewardPoolPercentage;
        } else {
            revert("Invalid category");  
            /*

            * KO: 카테고리가 잘못된 경우 예외 처리.
            */
        }
    }

    function voteForUpgrade() external {
        require(balanceOf(msg.sender) >= 100 * 10 ** decimals(), "You must hold at least 100 EFI tokens to vote");  
        /*
        * KO: 투표하려면 최소 100 토큰을 보유해야 한다는 것을 확인.
        */

        require(!hasVoted[msg.sender], "You have already voted");  
        /*
        
        * KO: 이미 투표한 주소가 아니어야 한다는 것을 확인.
        */

        // Mark the sender as having voted
        hasVoted[msg.sender] = true;  

        // Add the sender's token balance to the total votes
        totalVotesCast = totalVotesCast.add(balanceOf(msg.sender));  

        // If total votes exceed the required percentage, allow the upgrade
        if (totalVotesCast >= TOTAL_SUPPLY.mul(requiredVotesPercentage).div(100)) {
            enableUpgrade();  
            /*

            * KO: 충분한 투표가 진행되면 enableUpgrade() 함수를 호출.
            */
        }
    }
    // Function to allow upgrade after sufficient votes have been cast
    function enableUpgrade() public {
        require(totalVotesCast >= TOTAL_SUPPLY.mul(requiredVotesPercentage).div(100), "Not enough votes for upgrade");  
        /*
        
        * KO: 업그레이드를 허용하기 위해 충분한 투표가 있는지 확인.
        */

        // Emit an event indicating the upgrade has been enabled
        emit UpgradeEnabled(msg.sender, totalVotesCast);  
        /*
        
        * KO: 업그레이드가 활성화되었음을 알리는 이벤트를 발생.
        */
    }

    // Function to track total supply for a specific category (useful for auditing purposes)
    function totalSupplyByCategory() public view returns (uint256) {
        return totalSupply();  
        /*
        
        * KO: 토큰의 총 공급량을 반환.
        */
    }

    // Function to unlock development team tokens each quarter (admin can execute)
    // 90일마다 25%씩 자동으로 발행되며, 이는 절대로 수정되지 않도록 설정
    bool public devTokensUnlocked = false;

    function unlockDevTokens(address devAddress) public {
        require(block.timestamp >= lastExecutionTime + interval, "Too early to execute");  
        /*
        
        * KO: 지정된 간격이 지난 후에만 실행되도록 확인.
        */

        require(!devTokensUnlocked, "Development team tokens are already unlocked.");  
        /*
        
        * KO: 개발 팀 토큰이 한 번만 잠금 해제되는지 확인.
        */

        uint256 unlockAmount = devTeamTotalAllocated.mul(25).div(100); // 25% per quarter  
        /*
        
        * KO: 개발 팀에 할당된 토큰의 25%를 잠금 해제.
        */

        _mint(devAddress, unlockAmount);  
        /*
        
        * KO: 잠금 해제된 토큰을 개발 팀 주소로 발행하고 전송.
        */

        devTokensUnlocked = true;  
        /*
        
        * KO: 개발 팀 토큰이 잠금 해제됨으로 표시되어 향후 수정 방지.
        */

        devTeamTotalAllocated -= unlockAmount;  
        /*
        
        * KO: 개발 팀의 할당량을 줄임.
        */

        lastExecutionTime = block.timestamp;  
        /*
        
        * KO: 마지막 실행 시간을 업데이트.
        */
    }

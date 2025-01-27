// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

contract EscapeFromInternetWithAITest is ERC20VotesUpgradeable {
    using SafeMath for uint256;

    uint256 public lastExecutionTime;
    uint256 public interval = 1 days;
    uint256 public constant TOTAL_SUPPLY = 100000000 * (10 ** 18);
    /*
    * EN: TOTAL_SUPPLY = 100,000,000 tokens with 18 decimals.
    * JP: TOTAL_SUPPLY = 1億トークン、18桁の精度。
    * KO: TOTAL_SUPPLY = 1억 개의 토큰, 18자리 소수점.
    */

    address public constant EXCHANGE_ADDRESS = 0xD9e3C471Db8bB6281Fd57745EC00B8C1CC7CCA77;
    address public constant DEV_TEAM_ADDRESS = 0xD9e3C471Db8bB6281Fd57745EC00B8C1CC7CCA77;
    address public constant REWARD_POOL_ADDRESS = 0xD9e3C471Db8bB6281Fd57745EC00B8C1CC7CCA77;

    uint256 public constant INITIAL_EXCHANGE_LISTING_PERCENT = 40; 
    /*
    * EN: INITIAL_EXCHANGE_LISTING_PERCENT = 40% of total supply allocated for exchange listing initially.
    * JP: 初期の取引所上場の割合40%。
    * KO: 최초 거래소 상장에 할당된 비율 40%.
    */

    uint256 public constant INITIAL_DEV_TEAM_PERCENT = 10; 
    /*
    * EN: INITIAL_DEV_TEAM_PERCENT = 10% of total supply allocated for development team initially.
    * JP: 開発チームに対する初期配分割合10%。
    * KO: 최초 개발팀에 할당된 비율 10%.
    */

    uint256 public constant INITIAL_REWARD_POOL_PERCENT = 50; 
    /*
    * EN: INITIAL_REWARD_POOL_PERCENT = 50% of total supply allocated for the reward pool initially.
    * JP: 報酬プールに対する初期配分割合50%。
    * KO: 최초 보상 풀에 할당된 비율 50%.
    */

    uint256 public constant FINAL_EXCHANGE_LISTING_PERCENT = 60; 
    /*
    * EN: FINAL_EXCHANGE_LISTING_PERCENT = 60% of total supply allocated for exchange listing after 10 years.
    * JP: 10年後に取引所上場に対する最終的な配分割合60%。
    * KO: 10년 후 거래소 상장에 할당된 최종 비율 60%.
    */

    uint256 public constant FINAL_DEV_TEAM_PERCENT = 20; 
    /*
    * EN: FINAL_DEV_TEAM_PERCENT = 20% of total supply allocated for development team after 10 years.
    * JP: 10年後に開発チームに対する最終的な配分割合20%。
    * KO: 10년 후 개발팀에 할당된 최종 비율 20%.
    */

    uint256 public constant FINAL_REWARD_POOL_PERCENT = 20;
    /*
    * EN: FINAL_REWARD_POOL_PERCENT = 20% of total supply allocated for the reward pool after 10 years.
    * JP: 10年後に報酬プールに対する最終的な配分割合20%。
    * KO: 10년 후 보상 풀에 할당된 최종 비율 20%.
    */

    uint256 public constant YEARS = 10;
    /*
    * EN: YEARS = Total number of years for distribution (10 years).
    * JP: 分配の総期間は10年。
    * KO: 배분 기간은 총 10년.
    */

    uint256 public constant QUARTERS_IN_YEAR = 4;
    /*
    * EN: QUARTERS_IN_YEAR = 4 quarters in a year.
    * JP: 1年は4四半期です。
    * KO: 1년에 4분기.
    */

    uint256 public lastDistributionYear = 1;
    /*
    * EN: lastDistributionYear = Year of the last token distribution.
    * JP: 最後のトークン配分年。
    * KO: 마지막 토큰 배분 연도.
    */

    uint256 public devTeamTotalAllocated;
    uint256 public rewardPoolAllocated;
    uint256 public exchangeAllocated;

    uint256 public currentYear = 1;

    uint256 public requiredVotesPercentage = 50; 
    /*
    * EN: requiredVotesPercentage = 50% of total supply required for voting-based actions.
    * JP: 必要な投票割合は、総供給量の50%。
    * KO: 투표 기반 작업을 위한 필요한 투표 비율 50%.
    */

    uint256 public totalVotesCast = 0;
    uint256 public constant lockUntil = 1761590400; 
    /*
    * EN: lockUntil = Timestamp indicating the time until which the reward pool tokens are locked.
    * JP: ロック解除されるまでのタイムスタンプ。
    * KO: 락업 종료까지의 타임스탬프.
    */

    uint256 public lockedRewardSented = 0;

    mapping(address => bool) public hasVoted;
    mapping(address => uint256) public lockedBalances;

    function initialize() public initializer {
        __ERC20_init("EscapeFromInternetWithAITest", "EAIT");
        __ERC20Votes_init();
        _mint(msg.sender, TOTAL_SUPPLY); 
        /*
        * EN: Mint the total supply of tokens to the sender during initialization.
        * JP: 初期化時にトークンの総供給量を送信者に発行。
        * KO: 초기화 시 전체 토큰 공급량을 송신자에게 발행.
        */
        distributeInitialSupply();
        lastExecutionTime = block.timestamp;
    }
    function distributeInitialSupply() private {
        uint256 exchangeTokens = (TOTAL_SUPPLY / YEARS / 100 * INITIAL_EXCHANGE_LISTING_PERCENT);  
        /*
        * EN: Calculates the number of tokens allocated to the exchange listing for the first year.
        * JP: 最初の年に取引所上場用に配分されるトークンの数を計算。
        * KO: 첫 해 거래소 상장에 할당될 토큰 수를 계산.
        */

        uint256 devTokens = (TOTAL_SUPPLY / YEARS / 100 * INITIAL_DEV_TEAM_PERCENT / 4);  
        /*
        * EN: Calculates the number of tokens allocated to the development team for the first year (divided by 4 since the allocation happens quarterly).
        * JP: 最初の年に開発チームに配分されるトークンの数を計算（4分割されるので4で割る）。
        * KO: 첫 해 개발팀에 할당될 토큰 수를 계산 (분기가 4번이므로 4로 나눔).
        */

        uint256 rewardTokens = (TOTAL_SUPPLY / YEARS / 100 * INITIAL_REWARD_POOL_PERCENT);  
        /*
        * EN: Calculates the number of tokens allocated to the reward pool for the first year.
        * JP: 最初の年に報酬プールに配分されるトークンの数を計算。
        * KO: 첫 해 보상 풀에 할당될 토큰 수를 계산.
        */

        _transfer(msg.sender, EXCHANGE_ADDRESS, exchangeTokens);  
        /*
        * EN: Transfers the allocated tokens to the exchange address.
        * JP: 配分されたトークンを取引所のアドレスに送信。
        * KO: 할당된 토큰을 거래소 주소로 전송.
        */

        _transfer(msg.sender, DEV_TEAM_ADDRESS, devTokens);  
        /*
        * EN: Transfers the allocated tokens to the development team address.
        * JP: 配分されたトークンを開発チームのアドレスに送信。
        * KO: 할당된 토큰을 개발팀 주소로 전송.
        */

        lockedBalances[REWARD_POOL_ADDRESS] = lockedBalances[REWARD_POOL_ADDRESS].add(rewardTokens);  
        /*
        * EN: Adds the allocated reward pool tokens to the locked balance, which will be transferred later.
        * JP: 配分された報酬プールトークンをロックされた残高に加算（後で転送される）。
        * KO: 할당된 보상 풀 토큰을 나중에 전송될 잠금된 잔액에 추가.
        */

        devTeamTotalAllocated = devTokens;
        rewardPoolAllocated = rewardTokens;
        exchangeAllocated = exchangeTokens;
    }

    function distributeTokensAutomatically() public {
        require(block.timestamp >= lastExecutionTime + interval, "Too early to execute");
        /*
        * EN: Ensures that the distribution happens only after the specified interval.
        * JP: 配分が指定されたインターバル後にのみ実行されることを確認。
        * KO: 지정된 간격 후에만 배분이 실행되도록 확인.
        */

        require(currentYear <= YEARS, "All tokens have already been distributed");
        /*
        * EN: Ensures that the token distribution is still within the distribution period (10 years).
        * JP: トークン配分が配分期間内（10年）であることを確認。
        * KO: 토큰 배분이 배분 기간 내(10년)인지를 확인.
        */

        require(currentYear > lastDistributionYear, "Tokens for this year have already been distributed");
        /*
        * EN: Ensures that tokens for the current year have not already been distributed.
        * JP: 現在の年にトークンがすでに配分されていないことを確認。
        * KO: 현재 연도의 토큰이 이미 배분되지 않았는지 확인.
        */

        uint256 exchangeTokens = calculateReleasePercentage(currentYear,"EXC");  
        /*
        * EN: Calculates the percentage of exchange listing tokens to be distributed in the current year.
        * JP: 現在の年に配分される取引所上場トークンの割合を計算。
        * KO: 현재 연도에 배분될 거래소 상장 토큰의 비율을 계산.
        */

        uint256 devTokens = calculateReleasePercentage(currentYear,"DEV");  
        /*
        * EN: Calculates the percentage of development team tokens to be distributed in the current year.
        * JP: 現在の年に配分される開発チームトークンの割合を計算。
        * KO: 현재 연도에 배분될 개발팀 토큰의 비율을 계산.
        */

        uint256 rewardTokens = calculateReleasePercentage(currentYear,"POOL");  
        /*
        * EN: Calculates the percentage of reward pool tokens to be distributed in the current year.
        * JP: 現在の年に配分される報酬プールトークンの割合を計算。
        * KO: 현재 연도에 배분될 보상 풀 토큰의 비율을 계산.
        */

        _transfer(msg.sender, EXCHANGE_ADDRESS, exchangeTokens);  
        /*
        * EN: Transfers the calculated exchange listing tokens to the exchange address.
        * JP: 計算された取引所上場トークンを取引所アドレスに送信。
        * KO: 계산된 거래소 상장 토큰을 거래소 주소로 전송.
        */

        _transfer(msg.sender, DEV_TEAM_ADDRESS, devTokens);  
        /*
        * EN: Transfers the calculated development team tokens to the development team address.
        * JP: 計算された開発チームトークンを開発チームアドレスに送信。
        * KO: 계산된 개발팀 토큰을 개발팀 주소로 전송.
        */

        if (block.timestamp < lockUntil) {
            lockedBalances[REWARD_POOL_ADDRESS] = lockedBalances[REWARD_POOL_ADDRESS].add(rewardTokens);  
            /*
            * EN: Adds the calculated reward pool tokens to the locked balance if the lock period is not over.
            * JP: ロック期間が終了していない場合、計算された報酬プールトークンをロックされた残高に加算。
            * KO: 락업 기간이 끝나지 않으면 계산된 보상 풀 토큰을 잠긴 잔액에 추가.
            */
        } else if (block.timestamp < lockUntil && lockedRewardSented == 0) {
            _transfer(msg.sender, REWARD_POOL_ADDRESS, lockedBalances[REWARD_POOL_ADDRESS]);  
            /*
            * EN: Transfers the locked reward pool tokens to the reward pool address once the lock period ends.
            * JP: ロック期間が終了した後、ロックされた報酬プールトークンを報酬プールアドレスに送信。
            * KO: 락업 기간이 끝나면 보상 풀 주소로 잠긴 보상 풀 토큰을 전송.
            */
            lockedRewardSented = 1;
        } else {
            _transfer(msg.sender, REWARD_POOL_ADDRESS, rewardTokens);  
            /*
            * EN: Transfers the calculated reward pool tokens to the reward pool address once the lock period is over.
            * JP: ロック期間が終了した後、計算された報酬プールトークンを報酬プールアドレスに送信。
            * KO: 락업 기간이 끝나면 계산된 보상 풀 토큰을 보상 풀 주소로 전송.
            */
        }

        exchangeAllocated = exchangeAllocated.add(exchangeTokens);  
        /*
        * EN: Updates the total number of exchange tokens that have been allocated.
        * JP: 配分された取引所トークンの総数を更新。
        * KO: 할당된 거래소 토큰의 총 수를 업데이트.
        */

        devTeamTotalAllocated = devTeamTotalAllocated.add(devTokens);  
        /*
        * EN: Updates the total number of development team tokens that have been allocated.
        * JP: 配分された開発チームトークンの総数を更新。
        * KO: 할당된 개발팀 토큰의 총 수를 업데이트.
        */

        rewardPoolAllocated = rewardPoolAllocated.add(rewardTokens);  
        /*
        * EN: Updates the total number of reward pool tokens that have been allocated.
        * JP: 配分された報酬プールトークンの総数を更新。
        * KO: 할당된 보상 풀 토큰의 총 수를 업데이트.
        */

        currentYear = currentYear.add(1);  
        /*
        * EN: Advances to the next year for the token distribution.
        * JP: 次の年に進み、トークンの配分を実行。
        * KO: 토큰 배분을 위해 다음 해로 진행.
        */

        lastDistributionYear = currentYear.sub(1);  
        /*
        * EN: Updates the last distribution year to the current year.
        * JP: 最後の配分年を現在の年に更新。
        * KO: 마지막 배분 연도를 현재 연도로 업데이트.
        */

        lastExecutionTime = block.timestamp;  
        /*
        * EN: Updates the last execution time to the current block timestamp.
        * JP: 最後の実行時間を現在のブロックタイムスタンプに更新。
        * KO: 마지막 실행 시간을 현재 블록 타임스탬프로 업데이트.
        */

        emit TokensDistributed(exchangeTokens, devTokens, rewardTokens);  
        /*
        * EN: Emits an event indicating the distribution of tokens.
        * JP: トークンの配分を示すイベントを発行。
        * KO: 토큰 배분을 나타내는 이벤트를 발생.
        */
    }

    function calculateReleasePercentage(uint256 year, string memory category) public pure returns (uint256) {
        require(year >= 1 && year <= YEARS, "Invalid year");  
        /*
        * EN: Ensures the year is within the valid range (1 to 10).
        * JP: 年が有効な範囲（1年から10年）内であることを確認。
        * KO: 연도가 유효한 범위(1년 ~ 10년) 내에 있는지 확인.
        */

        uint256 exchangePercentage;
        uint256 devTeamPercentage;
        uint256 rewardPoolPercentage;

        // Calculate the release percentage for each category
        exchangePercentage = INITIAL_EXCHANGE_LISTING_PERCENT
            .sub(INITIAL_EXCHANGE_LISTING_PERCENT.sub(FINAL_EXCHANGE_LISTING_PERCENT).mul(year).div(YEARS));
        /*
        * EN: Calculates the percentage for exchange listing based on the current year.
        * JP: 現在の年に基づいて取引所上場の割合を計算。
        * KO: 현재 연도를 기준으로 거래소 상장 비율을 계산.
        */

        devTeamPercentage = INITIAL_DEV_TEAM_PERCENT
            .sub(INITIAL_DEV_TEAM_PERCENT.sub(FINAL_DEV_TEAM_PERCENT).mul(year).div(YEARS));
        /*
        * EN: Calculates the percentage for the development team based on the current year.
        * JP: 現在の年に基づいて開発チームの割合を計算。
        * KO: 현재 연도를 기준으로 개발팀 비율을 계산.
        */

        rewardPoolPercentage = INITIAL_REWARD_POOL_PERCENT
            .sub(INITIAL_REWARD_POOL_PERCENT.sub(FINAL_REWARD_POOL_PERCENT).mul(year).div(YEARS));
        /*
        * EN: Calculates the percentage for the reward pool based on the current year.
        * JP: 現在の年に基づいて報酬プールの割合を計算。
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
            * EN: Reverts if the category is invalid.
            * JP: カテゴリが無効な場合は処理を中止。
            * KO: 카테고리가 잘못된 경우 예외 처리.
            */
        }
    }

    function voteForUpgrade() external {
        require(balanceOf(msg.sender) >= 100 * 10 ** decimals(), "You must hold at least 100 EFI tokens to vote");  
        /*
        * EN: Ensures the voter holds at least 100 tokens to vote.
        * JP: 投票するには最低100トークンを保持していることを確認。
        * KO: 투표하려면 최소 100 토큰을 보유해야 한다는 것을 확인.
        */

        require(!hasVoted[msg.sender], "You have already voted");  
        /*
        * EN: Ensures the address has not voted already.
        * JP: 既に投票していないことを確認。
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
            * EN: Calls enableUpgrade() if enough votes have been cast.
            * JP: 十分な投票が行われた場合、enableUpgrade() を呼び出す。
            * KO: 충분한 투표가 진행되면 enableUpgrade() 함수를 호출.
            */
        }
    }
    // Function to allow upgrade after sufficient votes have been cast
    function enableUpgrade() public {
        require(totalVotesCast >= TOTAL_SUPPLY.mul(requiredVotesPercentage).div(100), "Not enough votes for upgrade");  
        /*
        * EN: Ensures there are enough votes for the upgrade to be allowed.
        * JP: アップグレードを許可するためには十分な投票があることを確認。
        * KO: 업그레이드를 허용하기 위해 충분한 투표가 있는지 확인.
        */

        // Emit an event indicating the upgrade has been enabled
        emit UpgradeEnabled(msg.sender, totalVotesCast);  
        /*
        * EN: Emits an event for upgrade enabling.
        * JP: アップグレードを有効化したことを示すイベントを発火。
        * KO: 업그레이드가 활성화되었음을 알리는 이벤트를 발생.
        */
    }

    // Function to track total supply for a specific category (useful for auditing purposes)
    function totalSupplyByCategory() public view returns (uint256) {
        return totalSupply();  
        /*
        * EN: Returns the total supply of tokens.
        * JP: トークンの総供給量を返す。
        * KO: 토큰의 총 공급량을 반환.
        */
    }

    // Function to unlock development team tokens each quarter (admin can execute)
    // 90일마다 25%씩 자동으로 발행되며, 이는 절대로 수정되지 않도록 설정
    bool public devTokensUnlocked = false;

    function unlockDevTokens(address devAddress) public {
        require(block.timestamp >= lastExecutionTime + interval, "Too early to execute");  
        /*
        * EN: Ensures the function can only be executed after the specified interval.
        * JP: 指定された間隔の後にのみ実行できるように確認。
        * KO: 지정된 간격이 지난 후에만 실행되도록 확인.
        */

        require(!devTokensUnlocked, "Development team tokens are already unlocked.");  
        /*
        * EN: Ensures the dev tokens are not unlocked more than once.
        * JP: 開発チームのトークンが一度だけ解除されることを確認。
        * KO: 개발 팀 토큰이 한 번만 잠금 해제되는지 확인.
        */

        uint256 unlockAmount = devTeamTotalAllocated.mul(25).div(100); // 25% per quarter  
        /*
        * EN: Unlocks 25% of the allocated development team tokens.
        * JP: 開発チームの割り当てられたトークンの25%を解除。
        * KO: 개발 팀에 할당된 토큰의 25%를 잠금 해제.
        */

        _mint(devAddress, unlockAmount);  
        /*
        * EN: Mints and transfers the unlocked tokens to the development team.
        * JP: 解除されたトークンを開発チームに発行して転送。
        * KO: 잠금 해제된 토큰을 개발 팀 주소로 발행하고 전송.
        */

        devTokensUnlocked = true;  
        /*
        * EN: Marks the development team tokens as unlocked to prevent future changes.
        * JP: 開発チームのトークンを解除済みとしてマークし、将来の変更を防止。
        * KO: 개발 팀 토큰이 잠금 해제됨으로 표시되어 향후 수정 방지.
        */

        devTeamTotalAllocated -= unlockAmount;  
        /*
        * EN: Reduces the allocated amount for the development team.
        * JP: 開発チームの割り当て量を減少させる。
        * KO: 개발 팀의 할당량을 줄임.
        */

        lastExecutionTime = block.timestamp;  
        /*
        * EN: Updates the last execution time.
        * JP: 最後の実行時間を更新。
        * KO: 마지막 실행 시간을 업데이트.
        */
    }
    
    event ContractDeployed(address deployedBy, uint256 deployTime);

    event UpgradeEnabled(address sender, uint256 totalVotes);

    event TokensDistributed(uint256 exchangeTokens, uint256 devTokens, uint256 rewardTokens);

}

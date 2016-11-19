function [leftLottery, rightLottery, goodLotteryLoc] = determine_lottery_loc(lotteryOption1, lotteryOption2)

% Concatenates all lotteries into 3D matrix and randomly determines, which
% lottery is left or right of fixcross
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
% 
% [leftLottery, rightLottery, goodLotteryLoc] = determine_lottery_loc(lotteryOption1, lotteryOption2)
%
% IN:
% - lotteryOption1: a vector of 0s and 1s defining p(success)
% - lotteryOption2: a vector of 0s and 1s defining p(success) for option 2
%
% OUT:
% - leftLottery: 1by10 vector of 0s and 1s reflecting a lottery 
% - rightLottery: 1by10 vector of 0s and 1s reflecting another lottery 
% - goodLotteryLoc: the location of the better lottery 1(left) or 2(right)
%

%% Function start

goodLotteryLoc = randi(2,1)                                                 ; % determine whether good lottery will be left(1) or right(2)

if goodLotteryLoc == 1
    allLotteries = cat(3, lotteryOption1, lotteryOption2)                   ; % put all lotteries into 3D matrix so that we can pick randomly
else
    allLotteries = cat(3, lotteryOption2, lotteryOption1)                   ;
end

leftLottery = allLotteries(:,:,1)                                           ;
rightLottery = allLotteries(:,:,2)                                          ;

%% Function end
end

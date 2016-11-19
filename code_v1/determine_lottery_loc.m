function [leftLottery, rightLottery, goodLotteryLoc] = determine_lottery_loc(lotteryOption1, lotteryOption2)

% a function to determine lottery location
%
% Concatenate all our lotteries into 3D matrix and randomly determine
% which lottery is left or right of fixcross
% This is done once per 'game' and is drawn uniformly
%
% Parameters
% ----------
% lotteryOption1: a vector of 0s and 1s defining p(success)
% lotteryOption2: a vector of 0s and 1s defining p(success) for option 2
%
%
% Returns
% ----------
% leftLottery: 
% rightLottery:
% goodLotteryLoc: the location of the better lottery 1(left) or 2(right)
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

end

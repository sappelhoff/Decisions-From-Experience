function [left_lottery, right_lottery, good_lottery_loc] = determine_lottery_loc(lottery_option1, lottery_option2)

% a function to determine lottery location
%
% Concatenate all our lotteries into 3D matrix and randomly determine
% which lottery is left or right of fixcross
% This is done once per 'game' and is drawn uniformly
%
% Parameters
% ----------
% lottery_option1: a vector of 0s and 1s defining p(success)
% lottery_option2: a vector of 0s and 1s defining p(success) for option 2
%
%
% Returns
% ----------
% left_lottery: 
% right_lottery:
% good_lottery_loc: the location of the better lottery 1(left) or 2(right)
%


%% Function start

good_lottery_loc = randi(2,1)                                              ; % determine whether good lottery will be left(1) or right(2)

if good_lottery_loc == 1
    all_lotteries = cat(3, lottery_option1, lottery_option2)               ; % put all lotteries into 3D matrix so that we can pick randomly
else
    all_lotteries = cat(3, lottery_option2, lottery_option1)               ;
end

left_lottery = all_lotteries(:,:,1)                                        ;
right_lottery = all_lotteries(:,:,2)                                       ;

end

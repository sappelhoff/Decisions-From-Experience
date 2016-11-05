function [pickedLoc, rewardBool, rt] = require_response(leftLottery, rightLottery, pDistr)
% a function to inquire about key pressed and their timings
%
% Parameters
% ----------
% - leftLottery: the lottery connected to button [left]
% - rightLottery: the lottery connected to button [right]
% - pDistr(optional argument): probability of a distractor occuring 
%
% Returns
% ----------
% - pickedLoc: either 1(=left) or 2(=right) for the picked location
% - rewardBool: either 0 or 1 depending on whether the choice was rewarded
% ... can also be 2 in 5% of all cases, to present a distractor
% - rt: reaction time in ms to respond
%
%
%-------------------------------------------------------------------------%
%                      Keyboard information                              %
%-------------------------------------------------------------------------%


leftKey = KbName('LeftArrow')                                               ; % choose left lottery
rightKey = KbName('RightArrow')                                             ; % choose right lottery

%% Function start

tStart = GetSecs                                                            ; % get time of start
respToBeMade = true                                                         ; % condition for while loop
while respToBeMade            
    [~,tEnd,keyCode] = KbCheck                                              ; % PTB inquiry to keyboard including time when button is pressed
        if keyCode(leftKey)
            rewardBool = Sample(leftLottery)                                ; % drawing either a 0(loss) or a 1(win)
            pickedLoc = 1                                                   ; % 1 for left
            respToBeMade = false                                            ; % stop checking now
        elseif keyCode(rightKey)
            rewardBool = Sample(rightLottery)                               ; 
            pickedLoc = 2                                                   ; % 2 for right
            respToBeMade = false                                            ;            
        end
end
rt = tEnd - tStart                                                          ; % Measure timing

if nargin == 3
    if rand <= pDistr
        rewardBool = 2                                                      ; % in p_distractor of all trials, present a distractor instead of the reward
    end
end
end
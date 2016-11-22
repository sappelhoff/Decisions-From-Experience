function [pickedLoc, rewardBool, rt] = require_response(leftLottery, rightLottery, tStart)

% Function remains in a while loop until either [left] or [right] are
% pressed. Then, measures the associated RT, and samples the lottery either
% left or right.
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
%
% [pickedLoc, rewardBool, rt] = require_response(leftLottery, rightLottery)
%
% IN:
% - leftLottery: the lottery connected to button [left]
% - rightLottery: the lottery connected to button [right]
% - tStart: the time, when the RT test was triggered. E.g., a vbl from the
% last screen flip. Alternatively, a GetSecs; right before the function
% call
%
% OUT:
% - pickedLoc: either 1(=left) or 2(=right) for the picked location
% - rewardBool: either 0 or 1 depending on whether the choice was rewarded
% ... can also be 2 in 5% of all cases, to present a distractor
% - rt: reaction time in ms to respond
%

%% Function start

%-------------------------------------------------------------------------%
%                      Keyboard information                               %
%-------------------------------------------------------------------------%

leftKey = KbName('LeftArrow')                                               ; % choose left lottery
rightKey = KbName('RightArrow')                                             ; % choose right lottery

%% 

respToBeMade = true                                                         ; % condition for while loop
while respToBeMade            
    [~,tEnd,keyCode] = KbCheck                                              ; % PTB inquiry to keyboard including time when button is pressed
        if keyCode(leftKey)
            rt = tEnd - tStart                                              ; % Measure timing
            rewardBool = Sample(leftLottery)                                ; % drawing either a 0(loss) or a 1(win)
            pickedLoc = 1                                                   ; % 1 for left
            respToBeMade = false                                            ; % stop checking now
        elseif keyCode(rightKey)
            rt = tEnd - tStart                                              ; % Measure timing
            rewardBool = Sample(rightLottery)                               ; 
            pickedLoc = 2                                                   ; % 2 for right
            respToBeMade = false                                            ;            
        end
end

%% Function end
end
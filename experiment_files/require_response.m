function [pickedLoc, rewardBool, rt] = require_response(leftLottery, rightLottery)
% a function to inquire about keypressed and their timings
%
% Parameters
% ----------
% - leftLottery: the lottery connected to button [left]
% - rightLottery: the lottery connected to button [right]
%
% Returns
% ----------
% - pickedLoc: either 1(=left) or 2(=right) for the picked location
% - rewardBool: either 0 or 1 depending on whether the choice was rewarded
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
end
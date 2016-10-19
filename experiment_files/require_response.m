function [picked_loc, reward_bool, rt] = require_response(left_lottery, right_lottery)
% a function to inquire about keypressed and their timings
%
% Parameters
% ----------
% - left_lottery: the lottery connected to button [left]
% - right_lottery: the lottery connected to button [right]
%
% Returns
% ----------
% - picked_loc: either 1(=left) or 2(=right) for the picked location
% - reward_bool: either 0 or 1 depending on whether the choice was rewarded
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
            reward_bool = Sample(left_lottery)                              ; % drawing either a 0(loss) or a 1(win)
            picked_loc = 1                                                  ; % 1 for left
            respToBeMade = false                                            ; % stop checking now
        elseif keyCode(rightKey)
            reward_bool = Sample(right_lottery)                             ; 
            picked_loc = 2                                                  ; % 2 for right
            respToBeMade = false                                            ;            
        end
end
rt = tEnd - tStart                                                          ; % Measure timing
end
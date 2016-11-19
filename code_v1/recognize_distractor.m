function distrMat = recognize_distractor(distrMat)

% Inquires about the space key pressed and the associated timing. Remains
% in a while loop until space is pressed. 
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
%
% Parameters
% ----------
% - distrMat: Here we save RTs for detecting the distractors
%
% Returns
% ----------
% - distrMat: An updated distrMat with RTs for current distractor appended
%
%
%-------------------------------------------------------------------------%
%                      Keyboard information                               %
%-------------------------------------------------------------------------%
spaceKey = KbName('space')                                                  ; % detect distractor

%% Function start

tStart = GetSecs                                                            ; % get time of start
respToBeMade = true                                                         ; % condition for while loop
while respToBeMade            
    [~,tEnd,keyCode] = KbCheck                                              ; % PTB inquiry to keyboard including time when button is pressed
        if keyCode(spaceKey)
            rt = tEnd - tStart                                              ; % Measure timing
            respToBeMade = false                                            ; % stop checking
        end
end

distrMat = [distrMat, rt] ;

%% Function end
end
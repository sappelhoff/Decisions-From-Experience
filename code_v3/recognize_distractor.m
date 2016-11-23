function distrMat = recognize_distractor(distrMat, tStart)

% Inquires about the space key pressed and the associated timing. Remains
% in a while loop until space is pressed. Then appends the RT to a vector
% given as input.
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
%
% distrMat = recognize_distractor(distrMat)
%
% IN
% - distrMat: Here we save RTs for detecting the distractors
% - tStart: the time, when the RT test was triggered. E.g., a vbl from the
% last screen flip. Alternatively, a GetSecs; right before the function
% call
%
% OUT
% - distrMat: An updated distrMat with RTs for current distractor appended
%
%% Function start

%-------------------------------------------------------------------------%
%                      Keyboard information                               %
%-------------------------------------------------------------------------%
spaceKey = KbName('space')                                                  ; % detect distractor

%% 

respToBeMade = true                                                         ; % condition for while loop
while respToBeMade            
    [~,tEnd,keyCode] = KbCheck                                              ; % PTB inquiry to keyboard including time when button is pressed
        if keyCode(spaceKey)
            rt = tEnd - tStart                                              ; % Measure timing
            respToBeMade = false                                            ; % stop checking
        end
end

distrMat = [distrMat, rt]                                                   ;

%% Function end
end
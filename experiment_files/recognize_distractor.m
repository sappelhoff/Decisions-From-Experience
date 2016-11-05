function distractorMat = recognize_distractor(distractorMat)
% a function to inquire about key pressed and their timings. This one is
% only for distractor conditions
%
% Parameters
% ----------
% - distractorMat: Here we save RTs for detecting the distractors
% - condi_idx: To know, which condition the distractor was presented in
%
% Returns
% ----------
% - distractorMat: An updated distractor_mat with RTs for current
% distractor
%
%
%-------------------------------------------------------------------------%
%                      Keyboard information                              %
%-------------------------------------------------------------------------%
spaceKey = KbName('space')                                                  ; % detect distractor

%% Function start

tStart = GetSecs                                                            ; % get time of start
respToBeMade = true                                                         ; % condition for while loop
while respToBeMade            
    [~,tEnd,keyCode] = KbCheck                                              ; % PTB inquiry to keyboard including time when button is pressed
        if keyCode(spaceKey)
            respToBeMade = false                                            ; % stop checking
            rt = tEnd - tStart                                              ; % Measure timing
        end
end

distractorMat = [distractorMat, rt] ;


end
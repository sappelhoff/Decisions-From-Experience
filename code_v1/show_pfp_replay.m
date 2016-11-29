function distractorMat = show_pfp_replay(aPFPmat, texts, reward, window, white, maskTexture, maskLocs, rectLocs, distractorMat, fixCoords, tShuffled, tTrialCount, tDelayFeedback, tFeedback, tShowPayoff, fixWidth, xCenter, yCenter)

% This function executes a replay
%
% Parameters
% ----------
% - aPFPmat: The aPFP_mat from which a previous game can be deduced.
% - texts: a container.Map with all texts for display
% - reward: the stimuli matrix that encodes the rewards
% - the window that we draw to
% - white: the color ...
% - maskTexture: texture to make our stimuli seem circular
% - maskLocs: locations of the mask texture
% - rectLocs: locations of the stimuli
% - distractorMat: to save RTs of distractor trials
% - fixCoords: for the fixcross
% - tShuffled: the time after the participants are being told that lotteries have been shuffled
% - tTrialCount: time that the trial counter is shown
% - tDelayFeedback: time after a choice before outcome is presented
% - tFeedback: time that the feedback is displayed
% - tShowPayoff: time that the payoff is shown
% - fixWidth: for drawing the fixcross
% - xCenter: center of the screen x axis
% - yCenter: center of the screen y axis
%
%
% Returns
% ----------
% -    distractorMat: an updated distractor mat

%% Function start

[~, pfpTrials, pfpRuns] = size(aPFPmat)                                     ; % trials are saved in 2nd dim, runs in 3rd dim



for replayRun = 1:pfpRuns
    
    % Pretend something has been shuffled
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white)  ;
    Screen('Flip', window)                                                  ;
    WaitSecs(tShuffled+rand/2)                                              ;
        
    
    for replayTrial = 1:pfpTrials


    % drawing trialcounter
    trial_counter = strcat(num2str(replayTrial),'/',num2str(pfpTrials))     ; % The pfp counter always shows current draw out of all draws within one game
    DrawFormattedText(window, trial_counter, 'center', 'center', white)     ;
    Screen('Flip', window)                                                  ;

    % drawing the fixcross
    Screen('DrawLines', window, fixCoords,...
        fixWidth, white, [xCenter yCenter], 2)                              ;
    WaitSecs(tTrialCount+rand/2)                                            ; % briefly show trial counter 
    Screen('Flip', window)                                                  ; % then show fixcross

    
    % now instead of a decision, take all information from a previous
    % decision
    pickedLoc = aPFPmat(1,replayTrial,replayRun)                            ; % which location was picked
    rt = aPFPmat(2,replayTrial,replayRun)                                   ; % how quickly was it picked
    rewardBool = aPFPmat(4,replayTrial,replayRun)                           ; % was it rewarded?

    
    % Replay decision process originally, as long as it is reasonable
    if rt <= 3
        WaitSecs(rt)                                                        ; % RTs below 3 seconds are reasonable
    else
        WaitSecs(1+rand/2)                                                  ; % if actual RT differs, create a conforming random RT
    end
    
    
    % drawing the fixcross
    Screen('DrawLines', window, fixCoords,...
    fixWidth, white, [xCenter yCenter], 2)                                  ;

    % drawing the checkerboard stim at the chosen location. The reward
    % bool tells us win(1) or loss(0) ... we add 1 so we get win=2,
    % loss=1
    Screen('FillRect', window, reward(:,:,rewardBool+1),...
    rectLocs(:,:,pickedLoc))                                                ;

    Screen('DrawTextures', window, maskTexture, [],...
    maskLocs(:,:,pickedLoc))                                                ;


    WaitSecs(tDelayFeedback+rand/2)                                        ; % after choice, wait briefly before displaying result
    Screen('Flip', window)                                                  ;

    if rewardBool == 2
        distractorMat = recognize_distractor(distractorMat)                 ; % if this trial was a distractor, measure the RT to it 
    else
        WaitSecs(tFeedback+rand/2)                                          ; % briefly display feedback 
    end
    
    
    
    end
    
    % Tell the subject how much was earned
    payoff = sum(aPFPmat(4,:,replayRun))                                    ; % the overall payoff
    payoffStr = strcat(texts('payoff'), sprintf(' %d', payoff))             ;
    DrawFormattedText(window, payoffStr, 'center', 'center', white)         ;
    Screen('Flip', window)                                                  ;
    WaitSecs(tShowPayoff+rand/2)                                            ; % briefly display payoff
    
    
 
    
    
end

end
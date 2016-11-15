function distractorMat = show_sp_replay(aSPmat, aSPprefLotMat, texts, reward, window, white, maskTexture, maskLocs, rectLocs, screenXpixels, screenYpixels, distractorMat, fixCoords, tShuffled, tTrialCount, tOutcomePresent, tFeedback, tShowPayoff, tChosenOpt)

% This function executes a replay
%
% Parameters
% ----------
% - aSPmat: The aSP_mat from which a previous game can be deduced.
% - aSPprefLotMat: needed for reproducing choice trials
% - texts: a container.Map with all texts for display
% - reward: the stimuli matrix that encodes the rewards
% - the window that we draw to
% - white: the color ...
% - maskTexture: texture to make our stimuli seem circular
% - maskLocs: locations of the mask texture
% - rectLocs: locations of the stimuli
% - screenXpixels: width of screen
% - screenYpixels: height of screen
% - distractorMat: to save RTs of distractor trials
% - fixCoords: for the fixcross
% - tShuffled: the time after the participants are being told that lotteries have been shuffled
% - tTrialCount: time that the trial counter is shown
% - tOutcomePresent: time after a choice before outcome is presented
% - tFeedback: time that the feedback is displayed
% - tShowPayoff: time that the payoff is shown
% - tChosenOpt: in SP, the time that the chosen option is "shown"
%
% Returns
% ----------
% - distractor_mat: an updated distractor mat

%% Function start

% Getting our indices ready for the replay
prevSamples = aSPprefLotMat(5,:)                                            ; % vector containing samples taken before a choice
allChoices = length(prevSamples)                                            ; % number of choices in whole SP task
aSPdataIdx = 1                                                              ; % to access the sample data throughout the loops with right idx


% Drawing the text options for sample vs choice decision      
textwin1 = [screenXpixels*.1, screenYpixels*.5, ...
    screenXpixels*.4, screenYpixels*.5]                                     ; % windows to center the formatted text in
textwin2 = [screenXpixels*.6, screenYpixels*.5, ...
    screenXpixels*.9, screenYpixels*.5]                                     ; % left top right bottom


for choiceRun = 1:allChoices % before each choice, there is a number of samples drawn. 

    % Pretend the lotteries have been shuffled
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white)  ;
    Screen('Flip', window)                                                  ;
    WaitSecs(tShuffled+rand/2)                                              ;
    
    for samples = 1:prevSamples(choiceRun) % the number of samples can be obtained here by indexing with the choice of interest
   
        % start with a pick
        pickedLoc = aSPmat(1, aSPdataIdx)                                   ;
        rt = aSPmat(2, aSPdataIdx)                                          ;
        rewardBool = aSPmat(3, aSPdataIdx)                                  ;
        aSPdataIdx = aSPdataIdx + 1                                         ; % increment our data index for next display
        
        % Replay decision process originally, as long as it is <3sec
        if rt > 3
            rt = rand+rand                                                  ; % if actual RT differs, create a conforming random RT
        end
        
        
        % draw fixcross
        Screen('DrawLines', window, fixCoords,...
            fixWidth, white, [xCenter yCenter], 2)                          ; 
        Screen('Flip', window)                                              ;
        WaitSecs(rt)                                                        ; % "wait for choice"        
        
        
        
        
        %feedback
        
        % draw fixcross again for feedback
        Screen('DrawLines', window, fixCoords,...
            fixWidth, white, [xCenter yCenter], 2)                          ; 
        
        % drawing the checkerboard stim at the chosen location. The
        % reward_bool tells us win(1) or loss(0) ... we add 1 so we get
        % win=2, loss=1
        Screen('FillRect', window, reward(:,:,rewardBool+1),...
            rectLocs(:,:,pickedLoc))                                        ;

        Screen('DrawTextures', window, maskTexture, [],...
            maskLocs(:,:,pickedLoc))                                        ;            
        Screen('Flip', window)                                              ;
        
        if rewardBool == 3
            distractorMat = recognize_distractor(distractorMat)             ; % if this trial was a distractor, measure the RT to it 
        end  

        
        WaitSecs(tFeedback+rand/2)                                          ; % briefly show feedback
            
        

        % display the question
        DrawFormattedText(window, 'Do you want to', ...
            'center', .25*screenYpixels, white)                             ;

        DrawFormattedText(window, 'draw another sample', ...
            'center', 'center', white, [], [], [], [], [], textwin1)        ;

        DrawFormattedText(window, 'make a choice', ...
            'center', 'center', white, [], [], [], [], [], textwin2)        ;

        Screen('Flip', window)                                              ;
        
        WaitSecs(rand+rand)                                                 ; % For this, just wait briefly above 1 sec, we have no RT to replay accurately
            
        
        % answer ... depending on "samples" idx whether another sample or
        % choice
        if samples ~= prevSamples(choiceRun)
            % if samples idx is not at its max, just sample ...
            DrawFormattedText(window, 'draw another sample', ...
                'center', 'center', white, [], [], [], [], [], textwin1)    ;
            Screen('Flip', window)                                          ;
            WaitSecs(tChosenOpt+rand/2)                                     ; % Briefly show the chosen option

            % now start from "samples" loop again
            
        else
            % now samples idx is at max, so we make a choice
            DrawFormattedText(window, 'make a choice', ...
                'center', 'center', white, [], [], [], [], [], textwin2)    ;
            Screen('Flip', window)                                          ;
            WaitSecs(tChosenOpt+rand/2)                                     ; % Briefly show the chosen option
            
            % get the historical values from our data
            pickedLoc = aSPprefLotMat(1, choiceRun)                         ;
            rt = aSPprefLotMat(2, choiceRun)                                ; % see a few lines below for checking the RT to be reasonable
            rewardBool = aSPprefLotMat(3, choiceRun)                        ;
            
            
            % Replay decision process originally, as long as it is [1,3]sec
            if rt < 1 ||  rt > 3
                rt = rand+rand                                              ; % if actual RT differs, create a conforming random RT
            end
     
            
            % "Ask the subject, which lottery she wants to select"
            DrawFormattedText(window, texts('aSP_choice'), 'center', ...
                'center', white)                                            ;
            Screen('Flip', window)                                          ;
            WaitSecs(rt)                                                    ; % For this, use actual rt (see above though) for waiting

            
            % draw fixcross
            Screen('DrawLines', window, fixCoords,...
                fixWidth, white, [xCenter yCenter], 2)                      ; 
            Screen('Flip', window)                                          ;
    
            

            % draw fixcross
            Screen('DrawLines', window, fixCoords,...
                fixWidth, white, [xCenter yCenter], 2)                      ; 
            
            % drawing the checkerboard stim at the chosen location. The
            % reward_bool tells us win(1) or loss(0) ... we add 1 so we get
            % win=2, loss=1
            Screen('FillRect', window, reward(:,:,rewardBool+1),...
                rectLocs(:,:,pickedLoc))                                    ;

            Screen('DrawTextures', window, maskTexture, [],...
                maskLocs(:,:,pickedLoc))                                    ;            
            Screen('Flip', window)                                          ;
            WaitSecs(tFeedback+rand/2)                                      ; % briefly show feedback
            
            % Now shuffle lotteries (i.e., advance in outer loop)
            
        end
   
        
    end
    
    
end

end
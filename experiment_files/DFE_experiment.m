function DFE_experiment

% This function implements an experimental paradigm consisting of a 2x2
% within design centered around the Decisions From Experience (DFE)
% framework.
%
% Factor 1 describes two different tasks procedures (see Hertwig, 2009):
% - level 1: Partial Feedback Paradigm (PFP) 
% - level 2: Sampling Paradigm (SP) 
%
% Factor 2 describes two different ways how the tasks are being performed:
% - level 1: Active selection of lotteries through button presses
% - level 2: Passive, i.e., watching a replay of previous decisions


%% Function start

% basic information
expStart = datestr(now)                                                     ; % Get time of start of the experiment
[subjId, winStim, startCond] = inquire_user                                 ; % Get user info and experiment environment specs
totalEarnings = 0                                                           ; % total earnings of user
euroFactor = 0.25                                                           ; % factor to convert points to Euros
pDistr = 0.5                                                                ; % probability that a distractor might occur

% timings in seconds
tShuffled = 1                                                               ; % the time after the participants are being told that lotteries have been shuffled
tTrialCount = 1                                                             ; % time that the trial counter is shown
tOutcomePresent = 1                                                         ; % time after a choice before outcome is presented
tFeedback = 1                                                               ; % time that the feedback is displayed
tShowPayoff = 1                                                             ; % time that the payoff is shown
tChosenOpt = .75                                                            ; % in SP, the time that the chosen option is "shown"
%-------------------------------------------------------------------------%
%                   Setting Defaults for the Experiment                   %
%-------------------------------------------------------------------------%
%%

PsychDefaultSetup(2)                                                        ; % default settings for Psychtoolbox


% Screen Management
screens = Screen('Screens')                                                 ; % get all available screens ordered from 0 (native screen of laptop) to i
screenNumber = min(screens)                                                 ; % take max of screens to draw to external screen.

% Define white/black/grey
white = WhiteIndex(screenNumber)                                            ; % This function returns an RGB tuble for 'white' = [1 1 1]

% Open an on screen window and get its size and center
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, white/2)    ; % our standard background will be grey
[screenXpixels, screenYpixels] = Screen('WindowSize', window)               ; % getting the dimensions of the screen in pixels
[xCenter, yCenter] = RectCenter(windowRect)                                 ; % getting the center of the screen

% for making transparency possible in RGBA tuples and for textures
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA')   ; % transparency is determined in RGBA tuples with each value [0,1], where A=0 means transparent, A=1 means opaque 

% Defaults for drawing text on the screen
Screen('TextFont',window, 'Verdana')                                        ; % Pick a font that's available everywhere ...
Screen('TextSize',window, 50 )                                              ;
Screen('TextStyle', window, 0)                                              ; %0=normal,1=bold,2=italic,4=underline

%HideCursor                                                                  ; % Hide the cursor



%-------------------------------------------------------------------------%
%                      Preparing all Stimuli                              %
%-------------------------------------------------------------------------%

[fixWidth, fixCoords, colors1, colors2, colors3, rectLocs, maskLocs, ...
    maskTexture] = produce_stims(window, windowRect, screenNumber)          ; % separate function for the stim creation to avoid clutter

%-------------------------------------------------------------------------%
%                         Experimental Conditions                         %
%-------------------------------------------------------------------------%
%%

% the overall trials determine the maximum number of draws possible in a
% SP game. If participants finish earlier, they get the next game of SP
% and so on, until the overall trials are reached. For PFP games, there
% are x PFP draws per game and thus (overall_trials/x) PFP games overall
overallTrials = 4                                                           ; 
pfpTrials = 2                                                               ; 

% selection whether blue or red stimulus will represent the reward;
% colors_1 is red, colors_2 is blue. The selection is on the entries into
% the gui at the startup of the experiment. These entries should be based
% on a randomization scheme. 
% In general, reward(:,:,2) will be the win, reward(:,:,1) will be the loss
%
% Furthermore the order of conditions is set according to the gui entries
% as well.
% Conditions are:
% 1 = active PFP
% 2 = passive PFP (replay of active PFP)
% 3 = active SP
% 4 = passive SP (replay of active SP)


% define winning stimulus
if strcmp(winStim, 'blue')
    reward = cat(3, colors1, colors2, colors3)                              ; % blue is win Stim ... red as loss. colors3(green) is the distractor condition
    
else 
    reward = cat(3, colors2, colors1, colors3)                              ; % red is win Stim ... blue as loss. colors3(green) is the distractor condition
end


% Define starting condition
if strcmp(startCond, 'pfp')
    condiOrder = [1, 2, 3, 4]                                               ; % use this variable later for a 'switch' procedure
else
    condiOrder = [3, 4, 1, 2]                                               ; 
end


% Here we will save the reaction times to the distractors
distractorMat = []                                                          ; % the recognize_distractor function will update this variable

% Create some lotteries - these are stable and hardcoded across the study
lotteryOption1 = [ones(1,7), zeros(1,3)]                                    ; % p(win)=.7 --> good lottery
lotteryOption2 = [ones(1,3), zeros(1,7)]                                    ; % p(win)=.3 --> bad lottery

%-------------------------------------------------------------------------%
%                         Text Presentation                               %
%-------------------------------------------------------------------------%

%% produce the texts

texts = produce_texts                                                       ; % separate function which outputs a "container.Map" with texts

%-------------------------------------------------------------------------%
%                         Experimental Loop                               %
%-------------------------------------------------------------------------%

%% Welcome screen

general_instructions(window, white, reward, maskTexture, rectLocs, ...
    maskLocs)                                                               ; % This will display the welcome screen and some general instructions

%% condition selection

for condi_idx = 1:4
currentCondi = condiOrder(condi_idx)                                        ; % condi_order has been set up before according to gui input

switch currentCondi
    
case 1
%% Active Partial Feedback Paradigm (aPFP)

% here we can save the data
aPFPmat = nan(4, pfpTrials, (overallTrials / pfpTrials))                    ; % for each bandit run, we have one 2D matrix ... each bandit run is one sheet(3D)

% Here we save the preferred lottery data --> which one is preferred
% (1=left, 2=right), is it the good one? (0/1), how quickly was it chosen
% (rt)
aPFPprefLotMat = nan(3, 1, (overallTrials / pfpTrials))                     ; 

    
% Active PFP Instructions
DrawFormattedText(window,texts('next_intro'), 'center', 'center', white)    ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window,texts('aPFP_intro1'), 'center', 'center', white)   ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window,texts('aPFP_intro2'), 'center', 'center', white)   ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;


    for pfpRun = 1:(overallTrials / pfpTrials)

    
    [leftLottery, rightLottery, goodLotteryLoc] = ...
        determine_lottery_loc(lotteryOption1, lotteryOption2)               ; % place good and bad lottery randomly either left or right
 
    % starting a new PFP
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white)  ;
    Screen('Flip', window)                                                  ;
    WaitSecs(tShuffled + rand/2)                                            ;
        
        

    % actual loop
    for pfpIdx = 1:pfpTrials

        % drawing trialcounter
        trialCounter = strcat(num2str(pfpIdx),'/',num2str(pfpTrials))       ; % The pfp counter always shows current draw out of all draws within one game
        DrawFormattedText(window, trialCounter, 'center', 'center', white)  ;
        Screen('Flip', window)                                              ;

        % drawing the fixcross
        Screen('DrawLines', window, fixCoords,...
            fixWidth, white, [xCenter yCenter], 2)                          ;

        WaitSecs(tTrialCount + rand/2)                                      ; % show trial counter for n seconds
        Screen('Flip', window)                                              ; % then show fixcross

        % start decision process
        [pickedLoc, rewardBool, ...
            rt] = require_response(leftLottery, rightLottery, pDistr)       ;

        % drawing the fixcross
        Screen('DrawLines', window, fixCoords,...
            fixWidth, white, [xCenter yCenter], 2)                          ;

        % drawing the checkerboard stim at the chosen location. The reward
        % bool tells us win(1) or loss(0) ... we add 1 so we get win=2,
        % loss=1

        Screen('FillRect', window, reward(:,:,rewardBool+1),...
            rectLocs(:,:,pickedLoc))                                        ;

        Screen('DrawTextures', window, maskTexture, [],...
            maskLocs(:,:,pickedLoc))                                        ;


        % even id, blue is win 
        aPFPmat(1,pfpIdx,pfpRun) = pickedLoc                                ; % which location was picked: 1, left - 2, right
        aPFPmat(2,pfpIdx,pfpRun) = rt                                       ; % how quickly was it picked in ms
        aPFPmat(3,pfpIdx,pfpRun) = (goodLotteryLoc == pickedLoc)            ; % boolean was the good lottery chosen? 0=no, 1=yes
        aPFPmat(4,pfpIdx,pfpRun) = rewardBool                               ; % boolean whether is was rewarded or not


        WaitSecs(tOutcomePresent+rand/2)                                    ; % after choice, wait before displaying result
        Screen('Flip', window)                                              ;
        
        if rewardBool == 2
            distractorMat = recognize_distractor(distractorMat)             ; % if this trial was a distractor, measure the RT to it 
        else
            WaitSecs(tFeedback+rand/2)                                      ; % feedback briefly displayed
        end
        
        
        

        
        
    end
    
    % Tell the subject how much she has earned
    dummy = aPFPmat(4,:,pfpRun)                                             ; % create a dummy from our data matrix to calculate payoff
    dummy(dummy == 2) = 0                                                   ; % disregard the distractors
    payoff = sum(dummy)                                                     ; % the overall payoff is the sum of our edited dummy
    clear dummy                                                             ; % get rid of the dummy
    
    payoffStr = strcat(texts('payoff'), sprintf(' %d', payoff))             ;    
    
    DrawFormattedText(window, payoffStr, 'center', 'center', white)         ;
    Screen('Flip', window)                                                  ;
    WaitSecs(tShowPayoff+rand/2)                                            ; % show payoff for 2 secs
    totalEarnings = totalEarnings + payoff                                  ; % increment the total earnings of the participant
    
    

    % Ask the subject, which lottery was better
    DrawFormattedText(window, texts('aPFP_PrefLot'), ...
        'center', 'center', white)                                          ;
    Screen('Flip', window)                                                  ;

    % start decision process
    [pickedLoc, ~, rt] = require_response(leftLottery, rightLottery)        ; % here, we do not want a distractor to occur ... so no p_distr argument
  
    % Record timing and whether preferred lottery was correct
    aPFPprefLotMat(1,1,pfpRun) = pickedLoc                                  ; % Which lottery was preferred? 1=left, 2=right
    aPFPprefLotMat(2,1,pfpRun) = rt                                         ; % rt to select preferred lottery
    aPFPprefLotMat(3,1,pfpRun) = pickedLoc == goodLotteryLoc                ; % boolean whether correct lottery was preferred
      
    end % end of bandit game loop

% Now there will be a short break before we go to the next task
DrawFormattedText(window, texts('break'), 'center', 'center', white)        ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;


case 2
%% Passive PFP ... showing the replay of active PFP
   

% Passive PFP Instructions
DrawFormattedText(window,texts('next_intro'), 'center', 'center', white)    ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window,texts('replay1'), 'center', 'center', white)       ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window,texts('replay2'), 'center', 'center', white)       ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window,texts('replay3'), 'center', 'center', white)       ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;


% Show the replay!
distractorMat = show_pfp_replay(aPFPmat, texts, reward, window, white, ...
    maskTexture, maskLocs, rectLocs, distractorMat, fixCoords, ...
    tShuffled, tTrialCount, tOutcomePresent, tFeedback, tShowPayoff, ...
    fixWidth, xCenter, yCenter)                                             ;


if condi_idx ~= 4
% Now there will be a short break before we go to the next task
DrawFormattedText(window, texts('break'), 'center', 'center', white)        ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;
end

case 3
%% Active Sampling Paradigm (aSP)


% here we can save the data
aSPmat = nan(4,overallTrials)                                               ;

% Here we save the preferred lottery data
aSPprefLotMat = nan(5,1)                                                    ; % we cannot preallocate exactly, but there will be at least ONE choice in DFE


% Active DFE Instructions
DrawFormattedText(window, texts('next_intro'), 'center', 'center', white)   ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, texts('aSPintro1'), 'center', 'center', white)    ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, texts('aSPintro2'), 'center', 'center', white)    ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, texts('aSPintro3'), 'center', 'center', white)    ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, texts('aSPintro4'), 'center', 'center', white)    ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, texts('aSPintro5'), 'center', 'center', white)    ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

% while loop implementing all possible SP games ... i.e., overall_trials, 
% if subject always goes to choice in first attempt

spIdxMax = overallTrials                                                    ;
spRunCount = 1                                                              ; % defines an SP "run", i.e., all samples taken before a choice belong to a run
datIdxCount = 1                                                             ; % to know where in our data matrix to place the responses
spChoiceCount = 1                                                           ; % also a data matrix counter to place the preferred lotteries
prevSamples = 0                                                             ; % variable to calculate number of samples prior to a choice

while spIdxMax >= 1                                                         ; % while we have at least one sp trial remaining, keep starting new SP runs

    
    [leftLottery, rightLottery, goodLotteryLoc] = ...
            determine_lottery_loc(lotteryOption1, lotteryOption2)           ; % place good and bad lottery randomly either left or right

            
    % starting a new SP by shuffling the lotteries
    DrawFormattedText(window, texts('shuffled'), 'center', 'center', white) ;
    Screen('Flip', window)                                                  ;
    WaitSecs(tShuffled+rand/2)                                              ;
        
        

    % actual loop
    for spIdx = 1:spIdxMax

        if spIdx ~= 1                                                       ; % this option only for draws that are NOT the first draw for newly shuffled lotteries  
            
            % Drawing the text options for sample vs choice decision      
            textwin1 = [screenXpixels*.1, screenYpixels*.5, ...
                screenXpixels*.4, screenYpixels*.5]                         ; % windows to center the formatted text in
            textwin2 = [screenXpixels*.6, screenYpixels*.5, ...
                screenXpixels*.9, screenYpixels*.5]                         ; % left top right bottom

            
            DrawFormattedText(window, 'Do you want to', ...
                'center', .25*screenYpixels, white)                         ;

            DrawFormattedText(window, 'draw another sample', ...
                'center', 'center', white, [], [], [], [], [], textwin1)    ;

            DrawFormattedText(window, 'make a choice', ...
                'center', 'center', white, [], [], [], [], [], textwin2)    ;

            Screen('Flip', window)                                          ;

            % start decision process. This time, only location is relevant
            [pickedLoc] = require_response(leftLottery, rightLottery)       ; % we do not enter p_distr - we are not interested in outcomes
            
            % show the chosen option
            if pickedLoc == 1
                DrawFormattedText(window, 'draw another sample', ...
                    'center', 'center', white, [], [], [], [], [],textwin1) ;
                Screen('Flip', window)                                      ;
                WaitSecs(tChosenOpt+rand/2)                                 ; % briefly show chosen option

            elseif pickedLoc == 2
                DrawFormattedText(window, 'make a choice', ...
                    'center', 'center', white, [], [], [], [], [],textwin2) ;
                Screen('Flip', window)                                      ;
                WaitSecs(tChosenOpt+rand/2)                                 ; % briefly show chosen option
            end
        
        else
            pickedLoc = 1                                                   ; % If it's the first draw of a new game, take a sample, without asking whether subject actually wants 'choice'
        end
        
        
        switch pickedLoc
            
            case 1 % =left ... draw a sample
                
                % draw trial counter
                trialCounter = ...
                    strcat(num2str(overallTrials-(spIdxMax-spIdx)))         ;
                
                
                DrawFormattedText(window, trialCounter, 'center', ...
                    'center', white)                                        ;
                Screen('Flip', window)                                      ;

                % drawing the fixcross
                Screen('DrawLines', window, fixCoords,...
                    fixWidth, white, [xCenter yCenter], 2)                  ;
                WaitSecs(tTrialCount+rand/2)                                ; % briefly show trial counter
                Screen('Flip', window)                                      ; % then show fixcross



                % start decision process
                [pickedLoc, rewardBool, rt] = require_response( ...
                    leftLottery, rightLottery, pDistr)                     ; % during the SP sampling, getting a distractor is possible

                % drawing the fixcross
                Screen('DrawLines', window, fixCoords,...
                    fixWidth, white, [xCenter yCenter], 2)                  ;

                % drawing the checkerboard stim at the chosen location. The
                % reward_bool tells us win(=1) or loss(=0) ... we add 1 so
                % we get win=2, loss=1
                Screen('FillRect', window, reward(:,:,rewardBool+1),...
                    rectLocs(:,:,pickedLoc))                                ;

                Screen('DrawTextures', window, maskTexture, [],...
                    maskLocs(:,:,pickedLoc))                                ;


                % even id, blue is win 
                aSPmat(1,datIdxCount) = pickedLoc                           ; % which location was picked: 1, left - 2, right
                aSPmat(2,datIdxCount) = rt                                  ; % how quickly was it picked in ms
                aSPmat(3,datIdxCount) = rewardBool                          ; % boolean whether is was rewarded or not
                aSPmat(4,datIdxCount) = (goodLotteryLoc == pickedLoc)       ; % boolean whether good or bad lottery was chosen

                datIdxCount = datIdxCount + 1                               ; % update our data index counter
                WaitSecs(tOutcomePresent+rand/2)                            ; % after choice, wait before displaying result
                Screen('Flip', window)                                      ;
                                    
                if rewardBool == 2
                    distractorMat = recognize_distractor(distractorMat)     ; % if this trial was a distractor, measure the RT to it 
                else
                    WaitSecs(tFeedback+rand/2)                              ; % feedback briefly displayed
                end  
                
                

                
                
            case 2 % =right ... make a choice 
                spIdxMax = spIdxMax + 1                                     ; % making a choice doesn't count into the trials. As usual, sp_idx_max will be reduced at end of the procedure one ... so +1 -1 = 0 difference
                break                                                       ; % To make a choice, we have to break the for loop
                
        end % end switch. Continue with new question: choice or sample?
    end % end of for loop of drawing samples

 
    % If 'right' (=2) was selected or there are no trials left, start the
    % choice procedure

    % After the following choice, the subject has completed one SP run.
    % We calculate, how many trials remain to start a new trial or go on
    % to the next task.
    spIdxMax = spIdxMax - spIdx                                             ;
    spRunCount = spRunCount + 1                                             ;     
    
    % if this is the last trial, tell the subject so
    if spIdxMax <= 1                                                        % spIdxMax will be 0 if participant came here through sampling ... and will be 1 if participant selected "choice" on the last trial
        DrawFormattedText(window, texts('aSPfinal'), 'center', ...
            'center', white)                                                ;
        Screen('Flip', window)                                              ;
        KbStrokeWait                                                        ;
    end
    
    % Ask the subject, which lottery she wants to select
    DrawFormattedText(window, texts('aSPchoice'), 'center', ...
        'center', white)                                                    ;
    Screen('Flip', window)                                                  ;
    KbStrokeWait                                                            ;
    
    % start decision process
    [pickedLoc, rewardBool, ...
        rt] = require_response(leftLottery, rightLottery)                   ; % during the choice procedure of the SP, getting a distractor is impossible

    % draw fixcross
    Screen('DrawLines', window, fixCoords,...
        fixWidth, white, [xCenter yCenter], 2)                              ; 
    Screen('Flip', window)                                                  ;
    
    
    

    % draw fixcross
    Screen('DrawLines', window, fixCoords,...
        fixWidth, white, [xCenter yCenter], 2)                              ; 
    
    % drawing the checkerboard stim at the chosen location. The reward_bool
    % tells us win(1) or loss(0) ... we add 1 so we get win=2, loss=1
    Screen('FillRect', window, reward(:,:,rewardBool+1),...
        rectLocs(:,:,pickedLoc))                                            ;

    Screen('DrawTextures', window, maskTexture, [],...
        maskLocs(:,:,pickedLoc))                                            ;

    
    
    
    
    % Measure timing and whether preferred lottery was correct
    prevSamples = size(aSPmat,2)-sum(isnan(mean(aSPmat)))-prevSamples       ; % counts cols filled in since last check
    
    aSPprefLotMat(1,spChoiceCount) = pickedLoc                              ; % which loc was picked? left=1, right=2
    aSPprefLotMat(2,spChoiceCount) = rt                                     ; % how quickly was it picked in ms
    aSPprefLotMat(3,spChoiceCount) = rewardBool                             ; % was it rewarded=1 or not=0
    aSPprefLotMat(4,spChoiceCount) = pickedLoc == goodLotteryLoc            ; % was the "good lottery" picked?
    aSPprefLotMat(5,spChoiceCount) = prevSamples                            ; % How many samples preceeded this choice?

    
    spChoiceCount = spChoiceCount + 1                                       ; % update the counter of the preferred lottery data matrix

   
    WaitSecs(tOutcomePresent+rand/2)                                        ; % wait for a bit before displaying feedback
    Screen('Flip', window)                                                  ;
    WaitSecs(tFeedback+rand/2)                                              ; % briefly show feedback 
    
    
    % Tell the subject how much she has earned 
    payoff = rewardBool                                                     ;
    
    payoffStr = strcat(texts('payoff'), sprintf(' %d', payoff))             ;
    DrawFormattedText(window, payoffStr, 'center', 'center', white)         ;
    Screen('Flip', window)                                                  ;
    KbStrokeWait                                                            ;
    totalEarnings = totalEarnings + payoff                                  ; % increment the total earnings of the participant
 	


    
end % end of while loop implmenting all possible SP runs



% Now there will be a short break before we go to the next task
DrawFormattedText(window, texts('break'), 'center', 'center', white)        ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

case 4
%% Passive SP ... showing the replay of active SP


% Passive SP Instructions
DrawFormattedText(window,texts('next_intro'), 'center', 'center', white)    ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window,texts('replay1'), 'center', 'center', white)       ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window,texts('replay2'), 'center', 'center', white)       ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window,texts('replay3'), 'center', 'center', white)       ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;


% Show the replay!
distractorMat = show_sp_replay(aPFPmat, texts, reward, window, white, ...
    maskTexture, maskLocs, rectLocs, distractorMat, fixCoords)              ;


if condi_idx ~= 4
% Now there will be a short break before we go to the next task
DrawFormattedText(window, texts('break'), 'center', 'center', white)        ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;
end

%% End the condition randomization
end % ending switch procedure to choose current game protocol
end % ending for loop implementing the random choice of games

%-------------------------------------------------------------------------%
%                         Closing the Experiment                          %
%-------------------------------------------------------------------------%
%% Finishing up and showing final payoff

DrawFormattedText(window, texts('end'),'center', 'center', white)           ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ; 

payoffStr = strcat(texts('total_payoff'), sprintf(' %.2f', ...
    totalEarnings*euroFactor))                                              ; % This displays the total earnings of the participant
DrawFormattedText(window, payoffStr, 'center', 'center', white)             ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ; % Wait for a key press to close the window and clear the screen




% Get time of end of the experiment
expEnd = datestr(now)                                                       ; % ... it's good to know the time when the experiment ended

sca                                                                         ; % shut down Psychtoolbox

%% Saving all the data
% use a separate function for this, which creates a "package" in form of a
% matlab structure out of all the data of the experiment and saves it
% neatly together with a readme in form of a matlab cell.

save_data(expStart, expEnd, totalEarnings, subjId, aPFPmat, ...
    aPFPprefLotMat, aSPmat, aSPprefLotMat, distactor_mat)                   ; % data located in /data ... sibling dir of /experiment_files

end % function end
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

experiment_start = datestr(now)                                             ; % Get time of start of the experiment

subj_id = inquire_user                                                      ; % get a user ID        

%-------------------------------------------------------------------------%
%                   Setting Defaults for the Experiment                   %
%-------------------------------------------------------------------------%
%%

PsychDefaultSetup(2)                                                        ; % default settings for Psychtoolbox


% Screen Management
screens = Screen('Screens')                                                 ; % get all available screens ordered from 0 (native screen of laptop) to i
screenNumber = max(screens)                                                 ; % take max of screens to draw to external screen.

% Define white/black/grey
white = WhiteIndex(screenNumber)                                            ; % This function returns an RGB tuble for 'white' = [1 1 1]

% Open an on screen window and get its size and center
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, white/2)    ; % our standard background will be grey
[screenXpixels, screenYpixels] = Screen('WindowSize', window)               ; % geting the dimensions of the screen in pixels
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

[fixWidth, fixCoords, colors_1, colors_2, rect_locs, mask_locs, ...
    masktexture] = produce_stims(window, windowRect, screenNumber)          ; % separate function for this to avoid clutter

%-------------------------------------------------------------------------%
%                         Experimental Conditions                         %
%-------------------------------------------------------------------------%
%%

% the overall trials determine the maximum number of draws possible in a
% SP game. If participants finish earlier, they get the next game of SP
% and so on, until the overall trials are reached. For PFP games, there
% are x PFP draws per game and thus (overall_trials/x) PFP games overall
overall_trials = 10                                                         ; 
pfp_trials = 5                                                              ; 

% selection whether blue or red stimulus will represent the reward;
% colors_1 is red, colors_2 is blue. The selection is depending on subject
% ID --> if it's even, reward is blue, else if it's odd, reward is red
% put the rewards into a 3D matrix to choose from
% reward(:,:,2) will be the win, reward(:,:,1) will be the loss
%
% Furthermore set order of conditions according to ID: for even, start with
% SP active, then SP passive, then PFP active, finally PFP passive. For
% odd, go with PFP active, PFP passive, SP active, SP passive.
%
% Conditions are:
% 1 = active PFP
% 2 = passive PFP (replay of active PFP)
% 3 = active SP
% 4 = passive SP (replay of active SP)

if ~mod(subj_id,2)                                                       
    reward = cat(3, colors_1, colors_2)                                     ; % even ID ... put red as loss ... put blue as win ... start with SP
    condi_order = [3, 4, 1, 2]                                              ; % use this variable later for a 'switch' procedure
else 
    reward = cat(3, colors_2, colors_1)                                     ; % odd ID ... put blue as loss ... put red as win ... start with PFP
    condi_order = [1, 2, 3, 4]                                              ; % use this variable later for a 'switch' procedure
end


% Create some lotteries - these are stable and hardcoded across the study
lottery_option1 = [ones(1,7), zeros(1,3)]                                   ; % p(win)=.7 --> good lottery
lottery_option2 = [ones(1,3), zeros(1,7)]                                   ; % p(win)=.3 --> bad lottery

%-------------------------------------------------------------------------%
%                         Text Presentation                               %
%-------------------------------------------------------------------------%

%% produce the texts

texts = produce_texts; % separate function which outputs a "container.Map"


% these texts will be relevant for multiple conditions
breakText = sprintf('Now there will be a short break\n\nbefore we continue with the next task.\n\n\nPress a key if you want to continue.');
PFP_PrefLot = sprintf('Which lottery do you think was more profitable?\nPress [left] or [right].');
SPchoice = sprintf('From which lottery do\nyou want to draw your payoff?\n[left] or [right]\n\nPress twice!');
SPaddUrn = sprintf('This outcome will be added\nto your final urn.');
SPfinalUrn1 = sprintf('This task is done.\n\nNow there will be 4 random draws\n\nwith replacement from your final urn.');
SPfinalUrn2 = sprintf('These 4 random draws will\n\nbe summed up to determine\n\nyour payoff. Remember a "win"\n\noutcome is worth 13, and a\n\n "lose" outcome is worth 0.');


%% Passive Partial Feedback Paradigm

passivePFPShuffle = sprintf('Passive PFP\n\n\nThe lotteries have been shuffled.');
passivePFPPayoff = sprintf('The computer earned the\n\nfollowing amount for you: ');

%% Active Sampling Paradigm

activeSP1 = sprintf('Active SP\n\n\nWhenever you see the + sign,\n\nuse [left] and [right] to choose a lottery.');
activeSP2 = sprintf('However, the outcomes you see\n\n reflect "samples".\n\nYou do not receive\n\npoints for these samples.');
activeSP3 = sprintf('Once you have taken enough samples\n\nto know whether a certain lottery is profitable,\n\nyou can stop sampling and choose a lottery');
activeSP4 = sprintf('Upon choice, the outcome is added\n\nto a "final urn". After that,\n\nyou can continue to sample.\n\nOnce you have drawn\n\nall your samples, 4 outcomes\n\nwill be drawn from your personal\n\n"final urn" with replacement.');
activeSP5 = sprintf('A "win" outcome drawn\n\nfrom your accumulated "final urn" will\n\nbe worth 13. A "lose" outcome\n\ndrawn from your accumulated\n\n"final urn" will be worth 0.');
activeSPShuffle = sprintf('Active SP\n\n\nThe lotteries have been shuffled.');


%% Passive Sampling Paradigm

passiveSP1 = sprintf('Passive SP\n\n\nThe computer will choose the lotteries for you.\n\nPlease just observe.');
passiveSP2 = sprintf('However, the outcomes you see\n\n reflect "samples".\n\nYou do not receive\n\npoints for these samples.');
passiveSP3 = sprintf('Once you have observed enough samples\n\nto know whether a certain lottery is profitable,\n\nyou can stop sampling and choose a lottery');
passiveSP4 = sprintf('Upon choice, the outcome is added\n\nto a "final urn". After that,\n\nyou can continue to sample.\n\nOnce you have drawn\n\nall your samples, 4 outcomes\n\nwill be drawn from your personal\n\n"final urn" with replacement.');
passiveSP5 = sprintf('A "win" outcome drawn from\n\nyour accumulated "final urn" will\n\nbe worth 13. A "lose" outcome\n\ndrawn from your accumulated\n\n"final urn" will be worth 0.');
passiveSPShuffle = sprintf('Passive SP\n\nThe lotteries have been shuffled.');


%-------------------------------------------------------------------------%
%                         Experimental Loop                               %
%-------------------------------------------------------------------------%

%% Welcome screen

general_instructions(window, white, reward, masktexture, rect_locs, ...
    mask_locs)                                                              ; % This will display the welcome screen and some general instructions

%% condition selection

for condi_idx = 1:4
current_condi = condi_order(condi_idx)                                      ; % condi_order has been set up before according to odd/even id of subj

switch current_condi
    
case 1
%% Active Partial Feedback Paradigm (aPFP)

% here we can save the data
aPFP_mat = nan(5,pfp_trials,(overall_trials / pfp_trials))                  ; % for each bandit run, we have one 2D matrix ... each bandit run is one sheet(3D)

% Here we save the preferred lottery data --> which one is preferred
% (1=left, 2=right), is it the good one? (0/1), how quickly was it chosen
% (rt)
aPFP_prefLottery_mat = nan(3,1,(overall_trials/pfp_trials))                 ; 

    
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

DrawFormattedText(window,texts('aPFP_intro3'), 'center', 'center', white)   ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;


    for pfp_run = 1:(overall_trials / pfp_trials)

    
    [left_lottery, right_lottery, good_lottery_loc] = ...
        determine_lottery_loc(lottery_option1, lottery_option2)             ; % place good and bad lottery randomly either left or right
 
    % starting a new PFP
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white)  ;
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ;
        
        

    % actual loop
    for pfp_idx = 1:pfp_trials

        % drawing trialcounter
        trial_counter = strcat(num2str(pfp_idx),'/',num2str(pfp_trials))    ; % The pfp counter always shows current draw out of all draws within one game
        DrawFormattedText(window, trial_counter, 'center', 'center', white) ;
        Screen('Flip', window)                                              ;

        % drawing the fixcross
        Screen('DrawLines', window, fixCoords,...
            fixWidth, white, [xCenter yCenter], 2)                          ;

        WaitSecs(2)                                                         ; % show trial counter for 2 seconds
        Screen('Flip', window)                                              ; % then show fixcross

        % start decision process
        KbEventFlush                                                        ; % clear all keyboard events
        [picked_loc, reward_bool, ...
            rt] = require_response(left_lottery, right_lottery)             ;

        % drawing the fixcross
        Screen('DrawLines', window, fixCoords,...
            fixWidth, white, [xCenter yCenter], 2)                          ;

        % drawing the checkerboard stim at the chosen location. The reward
        % bool tells us win(1) or loss(0) ... we add 1 so we get win=2,
        % loss=1

        Screen('FillRect', window, reward(:,:,reward_bool+1),...
            rect_locs(:,:,picked_loc))                                      ;

        Screen('DrawTextures', window, masktexture, [],...
            mask_locs(:,:,picked_loc))                                      ;


        % even id, blue is win 
        aPFP_mat(1,pfp_idx,pfp_run) = picked_loc                         ; % which location was picked: 1, left - 2, right
        aPFP_mat(2,pfp_idx,pfp_run) = rt                                 ; % how quickly was it picked in ms
        aPFP_mat(3,pfp_idx,pfp_run) = (good_lottery_loc == picked_loc)   ; % boolean whether good or bad lottery was chosen
        aPFP_mat(4,pfp_idx,pfp_run) = reward_bool                        ; % boolean whether is was rewarded or not
        aPFP_mat(5,pfp_idx,pfp_run) = (~mod(subj_id,2) + reward_bool)    ; % which color was the stim: 1: red ...  0/2: blue


        WaitSecs(1)                                                         ; % after choice, wait 1 sec before displaying result
        Screen('Flip', window)                                              ;
        WaitSecs(2)                                                         ; % feedback displayed for 2 secs

    end

    % Tell the subject how much she has earned
    payoff = sum(aPFP_mat(4,:,pfp_run))                                     ; % the overall payoff 
    payoff_str = strcat(texts('payoff'), num2str(payoff))                   ;    
    DrawFormattedText(window, payoff_str, 'center', 'center', white)        ;
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ; % show payoff for 2 secs

    
    

    % Ask the subject, which lottery was better
    DrawFormattedText(window, texts('aPFP_PrefLot'), ...
        'center', 'center', white)                                          ;
    Screen('Flip', window)                                                  ;



    % start decision process
    KbEventFlush                                                            ; % clear all keyboard events
    [picked_loc, ~, rt] = require_response(left_lottery, right_lottery)     ;

    
    % Record timing and whether preferred lottery was correct
    aPFP_prefLottery_mat(1,1,pfp_run) = picked_loc                       ; % Which lottery was preferred? 1=left, 2=right
    aPFP_prefLottery_mat(2,1,pfp_run) = rt                               ; % rt to select preferred lottery
    aPFP_prefLottery_mat(3,1,pfp_run) = picked_loc == good_lottery_loc   ; % boolean whether correct lottery was preferred
    
    
    
    end % end of bandit game loop

% Now there will be a short break before we go to the next task
DrawFormattedText(window, texts('break'), 'center', 'center', white)        ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;


case 2
%% Passive PFP ... showing the replay of active PFP
   

% Passive Bandit Instructions
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
show_pfp_replay(aPFP_mat, texts, reward, window, white, masktexture, ...
    mask_locs, rect_locs)                                                   ;


if condi_idx ~= 4
% Now there will be a short break before we go to the next task
DrawFormattedText(window, breakText, 'center', 'center', white)             ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;
end

case 3
%% Active Sampling Paradigm (aSP)


% here we can save the data
activeDFE_mat = nan(6,overall_trials)                                       ;

% Here we save the preferred lottery data
activeDFE_prefLottery_mat = nan(6,1)                                        ; % we cannot preallocate exactly, but there will be at least ONE choice in DFE


% Active DFE Instructions
DrawFormattedText(window, activeSP1, 'center', 'center', white)            ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, activeSP2, 'center', 'center', white)            ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, activeSP3, 'center', 'center', white)            ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, activeSP4, 'center', 'center', white)            ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, activeSP5, 'center', 'center', white)            ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;


% while loop implementing all possible dfe games ... i.e., overall_trials, 
% if subject always goes to choice in first attempt

dfe_idx_max = overall_trials                                                ;
dfe_run_counter = 1                                                         ;
data_idx_counter = 1                                                        ; % to know where in our data matrix to place the responses
lot_pref_counter = 1                                                        ; % also a data matrix counter to place the preferred lotteries

while dfe_idx_max >= 1 % while we have at least one dfe trial remaining, keep starting new DFE runs

    
    [left_lottery, right_lottery, good_lottery_loc] = ...
            determine_lottery_loc(lottery_option1, lottery_option2)         ; % place good and bad lottery randomly either left or right

            
    % starting a new DFE
    DrawFormattedText(window, activeSPShuffle, 'center', 'center', white)  ;
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ;
        
        

    % actual loop
    for dfe_idx = 1:dfe_idx_max

        if dfe_idx ~= 1 % this option only for draws that are NOT the first draw for newly shuffled lotteries  
            % Drawing the text options for sample vs choice decision      
            textwin1 = [screenXpixels*.1, screenYpixels*.5, screenXpixels*.4, screenYpixels*.5]; % windows to center the formatted text in
            textwin2 = [screenXpixels*.6, screenYpixels*.5, screenXpixels*.9, screenYpixels*.5]; % left top right bottom

            
            DrawFormattedText(window, 'Do you want to', ...
                'center', .25*screenYpixels, white)                         ;

            DrawFormattedText(window, 'draw another sample', ...
                'center', 'center', white, [], [], [], [], [], textwin1)    ;

            DrawFormattedText(window, 'make a choice', ...
                'center', 'center', white, [], [], [], [], [], textwin2)    ;

            Screen('Flip', window)                                          ;

            % start decision process ... this time, only location is relevant
            KbEventFlush                                                    ; % clear all keyboard events
            [picked_loc] = require_response(left_lottery, right_lottery);
        
        else
            picked_loc = 1                                                  ; % If it's the first draw of a new game, take a sample, without asking whether subject actually wants 'choice'
        end
        
        
        switch picked_loc
            
            case 1 % =left ... draw a sample
                
                % draw trial counter
                trial_counter = strcat(num2str(overall_trials-(dfe_idx_max-dfe_idx)), ...
                    '/', num2str(overall_trials))                                       ;
                DrawFormattedText(window, trial_counter, 'center', 'center', white)     ;
                Screen('Flip', window)                                                  ;

                % drawing the fixcross
                Screen('DrawLines', window, fixCoords,...
                    fixWidth, white, [xCenter yCenter], 2)              ;
                WaitSecs(2)                                                 ; % show trial counter for 2 seconds
                Screen('Flip', window)                                      ; % then show fixcross



                % start decision process
                KbEventFlush                                                ; % clear all keyboard events
                [picked_loc, reward_bool, rt] = require_response(left_lottery, right_lottery);

                % drawing the fixcross
                Screen('DrawLines', window, fixCoords,...
                    fixWidth, white, [xCenter yCenter], 2)              ;

                % drawing the checkerboard stim at the chosen location. The reward_bool
                % tells us win(1) or loss(0) ... we add 1 so we get win=2, loss=1

                Screen('FillRect', window, reward(:,:,reward_bool+1),...
                    rect_locs(:,:,picked_loc))                              ;

                Screen('DrawTextures', window, masktexture, [],...
                    mask_locs(:,:,picked_loc))                              ;


                % even id, blue is win 
                activeDFE_mat(1,data_idx_counter) = picked_loc                       ; % which location was picked: 1, left - 2, right
                activeDFE_mat(2,data_idx_counter) = rt                               ; % how quickly was it picked in ms
                activeDFE_mat(3,data_idx_counter) = reward_bool                      ; % boolean whether is was rewarded or not
                activeDFE_mat(4,data_idx_counter) = (good_lottery_loc == picked_loc) ; % boolean whether good or bad lottery was chosen
                activeDFE_mat(5,data_idx_counter) = (~mod(subj_id,2) + reward_bool)  ; % which color was the stim: 1: red ... 0 or 2: blue
                activeDFE_mat(6,data_idx_counter) = dfe_run_counter                  ; % current dfe run

                data_idx_counter = data_idx_counter + 1                     ; % update our data index counter
                WaitSecs(1)                                                 ; % after choice, wait 1 sec before displaying result
                Screen('Flip', window)                                      ;
                WaitSecs(2)                                                 ; % feedback displayed for 2 secs

                
                
            case 2 % =right ... make a choice 
                dfe_idx_max = dfe_idx_max + 1                               ; % making a choice doesn't count into the trials. As usual, dfe_idx_max will be reduced at end of the procedure one ... so +1 -1 = 0 difference
                break                                                       ; % To make a choice, we have to break the for loop  
        end % end switch procedure ... continue with new question: choice or sample?
    end % end of for loop of drawing samples

 
    % If 'right' (=2) was selected or there are no trials left, start the
    % choice procedure

    
    % Ask the subject, which lottery she wants to select
    DrawFormattedText(window, SPchoice, ...
        'center', 'center', white)                                          ;
    Screen('Flip', window)                                                  ;
    KbStrokeWait;
    % start decision process
    KbEventFlush                                                            ; % clear all keyboard events
    [picked_loc, reward_bool, rt] = require_response(left_lottery, right_lottery);

    % Prepare the feedback screen
    DrawFormattedText(window, SPaddUrn, 'center', ...
        .25*screenYpixels, white)                                           ; % Text before feedback of preferred lottery
    Screen('DrawLines', window, fixCoords,...
        fixWidth, white, [xCenter yCenter], 2)                          ; % draw fixcross
    Screen('Flip', window)                                                  ;
    
    
    % Measure timing and whether preferred lottery was correct
    activeDFE_prefLottery_mat(1,lot_pref_counter) = picked_loc                          ;
    activeDFE_prefLottery_mat(2,lot_pref_counter) = rt                                  ;
    activeDFE_prefLottery_mat(3,lot_pref_counter) = reward_bool                         ;
    activeDFE_prefLottery_mat(4,lot_pref_counter) = picked_loc == good_lottery_loc      ;
    activeDFE_prefLottery_mat(5,lot_pref_counter) = (~mod(subj_id,2) + reward_bool)     ; % even id and win: 1+1=2=blue. even id and lose: 1+0=1=red. odd id and win:0+1=1=red. odd id and lose: 0+0=0=blue
    activeDFE_prefLottery_mat(6,lot_pref_counter) = lot_pref_counter                    ; 

    lot_pref_counter = lot_pref_counter + 1                                 ; % update the counter of the preferred lottery data matrix
 
    

    
    WaitSecs(1)                                                             ; % wait for one second before displaying feedback
	% Replicate the screen from above - but this time with feedback
    DrawFormattedText(window, SPaddUrn, 'center', ...
        .25*screenYpixels, white)                                           ;
    Screen('DrawLines', window, fixCoords,...
        fixWidth, white, [xCenter yCenter], 2)                          ;

    % drawing the checkerboard stim at the chosen location. The reward_bool
    % tells us win(1) or loss(0) ... we add 1 so we get win=2, loss=1
    Screen('FillRect', window, reward(:,:,reward_bool+1),...
        rect_locs(:,:,picked_loc))                                          ;

    Screen('DrawTextures', window, masktexture, [],...
        mask_locs(:,:,picked_loc))                                          ;


    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ;


    % Now the subject has completed one DFE run. We calculate, how many
    % trials remain to start a new trial or go on to the next task.
    dfe_idx_max = dfe_idx_max - dfe_idx                                     ;
    dfe_run_counter = dfe_run_counter + 1                                   ; 
    
end % end of while loop implmenting all possible DFE runs

% All DFE samples have been taken. Now there are four final draws from all
% the results of the previous choices, thus from 
% activeDFE_prefLottery_mat(3,:)
% the outcome of the uniform draw from this urn will be multiplied by 13
% and will be the payoff for this game.


activeDFE_payoff_urn = repmat(activeDFE_prefLottery_mat(3,:),1,4)           ; % this step is necessary to avoid randsample(0,4,true), which throws an error
activeDFE_payoff = randsample(activeDFE_payoff_urn, 4)                      ; % repeating the payoff urn with 4 and drawing without replacement = not repeating the urn and drawing 4 times with replacement
activeDFE_payoff_sum = sum(activeDFE_payoff*13)                             ; % overall payoff value



DrawFormattedText(window, SPfinalUrn1, 'center', 'center', white)          ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, SPfinalUrn2, 'center', 'center', white)          ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, ...
    sprintf('You earned: %d', activeDFE_payoff_sum), ...
    'center', 'center', white)                                              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;   



% Now there will be a short break before we go to the next task
DrawFormattedText(window, breakText, 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait                                                                ;

case 4
%% Passive SP ... showing the replay of active SP

% here we can save the data --> response, mimiced decision interval by 
% computer, rewarded or not, color of stim, lottery_type that is at that 
% location, number of dfe run
passiveDFE_mat = nan(6,overall_trials); 

% Here we save the preferred lottery data --> which one is preferred
% (1=left, 2=right), is it the good one? (0/1), how quickly was it chosen
% (rt), was it rewarded or not? (0/1)
passiveDFE_prefLottery_mat = nan(6,1)                                       ; % we cannot preallocate exactly, but there will be at least ONE choice in DFE





% Passive DFE Instructions
DrawFormattedText(window, passiveSP1, 'center', 'center', white)           ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, passiveSP2, 'center', 'center', white)           ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, passiveSP3, 'center', 'center', white)           ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, passiveSP4, 'center', 'center', white)           ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, passiveSP5, 'center', 'center', white)           ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;


dfe_idx_max = overall_trials                                                ;
dfe_run_counter = 1                                                         ;
data_idx_counter = 1                                                        ; % to know where in our data matrix to place the responses
lot_pref_counter = 1                                                        ; % also a data matrix counter to place the preferred lotteries


while dfe_idx_max >= 1 % while we have at least one dfe trial remaining, keep starting new DFE runs

    
    
    [left_lottery, right_lottery, good_lottery_loc] = ...
            determine_lottery_loc(lottery_option1, lottery_option2)         ; % place good and bad lottery randomly either left or right

    
    
    % starting a new DFE
        DrawFormattedText(window, passiveSPShuffle, 'center', ...
            'center', white)                                                ;
        Screen('Flip', window)                                              ;
        WaitSecs(2)                                                         ;
    
    


    % actual loop
    for dfe_idx = 1:dfe_idx_max

        if dfe_idx ~= 1
            % Drawing the text options for sample vs choice decision      
            textwin1 = [screenXpixels*.1, screenYpixels*.5, screenXpixels*.4, screenYpixels*.5]; % windows to center the formatted text in
            textwin2 = [screenXpixels*.6, screenYpixels*.5, screenXpixels*.9, screenYpixels*.5]; % left top right bottom

            DrawFormattedText(window, 'Do you want to', ...
                'center', .25*screenYpixels, white)                         ;

            DrawFormattedText(window, 'observe a\nrandom sample', ...
                'center', 'center', white, [], [], [], [], [], textwin1)    ;

            DrawFormattedText(window, 'make a choice', ...
                'center', 'center', white, [], [], [], [], [], textwin2)    ;

            Screen('Flip', window)                                          ;
            
            % start decision process ... this time, only location is relevant
            KbEventFlush                                                    ; % clear all keyboard events
            [picked_loc] = require_response(left_lottery, right_lottery)                                 ;

        else
            picked_loc = 1                                                  ; %In first trial, always draw a sample
        end
        
        switch picked_loc
            
            case 1 % =left ... observe a sample drawn by the computer

                trial_counter = strcat(num2str(overall_trials-(dfe_idx_max-dfe_idx)),'/', num2str(overall_trials));

                DrawFormattedText(window, trial_counter, 'center', 'center', white);
                Screen('Flip', window);

                % drawing the fixcross
                Screen('DrawLines', window, fixCoords,...
                    fixWidth, white, [xCenter yCenter], 2)              ;

                WaitSecs(2); % show trial counter for 2 seconds
                Screen('Flip', window)                                      ; % Draw the fixcross
 
                % Passive DFE, so the computer decides
                picked_loc = randsample([2 1], 1)                           ; % in the passive viewing, the computer draws randomly from a location: 1=left, 2=right

                if picked_loc == 1
                    reward_bool = Sample(left_lottery)                      ;
                else
                    reward_bool = Sample(right_lottery)                     ;
                end

                current_interval = .5 + rand                                ; % this mimics some "decision interval" by the computer and will be used for "wait" below
                
                % drawing the fixcross
                Screen('DrawLines', window, fixCoords,...
                    fixWidth, white, [xCenter yCenter], 2)              ;

                % drawing the checkerboard stim at the chosen location. The reward_bool
                % tells us win(1) or loss(0) ... we add 1 so we get win=2, loss=1

                Screen('FillRect', window, reward(:,:,reward_bool+1),...
                    rect_locs(:,:,picked_loc))                              ;
 
                Screen('DrawTextures', window, masktexture, [],...
                    mask_locs(:,:,picked_loc))                              ;


                % even id, blue is win 
                passiveDFE_mat(1,data_idx_counter) = picked_loc                                        ; % which location was picked: 1, left - 2, right
                passiveDFE_mat(2,data_idx_counter) = current_interval                                  ; % % no rt ... but how long was the mimic decision interval
                passiveDFE_mat(3,data_idx_counter) = reward_bool                                       ; % boolean whether is was rewarded or not
                passiveDFE_mat(4,data_idx_counter) = (good_lottery_loc == picked_loc)                  ; % boolean whether good or bad lottery was chosen
                passiveDFE_mat(5,data_idx_counter) = (~mod(subj_id,2) + reward_bool)                   ; % which color was the stim: 1: red ... 0 or 2: blue
                passiveDFE_mat(6,data_idx_counter) = dfe_run_counter                                   ; % current dfe run

                data_idx_counter = data_idx_counter + 1                     ; % update our data index counter
                WaitSecs(current_interval)                                  ;   % after choice, wait 1 sec before displaying result
                Screen('Flip', window)                                      ;

                WaitSecs(2)                                                 ; % feedback displayed for 2 secs

        
        
            case 2 % =right ... make a choice 
                dfe_idx_max = dfe_idx_max + 1                               ; % making a choice doesn't count into the trials. As usual, dfe_idx_max will be reduced at end of the procedure one ... so +1 -1 = 0 difference
                break                                                       ; % To make a choice, we have to break the for loop  
        end % end switch procedure ... continue with new question: choice or sample?
    end % end of for loop of drawing samples

    


    % Start choice procedure
    
    % Ask the subject, which lottery she wants to select
    DrawFormattedText(window, SPchoice, 'center', 'center', white)         ;
    Screen('Flip', window)                                                  ;
    KbStrokeWait; 
    % start decision process
    KbEventFlush                                                            ; % clear all keyboard events
    [picked_loc, reward_bool, rt] = require_response(left_lottery, right_lottery);

    % Prepare a feedback screen
    DrawFormattedText(window, SPaddUrn, 'center', ...
        .25*screenYpixels, white)                                           ; % Text before feedback of preferred lottery
    Screen('DrawLines', window, fixCoords,...
        fixWidth, white, [xCenter yCenter], 2)                          ; % draw a fixcross
    Screen('Flip', window)                                                  ;
    
    
        
    % Save rt of selecting preferred lottery and whether it was good/bad
    passiveDFE_prefLottery_mat(1,lot_pref_counter) = picked_loc                         ;
    passiveDFE_prefLottery_mat(2,lot_pref_counter) = rt                                 ;
    passiveDFE_prefLottery_mat(3,lot_pref_counter) = reward_bool                        ;
    passiveDFE_prefLottery_mat(4,lot_pref_counter) = picked_loc == good_lottery_loc     ;
    passiveDFE_prefLottery_mat(5,lot_pref_counter) = (~mod(subj_id,2) + reward_bool)    ;
    passiveDFE_prefLottery_mat(6,lot_pref_counter) = lot_pref_counter                   ;
    
    lot_pref_counter = lot_pref_counter + 1                                 ; % update the counter of the preferred lottery data matrix
    

    WaitSecs(1)                                                             ; % Wait one second before displaying the actual feedback
    % Recreate screen from above but this time with feedback
    DrawFormattedText(window, SPaddUrn, 'center', ...
        .25*screenYpixels, white)                                           ; % Text before feedback of preferred lottery
    Screen('DrawLines', window, fixCoords,...
        fixWidth, white, [xCenter yCenter], 2)                          ;

    % drawing the checkerboard stim at the chosen location. The reward_bool
    % tells us win(1) or loss(0) ... we add 1 so we get win=2, loss=1
    Screen('FillRect', window, reward(:,:,reward_bool+1),...
        rect_locs(:,:,picked_loc))                                          ;

    Screen('DrawTextures', window, masktexture, [],...
        mask_locs(:,:,picked_loc))                                          ;


    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ;


    
    % Now the subject has completed one DFE run. We calculate, how many
    % trials remain to start a new trial or go on to the next task.
    dfe_idx_max = dfe_idx_max - dfe_idx                                     ;
    dfe_run_counter = dfe_run_counter + 1                                   ;  
    
end % end of while loop implmenting all possible DFE runs

% All DFE samples have been taken. Now there are four final draws from all
% the results of the previous choices, thus from 
% passiveDFE_prefLottery_mat(3,:)
% the outcome of the uniform draw from this urn will be multiplied by 13
% and will be the payoff for this game.

passiveDFE_payoff_urn = repmat(passiveDFE_prefLottery_mat(3,:),1,4)         ; % this step is necessary to avoid randsample(0,4,true), which throws an error
passiveDFE_payoff = randsample(passiveDFE_payoff_urn, 4)                    ; % repeating the payoff urn with 4 and drawing without replacement = not repeating the urn and drawing 4 times with replacement
passiveDFE_payoff_sum = sum(passiveDFE_payoff*13)                           ; % overall payoff value

DrawFormattedText(window, SPfinalUrn1, 'center', 'center', white)          ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ; 

DrawFormattedText(window, SPfinalUrn2, 'center', 'center', white)          ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, sprintf('You earned: %d', passiveDFE_payoff_sum), ...
    'center', 'center', white)                                              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;



if condi_idx ~= 4
% Now there will be a short break before we go to the next task
DrawFormattedText(window, breakText, 'center', 'center', white)             ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;
end
    
    
%% End the condition randomization
end % ending switch procedure to choose current game protocol
end % ending for loop implementing the random choice of games


%-------------------------------------------------------------------------%
%                         Closing the Experiment                          %
%-------------------------------------------------------------------------%
%% Finishing up


DrawFormattedText(window, texts('end'),'center', 'center', white)                 ;

Screen('Flip', window)                                                      ;


% Wait for a key press to close the window and clear the screen
KbStrokeWait                                                                ;

% Get time of end of the experiment
experiment_end = datestr(now)                                               ; % ... it's good to know the time when the experiment ended

sca                                                                         ;


%% Saving all the data


% data 'readme' cells for quick reference in data analysis part

SP_Readme = cell(7,1);
SP_Readme(1,1) = cellstr('row1: which location was picked? 1=left 2=right');
SP_Readme(2,1) = cellstr('row2: how quickly was it picked in ms? (for passive DFE: how long was the jitter)');
SP_Readme(3,1) = cellstr('row3: was it rewarded? 0=no, 1=yes');
SP_Readme(4,1) = cellstr('row4: was the good lottery chosen? 0=no, 1=yes') ;
SP_Readme(5,1) = cellstr('row5: which color was the stim? 1=red, 0/2=blue');
SP_Readme(6,1) = cellstr('row6: what is the current run in DFE? (sample-run or choice-run respectively');
SP_Readme(7,1) = cellstr('*Additional INFO*: the "payoff" array describes the four final draws from the reward urn');


% In Bandit, we do not have a feedback for the last 'draw' of indicating
% your preferred lottery. Thus, there are two cells less in the choice
% Bandit (whether feedback was rewarded, and which color it had) compared
% to the sample bandit.
% Furthermore, the Bandit data structure has separate bandit runs encoded
% in the 3rd dimension, whereas the DFE data structure does this in 2D
PFP_Readme = cell(6,1);
PFP_Readme(1,1) = cellstr('row1: which location was picked? 1=left 2=right');
PFP_Readme(2,1) = cellstr('row2: how quickly was it picked in ms? (for passive Bandit: how long was the jitter)');
PFP_Readme(3,1) = cellstr('row3: was the good lottery chosen? 0=no, 1=yes');
PFP_Readme(4,1) = cellstr('row4: *Only for sample*: was it rewarded? 0=no, 1=yes');
PFP_Readme(5,1) = cellstr('row5: *Only for sample*: which color was the stim? 1=red, 0/2=blue');
PFP_Readme(6,1) = cellstr('*Additional INFO*: separate bandit runs are encoded in the 3rd dimension of the data structure');


% one data structure with every game type as a nested structure, which then
% contains the data

activeSP.sampleData = activeDFE_mat                                        ;
activeSP.choiceData = activeDFE_prefLottery_mat                            ;
activeSP.payoff = activeDFE_payoff                                         ;
activeSP.readme = SP_Readme                                               ;

passiveSP.sampleData = passiveDFE_mat                                      ;
passiveSP.choiceData = passiveDFE_prefLottery_mat                          ;
passiveSP.payoff = passiveDFE_payoff                                       ;
passiveSP.readme = SP_Readme                                              ;

activePFP.sampleData = aPFP_mat                                  ;
activePFP.choiceData = aPFP_prefLottery_mat                      ;
activePFP.readme = PFP_Readme                                         ;

passivePFP.sampleData = passiveBandit_mat                                ;
passivePFP.choiceData = passiveBandit_prefLottery_mat                    ;
passivePFP.readme = PFP_Readme                                        ;

experimentalVars.expStart = experiment_start                                ;
experimentalVars.expEnd = experiment_end                                    ;
experimentalVars.subj_id = subj_id                                          ;

data.activeSP = activeSP                                                  ;
data.passiveSP = passiveSP                                                ;
data.activePFP = activePFP                                            ;
data.passivePFP = passivePFP                                          ;
data.experimentalVars = experimentalVars                                    ;   

% Save all the data with an appropriate file name 

cd ..                                                                       ; % data dir is a sibling of the current working dir, not a child

% make sure we get the correct data dir
if exist(fullfile(pwd, 'data'),'dir')==7
    data_dir = fullfile(pwd, 'data')                                        ;
    sprintf('Saving in data dir: %s', data_dir)         
else
    mkdir(data)
    data_dir = fullfile(pwd, 'data')                                        ;  
    sprintf('creating new data dir: %s', data_dir) 
end

% saving it to the data dir
cur_time = datestr(datetime('now','Format','d_MMM_y_HH_mm_ss'))             ; % the current time and date                                          
fname = fullfile(data_dir, strcat('subj_', sprintf('%03d_', subj_id), ...
    cur_time, '.mat'))                                                      ; % fname consists of subj_id and datetime to avoid overwriting files
save(fname, 'data')                                                         ; % save it!

end % function end
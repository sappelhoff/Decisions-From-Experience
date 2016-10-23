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

exp_start = datestr(now)                                                    ; % Get time of start of the experiment

subj_id = inquire_user                                                      ; % get a user ID        
total_earnings = 0                                                          ; % total earnings of user
euro_factor = 0.25                                                          ; % factor to convert points to Euros

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
    masktexture] = produce_stims(window, windowRect, screenNumber)          ; % separate function for the stim creation to avoid clutter

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

texts = produce_texts                                                       ; % separate function which outputs a "container.Map"

%-------------------------------------------------------------------------%
%                         Experimental Loop                               %
%-------------------------------------------------------------------------%

%% Welcome screen

general_instructions(window, white, reward, masktexture, rect_locs, ...
    mask_locs, euro_factor)                                                 ; % This will display the welcome screen and some general instructions

%% condition selection

for condi_idx = 1:4
current_condi = condi_order(condi_idx)                                      ; % condi_order has been set up before according to odd/even id of subj

switch current_condi
    
case 1
%% Active Partial Feedback Paradigm (aPFP)

% here we can save the data
aPFP_mat = nan(4,pfp_trials,(overall_trials / pfp_trials))                  ; % for each bandit run, we have one 2D matrix ... each bandit run is one sheet(3D)

% Here we save the preferred lottery data --> which one is preferred
% (1=left, 2=right), is it the good one? (0/1), how quickly was it chosen
% (rt)
aPFP_prefLot_mat = nan(3,1,(overall_trials/pfp_trials))                     ; 

    
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
        aPFP_mat(1,pfp_idx,pfp_run) = picked_loc                            ; % which location was picked: 1, left - 2, right
        aPFP_mat(2,pfp_idx,pfp_run) = rt                                    ; % how quickly was it picked in ms
        aPFP_mat(3,pfp_idx,pfp_run) = (good_lottery_loc == picked_loc)      ; % boolean was the good lottery chosen? 0=no, 1=yes
        aPFP_mat(4,pfp_idx,pfp_run) = reward_bool                           ; % boolean whether is was rewarded or not


        WaitSecs(1)                                                         ; % after choice, wait 1 sec before displaying result
        Screen('Flip', window)                                              ;
        WaitSecs(2)                                                         ; % feedback displayed for 2 secs

    end

    % Tell the subject how much she has earned
    payoff = sum(aPFP_mat(4,:,pfp_run))                                     ; % the overall payoff 
    payoff_str = strcat(texts('payoff'), sprintf(' %d', num2str(payoff)))   ;    
    DrawFormattedText(window, payoff_str, 'center', 'center', white)        ;
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ; % show payoff for 2 secs
    total_earnings = total_earnings + payoff                                ; % increment the total earnings of the participant
    
    

    % Ask the subject, which lottery was better
    DrawFormattedText(window, texts('aPFP_PrefLot'), ...
        'center', 'center', white)                                          ;
    Screen('Flip', window)                                                  ;

    % start decision process
    [picked_loc, ~, rt] = require_response(left_lottery, right_lottery)     ;
  
    % Record timing and whether preferred lottery was correct
    aPFP_prefLot_mat(1,1,pfp_run) = picked_loc                              ; % Which lottery was preferred? 1=left, 2=right
    aPFP_prefLot_mat(2,1,pfp_run) = rt                                      ; % rt to select preferred lottery
    aPFP_prefLot_mat(3,1,pfp_run) = picked_loc == good_lottery_loc          ; % boolean whether correct lottery was preferred
      
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
aSP_mat = nan(4,overall_trials)                                             ;

% Here we save the preferred lottery data
aSP_prefLot_mat = nan(5,1)                                                  ; % we cannot preallocate exactly, but there will be at least ONE choice in DFE


% Active DFE Instructions
DrawFormattedText(window, texts('next_intro'), 'center', 'center', white)   ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, texts('aSP_intro1'), 'center', 'center', white)   ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, texts('aSP_intro2'), 'center', 'center', white)   ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, texts('aSP_intro3'), 'center', 'center', white)   ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, texts('aSP_intro4'), 'center', 'center', white)   ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, texts('aSP_intro5'), 'center', 'center', white)   ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, texts('aSP_intro6'), 'center', 'center', white)   ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

% while loop implementing all possible SP games ... i.e., overall_trials, 
% if subject always goes to choice in first attempt

sp_idx_max = overall_trials                                                 ;
sp_run_count = 1                                                          ; % defines an SP "run", i.e., all samples taken before a choice belong to a run
dat_idx_count = 1                                                           ; % to know where in our data matrix to place the responses
sp_choice_count = 1                                                         ; % also a data matrix counter to place the preferred lotteries
prev_samples = 0                                                            ; % variable to calculate number of samples prior to a choice

while sp_idx_max >= 1                                                       ; % while we have at least one dfe trial remaining, keep starting new SP runs

    
    [left_lottery, right_lottery, good_lottery_loc] = ...
            determine_lottery_loc(lottery_option1, lottery_option2)         ; % place good and bad lottery randomly either left or right

            
    % starting a new SP by shuffling the lotteries
    DrawFormattedText(window, texts('shuffled'), 'center', 'center', white) ;
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ;
        
        

    % actual loop
    for sp_idx = 1:sp_idx_max

        if sp_idx ~= 1                                                      ; % this option only for draws that are NOT the first draw for newly shuffled lotteries  
            
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
            [picked_loc] = require_response(left_lottery, right_lottery)    ;
            
            % show the chosen option
            if picked_loc == 1
                DrawFormattedText(window, 'draw another sample', ...
                    'center', 'center', white, [], [], [], [], [],textwin1) ;
                Screen('Flip', window)                                      ;
                WaitSecs(2)                                                 ; % show chosen option for 1 sec

            elseif picked_loc == 2
                DrawFormattedText(window, 'make a choice', ...
                    'center', 'center', white, [], [], [], [], [],textwin2) ;
                Screen('Flip', window)                                      ;
                WaitSecs(2)                                                 ; % show chosen option for 1 sec
            end
        
        else
            picked_loc = 1                                                  ; % If it's the first draw of a new game, take a sample, without asking whether subject actually wants 'choice'
        end
        
        
        switch picked_loc
            
            case 1 % =left ... draw a sample
                
                % draw trial counter
                trial_counter = ...
                    strcat(num2str(overall_trials-(sp_idx_max-sp_idx)))     ;
                
                
                DrawFormattedText(window, trial_counter, 'center', ...
                    'center', white)                                        ;
                Screen('Flip', window)                                      ;

                % drawing the fixcross
                Screen('DrawLines', window, fixCoords,...
                    fixWidth, white, [xCenter yCenter], 2)                  ;
                WaitSecs(2)                                                 ; % show trial counter for 2 seconds
                Screen('Flip', window)                                      ; % then show fixcross



                % start decision process
                [picked_loc, reward_bool, ...
                    rt] = require_response(left_lottery, right_lottery)     ;

                % drawing the fixcross
                Screen('DrawLines', window, fixCoords,...
                    fixWidth, white, [xCenter yCenter], 2)                  ;

                % drawing the checkerboard stim at the chosen location. The
                % reward_ bool tells us win(=1) or loss(=0) ... we add 1 so
                % we get win=2, loss=1
                Screen('FillRect', window, reward(:,:,reward_bool+1),...
                    rect_locs(:,:,picked_loc))                              ;

                Screen('DrawTextures', window, masktexture, [],...
                    mask_locs(:,:,picked_loc))                              ;


                % even id, blue is win 
                aSP_mat(1,dat_idx_count) = picked_loc                       ; % which location was picked: 1, left - 2, right
                aSP_mat(2,dat_idx_count) = rt                               ; % how quickly was it picked in ms
                aSP_mat(3,dat_idx_count) = reward_bool                      ; % boolean whether is was rewarded or not
                aSP_mat(4,dat_idx_count) = (good_lottery_loc == picked_loc) ; % boolean whether good or bad lottery was chosen

                dat_idx_count = dat_idx_count + 1                           ; % update our data index counter
                WaitSecs(1)                                                 ; % after choice, wait 1 sec before displaying result
                Screen('Flip', window)                                      ;
                WaitSecs(2)                                                 ; % feedback displayed for 2 secs

                
                
            case 2 % =right ... make a choice 
                sp_idx_max = sp_idx_max + 1                                 ; % making a choice doesn't count into the trials. As usual, sp_idx_max will be reduced at end of the procedure one ... so +1 -1 = 0 difference
                break                                                       ; % To make a choice, we have to break the for loop
                
        end % end switch. Continue with new question: choice or sample?
    end % end of for loop of drawing samples

 
    % If 'right' (=2) was selected or there are no trials left, start the
    % choice procedure
    
    if sp_idx_max >= 1 % if this is the last trial, tell the subject so
        DrawFormattedText(window, texts('aSP_final'), 'center', ...
            'center', white)                                                ;
        Screen('Flip', window)                                              ;
        KbStrokeWait                                                        ;
    end
    
    % Ask the subject, which lottery she wants to select
    DrawFormattedText(window, texts('aSP_choice'), 'center', ...
        'center', white)                                                    ;
    Screen('Flip', window)                                                  ;
    KbStrokeWait                                                            ;
    
    % start decision process
    [picked_loc, reward_bool, ...
        rt] = require_response(left_lottery, right_lottery)                 ;

    % draw fixcross
    Screen('DrawLines', window, fixCoords,...
        fixWidth, white, [xCenter yCenter], 2)                              ; 
    Screen('Flip', window)                                                  ;
    
    
    % drawing the checkerboard stim at the chosen location. The reward_bool
    % tells us win(1) or loss(0) ... we add 1 so we get win=2, loss=1
    Screen('FillRect', window, reward(:,:,reward_bool+1),...
        rect_locs(:,:,picked_loc))                                          ;

    Screen('DrawTextures', window, masktexture, [],...
        mask_locs(:,:,picked_loc))                                          ;

    
    
    % Measure timing and whether preferred lottery was correct
    prev_samples = size(aSP_mat,2)-sum(isnan(mean(aSP_mat)))-prev_samples   ; % counts cols filled in since last check
    
    aSP_prefLot_mat(1,sp_choice_count) = picked_loc                         ; % which loc was picked? left=1, right=2
    aSP_prefLot_mat(2,sp_choice_count) = rt                                 ; % how quickly was it picked in ms
    aSP_prefLot_mat(3,sp_choice_count) = reward_bool                        ; % was it rewarded=1 or not=0
    aSP_prefLot_mat(4,sp_choice_count) = picked_loc == good_lottery_loc     ; % was the "good lottery" picked?
    aSP_prefLot_mat(5,sp_choice_count) = prev_samples                       ; % How many samples preceeded this choice?

    
    sp_choice_count = sp_choice_count + 1                                   ; % update the counter of the preferred lottery data matrix

   
    WaitSecs(1)                                                             ; % wait for one second before displaying feedback
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ; % show feedback for 2 seconds
    
    
    % Tell the subject how much she has earned 
    switch reward_bool
        case 0
            payoff = -3;
        case 1
            payoff = 10;
    end
    
    payoff_str = strcat(texts('payoff'), sprintf(' %d', num2str(payoff)))   ;
    DrawFormattedText(window, payoff_str, 'center', 'center', white)        ;
    Screen('Flip', window)                                                  ;
    KbStrokeWait                                                            ;
    total_earnings = total_earnings + payoff                                ; % increment the total earnings of the participant
 	

    % Now the subject has completed one SP run. We calculate, how many
    % trials remain to start a new trial or go on to the next task.
    sp_idx_max = sp_idx_max - sp_idx                                        ;
    sp_run_count = sp_run_count + 1                                     ; 
    
end % end of while loop implmenting all possible SP runs



% Now there will be a short break before we go to the next task
DrawFormattedText(window, breakText, 'center', 'center', white)             ;
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
show_sp_replay(aPFP_mat, texts, reward, window, white, masktexture, ...
    mask_locs, rect_locs)                                                   ;


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
%% Finishing up and showing final payoff

DrawFormattedText(window, texts('end'),'center', 'center', white)           ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ; 

payoff_str = strcat(texts('total_payoff'), sprintf(' %d?', ...
    total_earnings*euro_factor))                                            ; % This displays the total earnings of the participant
DrawFormattedText(window, payoff_str, 'center', 'center', white)            ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ; % Wait for a key press to close the window and clear the screen




% Get time of end of the experiment
exp_end = datestr(now)                                                      ; % ... it's good to know the time when the experiment ended

sca                                                                         ; % shut down Psychtoolbox

%% Saving all the data
% use a separate function for this, which creates a "package" in form of a
% matlab structure out of all the data of the experiment and saves it
% neatly together with a readme in form of a matlab cell.

save_data(exp_start, exp_end, total_earnings, subj_id)                      ; % data located in /data ... sibling dir of /experiment_files

end % function end
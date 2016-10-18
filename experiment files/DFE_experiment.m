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
%
%
% Copyright (c) 2016 Stefan Appelhoff


%% function start

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
grey = white / 2                                                            ; % RGB values are defined on the interval [0,1], white is 1 - black is 0 ... so grey is [.5 .5 .5]

% Open an on screen window and get its size and center
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey)       ; % our standard background will be grey
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

[fixWidth, fixCoords, colors_1, colors_2, rect_locs, ...
    mask_locs, masktexture] = produce_stims                                 ; % separate function for this to avoid clutter

%-------------------------------------------------------------------------%
%                         Experimental Conditions                         %
%-------------------------------------------------------------------------%
%%

% the overall trials determine the maximum number of draws possible in a
% DFE game. If participants finish earlier, they get the next game of DFE
% and so on, until the overall trials are reached. For Bandit games, there
% are 25 draws per game and thus (overall_trials/25) Bandit games overall.
overall_trials = 40                                                          ; 
bandit_trials = 20                                                           ; 

% selection whether blue or red stimulus will represent the reward;
% colors_1 is red, colors_2 is blue. The selection is depending on subject
% ID --> if it's even, reward is blue, else if it's odd, reward is red
% put the rewards into a 3D matrix to choose from
% reward(:,:,2) will be the win, reward(:,:,1) will be the loss
if ~mod(subj_id,2)                                                       
    reward = cat(3, colors_1, colors_2)                                     ; % even ID ... put red as loss ... put blue as win
else
    reward = cat(3, colors_2, colors_1)                                     ; % odd ID ... put blue as loss ... put red as win
end


% Create some lotteries - these are stable and hardcoded across the study
lottery_option1 = [ones(1,7), zeros(1,3)]                                   ; % .7 win --> good
lottery_option2 = [ones(1,3), zeros(1,7)]                                   ; % .3 win --> bad





% Conditions are
% 1 = active bandit
% 2 = passive bandit
% 3 = active DFE
% 4 = passive DFE

% Randomizing the order of conditions for each participant
condi_order = randperm(4)                                                   ; % use this variable later for a 'switch' procedure
%-------------------------------------------------------------------------%
%                         Text Presentation                               %
%-------------------------------------------------------------------------%

%% General instructions

welcome = sprintf('Welcome to the experiment.\n\n\nPress any key to proceed\n\nthroughout the general instructions.');
instruct1 = sprintf('The following tasks will require\n\nyou to make choices between\n\ntwo different lotteries:\n\n[left] or [right]');
instruct2 = sprintf('The lotteries [left] and [right]\n\neach contain two possible outcomes,\n\nnamely "win" or "lose"');
instruct3 = sprintf('Some lotteries have a higher chance\n\nto yield a "win" outcome\n\nother lotteries will yield\n\na "lose" outcome more often.\n\n\nAll lotteries will remain stable for one task.\n\nOnce they are shuffled, you are being told.');
instruct4 = sprintf('Although the following tasks might differ slightly,\n\nyour  overarching assignment is\n\nto maximize the "win" outcomes.\n\n\nThis is in your interest,\n\nbecause your final payoff will depend on it.');
instruct5 = sprintf('On the following screens, you will be\n\nshown, how a "win" and a "lose" outcome\n\nlook like.\n\n\nRemember these outcomes well.');
showWin = sprintf('This outcome signifies "win"');
showLose = sprintf('This outcome signifies "lose"');
leadOver = sprintf('Before each task, you will receive\n\nmore detailed instructions.\n\n\nIf you have any questions,\n\nplease ask the experimenter.\n\n\nIf you are ready, press any key to start.');

% these texts will be relevant for multiple conditions
breakText = sprintf('Now there will be a short break\n\nbefore we continue with the next task.\n\n\nPress a key if you want to continue.');
BanditPrefLot = sprintf('Which lottery do you think was more profitable?\nPress [left] or [right].');
DFEchoice = sprintf('From which lottery do\nyou want to draw your payoff?\n[left] or [right]\n\nPress twice!');
DFEaddUrn = sprintf('This outcome will be added\nto your final urn.');
DFEfinalUrn1 = sprintf('This task is done.\n\nNow there will be 4 random draws\n\nwith replacement from your final urn.');
DFEfinalUrn2 = sprintf('These 4 random draws will\n\nbe summed up to determine\n\nyour payoff. Remember a "win"\n\noutcome is worth 13, and a\n\n "lose" outcome is worth 0.');

%% Active Bandit
activeBandit1 = sprintf('Active Bandit\n\n\nWhenever you see the + sign,\n\nuse [left] and [right] to choose a lottery.');
activeBandit2 = sprintf('Active Bandit\n\n\nEach "win" outcome will be worth 1.\n\nEach "lose" outcome will be worth 0.');
activeBanditShuffle = sprintf('Active Bandit\n\n\nThe lotteries have been shuffled.');
activeBanditPayoff = sprintf('You earned: ');

%% Passive Bandit

passiveBandit1 = sprintf('Passive Bandit\n\n\nThe computer will choose the lotteries for you.\n\nPlease just observe.');
passiveBandit2 = sprintf('Passive Bandit\n\n\nEach "win" outcome will be worth 1.\n\nEach "lose" outcome will be worth 0.');
passiveBanditShuffle = sprintf('Passive Bandit\n\n\nThe lotteries have been shuffled.');
passiveBanditPayoff = sprintf('The computer earned the\n\nfollowing amount for you: ');

%% Active DFE

activeDFE1 = sprintf('Active DFE\n\n\nWhenever you see the + sign,\n\nuse [left] and [right] to choose a lottery.');
activeDFE2 = sprintf('However, the outcomes you see\n\n reflect "samples".\n\nYou do not receive\n\npoints for these samples.');
activeDFE3 = sprintf('Once you have taken enough samples\n\nto know whether a certain lottery is profitable,\n\nyou can stop sampling and choose a lottery');
activeDFE4 = sprintf('Upon choice, the outcome is added\n\nto a "final urn". After that,\n\nyou can continue to sample.\n\nOnce you have drawn\n\nall your samples, 4 outcomes\n\nwill be drawn from your personal\n\n"final urn" with replacement.');
activeDFE5 = sprintf('A "win" outcome drawn\n\nfrom your accumulated "final urn" will\n\nbe worth 13. A "lose" outcome\n\ndrawn from your accumulated\n\n"final urn" will be worth 0.');
activeDFEShuffle = sprintf('Active DFE\n\n\nThe lotteries have been shuffled.');


%% Passive DFE

passiveDFE1 = sprintf('Passive DFE\n\n\nThe computer will choose the lotteries for you.\n\nPlease just observe.');
passiveDFE2 = sprintf('However, the outcomes you see\n\n reflect "samples".\n\nYou do not receive\n\npoints for these samples.');
passiveDFE3 = sprintf('Once you have observed enough samples\n\nto know whether a certain lottery is profitable,\n\nyou can stop sampling and choose a lottery');
passiveDFE4 = sprintf('Upon choice, the outcome is added\n\nto a "final urn". After that,\n\nyou can continue to sample.\n\nOnce you have drawn\n\nall your samples, 4 outcomes\n\nwill be drawn from your personal\n\n"final urn" with replacement.');
passiveDFE5 = sprintf('A "win" outcome drawn from\n\nyour accumulated "final urn" will\n\nbe worth 13. A "lose" outcome\n\ndrawn from your accumulated\n\n"final urn" will be worth 0.');
passiveDFEShuffle = sprintf('Passive DFE\n\nThe lotteries have been shuffled.');


%% Goodbye

ending = sprintf('You are done.\n\nThank you for participating!\n\n\nPress a key to close.');


%-------------------------------------------------------------------------%
%                         Experimental Loop                               %
%-------------------------------------------------------------------------%

%% Welcome screen

% General welcome
DrawFormattedText(window, welcome,'center', 'center', white)                ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, instruct1,'center', 'center', white)              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, instruct2,'center', 'center', white)              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, instruct3,'center', 'center', white)              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, instruct4,'center', 'center', white)              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, instruct5,'center', 'center', white)              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

% Show "win" outcome
DrawFormattedText(window, showWin, 'center', 'center', white)               ;
Screen('FillRect', window, reward(:,:,2), allRectsCenter)                   ;
Screen('DrawTextures', window, masktexture, [], mask_locs(:,:,3))           ;
Screen('Flip', window)                                                      ;
WaitSecs(2)                                                                 ; % force people to look at it for at least 2 seconds
KbStrokeWait                                                                ;

% Show "lose" outcome
DrawFormattedText(window, showLose, 'center', 'center', white)              ;
Screen('FillRect', window, reward(:,:,1), allRectsCenter)                   ;
Screen('DrawTextures', window, masktexture, [], mask_locs(:,:,3))           ;
Screen('Flip', window)                                                      ;
WaitSecs(2)                                                                 ; % force people to look at it for at least 2 seconds
KbStrokeWait                                                                ;

% Leading over to real experiment
DrawFormattedText(window, leadOver, 'center', 'center', white)              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;


%% Random condition selection

for condi_idx = 1:4
current_condi = condi_order(condi_idx)                                      ;

switch current_condi
    
case 1
%% Active Bandit

% here we can save the data
activeBandit_mat = nan(5,bandit_trials,(overall_trials / bandit_trials))    ; % for each bandit run, we have one 2D matrix ... each bandit run is one sheet(3D)

% Here we save the preferred lottery data --> which one is preferred
% (1=left, 2=right), is it the good one? (0/1), how quickly was it chosen
% (rt)
activeBandit_prefLottery_mat = nan(3,1,(overall_trials/bandit_trials))      ; 


[left_lottery, right_lottery, good_lottery_loc] = ...
        determine_lottery_loc(lottery_option1, lottery_option2)             ; % place good and bad lottery randomly either left or right

    
% Active Bandit Instructions
DrawFormattedText(window,activeBandit1, 'center', 'center', white)          ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window,activeBandit2, 'center', 'center', white)          ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;


    for bandit_run = 1:(overall_trials / bandit_trials)


    % starting a new bandit
    DrawFormattedText(window,activeBanditShuffle, 'center', 'center', white);
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ;
        
        

    % actual loop
    for bandit_idx = 1:bandit_trials

        % drawing trialcounter
        trial_counter = strcat(num2str(bandit_idx),'/', num2str(bandit_trials)) ; % The bandit counter always shows current draw out of all draws within one game
        DrawFormattedText(window, trial_counter, 'center', 'center', white) ;
        Screen('Flip', window)                                              ;

        % drawing the fixcross
        Screen('DrawLines', window, fixCoords,...
            fixWidth, white, [xCenter yCenter], 2)                      ;

        WaitSecs(2)                                                         ; % show trial counter for 2 seconds
        Screen('Flip', window)                                              ; % then show fixcross

        % start decision process
        KbEventFlush                                                        ; % clear all keyboard events
        [picked_loc, reward_bool, rt] = require_response                    ;

        % drawing the fixcross
        Screen('DrawLines', window, fixCoords,...
            fixWidth, white, [xCenter yCenter], 2)                      ;

        % drawing the checkerboard stim at the chosen location. The reward_bool
        % tells us win(1) or loss(0) ... we add 1 so we get win=2, loss=1

        Screen('FillRect', window, reward(:,:,reward_bool+1),...
            rect_locs(:,:,picked_loc))                                      ;

        Screen('DrawTextures', window, masktexture, [],...
            mask_locs(:,:,picked_loc))                                      ;


    % even id, blue is win 
        activeBandit_mat(1,bandit_idx,bandit_run) = picked_loc                         ; % which location was picked: 1, left - 2, right
        activeBandit_mat(2,bandit_idx,bandit_run) = rt                                 ; % how quickly was it picked in ms
        activeBandit_mat(3,bandit_idx,bandit_run) = (good_lottery_loc == picked_loc)   ; % boolean whether good or bad lottery was chosen
        activeBandit_mat(4,bandit_idx,bandit_run) = reward_bool                        ; % boolean whether is was rewarded or not
        activeBandit_mat(5,bandit_idx,bandit_run) = (~mod(subj_id,2) + reward_bool)    ; % which color was the stim: 1: red ...  0/2: blue


        WaitSecs(1)                                                         ; % after choice, wait 1 sec before displaying result
        Screen('Flip', window)                                              ;
        WaitSecs(2)                                                         ; % feedback displayed for 2 secs

    end

    % Tell the subject how much she has earned
    payoff = sum(activeBandit_mat(4,:,bandit_run))                          ; % the overall payoff 
    payoff_str = strcat(activeBanditPayoff, num2str(payoff))                ;    
    DrawFormattedText(window, payoff_str, 'center', 'center', white)        ;
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ; % show payoff for 2 secs

    
    

    % Ask the subject, which lottery was better
    DrawFormattedText(window, BanditPrefLot, 'center', 'center', white)     ;
    Screen('Flip', window)                                                  ;



    % start decision process
    KbEventFlush                                                            ; % clear all keyboard events
    [picked_loc, ~, rt] = require_response                                  ;

    
    % Record timing and whether preferred lottery was correct
    activeBandit_prefLottery_mat(1,1,bandit_run) = picked_loc                       ; % Which lottery was preferred? 1=left, 2=right
    activeBandit_prefLottery_mat(2,1,bandit_run) = rt                               ; % rt to select preferred lottery
    activeBandit_prefLottery_mat(3,1,bandit_run) = picked_loc == good_lottery_loc   ; % boolean whether correct lottery was preferred
    
    
    
    end % end of bandit game loop

if condi_idx ~= 4
% Now there will be a short break before we go to the next
DrawFormattedText(window, breakText, 'center', 'center', white)             ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;
end

case 2
%% Passive Bandit

[left_lottery, right_lottery, good_lottery_loc] = ...
        determine_lottery_loc(lottery_option1, lottery_option2)             ; % place good and bad lottery randomly either left or right


% here we can save the data
% The data is saved per bandit run (3rd dimension)
passiveBandit_mat = nan(5,bandit_trials,(overall_trials / bandit_trials))   ; % for each bandit run, we have one 2D matrix ... each bandit run is one sheet(3D)

% Here we save the preferred lottery data --> which one is preferred
% (1=left, 2=right), is it the good one? (0/1), how quickly was it chosen
% (rt)
passiveBandit_prefLottery_mat = nan(3,1,(overall_trials/bandit_trials))     ; 

    

% Passive Bandit Instructions
DrawFormattedText(window,passiveBandit1, 'center', 'center', white)         ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window,passiveBandit2, 'center', 'center', white)         ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;


for bandit_run = 1:(overall_trials / bandit_trials)

    
    % starting a new bandit
    DrawFormattedText(window,passiveBanditShuffle,'center','center',white)  ;
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ;
        
        
        
    
    % actual loop
    for bandit_idx = 1:bandit_trials

        % drawing the trial counter
        trial_counter = strcat(num2str(bandit_idx),'/', num2str(bandit_trials)) ;
        DrawFormattedText(window, trial_counter, 'center', 'center', white) ;
        Screen('Flip', window)                                              ;

        % drawing the fixcross
        Screen('DrawLines', window, fixCoords,...
            fixWidth, white, [xCenter yCenter], 2)                      ;

        WaitSecs(2)                                                         ; % show trial counter for 2 seconds
        Screen('Flip', window)                                              ; % then show fixcross

        
        % Passive Bandit, so the computer decides
        picked_loc = randsample([2 1], 1)                                   ; % in the passive viewing, the computer draws randomly from a location: 1=left, 2=right

        if picked_loc == 1
            reward_bool = Sample(left_lottery);
        else
            reward_bool = Sample(right_lottery);
        end

        current_interval = 1 + rand                                         ; % wait for a randomly determined time to mimic some decision interval
        WaitSecs(current_interval)                                          ; 


        % drawing the fixcross
        Screen('DrawLines', window, fixCoords,...
            fixWidth, white, [xCenter yCenter], 2);

        % drawing the checkerboard stim at the chosen location. The reward_bool
        % tells us win(1) or loss(0) ... we add 1 so we get win=2, loss=1

        Screen('FillRect', window, reward(:,:,reward_bool+1),...
            rect_locs(:,:,picked_loc));

        Screen('DrawTextures', window, masktexture, [],...
            mask_locs(:,:,picked_loc));


    % even id, blue is win 
        passiveBandit_mat(1,bandit_idx, bandit_run) = picked_loc                            ; % which location was picked: 1, left - 2, right
        passiveBandit_mat(2,bandit_idx, bandit_run) = current_interval                      ; % no rt ... but how long was the mimic decision interval
        passiveBandit_mat(3,bandit_idx, bandit_run) = (good_lottery_loc == picked_loc)      ; % boolean whether good or bad lottery was chosen
        passiveBandit_mat(4,bandit_idx, bandit_run) = reward_bool                           ; % boolean whether is was rewarded or not
        passiveBandit_mat(5,bandit_idx, bandit_run) = (~mod(subj_id,2) + reward_bool)       ; % which color was the stim: 1: red ... 0 or 2: blue
        


        WaitSecs(1)                                                         ; % after choice, wait 1 sec before displaying result
        Screen('Flip', window)                                              ;

        WaitSecs(2)                                                         ; % feedback displayed for 2 secs

    end

    % Tell the subject how much she has earned
    payoff = sum(passiveBandit_mat(4,:,bandit_run))                         ; % the overall payoff
    payoff_str = strcat(passiveBanditPayoff, num2str(payoff))               ;
    DrawFormattedText(window, payoff_str, 'center', 'center', white)        ;
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ; % Display payoff for 2 secs

    % Ask the subject, which lottery was better
    DrawFormattedText(window, BanditPrefLot, 'center', 'center', white)     ;
    Screen('Flip', window)                                                  ;


    % start decision process
    KbEventFlush                                                            ; % clear all keyboard events
    [picked_loc, ~, rt] = require_response;

 
    % Record timing and whether preferred lottery was correct
    passiveBandit_prefLottery_mat(1,1,bandit_run) = picked_loc                       ; % Which lottery was preferred? 1=left, 2=right
    passiveBandit_prefLottery_mat(2,1,bandit_run) = rt                               ; % rt to select preferred lottery
    passiveBandit_prefLottery_mat(3,1,bandit_run) = picked_loc == good_lottery_loc   ; % boolean whether correct lottery was preferred
    
    
end % end of bandit game loop


if condi_idx ~= 4
% Now there will be a short break before we go to the next
DrawFormattedText(window, breakText, 'center', 'center', white)             ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;
end

case 3
%% Active DFE


% here we can save the data
activeDFE_mat = nan(6,overall_trials)                                       ;

% Here we save the preferred lottery data
activeDFE_prefLottery_mat = nan(6,1)                                        ; % we cannot preallocate exactly, but there will be at least ONE choice in DFE


% Active DFE Instructions
DrawFormattedText(window, activeDFE1, 'center', 'center', white)            ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, activeDFE2, 'center', 'center', white)            ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, activeDFE3, 'center', 'center', white)            ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, activeDFE4, 'center', 'center', white)            ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, activeDFE5, 'center', 'center', white)            ;
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
    DrawFormattedText(window, activeDFEShuffle, 'center', 'center', white)  ;
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
            [picked_loc] = require_response;
        
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
                [picked_loc, reward_bool, rt] = require_response;

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
    DrawFormattedText(window, DFEchoice, ...
        'center', 'center', white)                                          ;
    Screen('Flip', window)                                                  ;
    KbStrokeWait;
    % start decision process
    KbEventFlush                                                            ; % clear all keyboard events
    [picked_loc, reward_bool, rt] = require_response;

    % Prepare the feedback screen
    DrawFormattedText(window, DFEaddUrn, 'center', ...
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
    DrawFormattedText(window, DFEaddUrn, 'center', ...
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



DrawFormattedText(window, DFEfinalUrn1, 'center', 'center', white)          ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, DFEfinalUrn2, 'center', 'center', white)          ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, ...
    sprintf('You earned: %d', activeDFE_payoff_sum), ...
    'center', 'center', white)                                              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;   



if condi_idx ~= 4
% Now there will be a short break before we go to the next
DrawFormattedText(window, breakText, 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait                                                                ;
end                                                                         ;

case 4
%% Passive DFE

% here we can save the data --> response, mimiced decision interval by 
% computer, rewarded or not, color of stim, lottery_type that is at that 
% location, number of dfe run
passiveDFE_mat = nan(6,overall_trials); 

% Here we save the preferred lottery data --> which one is preferred
% (1=left, 2=right), is it the good one? (0/1), how quickly was it chosen
% (rt), was it rewarded or not? (0/1)
passiveDFE_prefLottery_mat = nan(6,1)                                       ; % we cannot preallocate exactly, but there will be at least ONE choice in DFE





% Passive DFE Instructions
DrawFormattedText(window, passiveDFE1, 'center', 'center', white)           ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, passiveDFE2, 'center', 'center', white)           ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, passiveDFE3, 'center', 'center', white)           ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, passiveDFE4, 'center', 'center', white)           ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, passiveDFE5, 'center', 'center', white)           ;
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
        DrawFormattedText(window, passiveDFEShuffle, 'center', ...
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
            [picked_loc] = require_response                                 ;

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
    DrawFormattedText(window, DFEchoice, 'center', 'center', white)         ;
    Screen('Flip', window)                                                  ;
    KbStrokeWait; 
    % start decision process
    KbEventFlush                                                            ; % clear all keyboard events
    [picked_loc, reward_bool, rt] = require_response;

    % Prepare a feedback screen
    DrawFormattedText(window, DFEaddUrn, 'center', ...
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
    DrawFormattedText(window, DFEaddUrn, 'center', ...
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

DrawFormattedText(window, DFEfinalUrn1, 'center', 'center', white)          ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ; 

DrawFormattedText(window, DFEfinalUrn2, 'center', 'center', white)          ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, sprintf('You earned: %d', passiveDFE_payoff_sum), ...
    'center', 'center', white)                                              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;



if condi_idx ~= 4
% Now there will be a short break before we go to the next
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


DrawFormattedText(window, ending,'center', 'center', white)                 ;

Screen('Flip', window)                                                      ;


% Wait for a key press to close the window and clear the screen
KbStrokeWait                                                                ;

% Get time of end of the experiment
experiment_end = datestr(now)                                               ; % ... it's good to know the time when the experiment ended

sca                                                                         ;


%% Saving all the data


% data 'readme' cells for quick reference in data analysis part

DFE_Readme = cell(7,1);
DFE_Readme(1,1) = cellstr('row1: which location was picked? 1=left 2=right');
DFE_Readme(2,1) = cellstr('row2: how quickly was it picked in ms? (for passive DFE: how long was the jitter)');
DFE_Readme(3,1) = cellstr('row3: was it rewarded? 0=no, 1=yes');
DFE_Readme(4,1) = cellstr('row4: was the good lottery chosen? 0=no, 1=yes') ;
DFE_Readme(5,1) = cellstr('row5: which color was the stim? 1=red, 0/2=blue');
DFE_Readme(6,1) = cellstr('row6: what is the current run in DFE? (sample-run or choice-run respectively');
DFE_Readme(7,1) = cellstr('*Additional INFO*: the "payoff" array describes the four final draws from the reward urn');


% In Bandit, we do not have a feedback for the last 'draw' of indicating
% your preferred lottery. Thus, there are two cells less in the choice
% Bandit (whether feedback was rewarded, and which color it had) compared
% to the sample bandit.
% Furthermore, the Bandit data structure has separate bandit runs encoded
% in the 3rd dimension, whereas the DFE data structure does this in 2D
Bandit_Readme = cell(6,1);
Bandit_Readme(1,1) = cellstr('row1: which location was picked? 1=left 2=right');
Bandit_Readme(2,1) = cellstr('row2: how quickly was it picked in ms? (for passive Bandit: how long was the jitter)');
Bandit_Readme(3,1) = cellstr('row3: was the good lottery chosen? 0=no, 1=yes');
Bandit_Readme(4,1) = cellstr('row4: *Only for sample*: was it rewarded? 0=no, 1=yes');
Bandit_Readme(5,1) = cellstr('row5: *Only for sample*: which color was the stim? 1=red, 0/2=blue');
Bandit_Readme(6,1) = cellstr('*Additional INFO*: separate bandit runs are encoded in the 3rd dimension of the data structure');


% one data structure with every game type as a nested structure, which then
% contains the data

activeDFE.sampleData = activeDFE_mat                                        ;
activeDFE.choiceData = activeDFE_prefLottery_mat                            ;
activeDFE.payoff = activeDFE_payoff                                         ;
activeDFE.readme = DFE_Readme                                               ;

passiveDFE.sampleData = passiveDFE_mat                                      ;
passiveDFE.choiceData = passiveDFE_prefLottery_mat                          ;
passiveDFE.payoff = passiveDFE_payoff                                       ;
passiveDFE.readme = DFE_Readme                                              ;

activeBandit.sampleData = activeBandit_mat                                  ;
activeBandit.choiceData = activeBandit_prefLottery_mat                      ;
activeBandit.readme = Bandit_Readme                                         ;

passiveBandit.sampleData = passiveBandit_mat                                ;
passiveBandit.choiceData = passiveBandit_prefLottery_mat                    ;
passiveBandit.readme = Bandit_Readme                                        ;

experimentalVars.expStart = experiment_start                                ;
experimentalVars.expEnd = experiment_end                                    ;
experimentalVars.subj_id = subj_id                                          ;

data.activeDFE = activeDFE                                                  ;
data.passiveDFE = passiveDFE                                                ;
data.activeBandit = activeBandit                                            ;
data.passiveBandit = passiveBandit                                          ;
data.experimentalVars = experimentalVars                                    ;        %#ok ... need to suppress linter here, because it doesn't recognize the 'save' call

% Save all the data with an appropriate file name (the subject id)

data_dir = fullfile(pwd, 'DFE_Bandit_data');
fname = fullfile(data_dir, strcat('subj_', sprintf('%03d', subj_id), ...
    '.mat'))                                                                ;

% be careful not to overwrite data
if exist(data_dir, 'dir') == 7                                              % check if we already have our data dir 

    if exist(fname, 'file') == 2                                            % check if a file with the same name erroneously exists
        warning(strcat('The filename already exists. Saving as 666.', ...
            ' Check immediately after the experiment'))                     % in that case ... warning
        fname(end-6:end-4) = num2str(666)                                   ; % and save our data as id 666 ... to be checked immediately
        save(fname, 'data')
    else
        save(fname, 'data')                                                 % else, just save it
    end
    
else
    mkdir(data_dir)                                                         % if data dir doesn't exist, make it
    save(fname, 'data')                                                     % and save the data there
end
    


end % function end
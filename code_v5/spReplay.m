function [SPdistrMat, SPdistrInsertMat] = spReplay(sampleMat, choiceMat, questionMat, winStim, ID)

% Implements a replay of a sampling paradigm performed earlier as descibed
% in the documentation.
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
% 
% [SPdistrMat, SPdistrInsertMat] = spReplay(sampleMat, choiceMat, questionMat, winStim, ID)
%
% IN:
% - sampleMat: Data for how to behave during sampling
% - choiceMat: How to behave during choice
% - questionMat: For each trial, which to pick: sample or choice
% - winStim: Color of winning stimulus. Either 'blue' or 'red'.
% - ID: the ID of the subject. A three digit number.
%
% OUT:
% - SPdistrsMat: RTs to the distractor trials that happened during the replay
% - SPdistrInsertMat: a 1Xtrials matrix of zeros. 1s, where distr was
% inserted

%% Function start


if nargin ~= 5, error('Check the function inputs!'), end

% Default settings for Psychtoolbox
PsychDefaultSetup(2); 

% Screen management: Get all available screens ordered from 0 to i. Take
% the max of screens to draw to external screen.
screens = Screen('Screens');
screenNumber = max(screens);

% Define white as an RGB tuple.
white = WhiteIndex(screenNumber);

% Open an on screen window and get its size and center in pixels. Set the
% standard background to white/2, which is grey.
[window, windowRect] = PsychImaging('OpenWindow',screenNumber,white/2);
[~,screenYpixels] = Screen('WindowSize',window);
[xCenter,yCenter] = RectCenter(windowRect);

% Make transparency possible with RGBA tuples and for textures. A=0 means
% transparent, A=1 means opaque .
Screen('BlendFunction',window,'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA'); 

% Defaults for drawing text on the screen. Pick a font that's available
% everywhere. For style, note that 0=normal,1=bold,2=italic,4=underline.
Screen('TextFont',window,'Verdana');
Screen('TextSize',window,25);
Screen('TextStyle',window,0);

% Retreive the maximum priority number and set priority level once for the
% whole script.
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% Set Verbosity level to very low to speed up PTB. This makes only sense
% once the code has been thoroughly tested.
% Screen('Preference', 'Verbosity', 0);

HideCursor;

%-------------------------------------------------------------------------%
%           Preparing all Stimuli and Experimental Information            %
%-------------------------------------------------------------------------%

% All Psychtoolbox stimuli
Stims = ptbStims(window, windowRect, screenNumber)          ; % separate function for the stim creation to avoid clutter


% Drawing the text options for sample vs choice decision      
textwin1 = [screenXpixels*0.1,screenYpixels*0.5,screenXpixels*0.4, ...
    screenYpixels*0.5]                                                       ; % windows to center the formatted text in
textwin2 = [screenXpixels*0.6,screenYpixels*0.5,screenXpixels*0.9, ...
    screenYpixels*0.5]                                                       ; % arguments are: left top right bottom


% All presentation texts
texts = containers.Map                                                      ;
texts('shuffled') = sprintf('The lotteries have been shuffled.')            ;
texts('payoff') = sprintf('You earned: ')                                   ;
texts('end') = sprintf(['This task is done.\n\nThank you so far!\n\n\n',...
    'Press a key to close.'])                                               ;
texts('aSPchoice') = sprintf(['From which lottery do\nyou want to draw',...
    'your payoff?\nPress [left] or [right]'])                               ;
texts('aSPfinal') = sprintf(['You have reached the final\ntrial. You', ...
    'are granted one\nlast choice towards your payoff.\nPress any key.'])   ;

% define winning stimulus
if strcmp(winStim, 'blue')
    reward = cat(3, Stims.colors1, Stims.colors2, Stims.colors3)                              ; % blue is win Stim ... red as loss. Stims.colors3(green) is the distractor condition
elseif strcmp(winStim, 'red') 
    reward = cat(3, Stims.colors2, Stims.colors1, Stims.colors3)                              ; % red is win Stim ... blue as loss. Stims.colors3(green) is the distractor condition
else
    sca;
    error('check the function inputs!')
end

% Probability of a distractor replacing a previous outcome
pDistr = 0.2                                                                ;

% Keyboard information
spaceKey = KbName('space')                                                  ; % detect distractor

% Timings in seconds
tShowShuffled = 1                                                           ; % the time after the participants are being told that lotteries have been shuffled
tShowTrialCount = 0                                                         ; % time that the trial counter is shown
tDelayFeedback = 1                                                          ; % time after a choice before outcome is presented
tShowFeedback = 1                                                           ; % time that the feedback is displayed
tShowPayoff = 1                                                             ; % time that the payoff is shown
tShowChosenOpt = 0.75                                                       ; % time that the chosen option during the question will be shown

% Variables we get from our input matrices
nTrials = size(sampleMat,2)                                                 ;

% Indices for the loops and assigning data to their places within matrices
trlCount = nTrials                                                          ; % A trial counter that will be counted down during the while loop
sampIdx = 1                                                                ; % Assign data a place within sampleMat
choiIdx = 1                                                                ; % Assign data a place within choiceMat
quesIdx = 1;

% Shuffle the random number generator
rng('shuffle')                                                              ;

% For saving the RTs to distractors
SPdistrMat = nan(1,nTrials)                                                 ;
distrIdx = 1                                                                ; % Running index to put RTs into SPdistrMat
SPdistrInsertMat = zeros(1,nTrials)                                         ; % A 1 will be put, where a distractor was inserted


% EEG markers
mrkShuffle  = 1                                                             ; % Onset of lotteries have been shuffled screen at the beginning of one game
mrkFixOnset = 2                                                             ; % Onset of fixation cross during new trial
mrkDistr    = 3                                                             ; % Button press upon detection of a distractor
mrkFeedback = 4                                                             ; % Onset of feedback presentation
mrkPayoff   = 5                                                             ; % Onset of payoff presentation at the end of one game
mrkPrefLot  = 6                                                             ; % Onset of the question, which lottery was preferred

mrkResult   = 8                                                             ; % Feedback on the choice of preferred lottery
mrkQuestion = 9                                                             ; % Question whether to continue sampling or start choosing
mrkAnswer   = 10                                                            ; % Show of selected answer to question


% set up the parallel port
config_io                                                                   ; % The io64 module, see documentation

% Parallel port address
ppAddress = hex2dec('D050')                                                 ; % do the hex2dec only once, because it is a slow function

%% Do the experimental flow

vbl = Screen('Flip', window)                                                ; % Get initial system time

while trlCount > 0

    % Inform about shuffled lotteries. But no need to actually shuffle anything
    Screen('TextSize',window,50)                                                ; % If we draw text, make font a bit bigger
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white)      ; % The text is taken from our texts container created in the beginning
    vbl = Screen('Flip',window,vbl+tShowPayoff+rand/2)                          ; % Show that lotteries have been shuffled

    % Write EEG Marker --> lotteries have been shuffled
    outp(ppAddress,mrkShuffle); WaitSecs(0.010)                                 ;
    outp(ppAddress,0)         ; WaitSecs(0.001)                                 ;

    Screen('TextSize',window,25)                                                ; % Don't forget to reset the font


    for trial=1:trlCount

         % Drawing trial counter
        trialCounter = sprintf('%d', sampIdx)                                      ; % Current trial 
        DrawFormattedText(window, trialCounter, 'center', screenYpixels*0.45, white) ; % Trial counter is presented at the top of the screen
        if trial==1
            vbl = Screen('Flip',window,vbl+tShowShuffled+rand/2)                    ; % draw it on an otherwise grey screen ... waiting for fixcross
        else
            vbl = Screen('Flip',window,vbl+tShowChosenOpt+rand/2)                   ; % draw it on an otherwise grey screen ... waiting for fixcross
        end




        % Fixation cross & choice selection
        DrawFormattedText(window, trialCounter, 'center', screenYpixels*0.45, white) ; % Redraw trial counter
        Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth,white,[xCenter yCenter],2)     ; % Draw fixcross
        vbl = Screen('Flip',window,vbl+tShowTrialCount+rand/2)                      ; % Show fixcross

        % Write EEG Marker --> Fixation cross onset, expect a response
        outp(ppAddress,mrkFixOnset); WaitSecs(0.010)                                ;
        outp(ppAddress,0)          ; WaitSecs(0.001)                                ;

        pickedLoc   = sampleMat(1,sampIdx)                                         ; % decide and see outcomes exactly as in recorded game
        rt          = sampleMat(2,sampIdx)                                         ;
        rewardBool  = sampleMat(4,sampIdx)                                         ;
        sampIdx    = sampIdx+1                                                    ;

        if rt <3
            tWait = rt                                                              ; % wait the actual reaction time    
        else
            tWait = 1+rand/2                                                        ; % unless it was unreasonably long ... then replace it
        end


        % Feedback & possibly distractor
        if rand <= pDistr
           rewardBool = 2                                                           ; % On pDistr of all trials, replace the reward with a distractor
        end

        DrawFormattedText(window, trialCounter, 'center', screenYpixels*0.45, white) ; % Redraw trial counter
        Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth,white,[xCenter yCenter],2)     ; % Redraw fixcross
        Screen('FillRect',window,reward(:,:,rewardBool+1),Stims.rectLocs(:,:,pickedLoc))  ; % Draw checkerboard at chosen location. Reward tells us the color                      
        Screen('DrawTextures',window,Stims.maskTexture,[],Stims.maskLocs(:,:,pickedLoc))        ;                                
        [vbl, stimOnset] = Screen('Flip',window,vbl+tWait+tDelayFeedback+rand/2)    ; % Show feedback

        % Write EEG Marker --> the feedback is presented
        outp(ppAddress,mrkFeedback); WaitSecs(0.010)                                ;
        outp(ppAddress,0)          ; WaitSecs(0.001)                                ;

        if rewardBool == 2
            % If a distractor occurred, measure the RT to it
            respToBeMade = true                                                     ; % condition for while loop
            while respToBeMade            
            [~,tEnd,keyCode] = KbCheck                                              ; % PTB inquiry to keyboard including time when button is pressed
                if keyCode(spaceKey)
                    % Write EEG Marker --> button press, a distractor was seen
                    outp(ppAddress,mrkDistr); WaitSecs(0.010)                       ;
                    outp(ppAddress,0)       ; WaitSecs(0.001)                       ;            
                    rt = tEnd - stimOnset                                           ; % Measure timing
                    respToBeMade = false                                            ; % stop checking
                end
            end
            SPdistrMat(distrIdx) = rt                                               ;
            SPdistrInsertMat(trial) = 1                                             ; % insert trial, where a distractor occurred
            tWait = SPdistrMat(distrIdx) + rand/2                                   ;
            distrIdx = distrIdx + 1                                                 ;
        else
            tWait = tShowFeedback+rand/2                                            ; % Else, just display the feedback for a bit
        end

        % Check, whether there are more trials remaining. If not, no need to ask
        % whether to continue to sample or make a choice. Then it will be only
        % choice.
        if sampIdx > nTrials
            Screen('TextSize',window,50)                                            ; % If we draw text, make font a bit bigger
            DrawFormattedText(window, texts('aSPfinal'), 'center', ...
                'center',white)                                                     ; % If the last trial has been reached, tell the subject so
            vbl = Screen('Flip',window,vbl+tWait)                                   ;
            WaitSecs(1+rand/2)                                                      ;
            break                                                                   ; % no more trials available ... the same as choosing "choice" 
        else    
            % Decision process whether to continue to sample or make a choice    
            Screen('TextSize',window,50)                                            ; % If we draw text, make font a bit bigger
            DrawFormattedText(window,'Do you want to','center', ...
                .25*screenYpixels,white)                                            ;                       
            DrawFormattedText(window,'draw another sample','center', ...
                'center',white, ...
                [], [], [], [], [], textwin1)                                       ;
            DrawFormattedText(window,'make a choice','center','center', ...
                white,[], [], [], [], [], textwin2)                                 ;
            vbl = Screen('Flip',window,vbl+tWait)                                   ;    

            % Write EEG Marker --> Question whether to continue sampling or choose
            outp(ppAddress,mrkQuestion); WaitSecs(0.010)                            ;
            outp(ppAddress,0)          ; WaitSecs(0.001)                            ;    

            rt          = questionMat(1,quesIdx)                                   ;
            pickedLoc   = questionMat(2,quesIdx)                                   ;
            quesIdx    = quesIdx+1                                                ;

            if rt <3
                tWait = rt                                                          ; % wait the actual reaction time    
            else
                tWait = 1+rand/2                                                    ; % unless it was unreasonably long ... then replace it
            end


            if pickedLoc == 1
                DrawFormattedText(window,'draw another sample','center', ...
                    'center',white, [], [], [], [], [],textwin1)                    ; % Pick sampling
                vbl = Screen('Flip',window,vbl+tWait*1.1)                           ;
                % Write EEG Marker --> Selection screen of answer to question
                outp(ppAddress,mrkAnswer); WaitSecs(0.010)                          ;
                outp(ppAddress,0)        ; WaitSecs(0.001)                          ;       
                Screen('TextSize',window,25)                                        ; % Reset font size

            elseif pickedLoc == 2
                DrawFormattedText(window,'make a choice','center','center', ...
                    white,[], [], [], [], [],textwin2)                              ; % Pick choice
                vbl = Screen('Flip',window,vbl+tWait*1.1)                           ; 
                % Write EEG Marker --> Selection screen of answer to question
                outp(ppAddress,mrkAnswer); WaitSecs(0.010)                          ;
                outp(ppAddress,0)        ; WaitSecs(0.001)                          ;               
                break                                                               ; % The subject selected "choice", so we break the sampling loop and enter the choice loop
            end
        end


    end % end of sampling loop


    % Update trial counter ... if it becomes zero, we are done
    trlCount = trlCount - trial                                                 ; % Deduct the number of trials from overall remaining trials

    % Let the participant make a choice
    DrawFormattedText(window,texts('aSPchoice'),'center','center',white)        ; % Prompt for making a choice [left] or [right]
    vbl = Screen('Flip',window,vbl+tShowChosenOpt+rand/2)                       ; % Print it to the screen

    % Write EEG Marker --> the preferred lottery is being inquired
    outp(ppAddress,mrkPrefLot); WaitSecs(0.010)                                 ;
    outp(ppAddress,0)         ; WaitSecs(0.001)                                 ;

    Screen('TextSize',window,25)                                                ; % After a lot of text, don't forget to reset font size


    Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth,white,[xCenter yCenter],2)     ; % After pick, show fixation cross    
    Screen('DrawingFinished', window)                                           ; % This can speed up PTB while we do some other stuff before flipping the screen

    pickedLoc   = choiceMat(1,choiIdx)                                         ;
    rt          = choiceMat(2,choiIdx)                                         ;
    rewardBool  = choiceMat(4,choiIdx)                                         ;
    choiIdx    = choiIdx+1                                                    ;

    if rt <3
        tWait = rt                                                              ; % wait the actual reaction time    
    else
        tWait = 1+rand/2                                                        ; % unless it was unreasonably long ... then replace it
    end

    vbl = Screen('Flip',window,vbl+tWait*1.1)                                   ;


    % Feedback
    Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth,white,[xCenter yCenter],2)     ; % Redraw fixcross
    Screen('FillRect',window,reward(:,:,rewardBool+1),Stims.rectLocs(:,:,pickedLoc))  ; % Drawing the checkerboard stim at the chosen location. The reward_bool % tells us win(1) or loss(0) ... we add 1 so we get win=2, loss=1
    Screen('DrawTextures',window,Stims.maskTexture,[],Stims.maskLocs(:,:,pickedLoc))        ;
    vbl = Screen('Flip',window,vbl+tDelayFeedback+rand/2)                       ;

    % Write EEG Marker --> Result of the choice process is presented
    outp(ppAddress,mrkResult); WaitSecs(0.010)                                  ;
    outp(ppAddress,0)        ; WaitSecs(0.001)                                  ;


    % Tell the subject how much she has earned 
    Screen('TextSize',window,50)                                                ; % Make font size bigger for text
    payoff = rewardBool                                                         ; % The subject earned as much as the reward bool of the choice outcome indicated
    payoffStr = strcat(texts('payoff'), sprintf(' %d',payoff))                  ;
    DrawFormattedText(window,payoffStr,'center','center',white)                 ;
    vbl = Screen('Flip',window,vbl+tShowFeedback+rand/2)                        ;

    % Write EEG Marker --> the payoff is shown
    outp(ppAddress,mrkPayoff); WaitSecs(0.010)                                  ;
    outp(ppAddress,0)        ; WaitSecs(0.001)                                  ;

    Screen('TextSize',window,25)                                                ; % Reset font size



end % end of choice loop (while loop)



% Save the RT data to the distractors
SPdistrMat(isnan(SPdistrMat)) = []                                          ; % Drop those preallocated spaces we didn't fill
dataDir = fullfile(pwd)                                                    ; % Puts the data where the script is
curTime = datestr(now,'dd_mm_yyyy_HH_MM_SS')                               ; % the current time and date                                          
fname = fullfile(dataDir,strcat('spReplay_subj_', ...
    sprintf('%03d_',ID),curTime))                                          ; % fname consists of subj_id and datetime to avoid overwriting files
save(fname, 'SPdistrMat', 'SPdistrInsertMat')                               ; % save it!

% Time for a break :-)
Screen('TextSize',window,50)                                                ; % If we draw text, make font a bit bigger
DrawFormattedText(window,texts('end'),'center','center',white)              ; % Some nice words
Screen('Flip',window,vbl+tShowPayoff+rand/2)                                ;
KbStrokeWait                                                                ;
Priority(0)                                                                 ; % Reset priority level to 0
ShowCursor                                                                  ;
sca                                                                         ;


%% Function end
end
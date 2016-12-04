function [sampleMat, choiceMat, questionMat] = sp(nTrials, winStim, ID)

% Implements the sampling paradigm as descibed in the documentation.
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
% 
% [sampleMat, choiceMat] = sp(nTrials, winStim, ID)
%
% IN:
% - nTrials: Number of trials within a game.
% - winStim: Color of winning stimulus. Either 'blue' or 'red'.
% - ID: the ID of the subject. A three digit number.
%
% OUT:
% - sampleMat: data for each sampling round
% - choiceMat: data for each choice round
% - questionMat: data about decision for each question "sample or choice"

%% Function start

if nargin ~= 3, error('Check the function inputs!'), end

PsychDefaultSetup(2)                                                        ; % default settings for Psychtoolbox


% Screen Management
screens = Screen('Screens')                                                 ; % get all available screens ordered from 0 (native screen of laptop) to i
screenNumber = max(screens)                                                 ; % take max of screens to draw to external screen.

% Define white/black/grey
white = WhiteIndex(screenNumber)                                            ; % This function returns an RGB tuble for 'white' = [1 1 1]

% Open an on screen window and get its size and center
[window, windowRect] = PsychImaging('OpenWindow',screenNumber,white/2)      ; % our standard background will be grey
[screenXpixels,screenYpixels] = Screen('WindowSize',window)                 ; % getting the dimensions of the screen in pixels
[xCenter,yCenter] = RectCenter(windowRect)                                  ; % getting the center of the screen

% for making transparency possible in RGBA tuples and for textures
Screen('BlendFunction',window,'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA')      ; % transparency is determined in RGBA tuples with each value [0,1], where A=0 means transparent, A=1 means opaque 

% Defaults for drawing text on the screen
Screen('TextFont',window,'Verdana')                                         ; % Pick a font that's available everywhere ...
Screen('TextSize',window,25)                                                ;
Screen('TextStyle',window,0)                                                ; %0=normal,1=bold,2=italic,4=underline

% Retreive the maximum priority number
topPriorityLevel = MaxPriority(window)                                      ;
Priority(topPriorityLevel)                                                  ; % Set priority level once for the whole script

% Set Verbosity level to very low.
% Screen('Preference', 'Verbosity', 0)                                      ; % makes only sense, once this code is thoroughly tested

HideCursor                                                                  ; % Hide the cursor

%-------------------------------------------------------------------------%
%           Preparing all Stimuli and Experimental Information            %
%-------------------------------------------------------------------------%

% All Psychtoolbox stimuli
[fixWidth, fixCoords, colors1, colors2, colors3, rectLocs, maskLocs, ...
    maskTexture] = produce_stims(window, windowRect, screenNumber)          ; % separate function for the stim creation to avoid clutter


% Drawing the text options for sample vs choice decision      
textwin1 = [screenXpixels*.1,screenYpixels*.5,screenXpixels*.4, ...
    screenYpixels*.5]                                                       ; % windows to center the formatted text in
textwin2 = [screenXpixels*.6,screenYpixels*.5,screenXpixels*.9, ...
    screenYpixels*.5]                                                       ; % arguments are: left top right bottom


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
    reward = cat(3, colors1, colors2, colors3)                              ; % blue is win Stim ... red as loss. colors3(green) is the distractor condition
elseif strcmp(winStim, 'red') 
    reward = cat(3, colors2, colors1, colors3)                              ; % red is win Stim ... blue as loss. colors3(green) is the distractor condition
else
    sca                                                                     ;
    error('check the function inputs!')
end

% Create some lotteries - these are stable and hardcoded across the study
lotteryOption1 = [ones(1,7), zeros(1,3)]                                    ; % p(win)=.7 --> good lottery
lotteryOption2 = [ones(1,3), zeros(1,7)]                                    ; % p(win)=.3 --> bad lottery

% Keyboard information
leftKey = KbName('LeftArrow')                                               ; % choose left lottery
rightKey = KbName('RightArrow')                                             ; % choose right lottery

% Timings in seconds
tShowShuffled = 1                                                           ; % the time after the participants are being told that lotteries have been shuffled
tShowTrialCount = 0                                                         ; % time that the trial counter is shown
tDelayFeedback = 1                                                          ; % time after a choice before outcome is presented
tShowFeedback = 1                                                           ; % time that the feedback is displayed
tShowPayoff = 1                                                             ; % time that the payoff is shown
tShowChosenOpt = 0.75                                                       ; % time that the chosen option during the question will be shown

% Indices for the loops and assigning data to their places within matrices
trlCount = nTrials                                                          ; % A trial counter that will be counted down during the while loop
samp_idx = 1                                                                ; % Assign data a place within sampleMat
choi_idx = 1                                                                ; % Assign data a place within choiceMat
ques_idx = 1                                                                ;

% Shuffle the random number generator
rng('shuffle')                                                              ;

% Matrices for saving the data. For sampling loop, choice loop, questions
sampleMat = nan(4,nTrials)                                                  ; % So far just a placeholder. For the meaning of each row, column, ans sheet, see below.
choiceMat = nan(4,nTrials)                                                  ; % Cannot preallocate choices exactly, so drop unnecessary NANs later.
questionMat = nan(2,nTrials-1)                                              ; % Save the decision in the questions. For last trial, there won't be a question, CHOICE will be forced. Thus nTrails-1 as dim.


% EEG markers
mrkShuffle  = 1                                                             ; % Onset of lotteries have been shuffled screen at the beginning of one game
mrkFixOnset = 2                                                             ; % Onset of fixation cross during new trial
mrkSample   = 3                                                             ; % Button press upon choice of a lottery
mrkFeedback = 4                                                             ; % Onset of feedback presentation
mrkPayoff   = 5                                                             ; % Onset of payoff presentation at the end of one game
mrkPrefLot  = 6                                                             ; % Onset of the question, which lottery was preferred
mrkChoice   = 7                                                             ; % Button press upon selection of the preferred lottery
mrkResult   = 8                                                             ; % Feedback on the choice of preferred lottery
mrkQuestion = 9                                                             ; % Question whether to continue sampling or start choosing
mrkAnswer   = 10                                                            ; % Show of selected answer to question


% set up the parallel port
config_io                                                                   ; % The io64 module, see documentation

% Parallel port address
ppAddress = hex2dec('D050')                                                 ; % do the hex2dec only once, because it is a slow function

% "Warming up" (i.e., loading into memory) before timing becomes crucial
outp(ppAddress, 0)                                                          ; 
Sample(1)                                                                   ;
randi(1)                                                                    ;
KbCheck                                                                     ; 
num2str(1)                                                                  ; 
WaitSecs(0)                                                                 ;
strcat('warm', 'up')                                                        ;
rand                                                                        ;
sum(1)                                                                      ;
sprintf('warm up')                                                          ; 

%% Do the experimental flow

vbl = Screen('Flip', window)                                                ; % Get initial system time

while trlCount > 0


% Shuffle the lotteries & inform about it
goodLotteryLoc = randi(2,1)                                                 ; % determine whether good lottery will be left(1) or right(2)
if goodLotteryLoc == 1
    leftLottery = lotteryOption1                                            ; % Note: lotteryOption1 is always the better one
    rightLottery = lotteryOption2                                           ; % Note2: lotteryOption2 is always the worse one
else
    leftLottery = lotteryOption2                                            ;
    rightLottery = lotteryOption1                                           ;
end

Screen('TextSize',window,50)                                                ; % If we draw text, make font a bit bigger
DrawFormattedText(window,texts('shuffled'), 'center', 'center', white)      ; % The text is taken from our texts container created in the beginning
vbl = Screen('Flip',window,vbl+tShowPayoff+rand/2)                          ; % Show that lotteries have been shuffled

% Write EEG Marker --> lotteries have been shuffled
outp(ppAddress,mrkShuffle); WaitSecs(0.010)                                 ;
outp(ppAddress,0)         ; WaitSecs(0.001)                                 ;

Screen('TextSize',window,25)                                                ; % Don't forget to reset the font

for trial=1:trlCount

% Drawing trial counter
trialCounter = sprintf('%d', samp_idx)                                      ; % Current trial 
DrawFormattedText(window, trialCounter, 'center', screenYpixels*.45, white) ; % Trial counter is presented at the top of the screen
if trial==1
    vbl = Screen('Flip',window,vbl+tShowShuffled+rand/2)                    ; % draw it on an otherwise grey screen ... waiting for fixcross
else
    vbl = Screen('Flip',window,vbl+tShowChosenOpt+rand/2)                   ; % draw it on an otherwise grey screen ... waiting for fixcross
end


% Fixation cross & choice selection
DrawFormattedText(window, trialCounter, 'center', screenYpixels*.45, white) ; % Redraw trial counter
Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % Draw fixcross
[vbl, stimOnset] = Screen('Flip',window,vbl+tShowTrialCount+rand/2)         ; % Show fixcross

% Write EEG Marker --> Fixation cross onset, expect a response
outp(ppAddress,mrkFixOnset); WaitSecs(0.010)                                ;
outp(ppAddress,0)          ; WaitSecs(0.001)                                ;

% Inquire response
respToBeMade = true                                                         ; % condition for while loop
while respToBeMade            
    [~,tEnd,keyCode] = KbCheck                                              ; % PTB inquiry to keyboard including time when button is pressed
        if keyCode(leftKey)
            % Write EEG Marker --> button press, a choice has been made
            outp(ppAddress,mrkSample); WaitSecs(0.010)                      ;
            outp(ppAddress,0)        ; WaitSecs(0.001)                      ;
            rt = tEnd - stimOnset                                           ; % Measure timing
            rewardBool = Sample(leftLottery)                                ; % drawing either a 0(loss) or a 1(win)
            pickedLoc = 1                                                   ; % 1 for left
            respToBeMade = false                                            ; % stop checking now
        elseif keyCode(rightKey)
            % Write EEG Marker --> button press, a choice has been made
            outp(ppAddress,mrkSample); WaitSecs(0.010)                      ;
            outp(ppAddress,0)        ; WaitSecs(0.001)                      ;
            rt = tEnd - stimOnset                                           ; % Measure timing
            rewardBool = Sample(rightLottery)                               ; 
            pickedLoc = 2                                                   ; % 2 for right
            respToBeMade = false                                            ;            
        end
end



% Feedback
DrawFormattedText(window, trialCounter, 'center', screenYpixels*.45, white) ; % Redraw trial counter
Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % Redraw fixcross
Screen('FillRect',window,reward(:,:,rewardBool+1),rectLocs(:,:,pickedLoc))  ; % Draw checkerboard at chosen location. Reward tells us the color                      
Screen('DrawTextures',window,maskTexture,[],maskLocs(:,:,pickedLoc),[],0)   ;                                
Screen('DrawingFinished', window)                                           ; % This can speed up PTB while we do some other stuff before flipping the screen

sampleMat(1,samp_idx) = pickedLoc                                           ;
sampleMat(2,samp_idx) = rt                                                  ;
sampleMat(3,samp_idx) = (pickedLoc==goodLotteryLoc)                         ;
sampleMat(4,samp_idx) = rewardBool                                          ;
samp_idx              = samp_idx+1                                          ;


vbl = Screen('Flip',window,vbl+tDelayFeedback+rand/2+rt)                    ; % Show feedback

% Write EEG Marker --> the feedback is presented
outp(ppAddress,mrkFeedback); WaitSecs(0.010)                                ;
outp(ppAddress,0)          ; WaitSecs(0.001)                                ;

% Check, whether there are more trials remaining. If not, no need to ask
% whether to continue to sample or make a choice. Then it will be only
% choice.
if samp_idx > nTrials
    Screen('TextSize',window,50)                                            ; % If we draw text, make font a bit bigger
    DrawFormattedText(window, texts('aSPfinal'), 'center', ...
        'center',white)                                                     ; % If the last trial has been reached, tell the subject so
    vbl = Screen('Flip',window,vbl+tShowFeedback+rand/2)                    ;
    KbStrokeWait                                                            ;
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
    [vbl, stimOnset] = Screen('Flip',window,vbl+tShowFeedback+rand/2)                                                  ;    

    % Write EEG Marker --> Question whether to continue sampling or choose
    outp(ppAddress,mrkQuestion); WaitSecs(0.010)                            ;
    outp(ppAddress,0)          ; WaitSecs(0.001)                            ;
    

    % Inquire about the answer
    respToBeMade = true                                                     ; % condition for while loop
    while respToBeMade            
        [~,tEnd,keyCode] = KbCheck                                          ; % PTB inquiry to keyboard including time when button is pressed
            if keyCode(leftKey)
                rt = tEnd - stimOnset                                       ; % Measure timing
                pickedLoc = 1                                               ; % 1 for left
                respToBeMade = false                                        ; % stop checking now
            elseif keyCode(rightKey)
                rt = tEnd - stimOnset                                       ; % Measure timing
                pickedLoc = 2                                               ; % 2 for right
                respToBeMade = false                                        ;            
            end
    end

    
    questionMat(1,ques_idx) = rt                                            ; % How quickly did the participant choose whether to sample or make a choice.
    questionMat(2,ques_idx) = pickedLoc                                     ; % What did the participant choose?
    ques_idx = ques_idx+1                                                   ; % Increment question index to be ready for next question    
    

    if pickedLoc == 1
        DrawFormattedText(window,'draw another sample','center', ...
            'center',white, [], [], [], [], [],textwin1)                    ; % Pick sampling
        vbl = Screen('Flip',window,vbl+rt*1.1)                              ;
        % Write EEG Marker --> Selection screen of answer to question
        outp(ppAddress,mrkAnswer); WaitSecs(0.010)                          ;
        outp(ppAddress,0)        ; WaitSecs(0.001)                          ;
        Screen('TextSize',window,25)                                        ; % Reset font size
 
    elseif pickedLoc == 2
        DrawFormattedText(window,'make a choice','center','center', ...
            white,[], [], [], [], [],textwin2)                              ; % Pick choice
        vbl = Screen('Flip',window,vbl+rt*1.1)                              ;    
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
[vbl, stimOnset] = Screen('Flip',window,vbl+tShowChosenOpt+rand/2)          ; % Print it to the screen

% Write EEG Marker --> the preferred lottery is being inquired
outp(ppAddress,mrkPrefLot); WaitSecs(0.010)                                 ;
outp(ppAddress,0)         ; WaitSecs(0.001)                                 ;

Screen('TextSize',window,25)                                                ; % After a lot of text, don't forget to reset font size

 
% Inquire response
respToBeMade = true                                                         ; % condition for while loop
while respToBeMade            
    [~,tEnd,keyCode] = KbCheck                                              ; % PTB inquiry to keyboard including time when button is pressed
        if keyCode(leftKey)
            % Write EEG Marker --> button press, a selection has been made
            outp(ppAddress,mrkChoice); WaitSecs(0.010)                      ;
            outp(ppAddress,0)        ; WaitSecs(0.001)                      ;            
            rt = tEnd - stimOnset                                           ; % Measure timing
            rewardBool = Sample(leftLottery)                                ; % drawing either a 0(loss) or a 1(win)
            pickedLoc = 1                                                   ; % 1 for left
            respToBeMade = false                                            ; % stop checking now
        elseif keyCode(rightKey)
            % Write EEG Marker --> button press, a selection has been made
            outp(ppAddress,mrkChoice); WaitSecs(0.010)                      ;
            outp(ppAddress,0)        ; WaitSecs(0.001)                      ;            
            rt = tEnd - stimOnset                                           ; % Measure timing
            rewardBool = Sample(rightLottery)                               ; 
            pickedLoc = 2                                                   ; % 2 for right
            respToBeMade = false                                            ;            
        end
end
 
 
 
 
 
choiceMat(1,choi_idx) = pickedLoc                                           ; % Which location was picked: 1, left - 2, right
choiceMat(2,choi_idx) = rt                                                  ; % How quickly was it picked in s
choiceMat(3,choi_idx) = (goodLotteryLoc == pickedLoc)                       ; % Boolean was the good lottery chosen? 0=no, 1=yes
choiceMat(4,choi_idx) = rewardBool                                          ; % Boolean whether is was rewarded or not
choi_idx = choi_idx+1                                                       ; % Increment choice index for next round of choice

Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % After pick, show fixation cross    
vbl = Screen('Flip',window,vbl+rt*1.1)                                      ;




% Feedback
Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % Redraw fixcross
Screen('FillRect',window,reward(:,:,rewardBool+1),rectLocs(:,:,pickedLoc))  ; % Drawing the checkerboard stim at the chosen location. The reward_bool % tells us win(1) or loss(0) ... we add 1 so we get win=2, loss=1
Screen('DrawTextures',window,maskTexture,[],maskLocs(:,:,pickedLoc),[],0)   ;

vbl = Screen('Flip',window,vbl+tDelayFeedback+rand/2)                                                       ;

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


% Save all the data
data_dir = fullfile(pwd)                                                    ; % Puts the data where the script is
cur_time = datestr(now,'dd_mm_yyyy_HH_MM_SS')                               ; % the current time and date                                          
fname = fullfile(data_dir,strcat('sp_subj_', ...
    sprintf('%03d_',ID),cur_time))                                          ; % fname consists of subj_id and datetime to avoid overwriting files
save(fname, 'sampleMat', 'choiceMat', 'questionMat')                        ; % save it!


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
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

if nargin ~= 3
    error('Check the function inputs!')
end

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

%HideCursor                                                                  ; % Hide the cursor

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
texts = produce_texts                                                       ; % separate function which outputs a "container.Map" with texts

% define winning stimulus
if strcmp(winStim, 'blue')
    reward = cat(3, colors1, colors2, colors3)                              ; % blue is win Stim ... red as loss. colors3(green) is the distractor condition
elseif strcmp(winStim, 'red') 
    reward = cat(3, colors2, colors1, colors3)                              ; % red is win Stim ... blue as loss. colors3(green) is the distractor condition
else
    sca;
    error('check the function inputs!')
end

% Create some lotteries - these are stable and hardcoded across the study
lotteryOption1 = [ones(1,7), zeros(1,3)]                                    ; % p(win)=.7 --> good lottery
lotteryOption2 = [ones(1,3), zeros(1,7)]                                    ; % p(win)=.3 --> bad lottery

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
ques_idx = 1;

% Matrices for saving the data. For sampling loop, choice loop, questions
sampleMat = nan(4,nTrials)                                                  ; % So far just a placeholder. For the meaning of each row, column, ans sheet, see below.
choiceMat = nan(4,nTrials)                                                  ; % Cannot preallocate choices exactly, so drop unnecessary NANs later.
questionMat = nan(2,nTrials-1)                                              ; % Save the decision in the questions. For last trial, there won't be a question, CHOICE will be forced. Thus nTrails-1 as dim.

%% Do the experimental flow


while trlCount > 0


% Shuffle the lotteries & inform about it
[leftLottery,rightLottery,goodLotteryLoc] = ...
    determine_lottery_loc(lotteryOption1,lotteryOption2)                    ; % Place good and bad lottery randomly either left or right

Screen('TextSize',window,50)                                                ; % If we draw text, make font a bit bigger
DrawFormattedText(window,texts('shuffled'), 'center', 'center', white)      ; % The text is taken from our texts container created in the beginning
Screen('Flip', window)                                                      ; % Show that lotteries have been shuffled
Screen('TextSize',window,25)                                                ; % Don't forget to reset the font
WaitSecs(tShowShuffled+rand/2)                                              ; % ... Show it as long as we want to


for trial=1:trlCount

% Drawing trial counter
trialCounter = sprintf('%d', samp_idx)                                      ; % Current trial 
DrawFormattedText(window, trialCounter, 'center', screenYpixels*.1, white)  ; % Trial counter is presented at the top of the screen
Screen('Flip', window)                                                      ; % draw it on an otherwise grey screen ... waiting for fixcross

WaitSecs(tShowTrialCount+rand/2)                                            ; % Show it for our intended time period


% Fixation cross & choice selection
DrawFormattedText(window, trialCounter, 'center', screenYpixels*.1, white)  ; % Redraw trial counter
Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % Draw fixcross
Screen('Flip',window)                                                       ; % Show fixcross

[pickedLoc,rewardBool,rt] = require_response(leftLottery,rightLottery)      ; % Inquire response ... this is a while loop

sampleMat(1,samp_idx) = pickedLoc                                           ; % which location was picked: 1, left - 2, right
sampleMat(2,samp_idx) = rt                                                  ; % how quickly was it picked in s
sampleMat(3,samp_idx) = (goodLotteryLoc == pickedLoc)                       ; % boolean was the good lottery chosen? 0=no, 1=yes
sampleMat(4,samp_idx) = rewardBool                                          ; % boolean whether is was rewarded or not
samp_idx = samp_idx+1                                                       ; % increment index for sampleMat for next round of sampling

WaitSecs(tDelayFeedback+rand/2)                                             ; % Delay the feedback by a bit


% Feedback
DrawFormattedText(window, trialCounter, 'center', screenYpixels*.1, white)  ; % Redraw trial counter
Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % Redraw fixcross
Screen('FillRect',window,reward(:,:,rewardBool+1),rectLocs(:,:,pickedLoc))  ; % Draw checkerboard at chosen location. Reward tells us the color                      
Screen('DrawTextures',window,maskTexture,[],maskLocs(:,:,pickedLoc))        ;                                
Screen('Flip', window)                                                      ; % Show feedback

WaitSecs(tShowFeedback+rand/2)                                              ;

% Check, whether there are more trials remaining. If not, no need to ask
% whether to continue to sample or make a choice. Then it will be only
% choice.
if samp_idx > nTrials
    Screen('TextSize',window,50)                                            ; % If we draw text, make font a bit bigger
    DrawFormattedText(window, texts('aSPfinal'), 'center', ...
        'center',white)                                                     ; % If the last trial has been reached, tell the subject so
        Screen('Flip',window)                                               ;
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
    Screen('Flip', window)                                                  ;    

    [pickedLoc,~,rt] = require_response(leftLottery, rightLottery)          ; % We are only interested in location and rt
    
    questionMat(1,ques_idx) = rt                                            ; % How quickly did the participant choose whether to sample or make a choice.
    questionMat(2,ques_idx) = pickedLoc                                     ; % What did the participant choose?
    ques_idx = ques_idx+1                                                   ; % Increment question index to be ready for next question    
    

    if pickedLoc == 1
        DrawFormattedText(window,'draw another sample','center', ...
            'center',white, [], [], [], [], [],textwin1)                    ; % Pick sampling
        Screen('Flip', window)                                              ;
        WaitSecs(tShowChosenOpt+rand/2)                                     ; % Briefly show chosen option
        Screen('TextSize',window,25)                                        ; % Reset font size
    elseif pickedLoc == 2
        DrawFormattedText(window,'make a choice','center','center', ...
            white,[], [], [], [], [],textwin2)                              ; % Pick choice
        Screen('Flip', window)                                              ;
        WaitSecs(tShowChosenOpt+rand/2)                                     ; % Briefly show chosen option
        break                                                               ; % The subject selected "choice", so we break the sampling loop and enter the choice loop
    end
end
    
end % end of sampling loop


% Update trial counter ... if it becomes zero, we are done
trlCount = trlCount - trial                                                 ; % Deduct the number of trials from overall remaining trials

% Let the participant make a choice
DrawFormattedText(window,texts('aSPchoice'),'center','center',white)        ; % Prompt for making a choice [left] or [right]
Screen('Flip',window)                                                       ; % Print it to the screen
Screen('TextSize',window,25)                                                ; % After a lot of text, don't forget to reset font size

[pickedLoc,rewardBool,rt] = require_response(leftLottery,rightLottery)      ; % We want the picked location, the outcome, and the rt!

choiceMat(1,choi_idx) = pickedLoc                                           ; % Which location was picked: 1, left - 2, right
choiceMat(2,choi_idx) = rt                                                  ; % How quickly was it picked in s
choiceMat(3,choi_idx) = (goodLotteryLoc == pickedLoc)                       ; % Boolean was the good lottery chosen? 0=no, 1=yes
choiceMat(4,choi_idx) = rewardBool                                          ; % Boolean whether is was rewarded or not
choi_idx = choi_idx+1                                                       ; % Increment choice index for next round of choice

Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % After pick, show fixation cross    
Screen('Flip',window)                                                       ;
WaitSecs(tDelayFeedback+rand/2)                                             ; % Wait for a bit before displaying feedback


% Feedback
Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % Redraw fixcross
Screen('FillRect',window,reward(:,:,rewardBool+1),rectLocs(:,:,pickedLoc))  ; % Drawing the checkerboard stim at the chosen location. The reward_bool % tells us win(1) or loss(0) ... we add 1 so we get win=2, loss=1
Screen('DrawTextures',window,maskTexture,[],maskLocs(:,:,pickedLoc))        ;
Screen('Flip',window)                                                       ;
WaitSecs(tShowFeedback+rand/2)                                              ; % Briefly show feedback 

        
% Tell the subject how much she has earned 
Screen('TextSize',window,50)                                                ; % Make font size bigger for text
payoff = rewardBool                                                         ; % The subject earned as much as the reward bool of the choice outcome indicated
payoffStr = strcat(texts('payoff'), sprintf(' %d',payoff))                  ;
DrawFormattedText(window,payoffStr,'center','center',white)                 ;
Screen('Flip',window)                                                       ;
Screen('TextSize',window,25)                                                ; % Reset font size

WaitSecs(tShowPayoff+rand/2)                                                ; % show payoff for some time


   
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
Screen('Flip',window)                                                       ;
KbStrokeWait                                                                ;
sca                                                                         ;

%% Function end
end
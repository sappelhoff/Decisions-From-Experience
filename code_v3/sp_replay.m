function [SPdistrMat, SPdistrInsertMat] = sp_replay(sampleMat, choiceMat, questionMat, winStim, ID)

% Implements a replay of a sampling paradigm performed earlier as descibed
% in the documentation.
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
% 
% [SPdistrsMat, SPdistrsInsertMat] = sp_replay(sampleMat, choiceMat, questionMat, winStim, ID)
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


if nargin ~= 5
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

% Probability of a distractor replacing a previous outcome
pDistr = 0.2                                                                ;

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
samp_idx = 1                                                                ; % Assign data a place within sampleMat
choi_idx = 1                                                                ; % Assign data a place within choiceMat
ques_idx = 1;

% Shuffle the random number generator
rng('shuffle')                                                              ;

% For saving the RTs to distractors
SPdistrMat = nan(1,nTrials)                                                 ;
distrIdx = 1                                                                ; % Running index to put RTs into SPdistrMat
SPdistrInsertMat = zeros(1,nTrials)                                         ; % A 1 will be put, where a distractor was inserted
%% Do the experimental flow

vbl = Screen('Flip', window)                                                ; % Get initial system time

while trlCount > 0

% Inform about shuffled lotteries. But no need t actually shuffle anything
Screen('TextSize',window,50)                                                ; % If we draw text, make font a bit bigger
DrawFormattedText(window,texts('shuffled'), 'center', 'center', white)      ; % The text is taken from our texts container created in the beginning
vbl = Screen('Flip',window,vbl+tShowPayoff+rand/2)                          ; % Show that lotteries have been shuffled
Screen('TextSize',window,25)                                                ; % Don't forget to reset the font
  


for trial=1:trlCount
   
 % Drawing trial counter
trialCounter = sprintf('%d', samp_idx)                                      ; % Current trial 
DrawFormattedText(window, trialCounter, 'center', screenYpixels*.1, white)  ; % Trial counter is presented at the top of the screen
if trial==1
    vbl = Screen('Flip',window,vbl+tShowShuffled+rand/2)                    ; % draw it on an otherwise grey screen ... waiting for fixcross
else
    vbl = Screen('Flip',window,vbl+tShowChosenOpt+rand/2)                   ; % draw it on an otherwise grey screen ... waiting for fixcross
end




% Fixation cross & choice selection
DrawFormattedText(window, trialCounter, 'center', screenYpixels*.1, white)  ; % Redraw trial counter
Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % Draw fixcross
vbl = Screen('Flip',window,vbl+tShowTrialCount+rand/2)                      ; % Show fixcross

pickedLoc   = sampleMat(1,samp_idx)                                         ; % decide and see outcomes exactly as in recorded game
rt          = sampleMat(2,samp_idx)                                         ;
rewardBool  = sampleMat(4,samp_idx)                                         ;
samp_idx    = samp_idx+1                                                    ;

if rt <3
    tWait = rt                                                              ; % wait the actual reaction time    
else
    tWait = 1+rand/2                                                        ; % unless it was unreasonably long ... then replace it
end


% Feedback & possibly distractor
if rand <= pDistr
   rewardBool = 2                                                           ; % On pDistr of all trials, replace the reward with a distractor
end

DrawFormattedText(window, trialCounter, 'center', screenYpixels*.1, white)  ; % Redraw trial counter
Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % Redraw fixcross
Screen('FillRect',window,reward(:,:,rewardBool+1),rectLocs(:,:,pickedLoc))  ; % Draw checkerboard at chosen location. Reward tells us the color                      
Screen('DrawTextures',window,maskTexture,[],maskLocs(:,:,pickedLoc))        ;                                
[vbl, stimOnset] = Screen('Flip',window,vbl+tWait+tDelayFeedback+rand/2)    ; % Show feedback

if rewardBool == 2
    SPdistrMat = recognize_distractor(SPdistrMat,distrIdx,stimOnset)        ; % If a distractor occurred, measure the RT to it
    SPdistrInsertMat(1,trial) = 1                                           ; % insert trial, where a distractor occurred
    tWait = SPdistrMat(1,distrIdx) + rand/2                                 ;
    distrIdx = distrIdx + 1                                                 ;
else
    tWait = tShowFeedback+rand/2                                            ; % Else, just display the feedback for a bit
end

% Check, whether there are more trials remaining. If not, no need to ask
% whether to continue to sample or make a choice. Then it will be only
% choice.
if samp_idx > nTrials
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

    rt          = questionMat(1,ques_idx)                                   ;
    pickedLoc   = questionMat(2,ques_idx)                                   ;
    ques_idx    = ques_idx+1                                                ;
    
    if rt <3
        tWait = rt                                                          ; % wait the actual reaction time    
    else
        tWait = 1+rand/2                                                    ; % unless it was unreasonably long ... then replace it
    end
    

    if pickedLoc == 1
        DrawFormattedText(window,'draw another sample','center', ...
            'center',white, [], [], [], [], [],textwin1)                    ; % Pick sampling
        vbl = Screen('Flip',window,vbl+tWait*1.1)                           ;
        Screen('TextSize',window,25)                                        ; % Reset font size
    
    elseif pickedLoc == 2
        DrawFormattedText(window,'make a choice','center','center', ...
            white,[], [], [], [], [],textwin2)                              ; % Pick choice
        vbl = Screen('Flip',window,vbl+tWait*1.1)                           ; 
        break                                                               ; % The subject selected "choice", so we break the sampling loop and enter the choice loop
    end
end

    
end % end of sampling loop


% Update trial counter ... if it becomes zero, we are done
trlCount = trlCount - trial                                                 ; % Deduct the number of trials from overall remaining trials

% Let the participant make a choice
DrawFormattedText(window,texts('aSPchoice'),'center','center',white)        ; % Prompt for making a choice [left] or [right]
vbl = Screen('Flip',window,vbl+tShowChosenOpt+rand/2)                       ; % Print it to the screen
Screen('TextSize',window,25)                                                ; % After a lot of text, don't forget to reset font size


Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % After pick, show fixation cross    
Screen('DrawingFinished', window)                                           ; % This can speed up PTB while we do some other stuff before flipping the screen

pickedLoc   = choiceMat(1,choi_idx)                                         ;
rt          = choiceMat(2,choi_idx)                                         ;
rewardBool  = choiceMat(4,choi_idx)                                         ;
choi_idx    = choi_idx+1                                                    ;

if rt <3
    tWait = rt                                                              ; % wait the actual reaction time    
else
    tWait = 1+rand/2                                                        ; % unless it was unreasonably long ... then replace it
end

vbl = Screen('Flip',window,vbl+tWait*1.1)                                   ;


% Feedback
Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % Redraw fixcross
Screen('FillRect',window,reward(:,:,rewardBool+1),rectLocs(:,:,pickedLoc))  ; % Drawing the checkerboard stim at the chosen location. The reward_bool % tells us win(1) or loss(0) ... we add 1 so we get win=2, loss=1
Screen('DrawTextures',window,maskTexture,[],maskLocs(:,:,pickedLoc))        ;
vbl = Screen('Flip',window,vbl+tDelayFeedback+rand/2)                       ;


        
% Tell the subject how much she has earned 
Screen('TextSize',window,50)                                                ; % Make font size bigger for text
payoff = rewardBool                                                         ; % The subject earned as much as the reward bool of the choice outcome indicated
payoffStr = strcat(texts('payoff'), sprintf(' %d',payoff))                  ;
DrawFormattedText(window,payoffStr,'center','center',white)                 ;
vbl = Screen('Flip',window,vbl+tShowFeedback+rand/2)                        ;
Screen('TextSize',window,25)                                                ; % Reset font size



end % end of choice loop (while loop)





% Save the RT data to the distractors
SPdistrMat(isnan(SPdistrMat)) = []                                          ; % Drop those preallocated spaces we didn't fill
data_dir = fullfile(pwd)                                                    ; % Puts the data where the script is
cur_time = datestr(now,'dd_mm_yyyy_HH_MM_SS')                               ; % the current time and date                                          
fname = fullfile(data_dir,strcat('spReplay_subj_', ...
    sprintf('%03d_',ID),cur_time))                                          ; % fname consists of subj_id and datetime to avoid overwriting files
save(fname, 'SPdistrsMat', 'SPdistrsInsertMat')                             ; % save it!

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
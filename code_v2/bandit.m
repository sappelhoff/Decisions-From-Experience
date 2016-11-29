function [choiceMat, prefMat] = bandit(nGames, nTrials, winStim, ID)

% Implements the bandit paradigm as descibed in the documentation.
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
% 
% dataMat = bandit(nGames, nTrials, winStim, ID)
%
% IN:
% - nGames: Number of bandit games.
% - nTrials: Number of trials within a game.
% - winStim: Color of winning stimulus. Either 'blue' or 'red'.
% - ID: the ID of the subject. A three digit number.
%
% OUT:
% - choiceMat: data about the choice processes.
% - prefMat: data about preferred lottery at end of each game.

%% function start

if nargin ~= 4
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
[~,screenYpixels] = Screen('WindowSize',window)                             ; % getting the dimensions of the screen in pixels
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

% Matrix for saving the data
choiceMat = nan(4, nTrials, nGames)                                         ; % So far just a placeholder. For the meaning of each row, column, ans sheet, see below.
prefMat = nan(3,nGames)                                                     ; % saving the data from asking about the preferred lottery at end of each game

%% Doing the experimental flow

for game=1:nGames
    
% Shuffle the lotteries & inform about it
[leftLottery,rightLottery,goodLotteryLoc] = ...
    determine_lottery_loc(lotteryOption1,lotteryOption2)                    ; % Place good and bad lottery randomly either left or right

Screen('TextSize',window,50)                                                ; % If we draw text, make font a bit bigger
DrawFormattedText(window,texts('shuffled'), 'center', 'center', white)      ; % The text is taken from our texts container created in the beginning
Screen('Flip', window)                                                      ; % Show that lotteries have been shuffled
Screen('TextSize',window,25)                                                ; % Don't forget to reset the font
WaitSecs(tShowShuffled+rand/2)                                              ; % ... Show it as long as we want to


for trial=1:nTrials

% Drawing trial counter
trialCounter = strcat(num2str(trial),'/',num2str(nTrials))                  ; % Current trial out of all trials
DrawFormattedText(window, trialCounter, 'center', screenYpixels*.1, white)  ; % Trial counter is presented at the top of the screen
Screen('Flip', window)                                                      ; % draw it on an otherwise grey screen ... waiting for fixcross

WaitSecs(tShowTrialCount+rand/2)                                            ; % Show it for our intended time period


% Fixation cross & choice selection
DrawFormattedText(window, trialCounter, 'center', screenYpixels*.1, white)  ; % Redraw trial counter
Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % Draw fixcross
Screen('Flip',window)                                                       ; % Show fixcross

[pickedLoc,rewardBool,rt] = require_response(leftLottery,rightLottery)      ; % Inquire response ... this is a while loop

choiceMat(1,trial,game) = pickedLoc                                         ; % which location was picked: 1, left - 2, right
choiceMat(2,trial,game) = rt                                                ; % how quickly was it picked in s
choiceMat(3,trial,game) = (goodLotteryLoc == pickedLoc)                     ; % boolean was the good lottery chosen? 0=no, 1=yes
choiceMat(4,trial,game) = rewardBool                                        ; % boolean whether is was rewarded or not


WaitSecs(tDelayFeedback+rand/2)                                             ; % Delay the feedback by a bit


% Feedback
DrawFormattedText(window, trialCounter, 'center', screenYpixels*.1, white)  ; % Redraw trial counter
Screen('DrawLines',window,fixCoords,fixWidth,white,[xCenter yCenter],2)     ; % Redraw fixcross
Screen('FillRect',window,reward(:,:,rewardBool+1),rectLocs(:,:,pickedLoc))  ; % Draw checkerboard at chosen location. Reward tells us the color                      
Screen('DrawTextures',window,maskTexture,[],maskLocs(:,:,pickedLoc))        ;                                
Screen('Flip', window)                                                      ; % Show feedback

WaitSecs(tShowFeedback+rand/2)                                              ;

end % End of trial loop

% Present Earnings
summa = sum(choiceMat,2)                                                    ; % Computing the sum over trials
payoff = summa(4,:,game)                                                    ; % Extracting the sum of the rewardBools of the current game
payoffStr = strcat(texts('payoff'), sprintf(' %d',payoff))                  ; % Making a string out of the payoff
DrawFormattedText(window, payoffStr, 'center', 'center', white)             ; % Printing it out to the screen
Screen('Flip', window)                                                      ;
WaitSecs(tShowPayoff+rand/2)                                                ; % show payoff for some time


% Ask about preferred lottery
Screen('TextSize',window,50)                                                ; % If we draw text, make font a bit bigger
DrawFormattedText(window,texts('aPFP_PrefLot'),'center','center',white)     ; % Asking the question
Screen('Flip',window)                                                       ;
Screen('TextSize',window,25)                                                ; % Reset the text size

[pickedLoc,~,rt] = require_response(leftLottery, rightLottery)              ; % Inquiring about the answer. "~" instead of rewardBool, because there will be no outcome.

prefMat(1,game) = pickedLoc                                                 ; % Which lottery was preferred? 1=left, 2=right, note that this is saved for all trials of the game (":"), because it is valid for the whole game
prefMat(2,game) = rt                                                        ; % Rt to select preferred lottery
prefMat(3,game) = pickedLoc == goodLotteryLoc                               ; % Boolean whether correct lottery was preferred
        



end % End of game loop


% Save all the data
data_dir = fullfile(pwd)                                                    ; % Puts the data where the script is
cur_time = datestr(now,'dd_mm_yyyy_HH_MM_SS')                               ; % the current time and date                                          
fname = fullfile(data_dir,strcat('bandit_subj_', ...
    sprintf('%03d_',ID),cur_time))                                          ; % fname consists of subj_id and datetime to avoid overwriting files
save(fname, 'choiceMat', 'prefMat')                                         ; % save it!


% Time for a break :-)
Screen('TextSize',window,50)                                                ; % If we draw text, make font a bit bigger
DrawFormattedText(window,texts('end'),'center','center',white)              ; % Some nice words
Screen('Flip',window)                                                       ;
KbStrokeWait                                                                ;
sca                                                                         ;

%% function end
end
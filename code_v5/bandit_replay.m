function [BdistrMat, BdistrInsertMat] = bandit_replay(choiceMat, winStim, ID)

% Implements a replay of a bandit paradigm performed earlier as described in
% the documentation.
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
% 
% distrsMat = bandit_replay(dataMat, winStim, ID)
%
% IN:
% - choiceMat: The data provided by an earlier bandit paradigm about
% choice processes
% - winStim: Color of winning stimulus. Either 'blue' or 'red'.
% - ID: the ID of the subject. A three digit number.
%
% OUT:
% - BdistrsMat: RTs to the distractor trials that happened during the replay
% - BdistrsInsertMat: a trialsXgames matrix of zeros. 1s, where distr was
% inserted

%% function start


if nargin ~= 3, error('Check the function inputs!'), end

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
stims = produce_stims(window, windowRect, screenNumber)          ; % separate function for the stim creation to avoid clutter

% All presentation texts
texts = containers.Map                                                      ;
texts('shuffled') = sprintf('The lotteries have been shuffled.')            ;
texts('payoff') = sprintf('You earned: ')                                   ;
texts('end') = sprintf(['This task is done.\n\nThank you so far!\n\n\n',...
    'Press a key to close.'])                                               ;


% define winning stimulus
if strcmp(winStim, 'blue')
    reward = cat(3, stims.colors1, stims.colors2, stims.colors3)                              ; % blue is win Stim ... red as loss. stims.colors3(green) is the distractor condition
elseif strcmp(winStim, 'red') 
    reward = cat(3, stims.colors2, stims.colors1, stims.colors3)                              ; % red is win Stim ... blue as loss. stims.colors3(green) is the distractor condition
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

% Get the nTrials and nGames from dataMat
[~, nTrials, nGames] = size(choiceMat);

% Shuffle the random number generator
rng('shuffle')                                                              ;

% Matrix for saving the data
BdistrMat = nan(1,nTrials*nGames)                                           ; % Preallocate generously and drop the places we didn't fill later on
distrIdx = 1                                                                ; % Running index to put distractor data (RTs) into BdistrsMat
BdistrInsertMat = zeros(nTrials,nGames)                                     ; % A 1 will be put, where a distractor was used


% EEG markers
mrkShuffle  = 1                                                             ; % Onset of lotteries have been shuffled screen at the beginning of one game
mrkFixOnset = 2                                                             ; % Onset of fixation cross during new trial
mrkDistr    = 3                                                             ; % Button press upon choice of a lottery
mrkFeedback = 4                                                             ; % Onset of feedback presentation
mrkPayoff   = 5                                                             ; % Onset of payoff presentation at the end of one game


% set up the parallel port
config_io                                                                   ; % The io64 module, see documentation

% Parallel port address
ppAddress = hex2dec('D050')                                                 ; % do the hex2dec only once, because it is a slow function

%% Doing the experimental flow

vbl = Screen('Flip', window)                                                ; % Get initial system time

for game=1:nGames

    % Inform about shuffled lotteries, no need to actually shuffle them. We
    % just replay.
    Screen('TextSize',window,50)                                                ; % If we draw text, make font a bit bigger
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white)      ; % The text is taken from our texts container created in the beginning
    vbl = Screen('Flip',window,vbl+tShowPayoff+rand/2)                          ; % Show that lotteries have been shuffled
    Screen('TextSize',window,25)                                                ; % Don't forget to reset the font

    % Write EEG Marker --> lotteries have been shuffled
    outp(ppAddress,mrkShuffle); WaitSecs(0.010)                                 ;
    outp(ppAddress,0)         ; WaitSecs(0.001)                                 ;


    for trial=1:nTrials

        % drawing trialcounter
        trialCounter = strcat(num2str(trial),'/',num2str(nTrials))                  ; % Current trial out of all trials
        DrawFormattedText(window, trialCounter, 'center', screenYpixels*.45, white)  ; % Trial counter is presented at the top of the screen
        vbl = Screen('Flip',window,vbl+tShowShuffled+rand/2)                        ; % draw it on an otherwise grey screen ... waiting for fixcross


        % Fixation cross & recall of previous choice
        DrawFormattedText(window, trialCounter, 'center', screenYpixels*.45, white)  ; % Redraw trial counter
        Screen('DrawLines',window,stims.fixCoords,stims.fixWidth,white,[xCenter yCenter],2)     ; % Draw fixcross
        vbl = Screen('Flip',window,vbl+tShowTrialCount+rand/2)                      ; % Show fixcross

        % Write EEG Marker --> Fixation cross onset, expect a response
        outp(ppAddress,mrkFixOnset); WaitSecs(0.010)                                ;
        outp(ppAddress,0)          ; WaitSecs(0.001)                                ;

        pickedLoc   = choiceMat(1,trial,game)                                       ; % which location was picked: 1, left - 2, right
        rt          = choiceMat(2,trial,game)                                       ; % how quickly was it picked in s
        rewardBool  = choiceMat(4,trial,game)                                       ; % boolean whether is was rewarded or not

        if rt < 3
            tWait = rt                                                              ; % Wait for actual RT, as long as it's not over 3 seconds
        else
            tWait = 1+rand/2                                                        ; % If RT was over 3 seconds, create a more adequate one
        end


        % Feedback & possibly distractor
        if rand <= pDistr
           rewardBool = 2                                                           ; % On pDistr of all trials, replace the reward with a distractor
        end

        DrawFormattedText(window, trialCounter, 'center', screenYpixels*.45, white)  ; % Redraw trial counter
        Screen('DrawLines',window,stims.fixCoords,stims.fixWidth,white,[xCenter yCenter],2)     ; % Redraw fixcross
        Screen('FillRect',window,reward(:,:,rewardBool+1),stims.rectLocs(:,:,pickedLoc))  ; % Draw checkerboard at chosen location. Reward tells us the color                      
        Screen('DrawTextures',window,stims.maskTexture,[],stims.maskLocs(:,:,pickedLoc),[],0)   ;                                
        [vbl, stimOnset] = Screen('Flip',window,vbl+tWait+tDelayFeedback+rand/2) 	; % Show feedback

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
            BdistrMat(distrIdx) = rt                                                ;
            BdistrInsertMat(trial, game) = 1                                        ; % Note, where exactly a distractor was applied 
            tWait = BdistrMat(distrIdx) + rand/2                                    ; % add some time to RT
            distrIdx = distrIdx + 1                                                 ; % Increment our distractor counter

        else
            tWait = tShowFeedback+rand/2                                            ; % Else, just display the feedback for a bit
        end

    end % End of trial loop

    % Present Earnings
    summa = sum(choiceMat,2)                                                    ; % Computing the sum over trials
    payoff = summa(4,:,game)                                                    ; % Extracting the sum of the rewardBools of the current game
    payoffStr = strcat(texts('payoff'), sprintf(' %d',payoff))                  ; % Making a string out of the payoff
    Screen('TextSize',window,50)                                                ; % If we draw text, make font a bit bigger
    DrawFormattedText(window, payoffStr, 'center', 'center', white)             ; % Printing it out to the screen
    vbl = Screen('Flip',window,vbl+tWait)                                       ;
    Screen('TextSize',window,25)                                                ; % Reset font size

    % Write EEG Marker --> the payoff is shown
    outp(ppAddress,mrkPayoff); WaitSecs(0.010)                                  ;
    outp(ppAddress,0)        ; WaitSecs(0.001)                                  ;

    % We do not ask about the preferred lottery, this is a replay.

end % End of game loop

% Save the RT data to the distractors
BdistrMat(isnan(BdistrMat)) = []                                            ; % Drop those preallocated spaces we didn't fill
data_dir = fullfile(pwd)                                                    ; % Puts the data where the script is
cur_time = datestr(now,'dd_mm_yyyy_HH_MM_SS')                               ; % the current time and date                                          
fname = fullfile(data_dir,strcat('banditReplay_subj_', ...
    sprintf('%03d_',ID),cur_time))                                          ; % fname consists of subj_id and datetime to avoid overwriting files
save(fname, 'BdistrMat', 'BdistrInsertMat')                                 ; % save it!

% Time for a break :-)
Screen('TextSize',window,50)                                                ; % If we draw text, make font a bit bigger
DrawFormattedText(window,texts('end'),'center','center',white)              ; % Some nice words
Screen('Flip',window,vbl+tShowPayoff+rand/2)                                                       ;
KbStrokeWait                                                                ;
Priority(0)                                                                 ; % Reset priority level to 0
ShowCursor                                                                  ;
sca                                                                         ;

%% function end
end
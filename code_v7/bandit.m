function [choiceMat, prefMat] = bandit(nGames, nTrials, winStim, ID)

% Implements the bandit paradigm as descibed in the documentation.
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
% 
% [choiceMat, prefMat] = bandit(nGames, nTrials, winStim, ID)
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

if nargin ~= 4, error('Check the function inputs!'), end

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

%--------------------------------------------------------------------------
%           Preparing all Stimuli and Experimental Information            
%--------------------------------------------------------------------------

% All Psychtoolbox stimuli are created with a separate function. We can
% access the stimuli from the structure Stims.
Stims = ptbStims(window, windowRect, screenNumber);

% Define the winning stimulus based on the input to the present function.
% The winning stimulus is defined by a color (red or blue). The losing
% stimulus gets the remaining color. The distractor stimulus is always
% green.
if strcmp(winStim, 'blue')
    reward = cat(3, Stims.colors1, Stims.colors2, Stims.colors3); 
elseif strcmp(winStim, 'red') 
    reward = cat(3, Stims.colors2, Stims.colors1, Stims.colors3); 
else
    sca;
    error('check the function inputs!')
end % end defining winning stimulus

% Create some lotteries - these are stable and hardcoded across the study.
% We generally have a good lottery at p(win)=0.7 and a bad lottery at
% p(win)=0.3
lotteryOption1 = 0.7;
lotteryOption2 = 1 - lotteryOption1;

% Keyboard information
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');
scanList = zeros(1,256);
scanList([leftKey, rightKey]) = 1;

% Sampling rate of the EEG in Hz. important for timing of markers
sampRate = 500;

% Timings in seconds
tShowShuffled   = 1;
tDelayFeedback  = 1; 
tShowFeedback   = 1; 
tShowPayoff     = 1; 
tMrkWait        = 1/sampRate*2; % for safety, take twice the time needed

% Shuffle the random number generator
rng('shuffle');

% Matrices for saving the data (choiceMat). We save trial data in 2nd dim 
% and separate games using the 3rd dim. The 1st dim describes
% the choice per se, the RT, whether it was a good choice, and how it was
% rewarded. We also have a matrix to save the preferred lottery for each
% game (prefMat).
choiceMat = nan(4, nTrials, nGames); 
prefMat   = nan(3,nGames);

% Texts
texts             = containers.Map; 
texts('end')      = sprintf(['This task is done.\n\nThank you so far!',...
    '\n\n\nPress a key to close.']);
texts('shuffled') = sprintf('The lotteries have been shuffled.');
texts('payoff')   = sprintf('You earned: ');
texts('prefLot')  = sprintf(['Which lottery do you think was more', ...
    ' profitable?\n\nPress [left] or [right].']); 

% EEG markers
mrkShuffle  = 1; % Onset of lotteries shuffled screen at beginning of game
mrkFixOnset = 2; % Onset of fixation cross during new trial
mrkChoice   = 3; % Button press upon choice of a lottery
mrkFeedback = 4; % Onset of feedback presentation
mrkPayoff   = 5; % Onset of payoff presentation at the end of one game
mrkPrefLot  = 6; % Onset of the question, which lottery was preferred
mrkSelect   = 7; % Button press upon selection of the preferred lottery

% Set up the parallel port using the io64 module. If it's not working,
% still run the script and replace trigger functions by a bogus function.

config_io; 

% Parallel port address
ppAddress = hex2dec('378');


%% Doing the experimental flow

% Ready? ... press any key to start
Screen('TextSize',window,30);
DrawFormattedText(window,'READY', 'center', 'center', white);
Screen('Flip',window);
KbStrokeWait;


% Get initial system time and assign to "vbl". We will keep updating vbl
% upon each screen flip and use it to time accurately.
vbl = Screen('Flip', window); 

for game = 1:nGames

    % Shuffle the lotteries & inform about it. Good lottery will be left=1
    % or right=2
    goodLotteryLoc = randi(2,1); 
    if goodLotteryLoc == 1
        leftLottery = lotteryOption1; 
        rightLottery = lotteryOption2;
    else
        leftLottery = lotteryOption2;
        rightLottery = lotteryOption1;
    end % end shuffling lotteries

    Screen('TextSize',window,30);
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white);
    vbl = Screen('Flip',window,vbl+tShowFeedback+rand/2); 

    % Write EEG Marker --> lotteries have been shuffled
    outp(ppAddress,mrkShuffle); WaitSecs(tMrkWait);
    outp(ppAddress,0)         ; WaitSecs(0.001);
    Screen('TextSize',window,25);


    for trial = 1:nTrials

        % Drawing trial counter as current trial out of all trials. Then
        % also a fixation cross. Subjects can immediately start to react
        % with left or right key.
        trialCounter = strcat(num2str(trial),'/',num2str(nTrials));
        DrawFormattedText(window, trialCounter, 'center', ...
            screenYpixels*0.41, white);
        Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
            white,[xCenter yCenter],2);
        [vbl, stimOnset] = Screen('Flip',window,vbl+tShowShuffled+rand/2);

        % Write EEG Marker --> Fixation cross onset, expect a response
        outp(ppAddress,mrkFixOnset); WaitSecs(tMrkWait);
        outp(ppAddress,0)          ; WaitSecs(0.001);

        % Inquire the answer with a loop and PTB call to the keyboard.
        % Stop the loop only, once a keypress has been noticed.
        respToBeMade = true;
        while respToBeMade            
            [~,tEnd,keyCode] = KbCheck([], scanList); 
                if keyCode(leftKey)
                    % Write EEG Marker --> button press, choice done
                    outp(ppAddress,mrkChoice); WaitSecs(tMrkWait);
                    outp(ppAddress,0)        ; WaitSecs(0.001);
                    rt = tEnd - stimOnset;
                    pickedLoc = 1;
                    respToBeMade = false;
                elseif keyCode(rightKey)
                    % Write EEG Marker --> button press, choice done
                    outp(ppAddress,mrkChoice); WaitSecs(tMrkWait);
                    outp(ppAddress,0)        ; WaitSecs(0.001);            
                    rt = tEnd - stimOnset;
                    pickedLoc = 2;
                    respToBeMade = false;            
                end % end checking whether a keypress has been done
        end % end waiting for keypress


        % Observation. Drawing either a 0=loss or a 1=win.
        if pickedLoc == 1
            rewardBool = binornd(1,leftLottery);
        else 
            rewardBool = binornd(1,rightLottery);     
        end % end making an observation
            

        % Prepare feedback: Redraw trialcounter and fixation cross, then
        % draw the stimulus in adequate color and apply a texture. Calling
        % 'DrawingFinished' can speed up PTB, when we do other computations
        % before flipping to the screen.
        DrawFormattedText(window, trialCounter, 'center', ...
            screenYpixels*0.41, white);
        Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
            white,[xCenter yCenter],2);
        Screen('FillRect',window,reward(:,:,rewardBool+1), ...
            Stims.rectLocs(:,:,pickedLoc));
        Screen('DrawTextures',window,Stims.maskTexture,[], ...
            Stims.maskLocs(:,:,pickedLoc),[],0);                                
        Screen('DrawingFinished', window);

        % Save data: Which location was picked? (left=1, right=2), how
        % quickly was it picked in s? Boolean whether the good location
        % (lottery) was picked. Boolean whether the outcome was a reward or
        % not.
        choiceMat(1,trial,game) = pickedLoc;
        choiceMat(2,trial,game) = rt; 
        choiceMat(3,trial,game) = (goodLotteryLoc == pickedLoc); 
        choiceMat(4,trial,game) = rewardBool; 

        vbl = Screen('Flip', window, vbl+tDelayFeedback+rand/2+rt);

        % Write EEG Marker --> the feedback is presented
        outp(ppAddress,mrkFeedback); WaitSecs(tMrkWait);
        outp(ppAddress,0)          ; WaitSecs(0.001);

    end % End of trial loop

    % Present Earnings. First compute the sum over trials for all
    % variables, then extract the sum of the rewardBools of the current
    % game. Make a string out of it and present it.
    summa = sum(choiceMat,2); 
    payoff = summa(4,:,game); 
    payoffStr = strcat(texts('payoff'), sprintf(' %d',payoff));
    Screen('TextSize',window,30); 
    DrawFormattedText(window, payoffStr, 'center', 'center', white);
    vbl = Screen('Flip', window, vbl+tShowFeedback+rand/2);

    % Write EEG Marker --> the payoff is shown
    outp(ppAddress,mrkPayoff); WaitSecs(tMrkWait);
    outp(ppAddress,0)        ; WaitSecs(0.001);

    % Ask about preferred lottery
    DrawFormattedText(window,texts('prefLot'),'center','center',white);
    [vbl, stimOnset] = Screen('Flip',window,vbl+tShowPayoff+rand/2);

    % Write EEG Marker --> the preferred lottery is being inquired
    outp(ppAddress,mrkPrefLot); WaitSecs(tMrkWait);
    outp(ppAddress,0)         ; WaitSecs(0.001);


    % Inquire about the answer with a loop and PTB call to the keyboard.
    % Stop the loop only, once a keypress has been noticed.
    respToBeMade = true;
    while respToBeMade            
        [~,tEnd,keyCode] = KbCheck([], scanList); 
            if keyCode(leftKey)
                % Write EEG Marker --> button press, selection done
                outp(ppAddress,mrkSelect); WaitSecs(tMrkWait);
                outp(ppAddress,0)        ; WaitSecs(0.001);            
                rt = tEnd - stimOnset;
                pickedLoc = 1; % 1 = left
                respToBeMade = false;
            elseif keyCode(rightKey)
                % Write EEG Marker --> button press, selection done
                outp(ppAddress,mrkSelect); WaitSecs(tMrkWait);
                outp(ppAddress,0)        ; WaitSecs(0.001);            
                rt = tEnd - stimOnset;
                pickedLoc = 2; % 2 = right
                respToBeMade = false;            
            end % end checking whether a key has been pressed
    end % end waiting for a keypress


    % Save data: Which lottery was preferred? 1=left, 2=right, RT to select
    % the preferred lottery, Boolean whether the good lottery was preferred
    prefMat(1,game) = pickedLoc; 
    prefMat(2,game) = rt;
    prefMat(3,game) = pickedLoc == goodLotteryLoc;

    Screen('TextSize',window,25);

end % End of game loop


% Save all the data to same directory of the function. Use a file name
% consisting of subj_id and datetime to avoid overwriting files.
dataDir = fullfile(pwd);
curTime = datestr(now,'dd_mm_yyyy_HH_MM_SS');
fname   = fullfile(dataDir,strcat('bandit_subj_', ...
    sprintf('%03d_',ID),curTime));
save(fname, 'choiceMat', 'prefMat');


% Print that it's time for a break, reset priority level, and clean the
% screen (sca).
Screen('TextSize',window,30);
DrawFormattedText(window,texts('end'),'center','center',white);
Screen('Flip',window,vbl+rt+0.01);
KbStrokeWait;
Priority(0);
ShowCursor;
sca;
clear io64;

end % function end
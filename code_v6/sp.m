function [sampleMat, choiceMat] = sp(nTrials, winStim, ID)

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

%% Function start

if nargin ~= 3, error('Check the function inputs!'), end

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
lotteryOption2 = 1-lotteryOption1;

% Keyboard information
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');
downKey = KbName('DownArrow');
scanList = zeros(1,256);
scanList([leftKey,rightKey,downKey]) = 1;

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

% Indices for the loops and assigning data to their places within matrices
% trlCount is a trial counter that will be counted down during while loop
trlCount = nTrials; 
sampIdx = 1;
choiIdx = 1;

% Matrices for saving the data. For sampling loop, choice loop.
% The 1st dim describes the choice per se, the RT, whether it was a good 
% choice, and how it was rewarded.
sampleMat = nan(4,nTrials); 
choiceMat = nan(4,nTrials); 

% All presentation texts
texts              = containers.Map;
texts('shuffled')  = sprintf('The lotteries have been shuffled.');
texts('payoff')    = sprintf('You earned: ');
texts('end')       = sprintf(['This task is done.\n\nThank you so far!',...
    '\n\n\nPress a key to close.']);
texts('aSPchoice') = sprintf(['From which lottery do\n\nyou want to', ...
    ' draw your payoff?\n\nPress [left] or [right]']);
texts('aSPfinal')  = sprintf(['You have reached the final\n\ntrial.', ...
    ' You are granted one\n\nlast choice towards your payoff.\n\n', ...
    ' Press any key.']);

% EEG markers
mrkShuffle  = 1; % Onset of lotteries have been shuffled screen at of game
mrkFixOnset = 2; % Onset of fixation cross during new trial
mrkChoice   = 3; % Button press to sample a lottery or go to choice
mrkFeedback = 4; % Onset of feedback presentation
mrkPayoff   = 5; % Onset of payoff presentation at the end of one game
mrkPrefLot  = 6; % Onset of the question, which lottery was preferred
mrkSelect   = 7; % Button press upon selection of the preferred lottery
mrkResult   = 8; % Feedback on the choice of preferred lottery

% Set up the parallel port using the io64 module. If it's not working,
% still run the script and replace trigger functions by a bogus function.
try
    config_io; 
catch
    warning('io64 module not working. No triggers will be sent');
    outp = @(x,y) x*y; 
end

% Parallel port address
ppAddress = hex2dec('378');

%% Do the experimental flow

% Ready? ... press any key to start
Screen('TextSize',window,50);
DrawFormattedText(window,'READY', 'center', 'center', white);
Screen('Flip',window);
KbStrokeWait;

% Get initial system time and assign to "vbl". We will keep updating vbl
% upon each screen flip and use it to time accurately.
vbl = Screen('Flip', window); 

% As long as we have a trial left in our countdown, start a new "game"
while trlCount > 0
    
    % Shuffle the lotteries. Good lottery will be left=1
    % or right=2
    goodLotteryLoc = randi(2,1); 
    if goodLotteryLoc == 1
        leftLottery = lotteryOption1; 
        rightLottery = lotteryOption2;
    else
        leftLottery = lotteryOption2;
        rightLottery = lotteryOption1;
    end % end shuffling lotteries

    % Print out: lotteries have been shuffled. Send EEG markers
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white); 
    vbl = Screen('Flip',window,vbl+tShowPayoff+rand/2);
    outp(ppAddress,mrkShuffle); WaitSecs(tMrkWait);
    outp(ppAddress,0)         ; WaitSecs(0.001);

    % Now a game is set ... start the trials within the game
    for trial = 1:trlCount

        % Drawing trial counter and fixation cross. Subjects can
        % immediately start to press right or left key upon presentation
        Screen('TextSize',window,25);
        trialCounter = sprintf('%d/X', sampIdx);
        DrawFormattedText(window, trialCounter, 'center', ...
            screenYpixels*0.41, white);
        Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
            white,[xCenter yCenter],2);        
        
        % timing of presentation depends on position in the loop
        if trial == 1
            [vbl,stimOnset] = Screen('Flip',window, ...
                vbl+tShowShuffled+rand/2); 
        else
            [vbl,stimOnset] = Screen('Flip',window, ...
                vbl+tShowFeedback+rand/2);
        end

        % Write EEG Marker --> Fixation cross onset, expect a response
        outp(ppAddress,mrkFixOnset); WaitSecs(tMrkWait);
        outp(ppAddress,0)          ; WaitSecs(0.001);

        % Inquire the answer with a loop and PTB call to the keyboard.
        % Stop the loop only, once a keypress has been noticed. The subject
        % can either press left, or right to sample a lottery. Furthermore,
        % if it's NOT the first trial of the current game, the subject can
        % also decide to make a choice by pressing down.
        respToBeMade = true;
        while respToBeMade            
            [~,tEnd,keyCode] = KbCheck([], scanList); 
                % sample left lottery
                if keyCode(leftKey)
                    outp(ppAddress,mrkChoice); WaitSecs(tMrkWait);
                    outp(ppAddress,0)        ; WaitSecs(0.001);
                    rt = tEnd - stimOnset;
                    pickedLoc = 1;
                    respToBeMade = false;
                % sample right lottery
                elseif keyCode(rightKey)
                    outp(ppAddress,mrkChoice); WaitSecs(tMrkWait);
                    outp(ppAddress,0)        ; WaitSecs(0.001);            
                    rt = tEnd - stimOnset;
                    pickedLoc = 2;
                    respToBeMade = false;
                % stop sampling, start choice
                elseif trial~=1 && keyCode(downKey)
                    outp(ppAddress,mrkChoice); WaitSecs(tMrkWait);
                    outp(ppAddress,0)        ; WaitSecs(0.001);
                    rt = tEnd - stimOnset;
                    pickedLoc = 3;
                    respToBeMade = false;
                end % end checking whether a keypress has been done
        end % end waiting for keypress
        

        % If participant picked "sample"
        if pickedLoc == 1 || pickedLoc == 2
            
            % Observation. Sampling either a 0=loss or a 1=win.
            if pickedLoc == 1
                rewardBool = binornd(1,leftLottery);
            elseif pickedLoc == 2 
                rewardBool = binornd(1,rightLottery);
            end % end making an observation            

            % Prepare feedback: Redraw trial counter and fixation cross,
            % then draw the stimulus in adequate color and apply a texture.
            % Calling 'DrawingFinished' can speed up PTB, when we do other
            % computations before flipping the screen.
            DrawFormattedText(window, trialCounter, 'center', ...
                screenYpixels*0.41, white);
            Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
                white,[xCenter yCenter],2);
            Screen('FillRect',window,reward(:,:,rewardBool+1), ...
                Stims.rectLocs(:,:,pickedLoc));
            Screen('DrawTextures',window,Stims.maskTexture,[], ...
                Stims.maskLocs(:,:,pickedLoc),[],0);                                
            Screen('DrawingFinished', window);            

            % Save the data and increment the data allocation index
            sampleMat(1,sampIdx) = pickedLoc;
            sampleMat(2,sampIdx) = rt;
            sampleMat(3,sampIdx) = (pickedLoc==goodLotteryLoc);
            sampleMat(4,sampIdx) = rewardBool;
            sampIdx              = sampIdx+1;            
            
            % Show feedback and write marker to EEG
            vbl = Screen('Flip',window,vbl+tDelayFeedback+rand/2+rt);
            outp(ppAddress,mrkFeedback); WaitSecs(tMrkWait);
            outp(ppAddress,0)          ; WaitSecs(0.001);
 
            
        % If participant picked "choice"
        elseif pickedLoc == 3 
            
            % Let the participant make a choice
            Screen('TextSize',window,50);
            DrawFormattedText(window,texts('aSPchoice'),'center', ...
                'center',white); 
            [vbl, stimOnset] = Screen('Flip',window, vbl+rt+0.01); 

            % Write EEG Marker --> the preferred lottery is being inquired
            outp(ppAddress,mrkPrefLot); WaitSecs(tMrkWait);
            outp(ppAddress,0)         ; WaitSecs(0.001);

            % Inquire the answer with a loop and PTB call to the keyboard.
            % Stop the loop only, once a keypress has been noticed.
            respToBeMade = true;
            while respToBeMade            
                [~,tEnd,keyCode] = KbCheck([], scanList); 
                    % Choose the left lottery
                    if keyCode(leftKey)
                        outp(ppAddress,mrkSelect); WaitSecs(tMrkWait);
                        outp(ppAddress,0)        ; WaitSecs(0.001);
                        rt = tEnd - stimOnset;
                        pickedLoc = 1;
                        respToBeMade = false;
                    % Choose the right lottery
                    elseif keyCode(rightKey)
                        outp(ppAddress,mrkSelect); WaitSecs(tMrkWait);
                        outp(ppAddress,0)        ; WaitSecs(0.001);            
                        rt = tEnd - stimOnset;
                        pickedLoc = 2;
                        respToBeMade = false;            
                    end % end checking whether a keypress has been done
            end % end waiting for keypress

            % Observation. Sampling either a 0=loss or a 1=win.
            if pickedLoc == 1
                rewardBool = binornd(1,leftLottery);
            elseif pickedLoc == 2 
                rewardBool = binornd(1,rightLottery);
            end % end making an observation            
                  
            % Save data
            choiceMat(1,choiIdx) = pickedLoc;
            choiceMat(2,choiIdx) = rt;
            choiceMat(3,choiIdx) = (goodLotteryLoc == pickedLoc);
            choiceMat(4,choiIdx) = rewardBool;
            choiIdx = choiIdx+1;

            % Show fixation cross, ready for feedback
            Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
                white,[xCenter yCenter],2);
            vbl = Screen('Flip',window,vbl+rt+0.01);

            % Show feedback and send markers to EEG
            Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
                white,[xCenter yCenter],2);
            Screen('FillRect',window,reward(:,:,rewardBool+1), ...
                Stims.rectLocs(:,:,pickedLoc));
            Screen('DrawTextures',window,Stims.maskTexture,[], ...
                Stims.maskLocs(:,:,pickedLoc),[],0);

            vbl = Screen('Flip',window,vbl+tDelayFeedback+rand/2);
            outp(ppAddress,mrkResult); WaitSecs(tMrkWait);
            outp(ppAddress,0)        ; WaitSecs(0.001);

            % Tell the subject how much she has earned and send EEG markers
            payoff = rewardBool;
            payoffStr = strcat(texts('payoff'), sprintf(' %d',payoff));
            DrawFormattedText(window,payoffStr,'center','center',white);
            vbl = Screen('Flip',window,vbl+tShowFeedback+rand/2);
            outp(ppAddress,mrkPayoff); WaitSecs(tMrkWait);
            outp(ppAddress,0)        ; WaitSecs(0.001);

            % Add one to the trial count, because a choice does not "cost"
            % a trial. Then break the trial loop to update how many
            % trials remain and start a new game (shuffle lotteries)
            % accordingly.
            trlCount = trlCount + 1;
            break; 
            
        end %end of deciding for either sampling or choice
    end % end of trial loop

    % Update trial counter ... if it becomes zero, we are done. Deduct 
    % the number of trials we just did from overall remaining trials
    trlCount = trlCount - trial;
    
end % end of game loop (while) 

% We grant one final choice
Screen('TextSize',window,50);
DrawFormattedText(window, texts('aSPfinal'), 'center', 'center',white);
Screen('Flip',window,vbl+tShowFeedback+rand/2);
vbl = KbStrokeWait;

% Let the participant make a choice
DrawFormattedText(window,texts('aSPchoice'),'center', 'center',white); 
[vbl, stimOnset] = Screen('Flip',window, vbl+0.01); 

% Write EEG Marker --> the preferred lottery is being inquired
outp(ppAddress,mrkPrefLot); WaitSecs(tMrkWait);
outp(ppAddress,0)         ; WaitSecs(0.001);

% Inquire the answer with a loop and PTB call to the keyboard.
% Stop the loop only, once a keypress has been noticed.
respToBeMade = true;
while respToBeMade            
    [~,tEnd,keyCode] = KbCheck([], scanList); 
        % Choose the left lottery
        if keyCode(leftKey)
            outp(ppAddress,mrkSelect); WaitSecs(tMrkWait);
            outp(ppAddress,0)        ; WaitSecs(0.001);
            rt = tEnd - stimOnset;
            pickedLoc = 1;
            respToBeMade = false;
        % Choose the right lottery
        elseif keyCode(rightKey)
            outp(ppAddress,mrkSelect); WaitSecs(tMrkWait);
            outp(ppAddress,0)        ; WaitSecs(0.001);            
            rt = tEnd - stimOnset;
            pickedLoc = 2;
            respToBeMade = false;            
        end % end checking whether a keypress has been done
end % end waiting for keypress

% Observation. Sampling either a 0=loss or a 1=win.
if pickedLoc == 1
    rewardBool = binornd(1,leftLottery);
elseif pickedLoc == 2 
    rewardBool = binornd(1,rightLottery);
end % end making an observation            

% Save data
choiceMat(1,choiIdx) = pickedLoc;
choiceMat(2,choiIdx) = rt;
choiceMat(3,choiIdx) = (goodLotteryLoc == pickedLoc);
choiceMat(4,choiIdx) = rewardBool;


% Show fixation cross, ready for feedback
Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
    white,[xCenter yCenter],2);
vbl = Screen('Flip',window,vbl+rt+0.01);

% Show feedback and send markers to EEG
Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
    white,[xCenter yCenter],2);
Screen('FillRect',window,reward(:,:,rewardBool+1), ...
    Stims.rectLocs(:,:,pickedLoc));
Screen('DrawTextures',window,Stims.maskTexture,[], ...
    Stims.maskLocs(:,:,pickedLoc),[],0);

vbl = Screen('Flip',window,vbl+tDelayFeedback+rand/2);
outp(ppAddress,mrkResult); WaitSecs(tMrkWait);
outp(ppAddress,0)        ; WaitSecs(0.001);

% Tell the subject how much she has earned and send EEG markers
payoff = rewardBool;
payoffStr = strcat(texts('payoff'), sprintf(' %d',payoff));
DrawFormattedText(window,payoffStr,'center','center',white);
vbl = Screen('Flip',window,vbl+tShowFeedback+rand/2);
outp(ppAddress,mrkPayoff); WaitSecs(tMrkWait);
outp(ppAddress,0)        ; WaitSecs(0.001);


% Save all the data to same directory of the function. Use a file name
% consisting of subj_id and datetime to avoid overwriting files.
dataDir = fullfile(pwd);
curTime = datestr(now,'dd_mm_yyyy_HH_MM_SS');
fname = fullfile(dataDir,strcat('sp_subj_', ...
    sprintf('%03d_',ID),curTime));
save(fname, 'sampleMat', 'choiceMat');


% Print that it's time for a break, reset priority level, and clean the
% screen (sca).
DrawFormattedText(window,texts('end'),'center','center',white);
Screen('Flip',window,vbl+tShowPayoff+rand/2);
KbStrokeWait;
Priority(0);
ShowCursor;
sca;
clear io64;

end % Function end
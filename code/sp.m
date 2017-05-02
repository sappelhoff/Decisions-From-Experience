function [decisionMat, sampleMat, choiceMat] = sp(nTrials, winStim, ID)

% Implements the sampling paradigm as descibed in the documentation.
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
% 
% [decisionMat, sampleMat, choiceMat] = sp(nTrials, winStim, ID)
%
% IN:
% - nTrials: Number of trials within a game.
% - winStim: Color of winning stimulus. Either 'blue' or 'red'.
% - ID: the ID of the subject. A three digit number.
%
% OUT:
% - decisionMat: data for each decision whether to sample or to choose
% - sampleMat: data for each sampling round
% - choiceMat: data for each choice round
% - also saves the jitter timings

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

% Generate random jitter timings to be used later. It's handy to save them.
% For SP cannot exactly know how many jitters we will need, so generate the
% maximum possible number. Also initialize a counter to get these timings.
tJit = rand(1, 2 + 3*nTrials + 2*nTrials*nTrials)/2;
jitCount = 1;


% Indices for the loops and assigning data to their places within matrices
choiIdx     = 1;
decIdx      = 1;

% Trial counter and a boolean flag set to True, to begin with a new game
trlCount    = 0;
isNewGame   = 1;

% Matrices for saving the data. For decisions, sampling loop, choice loop.
% The 1st dim describes the choice per se, the RT, whether it was a good 
% choice, and whether it was rewarded. There might be a maximum of twice as
% many decisions whether to sample or to choose than there are trials in
% the game. There will be exactly as many samples as there are trials in
% the paradigm. There will be less choices than there are trials, in the
% paradigm, however we preallocate generously. Getting rid of NaNs in the
% matrices later is easy.
decisionMat = nan(2,nTrials*2);
sampleMat   = nan(4,nTrials); 
choiceMat   = nan(4,nTrials);

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

% EEG markers common across conditions
mrkShuffle  = 1; % Onset of lotteries have been shuffled screen at start up
mrkFixOnset = 2; % Onset of fixation cross during new trial
mrkChoice   = 3; % Button press to sample either lottery
mrkFeedback = 4; % Onset of feedback presentation
mrkPayoff   = 5; % Onset of payoff presentation at the end of one game
mrkPrefLot  = 6; % Onset of the question, which lottery was preferred
mrkSelect   = 7; % Button press upon selection of the preferred lottery

% EEG markers specific to this condition
mrkResult     = 8; % Feedback on the choice of preferred lottery
mrkStopSample = 9; % Button press to go to choice

% Set up the parallel port using the io64 module. 
config_io; 

% Parallel port address
ppAddress = hex2dec('378');

%% Do the experimental flow

% Ready? ... press any key to start
Screen('TextSize',window,30);
DrawFormattedText(window,'READY', 'center', 'center', white);
Screen('Flip',window);
KbStrokeWait;

% Get initial system time and assign to "vbl". We will keep updating vbl
% upon each screen flip and use it to time accurately.
vbl = Screen('Flip', window); 

% Implement the whole paradigm with one while loop. the trlCount is
% incremented after each sampling procedure. A choice procedure is possible
% earliest after the first sampling in a new game has happened, and a
% choice procedure does not increment the trlCount. Once all sampling
% procedures (=all trials) have been done, there is one final choice
% procedure offered, for which we use the boolen isLastTrial.
while trlCount <= nTrials

    % ------------------------------------------------------------
    % First check, if this is the last trial ... if it is, we skip all the
    % following and go on to one last choice procedure
    isLastTrial = (nTrials - trlCount) == 0;
    
    
    % ------------------------------------------------------------
    % Is this the beginning of a new game? If yes, shuffle lotteries and
    % set a flag isFirstTrial, that prevents a choice procedure in the
    % upcoming decision for sampling vs. choice
    if isNewGame && ~isLastTrial
        
        % Good lottery will be left=1 or right=2
        goodLotteryLoc = randi(2,1); 
        if goodLotteryLoc == 1
            leftLottery = lotteryOption1; 
            rightLottery = lotteryOption2;
        else
            leftLottery = lotteryOption2;
            rightLottery = lotteryOption1;
        end

        % Print out: lotteries have been shuffled. Send EEG markers
        DrawFormattedText(window,texts('shuffled'),'center','center', ...
            white);
        jitter = tJit(jitCount); jitCount = jitCount + 1;
        vbl = Screen('Flip',window,vbl+tShowPayoff+jitter);
        outp(ppAddress,mrkShuffle); WaitSecs(tMrkWait);
        outp(ppAddress,0)         ; WaitSecs(tMrkWait);
        isNewGame = 0;
        isFirstTrial = 1;
    end


    % ------------------------------------------------------------
    % Now, we print a trial counter and the fixation cross to the screen.
    % If this is not the last trial, the subject can decide to sample or to
    % choose. If it is the last trial, the choice procedure will be forced.
    % If it is the first trial of a game, the choice procedure will be
    % blocked.
    if ~isLastTrial
        
        % Present trial counter and fixation cross
        Screen('TextSize',window,25);
        trialCounter = sprintf('%d/%d',trlCount+1,nTrials);
        DrawFormattedText(window,trialCounter,'center', ...
            screenYpixels*0.41,white);
        Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
            white,[xCenter yCenter],2);        

        % Timing of presentation depends on position in the loop.
        jitter = tJit(jitCount); jitCount = jitCount + 1;
        if isFirstTrial
            [vbl,stimOnset] = Screen('Flip',window, ...
                vbl+tShowShuffled+jitter);
        else
            [vbl,stimOnset] = Screen('Flip',window, ...
                vbl+tShowFeedback+jitter);
        end

        % Write EEG Marker --> Fixation cross onset, expect a response
        outp(ppAddress,mrkFixOnset); WaitSecs(tMrkWait);
        outp(ppAddress,0)          ; WaitSecs(tMrkWait);

        % ------------------------------------------------------------    
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
                    outp(ppAddress,0)        ; WaitSecs(tMrkWait);
                    rt = tEnd - stimOnset;
                    pickedLoc = 1;
                    respToBeMade = false;
                    isFirstTrial = 0;
                % sample right lottery
                elseif keyCode(rightKey)
                    outp(ppAddress,mrkChoice); WaitSecs(tMrkWait);
                    outp(ppAddress,0)        ; WaitSecs(tMrkWait);            
                    rt = tEnd - stimOnset;
                    pickedLoc = 2;
                    respToBeMade = false;
                    isFirstTrial = 0;
                % stop sampling, start choice
                elseif isFirstTrial~=1 && keyCode(downKey)
                    outp(ppAddress,mrkStopSample); WaitSecs(tMrkWait);
                    outp(ppAddress,0)            ; WaitSecs(tMrkWait);
                    rt = tEnd - stimOnset;
                    pickedLoc = 3;
                    respToBeMade = false;
                end % end checking which keypress has been done
        end % end waiting for keypress
        
        % Save the data of the decision. Mainly important for implementing
        % a replay in another script.
        decisionMat(1,decIdx) = pickedLoc;
        decisionMat(2,decIdx) = rt;
        decIdx                = decIdx + 1;
        
    else
        % If this was the last trial, we force the choice procedure
        pickedLoc = 3;
    end % end of if clause checking if ~isLastTrial
    
    % ------------------------------------------------------------        
    % Now that the participant has decided, we either present the feedback
    % for the sampling that was done, or we lead over to the choice
    % procedure.
    % If participant picked "sample"
    if (pickedLoc == 1 || pickedLoc == 2) && ~isLastTrial

        % Increment the trial counter ... only sampling counts as a trial
        trlCount = trlCount +1;        
        
        % Observation. Sampling either a 0=loss or a 1=win.
        if pickedLoc == 1
            rewardBool = binornd(1,leftLottery);
        elseif pickedLoc == 2 
            rewardBool = binornd(1,rightLottery);
        end

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
        sampleMat(1,trlCount) = pickedLoc;
        sampleMat(2,trlCount) = rt;
        sampleMat(3,trlCount) = (pickedLoc==goodLotteryLoc);
        sampleMat(4,trlCount) = rewardBool;

        % Show feedback and write marker to EEG
        jitter = tJit(jitCount); jitCount = jitCount + 1;
        vbl = Screen('Flip',window,vbl+tDelayFeedback+jitter+rt);
        outp(ppAddress,mrkFeedback); WaitSecs(tMrkWait);
        outp(ppAddress,0)          ; WaitSecs(tMrkWait);


        
    % ------------------------------------------------------------        
    % If participant picked "choice"
    elseif pickedLoc == 3 
        
        Screen('TextSize',window,30);
        
        if isLastTrial
            DrawFormattedText(window,texts('aSPfinal'),'center', ...
                'center',white);
            jitter = tJit(jitCount); jitCount = jitCount + 1;
            Screen('Flip',window,vbl+tShowFeedback+jitter);
            vbl = KbStrokeWait;
            % If this is the last trial, we need to kill the paradigm while
            % loop by raising trlCount > nTrials
            trlCount = nTrials + 1;
        end
        
        % Present a question, which choice the subject wants to make
        DrawFormattedText(window,texts('aSPchoice'),'center', ...
            'center',white); 
        % Timing of presentation depends on place in the loop
        if ~isLastTrial
            [vbl, stimOnset] = Screen('Flip',window,vbl+rt+0.01); 
        else
            [vbl, stimOnset] = Screen('Flip',window,vbl+0.01); 
        end

        % Write EEG Marker --> the preferred lottery is being inquired
        outp(ppAddress,mrkPrefLot); WaitSecs(tMrkWait);
        outp(ppAddress,0)         ; WaitSecs(tMrkWait);

        % Inquire the answer with a loop and PTB call to the keyboard.
        % Stop the loop only, once a keypress has been noticed.
        respToBeMade = true;
        while respToBeMade            
            [~,tEnd,keyCode] = KbCheck([], scanList); 
                % Choose the left lottery
                if keyCode(leftKey)
                    outp(ppAddress,mrkSelect); WaitSecs(tMrkWait);
                    outp(ppAddress,0)        ; WaitSecs(tMrkWait);
                    rt = tEnd - stimOnset;
                    pickedLoc = 1;
                    respToBeMade = false;
                % Choose the right lottery
                elseif keyCode(rightKey)
                    outp(ppAddress,mrkSelect); WaitSecs(tMrkWait);
                    outp(ppAddress,0)        ; WaitSecs(tMrkWait);            
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
        end

        % Save data and increment an index to place the data correctly
        % during the next choice in this paradigm.
        choiceMat(1,choiIdx) = pickedLoc;
        choiceMat(2,choiIdx) = rt;
        choiceMat(3,choiIdx) = (goodLotteryLoc == pickedLoc);
        choiceMat(4,choiIdx) = rewardBool;
        choiIdx = choiIdx+1;

        % Show fixation cross, ready for feedback.
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

        jitter = tJit(jitCount); jitCount = jitCount + 1;
        vbl = Screen('Flip',window,vbl+tDelayFeedback+jitter);
        outp(ppAddress,mrkResult); WaitSecs(tMrkWait);
        outp(ppAddress,0)        ; WaitSecs(tMrkWait);

        % Tell the subject how much she has earned and send EEG markers
        payoff = rewardBool;
        payoffStr = strcat(texts('payoff'), sprintf(' %d',payoff));
        DrawFormattedText(window,payoffStr,'center','center',white);
        jitter = tJit(jitCount); jitCount = jitCount + 1;
        vbl = Screen('Flip',window,vbl+tShowFeedback+jitter);
        outp(ppAddress,mrkPayoff); WaitSecs(tMrkWait);
        outp(ppAddress,0)        ; WaitSecs(tMrkWait);
    
        % After a choice, we start a new game
        isNewGame = 1;
        
    end % end of if clause checking for either sampling or choice procedure
end % end of paradigm while loop


% Save all the data to same directory of the function. Use a file name
% consisting of subj_id and datetime to avoid overwriting files.
dataDir = fullfile(pwd);
curTime = datestr(now,'dd_mm_yyyy_HH_MM_SS');
fname = fullfile(dataDir,strcat('sp_subj_', ...
    sprintf('%03d_',ID),curTime));
save(fname, 'decisionMat', 'sampleMat', 'choiceMat', 'tJit');


% Print that it's time for a break, reset priority level, and clean the
% screen (sca).
DrawFormattedText(window,texts('end'),'center','center',white);
Screen('Flip',window,vbl+tShowPayoff+0.1);
KbStrokeWait;
Priority(0);
ShowCursor;
sca;
clear io64;

end % function end
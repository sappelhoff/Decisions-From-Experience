function [SPdistrMat, SPdistrInsertMat] = spReplay(decisionMat, ...
    sampleMat, choiceMat, winStim, ID)

% Implements a replay of sampling paradigm as descibed in the
% documentation.
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
% 
% [SPdistrMat, SPdistrInsertMat] = spReplay(decisionMat, ...
%   sampleMat, choiceMat, winStim, ID)
%
% IN:
% - decisionMat: data for each decision whether to sample or to choose
% - sampleMat: data for each sampling round
% - choiceMat: data for each choice round
% - winStim: Color of winning stimulus. Either 'blue' or 'red'.
% - ID: the ID of the subject. A three digit number.
%
% OUT:
% - SPdistrsMat: RTs to the distractor trials that happened during the
% replay
% - SPdistrsInsertMat: a 1 by nTrials matrix of zeros. A one is inserted,
% wherever a distractor replaced an original outcome.
%

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

% Likelihood of a distractor occuring
pDistr = 0.2;

% Keyboard information
spaceKey = KbName('space');
scanList = zeros(1,256);
scanList(spaceKey) = 1;

% Sampling rate of the EEG in Hz. important for timing of markers
sampRate = 500;

% Timings in seconds
tShowShuffled   = 1;
tDelayFeedback  = 1; 
tShowFeedback   = 1; 
tShowPayoff     = 1; 
tMrkWait        = 1/sampRate*2; % for safety, take twice the time needed
tWait           = tShowFeedback+rand/2; % needed for variable present time

% Shuffle the random number generator
rng('shuffle');

% Indices to get the data from previously recorded SP.
choiIdx     = 1;
decIdx      = 1;

% Trial counter and a boolean flag set to True, to begin with a new game.
% Also get the number of trials from sampleMat input to the function.
nTrials     = size(sampleMat,2);
trlCount    = 0;
isNewGame   = 1;

% Matrices for saving the data. Save the RTs to each distractor in
% SPdistrMat, preallocated generously, drop NaN later. in SPdistrInsertMat,
% we initialize at 0 and put a 1, whenever in the paradigm, a distractor
% replaced an original outcome. Distractors are only possible during the
% sampling procedure (to have the same number of possible places for
% distractors as in Bandit paradigm).
SPdistrMat = nan(1,nTrials);
SPdistrInsertMat = zeros(1,nTrials);
distrIdx = 1; 



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
mrkDistr    = 3; % Button press that a distractor was detected
mrkFeedback = 4; % Onset of feedback presentation
mrkPayoff   = 5; % Onset of payoff presentation at the end of one game
mrkPrefLot  = 6; % Onset of the question, which lottery was preferred

mrkResult   = 8; % Feedback on the choice of preferred lottery

% Set up the parallel port using the io64 module. If it's not working,
% still run the script and replace trigger functions by a bogus function.

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
        
        % This is a replay, so we do not really shuffle the lotteries,
        % because we already know how they were shuffled. Still, pretend
        % and send EEG markers.
        DrawFormattedText(window,texts('shuffled'),'center','center', ...
            white); 
        vbl = Screen('Flip',window,vbl+tShowPayoff+rand/2);
        outp(ppAddress,mrkShuffle); WaitSecs(tMrkWait);
        outp(ppAddress,0)         ; WaitSecs(0.001);
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
        trialCounter = sprintf('%d/X',trlCount+1);
        DrawFormattedText(window,trialCounter,'center', ...
            screenYpixels*0.41,white);
        Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
            white,[xCenter yCenter],2);        
        
        
        % Timing of presentation depends on position in the loop.
        if isFirstTrial
            vbl = Screen('Flip',window, vbl+tShowShuffled+rand/2);
            isFirstTrial = 0;
        else
            vbl = Screen('Flip',window, vbl+tWait);
        end

        % Write EEG Marker --> Fixation cross onset, expect a response
        outp(ppAddress,mrkFixOnset); WaitSecs(tMrkWait);
        outp(ppAddress,0)          ; WaitSecs(0.001);

        % ------------------------------------------------------------    
        % At this part, participants decided either to sample, or to move
        % on to the choice procedure. We get the data from previously saved
        % matrices.
        pickedLoc   = decisionMat(1,decIdx);
        rt          = decisionMat(2,decIdx);
        decIdx      = decIdx + 1;
        
    else
        % If this was the last trial, a choice procedure was forced.
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
        
        % Get the data from previously recorded matrix.
        pickedLoc   = sampleMat(1,trlCount);
        rt          = sampleMat(2,trlCount);
        rewardBool  = sampleMat(4,trlCount);

        % Possibly replace the original outcome with a distractor
        if rand <= pDistr, rewardBool = 2; end
                
        % Prepare feedback: Redraw trial counter and fixation cross,
        % then draw the stimulus in adequate color and apply a texture.
        DrawFormattedText(window, trialCounter, 'center', ...
            screenYpixels*0.41, white);
        Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
            white,[xCenter yCenter],2);
        Screen('FillRect',window,reward(:,:,rewardBool+1), ...
            Stims.rectLocs(:,:,pickedLoc));
        Screen('DrawTextures',window,Stims.maskTexture,[], ...
            Stims.maskLocs(:,:,pickedLoc),[],0);                                

        % Show feedback and write marker to EEG
        [vbl,stimOnset] = Screen('Flip',window, ...
            vbl+tDelayFeedback+rand/2+rt);
        outp(ppAddress,mrkFeedback); WaitSecs(tMrkWait);
        outp(ppAddress,0)          ; WaitSecs(0.001);
        
        % If there was a distractor, measure the RT to it
        if rewardBool == 2
            respToBeMade = true;
            while respToBeMade            
                [~,tEnd,keyCode] = KbCheck([], scanList);
                if keyCode(spaceKey)
                    % Write EEG Marker --> button press, distractor seen
                    outp(ppAddress,mrkDistr); WaitSecs(tMrkWait);
                    outp(ppAddress,0)       ; WaitSecs(0.001);            
                    rt = tEnd - stimOnset;
                    respToBeMade = false;
                end % End to check whether specific key has been pressed 
            end % End of while loop continuing until keypress detected
            SPdistrMat(distrIdx) = rt;
            SPdistrInsertMat(1,distrIdx) = 1; 
            tWait = SPdistrMat(distrIdx) + rand/2;
            distrIdx = distrIdx + 1; 
        else
            tWait = tShowFeedback+rand/2; 
        end % End of checking whether distractor trial or not
        
        
    % ------------------------------------------------------------        
    % If participant picked "choice"
    elseif pickedLoc == 3 
        
        Screen('TextSize',window,30);
        
        if isLastTrial
            DrawFormattedText(window,texts('aSPfinal'),'center', ...
                'center',white);
            Screen('Flip',window,vbl+tShowFeedback+rand/2);
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
            vbl = Screen('Flip',window,vbl+rt+0.01); 
        else
            vbl = Screen('Flip',window,vbl+0.01); 
        end

        % Write EEG Marker --> the preferred lottery is being inquired
        outp(ppAddress,mrkPrefLot); WaitSecs(tMrkWait);
        outp(ppAddress,0)         ; WaitSecs(0.001);

        % Get data from previously saved matrix
        pickedLoc = choiceMat(1,choiIdx);
        rt = choiceMat(2,choiIdx);
        rewardBool = choiceMat(4,choiIdx);
        choiIdx = choiIdx + 1;

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
    
        % After a choice, we start a new game
        isNewGame = 1;
        
    end % end of if clause checking for either sampling or choice procedure
end % end of paradigm while loop


% Save all the data to same directory of the function. Use a file name
% consisting of subj_id and datetime to avoid overwriting files.
dataDir = fullfile(pwd);
curTime = datestr(now,'dd_mm_yyyy_HH_MM_SS');
fname = fullfile(dataDir,strcat('spReplay_subj_', ...
    sprintf('%03d_',ID),curTime));
save(fname, 'SPdistrMat', 'SPdistrInsertMat');


% Print that it's time for a break, reset priority level, and clean the
% screen (sca).
DrawFormattedText(window,texts('end'),'center','center',white);
Screen('Flip',window,vbl+tShowPayoff+rand/2);
KbStrokeWait;
Priority(0);
ShowCursor;
sca;
clear io64;

end % function end
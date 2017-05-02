function [BdistrMat, BdistrInsertMat] = banditReplay(choiceMat,winStim, ID)

% Implements a replay of a bandit paradigm performed earlier as described
% in the documentation.
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
% 
% [BdistrMat, BdistrInsertMat] = banditReplay(choiceMat, winStim, ID)
%
% IN:
% - choiceMat: The data provided by an earlier bandit paradigm about
% choice processes
% - winStim: Color of winning stimulus. Either 'blue' or 'red'.
% - ID: the ID of the subject. A three digit number.
%
% OUT:
% - BdistrMat: RTs to the distractor trials that happened during the
% replay
% - BdistrInsertMat: a trialsXgames matrix of zeros. Ones, where distr was
% inserted
% - BdistrFalsePositiveMat: a trialsXgames matrix of zeros. Ones, where a
% participant responded to a distractor although no distractor was present.

%% function start


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

% Probability of a distractor replacing an original outcome
pDistr = 0.2;

% Keyboard information
spaceKey = KbName('space'); % detect distractor
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

% Get the nTrials and nGames from dataMat
[~, nTrials, nGames] = size(choiceMat);

% Shuffle the random number generator
rng('shuffle');

% Matrices for saving the data. BdistrMat is preallocated generously ...
% later on we will drop the NANs. The BdistrInsertMat is initialized as 0
% for all trials across all games and a one will be put where a distractor
% was used.
BdistrMat = nan(1,nTrials*nGames);
distrIdx = 1; 
BdistrInsertMat = zeros(nTrials,nGames);
BdistrFalsePositiveMat = zeros(nTrials,nGames);

% All presentation texts
texts             = containers.Map;
texts('shuffled') = sprintf('The lotteries have been shuffled.');
texts('payoff')   = sprintf('You earned: ');
texts('end')      = sprintf(['This task is done.\n\nThank you so far!' ,...
    '\n\n\nPress a key to close.']);


% EEG markers
mrkShuffle  = 1; % Onset of lotteries shuffled screen at beginning of game
mrkFixOnset = 2; % Onset of fixation cross during new trial
mrkDistr    = 3; % Button press upon detection of a distractor
mrkFeedback = 4; % Onset of feedback presentation
mrkPayoff   = 5; % Onset of payoff presentation at the end of one game
mrkOriginalResp = 6; % Marker, where the original response happened

% Set up the parallel port using the io64 module.
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

for game=1:nGames

    % Inform about shuffled lotteries, no need to actually shuffle them. We
    % just replay.
    Screen('TextSize',window,30);
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white);
    vbl = Screen('Flip',window,vbl+tShowPayoff+rand/2);
    Screen('TextSize',window,25);

    % Write EEG Marker --> lotteries have been shuffled
    outp(ppAddress,mrkShuffle); WaitSecs(tMrkWait);
    outp(ppAddress,0)         ; WaitSecs(tMrkWait);


    for trial=1:nTrials

        % Drawing trial counter as current trial out of all trials. Then
        % also a fixation cross. Subjects can immediately start to react
        % with left or right key.
        trialCounter = strcat(num2str(trial),'/',num2str(nTrials)); 
        DrawFormattedText(window, trialCounter, 'center', ...
            screenYpixels*0.41, white);
        Screen('DrawLines',window,Stims.fixCoords, ...
            Stims.fixWidth,white,[xCenter yCenter],2);        
        vbl = Screen('Flip',window,vbl+tShowShuffled+rand/2);
 

        % Write EEG Marker --> Fixation cross onset, expect a response
        outp(ppAddress,mrkFixOnset); WaitSecs(tMrkWait);
        outp(ppAddress,0)          ; WaitSecs(tMrkWait);

        
        % This is a replay, so we get the choice data by inquiring the data
        % matrices of the previous run.
        pickedLoc   = choiceMat(1,trial,game); 
        rt          = choiceMat(2,trial,game); 
        rewardBool  = choiceMat(4,trial,game);

        
        % Check whether actual RT is not too long and change it, if it is
        % too long.
        if rt < 3
            tWait = rt; 
        else
            tWait = 1+rand/2;
        end 

        
        % Here, the action in the original game would have happened. As
        % this is a replay, we do not have an actual response, but we send
        % a trigger to form ERPs later.
        
        vbl = WaitSecs(vbl+tWait);    
        outp(ppAddress,mrkOriginalResp); WaitSecs(tMrkWait);
        outp(ppAddress,0)              ; WaitSecs(tMrkWait);
        
             

        % Feedback & possibly distractor. Namely, on pDistr of all trials,
        % replace the reward with a distractor. This means changing the
        % stimulus color to green and then presenting it as a feedback.
        if rand <= pDistr
           rewardBool = 2; 
        end

        DrawFormattedText(window, trialCounter, 'center', ...
            screenYpixels*0.41, white);
        Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
            white,[xCenter yCenter],2);
        Screen('FillRect',window,reward(:,:,rewardBool+1), ...
            Stims.rectLocs(:,:,pickedLoc));
        Screen('DrawTextures',window,Stims.maskTexture,[], ...
            Stims.maskLocs(:,:,pickedLoc),[],0);                                
        [vbl, stimOnset] = Screen('Flip',window,vbl+tDelayFeedback+rand/2);

        % Write EEG Marker --> the feedback is presented
        outp(ppAddress,mrkFeedback); WaitSecs(tMrkWait);
        outp(ppAddress,0)          ; WaitSecs(tMrkWait);

   
        % If this trial is a distractor trial, we measure the RT to it and
        % note the current trial. We also increment our distractor counter.
        % Else if this was a usual trial, we wait for a certain time.
        if rewardBool == 2
            respToBeMade = true;
            while respToBeMade            
                [~,tEnd,keyCode] = KbCheck([], scanList);
                if keyCode(spaceKey)
                    % Write EEG Marker --> button press, distractor seen
                    outp(ppAddress,mrkDistr); WaitSecs(tMrkWait);
                    outp(ppAddress,0)       ; WaitSecs(tMrkWait);            
                    rt = tEnd - stimOnset;
                    respToBeMade = false;
                end % End to check whether specific key has been pressed 
            end % End of while loop continuing until keypress detected
            BdistrMat(distrIdx) = rt;
            BdistrInsertMat(trial, game) = 1; 
            tWait = BdistrMat(distrIdx) + rand/2;
            distrIdx = distrIdx + 1; 
        else
            tRecFalsePos = stimOnset + tShowFeedback + rand/2;
            while GetSecs < tRecFalsePos 
                if keyCode(spaceKey)
                    BdistrFalsePositiveMat(trial, game) = 1;
                end
            end
            tWait = tRecFalsePos + 0.01;
        end % End of checking whether distractor trial or not
    end % End of trial loop

    % Present Earnings. First compute the sum over trials for all
    % variables, then extract the sum of the rewardBools of the current
    % game. Make a string out of it and present it.    
    summa = sum(choiceMat,2); 
    payoff = summa(4,:,game); 
    payoffStr = strcat(texts('payoff'), sprintf(' %d',payoff)); 
    Screen('TextSize',window,30); 
    DrawFormattedText(window, payoffStr, 'center', 'center', white); 
    vbl = Screen('Flip',window,vbl+tWait);
    Screen('TextSize',window,25);

    % Write EEG Marker --> the payoff is shown
    outp(ppAddress,mrkPayoff); WaitSecs(tMrkWait);
    outp(ppAddress,0)        ; WaitSecs(tMrkWait);

    % We do not ask about the preferred lottery, this is a replay.

end % End of game loop

% Save all the data to same directory of the function. Use a file name
% consisting of subj_id and datetime to avoid overwriting files. Also drop
% the NANs corresponding to preallocated space we did not fill.
BdistrMat(isnan(BdistrMat)) = []; 
dataDir = fullfile(pwd);
curTime = datestr(now,'dd_mm_yyyy_HH_MM_SS');
fname   = fullfile(dataDir,strcat('banditReplay_subj_', ...
    sprintf('%03d_',ID),curTime));
save(fname, 'BdistrMat', 'BdistrInsertMat', 'BdistrFalsePositiveMat');

% Print that it's time for a break, reset priority level, and clean the
% screen (sca).
Screen('TextSize',window,30);
DrawFormattedText(window,texts('end'),'center','center',white); 
Screen('Flip',window,vbl+tShowPayoff+rand/2);
KbStrokeWait;
Priority(0);
ShowCursor;
sca;
clear io64;

end % function end
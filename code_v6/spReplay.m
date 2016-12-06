function [SPdistrMat,SPdistrInsertMat] = spReplay(sampleMat,choiceMat, ...
    questionMat,winStim,ID)

% Implements a replay of a sampling paradigm performed earlier as descibed
% in the documentation.
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
% 
% [SPdistrMat,SPdistrInsertMat] = spReplay(sampleMat,choiceMat, ...
% questionMat,winStim,ID)
%
% IN:
% - sampleMat: Data for how to behave during sampling
% - choiceMat: How to behave during choice
% - questionMat: For each trial, which to pick: sample or choice
% - winStim: Color of winning stimulus. Either 'blue' or 'red'.
% - ID: the ID of the subject. A three digit number.
%
% OUT:
% - SPdistrsMat: RTs to the distractor trials that happened during the
% replay
% - SPdistrInsertMat: a 1Xtrials matrix of zeros. 1s, where distr was
% inserted

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


% Making windows, for drawing the text options for sample vs choice 
% decision. Arguments are: left top right bottom.      
textwin1 = [screenXpixels*0.1,screenYpixels*0.5,screenXpixels*0.4, ...
    screenYpixels*0.5]; 
textwin2 = [screenXpixels*0.6,screenYpixels*0.5,screenXpixels*0.9, ...
    screenYpixels*0.5];


% Probability of a distractor replacing a previous outcome
pDistr = 0.2;

% Keyboard information
spaceKey = KbName('space');

% Sampling rate of the EEG in Hz. important for timing of markers
sampRate = 500;

% Timings in seconds
tShowShuffled   = 1;
tDelayFeedback  = 1; 
tShowFeedback   = 1; 
tShowPayoff     = 1; 
tShowChosenOpt  = 0.75;
mrkWait         = 1/sampRate*2; % for safety, take twice the time needed

% Variables we get from our input matrices
nTrials = size(sampleMat,2);

% Indices for the loops and assigning data to their places within matrices
trlCount = nTrials;
sampIdx = 1;
choiIdx = 1;
quesIdx = 1;

% Shuffle the random number generator
rng('shuffle');

% Matrices for saving the data. SPdistrMat is preallocated generously ...
% later on we will drop the NANs. The BdistrInsertMat is initialized as 0
% for all trials across all games and a one will be put where a distractor
% was used.
SPdistrMat = nan(1,nTrials);
distrIdx = 1;
SPdistrInsertMat = zeros(1,nTrials);


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
mrkShuffle  = 1; % Onset of lotteries shuffled screen at beginning of game
mrkFixOnset = 2; % Onset of fixation cross during new trial
mrkDistr    = 3; % Button press upon detection of a distractor
mrkFeedback = 4; % Onset of feedback presentation
mrkPayoff   = 5; % Onset of payoff presentation at the end of one game
mrkPrefLot  = 6; % Onset of the question, which lottery was preferred

mrkResult   = 8; % Feedback on the choice of preferred lottery
mrkQuestion = 9; % Question whether to continue sampling or start choosing
mrkAnswer   = 10; % Show of selected answer to question


% Set up the parallel port using the io64 module.
config_io; 

% Parallel port address
ppAddress = hex2dec('378');

%% Do the experimental flow

% Ready? ... press any key to start
DrawFormattedText(window,'READY', 'center', 'center', white);
Screen(Flip,window);
KbStrokeWait;

% Get initial system time and assign to "vbl". We will keep updating vbl
% upon each screen flip and use it to time accurately.
vbl = Screen('Flip', window); 

% As long as we have a trial left in our countdown, start a new "game"
while trlCount > 0

    % Inform about shuffled lotteries. But no need to actually
    % shuffle anything
    Screen('TextSize',window,50);
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white);
    vbl = Screen('Flip',window,vbl+tShowPayoff+rand/2);

    % Write EEG Marker --> lotteries have been shuffled
    outp(ppAddress,mrkShuffle); WaitSecs(mrkWait);
    outp(ppAddress,0)         ; WaitSecs(0.001);

    Screen('TextSize',window,25);


    for trial=1:trlCount

         % Drawing trial counter
        trialCounter = sprintf('%d/X', sampIdx);
        DrawFormattedText(window, trialCounter, 'center', ...
            screenYpixels*0.41, white);
        Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
            white,[xCenter yCenter],2);

        if trial==1
            vbl = Screen('Flip',window,vbl+tShowShuffled+rand/2);
        else
            vbl = Screen('Flip',window,vbl+tShowChosenOpt+rand/2);
        end


        % Write EEG Marker --> Fixation cross onset, expect a response
        outp(ppAddress,mrkFixOnset); WaitSecs(mrkWait);
        outp(ppAddress,0)          ; WaitSecs(0.001);

        % Get the data from previously recorded mat
        pickedLoc   = sampleMat(1,sampIdx);
        rt          = sampleMat(2,sampIdx);
        rewardBool  = sampleMat(4,sampIdx);
        sampIdx    = sampIdx+1;

        % Check whether actual RT is not too long and change it, if it is
        % too long.
        if rt < 3
            tWait = rt; 
        else
            tWait = 1+rand/2;
        end 


        % Feedback & possibly distractor
        % On pDistr of all trials, replace the reward with a distractor
        if rand <= pDistr
           rewardBool = 2; 
        end

        DrawFormattedText(window, trialCounter, 'center', ...
            screenYpixels*0.41, white);
        Screen('DrawLines',window,Stims.fixCoords, ...
            Stims.fixWidth,white,[xCenter yCenter],2);
        Screen('FillRect',window,reward(:,:,rewardBool+1), ...
            Stims.rectLocs(:,:,pickedLoc));
        Screen('DrawTextures',window,Stims.maskTexture, ...
            [],Stims.maskLocs(:,:,pickedLoc));
        [vbl, stimOnset] = Screen('Flip',window, ...
            vbl+tWait+tDelayFeedback+rand/2);

        % Write EEG Marker --> the feedback is presented
        outp(ppAddress,mrkFeedback); WaitSecs(mrkWait);
        outp(ppAddress,0)          ; WaitSecs(0.001);

        % If this trial is a distractor trial, we measure the RT to it and
        % note the current trial. We also increment our distractor counter.
        % Else if this was a usual trial, we wait for a certain time.
        if rewardBool == 2
            respToBeMade = true;
            while respToBeMade            
            [~,tEnd,keyCode] = KbCheck;
                if keyCode(spaceKey)
                    % Write EEG Marker --> button press, distractor seen
                    outp(ppAddress,mrkDistr); WaitSecs(mrkWait);
                    outp(ppAddress,0)       ; WaitSecs(0.001);            
                    rt = tEnd - stimOnset;
                    respToBeMade = false;
                end % End to check whether specific key has been pressed 
            end % End of while loop continuing until keypress detected
            SPdistrMat(distrIdx) = rt;
            SPdistrInsertMat(trial) = 1;
            tWait = SPdistrMat(distrIdx) + rand/2;
            distrIdx = distrIdx + 1;
        else
            tWait = tShowFeedback+rand/2; 
        end % End of checking whether distractor trial or not
   

        % Check, whether there are more trials remaining. If not, no need 
        % to ask whether to continue to sample or make a choice. Then it
        % will be only choice.
        if sampIdx > nTrials
            Screen('TextSize',window,50);
            DrawFormattedText(window, texts('aSPfinal'), 'center', ...
                'center',white);
            vbl = Screen('Flip',window,vbl+tWait);
            WaitSecs(1+rand/2);
            break;
        else    
            % Decision process whether to continue to sample or make a 
            % choice    
            Screen('TextSize',window,50);
            DrawFormattedText(window,'Do you want to','center', ...
                .25*screenYpixels,white);
            DrawFormattedText(window,'draw another sample','center', ...
                'center',white, ...
                [], [], [], [], [], textwin1);
            DrawFormattedText(window,'make a choice','center','center', ...
                white,[], [], [], [], [], textwin2);
            vbl = Screen('Flip',window,vbl+tWait);

            % Write EEG Marker --> Question whether to continue sampling 
            % or choose
            outp(ppAddress,mrkQuestion); WaitSecs(mrkWait);
            outp(ppAddress,0)          ; WaitSecs(0.001);

            % Get data from previously recorded mats
            rt          = questionMat(1,quesIdx);
            pickedLoc   = questionMat(2,quesIdx);
            quesIdx     = quesIdx+1;

            
            % Check whether actual RT is not too long and change it, if 
            % it is too long.
            if rt < 3
                tWait = rt; 
            else
                tWait = 1+rand/2;
            end 

            
            if pickedLoc == 1
                DrawFormattedText(window,'draw another sample', ...
                    'center', 'center',white, [], [], [], [], [],textwin1);
                vbl = Screen('Flip',window,vbl+tWait*1.1);
                % Write EEG Marker --> Selection screen: answer to question
                outp(ppAddress,mrkAnswer); WaitSecs(mrkWait);
                outp(ppAddress,0)        ; WaitSecs(0.001);       
                Screen('TextSize',window,25);

            elseif pickedLoc == 2
                DrawFormattedText(window,'make a choice','center', ...
                    'center', white,[], [], [], [], [],textwin2);
                vbl = Screen('Flip',window,vbl+tWait*1.1);
                % Write EEG Marker --> Selection screen: answer to question
                outp(ppAddress,mrkAnswer); WaitSecs(mrkWait);
                outp(ppAddress,0)        ; WaitSecs(0.001);
                % subject selected choice ... break sampling loop
                break;
            end
        end


    end % end of sampling loop


    % Update trial counter ... if it becomes zero, we are done. Deduct the
    % number of trials from overall remaining trials
    trlCount = trlCount - trial;

    % Let the participant make a choice
    DrawFormattedText(window,texts('aSPchoice'),'center','center',white);
    vbl = Screen('Flip',window,vbl+tShowChosenOpt+rand/2);

    % Write EEG Marker --> the preferred lottery is being inquired
    outp(ppAddress,mrkPrefLot); WaitSecs(mrkWait);
    outp(ppAddress,0)         ; WaitSecs(0.001);

    Screen('TextSize',window,25);

    Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth,white, ...
        [xCenter yCenter],2);
    Screen('DrawingFinished', window);

    pickedLoc   = choiceMat(1,choiIdx);
    rt          = choiceMat(2,choiIdx);
    rewardBool  = choiceMat(4,choiIdx);
    choiIdx    = choiIdx+1;


    % Check whether actual RT is not too long and change it, if it is
    % too long.
    if rt < 3
        tWait = rt; 
    else
        tWait = 1+rand/2;
    end
    
    
    vbl = Screen('Flip',window,vbl+tWait*1.1);


    % Feedback
    Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth,white, ...
        [xCenter yCenter],2);
    Screen('FillRect',window,reward(:,:,rewardBool+1), ...
        Stims.rectLocs(:,:,pickedLoc));
    Screen('DrawTextures',window,Stims.maskTexture,[], ...
        Stims.maskLocs(:,:,pickedLoc));
    vbl = Screen('Flip',window,vbl+tDelayFeedback+rand/2);

    % Write EEG Marker --> Result of the choice process is presented
    outp(ppAddress,mrkResult); WaitSecs(mrkWait);
    outp(ppAddress,0)        ; WaitSecs(0.001);


    % Tell the subject how much she has earned 
    Screen('TextSize',window,50);
    payoff = rewardBool;
    payoffStr = strcat(texts('payoff'), sprintf(' %d',payoff));
    DrawFormattedText(window,payoffStr,'center','center',white);
    vbl = Screen('Flip',window,vbl+tShowFeedback+rand/2);

    % Write EEG Marker --> the payoff is shown
    outp(ppAddress,mrkPayoff); WaitSecs(mrkWait);
    outp(ppAddress,0)        ; WaitSecs(0.001);

    Screen('TextSize',window,25);



end % end of choice loop (while loop)



% Save all the data to same directory of the function. Use a file name
% consisting of subj_id and datetime to avoid overwriting files. Also drop
% the NANs corresponding to preallocated space we did not fill.
SPdistrMat(isnan(SPdistrMat)) = [];
dataDir = fullfile(pwd);
curTime = datestr(now,'dd_mm_yyyy_HH_MM_SS');
fname = fullfile(dataDir,strcat('spReplay_subj_', ...
    sprintf('%03d_',ID),curTime));
save(fname, 'SPdistrMat', 'SPdistrInsertMat');


% Print that it's time for a break, reset priority level, and clean the
% screen (sca).
Screen('TextSize',window,50);
DrawFormattedText(window,texts('end'),'center','center',white);
Screen('Flip',window,vbl+rt);
KbStrokeWait;
Priority(0);
ShowCursor;
sca;
clear io64;



end % Function end
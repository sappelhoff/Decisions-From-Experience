function [sampleMat, choiceMat, questionMat] = sp(nTrials, winStim, ID)

% Implements the sampling paradigm as descibed in the documentation.
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
% 
% [sampleMat, choiceMat, questionMat] = sp(nTrials, winStim, ID)
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



% Create some lotteries - these are stable and hardcoded across the study.
% We generally have a good lottery at p(win)=0.7 and a bad lottery at
% p(win)=0.3
lotteryOption1 = 0.7;
lotteryOption2 = 1-lotteryOption1;

% Keyboard information
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');

% Timings in seconds
tShowShuffled   = 1;
tShowTrialCount = 0; 
tDelayFeedback  = 1; 
tShowFeedback   = 1; 
tShowPayoff     = 1; 
tShowChosenOpt = 0.75;

% Shuffle the random number generator
rng('shuffle');

% Indices for the loops and assigning data to their places within matrices
% trlCount is a trial counter that will be counted down during while loop
trlCount = nTrials; 
sampIdx = 1;
choiIdx = 1;
quesIdx = 1;


% Matrices for saving the data. For sampling loop, choice loop, questions.
% questionMat has one column less, because for the final trial, there won't
% be a question "sample or choose?" ... choice will be forced. 
% The 1st dim describes the choice per se, the RT, whether it was a good 
% choice, and how it was rewarded. For questionMat, we only have picked
% location and RT.
sampleMat = nan(4,nTrials); 
choiceMat = nan(4,nTrials); 
questionMat = nan(2,nTrials-1); 


% All presentation texts
texts              = containers.Map;
texts('shuffled')  = sprintf('The lotteries have been shuffled.');
texts('payoff')    = sprintf('You earned: ');
texts('end')       = sprintf(['This task is done.\n\nThank you so far!',...
    '\n\n\nPress a key to close.']);
texts('aSPchoice') = sprintf(['From which lottery do\nyou want to draw',...
    'your payoff?\nPress [left] or [right]']);
texts('aSPfinal')  = sprintf(['You have reached the final\ntrial. You', ...
    'are granted one\nlast choice towards your payoff.\nPress any key.']);


% EEG markers
mrkShuffle  = 1; % Onset of lotteries have been shuffled screen at of game
mrkFixOnset = 2; % Onset of fixation cross during new trial
mrkSample   = 3; % Button press upon choice of a lottery
mrkFeedback = 4; % Onset of feedback presentation
mrkPayoff   = 5; % Onset of payoff presentation at the end of one game
mrkPrefLot  = 6; % Onset of the question, which lottery was preferred
mrkChoice   = 7; % Button press upon selection of the preferred lottery
mrkResult   = 8; % Feedback on the choice of preferred lottery
mrkQuestion = 9; % Question whether to continue sampling or start choosing
mrkAnswer   = 10; % Show of selected answer to question


% Set up the parallel port using the io64 module.
config_io; 

% Parallel port address
ppAddress = hex2dec('D050');

%% Do the experimental flow

% Get initial system time and assign to "vbl". We will keep updating vbl
% upon each screen flip and use it to time accurately.
vbl = Screen('Flip', window); 

% As long as we have a trial left in our countdown, start a new "game"
while trlCount > 0
    
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

    
    Screen('TextSize',window,50);                                                
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white); 
    vbl = Screen('Flip',window,vbl+tShowPayoff+rand/2);

    % Write EEG Marker --> lotteries have been shuffled
    outp(ppAddress,mrkShuffle); WaitSecs(0.010);
    outp(ppAddress,0)         ; WaitSecs(0.001);
    Screen('TextSize',window,25);

    % Now a game is set ... start the trials within the game
    for trial = 1:trlCount
        % Drawing trial counter
        trialCounter = sprintf('%d', sampIdx);
        DrawFormattedText(window, trialCounter, 'center', ...
            screenYpixels*0.45, white);
        % timing of presentation depends on position in the loop
        if trial == 1
            vbl = Screen('Flip',window,vbl+tShowShuffled+rand/2); 
        else
            vbl = Screen('Flip',window,vbl+tShowChosenOpt+rand/2);
        end


        % Fixation cross & choice selection
        DrawFormattedText(window, trialCounter, 'center', ...
            screenYpixels*0.45, white);
        Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
            white,[xCenter yCenter],2);
        [vbl, stimOnset] = Screen('Flip',window, ...
            vbl+tShowTrialCount+rand/2);       

        % Write EEG Marker --> Fixation cross onset, expect a response
        outp(ppAddress,mrkFixOnset); WaitSecs(0.010);
        outp(ppAddress,0)          ; WaitSecs(0.001);

        % Inquire the answer with a loop and PTB call to the keyboard.
        % Stop the loop only, once a keypress has been noticed.
        respToBeMade = true;
        while respToBeMade            
            [~,tEnd,keyCode] = KbCheck; 
                if keyCode(leftKey)
                    % Write EEG Marker --> button press, choice done
                    outp(ppAddress,mrkSample); WaitSecs(0.010);
                    outp(ppAddress,0)        ; WaitSecs(0.001);
                    rt = tEnd - stimOnset;
                    pickedLoc = 1;
                    respToBeMade = false;
                elseif keyCode(rightKey)
                    % Write EEG Marker --> button press, choice done
                    outp(ppAddress,mrkSample); WaitSecs(0.010);
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
            screenYpixels*0.45, white);
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


        vbl = Screen('Flip',window,vbl+tDelayFeedback+rand/2+rt);

        % Write EEG Marker --> the feedback is presented
        outp(ppAddress,mrkFeedback); WaitSecs(0.010);
        outp(ppAddress,0)          ; WaitSecs(0.001);

        % Check, whether there are more trials remaining. If not, no need 
        % to ask whether to continue to sample or make a choice. Then it 
        % will be only choice, so break the loop. Else, we do the usual
        % decision process whether to continue sampling or to make a choice
        if sampIdx > nTrials
            Screen('TextSize',window,50);
            DrawFormattedText(window, texts('aSPfinal'), 'center', ...
                'center',white);
            vbl = Screen('Flip',window,vbl+tShowFeedback+rand/2);
            KbStrokeWait;
            break;
        else    
            Screen('TextSize',window,50);
            DrawFormattedText(window,'Do you want to','center', ...
                .25*screenYpixels,white);
            DrawFormattedText(window,'draw another sample','center', ...
                'center',white, ...
                [], [], [], [], [], textwin1);
            DrawFormattedText(window,'make a choice','center','center', ...
                white,[], [], [], [], [], textwin2);
            [vbl, stimOnset] = Screen('Flip',window, ...
                vbl+tShowFeedback+rand/2);

            % Write EEG Marker --> Question: continue sampling or choose
            outp(ppAddress,mrkQuestion); WaitSecs(0.010);
            outp(ppAddress,0)          ; WaitSecs(0.001);

            
            % Inquire about the answer
            respToBeMade = true;
            while respToBeMade            
                [~,tEnd,keyCode] = KbCheck;
                    if keyCode(leftKey)
                        rt = tEnd - stimOnset;
                        pickedLoc = 1;
                        respToBeMade = false;
                    elseif keyCode(rightKey)
                        rt = tEnd - stimOnset;
                        pickedLoc = 2;
                        respToBeMade = false;
                    end % end checking whether a key has been pressed
            end % end waiting for a keypress

            % save data for question phase of experiment
            questionMat(1,quesIdx) = rt;
            questionMat(2,quesIdx) = pickedLoc;
            quesIdx = quesIdx+1;


            if pickedLoc == 1
                DrawFormattedText(window,'draw another sample', ...
                    'center', 'center',white, [], [], [], [], [],textwin1);
                vbl = Screen('Flip',window,vbl+rt*1.1);
                % Write EEG Marker --> Selection screen: answer to question
                outp(ppAddress,mrkAnswer); WaitSecs(0.010);
                outp(ppAddress,0)        ; WaitSecs(0.001);
                Screen('TextSize',window,25);

            elseif pickedLoc == 2
                DrawFormattedText(window,'make a choice','center', ...
                    'center', white,[], [], [], [], [],textwin2)
                vbl = Screen('Flip',window,vbl+rt*1.1);
                % Write EEG Marker --> Selection screen: answer to question
                outp(ppAddress,mrkAnswer); WaitSecs(0.010);
                outp(ppAddress,0)        ; WaitSecs(0.001);
                % subject selected choice, so we break sampling loop
                break;
            end % end asking the question and evaluating the answer
        end % end checking whether a question should be asked or not

    end % end of sampling loop


    % Update trial counter ... if it becomes zero, we are done. Deduct 
    % the number of trials from overall remaining trials
    trlCount = trlCount - trial;

    % Let the participant make a choice
    DrawFormattedText(window,texts('aSPchoice'),'center','center',white); 
    [vbl, stimOnset] = Screen('Flip',window,vbl+tShowChosenOpt+rand/2); 

    % Write EEG Marker --> the preferred lottery is being inquired
    outp(ppAddress,mrkPrefLot); WaitSecs(0.010);
    outp(ppAddress,0)         ; WaitSecs(0.001);

    Screen('TextSize',window,25);


    % Inquire the answer with a loop and PTB call to the keyboard.
    % Stop the loop only, once a keypress has been noticed.
    respToBeMade = true;
    while respToBeMade            
        [~,tEnd,keyCode] = KbCheck; 
            if keyCode(leftKey)
                % Write EEG Marker --> button press, choice done
                outp(ppAddress,mrkChoice); WaitSecs(0.010);
                outp(ppAddress,0)        ; WaitSecs(0.001);
                rt = tEnd - stimOnset;
                pickedLoc = 1;
                respToBeMade = false;
            elseif keyCode(rightKey)
                % Write EEG Marker --> button press, choice done
                outp(ppAddress,mrkChoice); WaitSecs(0.010);
                outp(ppAddress,0)        ; WaitSecs(0.001);            
                rt = tEnd - stimOnset;
                pickedLoc = 2;
                respToBeMade = false;            
            end % end checking whether a keypress has been done
    end % end waiting for keypress




    % Save data
    choiceMat(1,choiIdx) = pickedLoc;
    choiceMat(2,choiIdx) = rt;
    choiceMat(3,choiIdx) = (goodLotteryLoc == pickedLoc);
    choiceMat(4,choiIdx) = rewardBool;
    choiIdx = choiIdx+1;

    Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth,white, ...
        [xCenter yCenter],2);
    vbl = Screen('Flip',window,vbl+rt*1.1);




    % Feedback
    Screen('DrawLines',window,Stims.fixCoords,Stims.fixWidth, ...
        white,[xCenter yCenter],2);
    Screen('FillRect',window,reward(:,:,rewardBool+1), ...
        Stims.rectLocs(:,:,pickedLoc));
    Screen('DrawTextures',window,Stims.maskTexture,[], ...
        Stims.maskLocs(:,:,pickedLoc),[],0);

    vbl = Screen('Flip',window,vbl+tDelayFeedback+rand/2);

    % Write EEG Marker --> Result of the choice process is presented
    outp(ppAddress,mrkResult); WaitSecs(0.010);
    outp(ppAddress,0)        ; WaitSecs(0.001);


    % Tell the subject how much she has earned 
    Screen('TextSize',window,50);
    payoff = rewardBool;
    payoffStr = strcat(texts('payoff'), sprintf(' %d',payoff));
    DrawFormattedText(window,payoffStr,'center','center',white);
    vbl = Screen('Flip',window,vbl+tShowFeedback+rand/2);

    % Write EEG Marker --> the payoff is shown
    outp(ppAddress,mrkPayoff); WaitSecs(0.010);
    outp(ppAddress,0)        ; WaitSecs(0.001);

    Screen('TextSize',window,25);


end % end of choice loop (while loop)


% Save all the data to same directory of the function. Use a file name
% consisting of subj_id and datetime to avoid overwriting files.
dataDir = fullfile(pwd);
curTime = datestr(now,'dd_mm_yyyy_HH_MM_SS');
fname = fullfile(dataDir,strcat('sp_subj_', ...
    sprintf('%03d_',ID),curTime));
save(fname, 'sampleMat', 'choiceMat', 'questionMat');


% Print that it's time for a break, reset priority level, and clean the
% screen (sca).
Screen('TextSize',window,50);
DrawFormattedText(window,texts('end'),'center','center',white);
Screen('Flip',window,vbl+rt);
KbStrokeWait;
Priority(0);
ShowCursor;
sca;


end % Function end
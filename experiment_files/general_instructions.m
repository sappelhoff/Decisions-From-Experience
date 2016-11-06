function general_instructions(window, white, reward, maskTexture, rectLocs, maskLocs)

% a function to display the initial instructions to the participants


% Parameters
% ----------
% - window: the window where we draw stuff to
% - white: the color of the font
% - reward: a 3D array containing the information for the stimuli
% - maskTexture: required to make the stimuli seem circular
% - rectLocs: locations of the stimuli
% - maskLocs: locations of the masks to make the stimuli seem circular
%
% Returns
% ----------
% - None
%
%
%% Function start
welcome = sprintf('Welcome to the experiment.\n\n\nPress any key to proceed\n\nthroughout the general instructions.');
fingers = sprintf('Place your right index finger on [left].\n\nPlace your right ring finger on [right].\n\nPlace your left index finger on [space].');
instruct1 = sprintf('The following tasks will require\n\nyou to make choices between\n\ntwo different lotteries:\n\n[left] or [right]');
instruct2 = sprintf('The lotteries [left] and [right]\n\neach contain two possible outcomes,\n\nnamely "win" or "lose"');
instruct3 = sprintf('Some lotteries have a higher chance\n\nto yield a "win" outcome\n\nother lotteries will yield\n\na "lose" outcome more often.\n\n\nAll lotteries will remain stable for one task.\n\nOnce they are shuffled, you are being told.');
instruct4 = sprintf('Although the following tasks might differ slightly,\n\nyour  overarching assignment is\n\nto maximize the "win" outcomes.\n\n\nThis is in your interest,\n\nbecause your final payoff will depend on it.');
instruct5 = sprintf('On the following screens, you will be\n\nshown, what a "win" and a "lose" outcome\n\nlook like.\n\n\nRemember these outcomes well.');
showWin = sprintf('This outcome signifies "win"');
showLose = sprintf('This outcome signifies "lose"');
instruct6 = sprintf('Depending on the task, the outcomes\n\nwill have different values.\n\nAt the end of the experiment,\n\nyour overall points will be normalized\n\nand multiplied by a factor to\n\ndetermine your payoff.');
leadOver = sprintf('Before each task, you will receive\n\nmore detailed instructions.\n\n\nIf you have any questions,\n\nplease ask the experimenter.\n\n\nIf you are ready, press any key to start.');


DrawFormattedText(window, welcome,'center', 'center', white)                ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, fingers,'center', 'center', white)                ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, instruct1,'center', 'center', white)              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, instruct2,'center', 'center', white)              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, instruct3,'center', 'center', white)              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, instruct4,'center', 'center', white)              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

DrawFormattedText(window, instruct5,'center', 'center', white)              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

% Show "win" outcome
DrawFormattedText(window, showWin, 'center', 'center', white)               ;
Screen('FillRect', window, reward(:,:,2), rectLocs(:,:,3))                  ;
Screen('DrawTextures', window, maskTexture, [], maskLocs(:,:,3))            ;
Screen('Flip', window)                                                      ;
WaitSecs(2)                                                                 ; % force people to look at it for at least 2 seconds
KbStrokeWait                                                                ;

% Show "lose" outcome
DrawFormattedText(window, showLose, 'center', 'center', white)              ;
Screen('FillRect', window, reward(:,:,1), rectLocs(:,:,3))                  ;
Screen('DrawTextures', window, maskTexture, [], maskLocs(:,:,3))            ;
Screen('Flip', window)                                                      ;
WaitSecs(2)                                                                 ; % force people to look at it for at least 2 seconds
KbStrokeWait                                                                ;

DrawFormattedText(window, instruct6,'center', 'center', white)              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;

% Leading over to real experiment
DrawFormattedText(window, leadOver, 'center', 'center', white)              ;
Screen('Flip', window)                                                      ;
KbStrokeWait                                                                ;   


end
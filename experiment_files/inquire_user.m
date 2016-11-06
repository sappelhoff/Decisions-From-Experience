function [subjId, winStim, startCond] = inquire_user

% GUI for entering participant ID, and experiment environment
%
% Randomization of the experiment environment, i.e., the starting condition
% and the color of the stimuli, will be done externally. The results of the
% randomization can then be entered into this gui before experiment start.
%

%% function start
dlgTitle ='New Participant'                                                 ; % title of the gui box
numLines = 1                                                                ; % 'size' of the gui box


prompt = {'Enter participant ID:', ...
    'Which color should the "win" stimulus have?', ...
    'Which condition should be the starting condition?'}                    ;


def = {'type a number', ...
    'type "red" or "blue"', ...
    'type "pfp" or "sp"'}                                                   ;


answers = inputdlg(prompt, dlgTitle, numLines, def, 'on')                   ; % presents box to enter data

IDanswer = answers{1}                                                       ;
STIManswer = answers{2}                                                     ;
CONDanswer = answers{3}                                                     ;            

%% check the inputs 

% first ID
switch isempty(IDanswer)
    case 1    
        error('Participant ID not entered.')                                  % it's empty. throw an error
    case 0
        if isnan(str2double(IDanswer))
            error('The participant ID must be numerical!')                    % it's not a number. throw an error
        else
            subjId = str2double(IDanswer)                                   ; % it's fine: save under subjId variable
        end    
end

% now stimulus

switch isempty(STIManswer)
    case 1    
        error('Winning stimulus color not entered.')                          % it's empty. throw an error
    case 0
        if strcmp(STIManswer, 'red') || strcmp(STIManswer, 'blue')
            winStim = STIManswer                                            ;
        else
            error('The winning stimulus color must be either "blue" or "red"!') % it's neither red nor blue. throw an error
        end    
end


% lastly condition

switch isempty(CONDanswer)
    case 1    
        error('Starting condition not entered.')                              % it's empty. throw an error
    case 0
        if strcmp(CONDanswer, 'pfp') || strcmp(CONDanswer, 'sp')
            startCond = CONDanswer                                          ;
        else
            error('The starting condition must be either "pfp" or "sp"!')     % it's neither pfp nor sp. throw an error
        end    
end







end
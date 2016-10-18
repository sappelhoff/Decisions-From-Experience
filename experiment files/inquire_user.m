function subj_id = inquire_user

% GUI for entering participant ID
% important for deciding stimuli colors and which condition will be shown
% first.
% odd IDs will get the red stimulus for reward and start with Partial
% feedback paradigm (PFP)
% even IDs will get the blue stimulus for reward and start with Sampling
% Paradigm (SP)

dlg_title ='New Participant'                                                ; % title of the gui box
prompt = {'Enter participant ID:'}                                          ; % text within the gui box
num_lines = 1                                                               ; % 'size' of the gui box
def = {'use a number'}                                                      ; % This is written within the input line as a hint
answer = inputdlg(prompt, dlg_title, num_lines, def, 'on')                  ; % presents box to enter data

% check the input
switch isempty(answer)
    case 1    
        error('Participant ID not entered')                                 % it's empty. throw an error
    case 0
        if isnan(str2double(answer))
            error('The participant ID must be numerical')                   % it's not a number. throw an error
        else
            subj_id = str2double(answer)                                    ; % it's fine: save under subj_id variable
        end    
end




end
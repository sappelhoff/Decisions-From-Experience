function show_sp_replay(aSP_mat, texts, reward, window, white, masktexture, mask_locs, rect_locs)

% This function executes a replay
%
% Parameters
% ----------
% - data_mat: The aSP_mat from which a previous game can be deduced.
% - texts: a container.Map with all texts for display
% - reward: the stimuli matrix that encodes the rewards
% - the window that we draw to
% - white: the color ...
% - masktexture: texture to make our stimuli seem circular
% - mask_locs: locations of the mask texture
% - rect_locs: locations of the stimuli
%
% Returns
% ----------
% - None

%% Function start

[~, sp_trials] = size(aSP_mat)                                              ; % trials are saved in 2nd dim



for replay_run = 1:sp_trials
    
    % Pretend something has been shuffled
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white)  ;
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ;
    
    
    picked_loc = aSP_mat(1,replay_run)                                      ;     
    rt = aSP_mat(2,replay_run)                                              ;
    reward_bool = aSP_mat(3,replay_run)                                     ;    
    sp_run = aSP_mat(5,sp_trials)                                           ;
end

end
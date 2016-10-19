
%  A LOT OF WORK TO DO HERE !!! SO FAR EVERYTHING JUST COPIED FROM SHOW PFP
%  REPLAY

%WORK ON IT
X========X % <- DELIBERATE ERROR HERE :-)

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

[~, pfp_trials, pfp_runs] = size(aSP_mat)                                  ; % trials are saved in 2nd dim, runs in 3rd dim



for replay_run = 1:pfp_runs
    
    % Pretend something has been shuffled
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white)  ;
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ;
        
    
    for replay_trial = 1:pfp_trials


    % drawing trialcounter
    trial_counter = strcat(num2str(replay_trial),'/',num2str(pfp_trials))   ; % The pfp counter always shows current draw out of all draws within one game
    DrawFormattedText(window, trial_counter, 'center', 'center', white)     ;
    Screen('Flip', window)                                                  ;

    % drawing the fixcross
    Screen('DrawLines', window, fixCoords,...
        fixWidth, white, [xCenter yCenter], 2)                              ;
    WaitSecs(2)                                                             ; % show trial counter for 2 seconds
    Screen('Flip', window)                                                  ; % then show fixcross

    
    % now instead of a decision, take all information from a previous
    % decision
    picked_loc = aSP_mat(1,replay_trial,replay_run)                        ; % which location was picked
    rt = aSP_mat(2,replay_trial,replay_run)                                ; % how quickly was it picked
    reward_bool = aSP_mat(4,replay_trial,replay_run)                       ; % was it rewarded?

    
    % Replay decision process originally, as long as it is reasonable
    if rt >= 1 && rt <= 3
        WaitSecs(rt)                                                        ; % RTs between 1 and 3 seconds are reasonable
    else
        WaitSecs(randi(2,1,1)+rand)                                         ; % if actual RT differs, create a conforming random RT
    end
    
    
    %%
    %%%%%
    % Here we need something to visually indicate that left or right has
    % been selected ...
    %%%%%        
    
    %%
    
    % drawing the fixcross
    Screen('DrawLines', window, fixCoords,...
    fixWidth, white, [xCenter yCenter], 2)                                  ;

    % drawing the checkerboard stim at the chosen location. The reward
    % bool tells us win(1) or loss(0) ... we add 1 so we get win=2,
    % loss=1
    Screen('FillRect', window, reward(:,:,reward_bool+1),...
    rect_locs(:,:,picked_loc))                                              ;

    Screen('DrawTextures', window, masktexture, [],...
    mask_locs(:,:,picked_loc))                                              ;


    WaitSecs(1)                                                             ; % after choice, wait 1 sec before displaying result
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ; % feedback displayed for 2 secs
    
    end
    
    % Tell the subject how much was earned
    payoff = sum(aSP_mat(4,:,pfp_run))                                     ; % the overall payoff
    payoff_str = strcat(texts('payoff'), num2str(payoff))                   ;
    DrawFormattedText(window, payoff_str, 'center', 'center', white)        ;
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ; % Display payoff for 2 secs    
    
    
    
    % REPLACE THE "asking which lottery was better" BY CHECKING QUESTION
    % "You think this is correct? [left='no'] [right='yes']" ???
    
    
    
    
    
end

end
function show_sp_replay(aSP_mat, aSP_prefLot_mat, texts, reward, window, white, masktexture, mask_locs, rect_locs, screenXpixels, screenYpixels)

% This function executes a replay
%
% Parameters
% ----------
% - aSP_mat: The aSP_mat from which a previous game can be deduced.
% - aSP_prefLot_mat: needed for reproducing choice trials
% - texts: a container.Map with all texts for display
% - reward: the stimuli matrix that encodes the rewards
% - the window that we draw to
% - white: the color ...
% - masktexture: texture to make our stimuli seem circular
% - mask_locs: locations of the mask texture
% - rect_locs: locations of the stimuli
% - screenXpixels: width of screen
% - screenYpixels: height of screen
%
% Returns
% ----------
% - None

%% Function start

% Getting our indices ready for the replay
prev_samples = aSP_prefLot_mat(5,:)                                         ; % vector containing samples taken before a choice
all_choices = length(prev_samples)                                          ; % number of choices in whole SP task
aSP_data_idx = 1                                                            ; % to access the sample data throughout the loops with right idx


% Drawing the text options for sample vs choice decision      
textwin1 = [screenXpixels*.1, screenYpixels*.5, ...
    screenXpixels*.4, screenYpixels*.5]                                     ; % windows to center the formatted text in
textwin2 = [screenXpixels*.6, screenYpixels*.5, ...
    screenXpixels*.9, screenYpixels*.5]                                     ; % left top right bottom


for choice_run = 1:all_choices % before each choice, there is a number of samples drawn. 

    % Pretend the lotteries have been shuffled
    DrawFormattedText(window,texts('shuffled'), 'center', 'center', white)  ;
    Screen('Flip', window)                                                  ;
    WaitSecs(2)                                                             ;
    
    for samples = 1:prev_samples(choice_run) % the number of samples can be obtained here by indexing with the choice of interest
   
        % start with a pick
        picked_loc = aSP_mat(1, aSP_data_idx)                               ;
        rt = aSP_mat(2, aSP_data_idx)                                       ;
        reward_bool = aSP_mat(3, aSP_data_idx)                              ;
        aSP_data_idx = aSP_data_idx + 1                                     ; % increment our data index for next display
        
        % Replay decision process originally, as long as it is [1,3]sec
        if rt < 1 ||  rt > 3
            rt = randi(2,1,1)+rand                                          ; % if actual RT differs, create a conforming random RT
        end
        
        
        % draw fixcross
        Screen('DrawLines', window, fixCoords,...
            fixWidth, white, [xCenter yCenter], 2)                          ; 
        Screen('Flip', window)                                              ;
        WaitSecs(rt)                                                        ; % "wait for choice"        
        
        
        
        
        %feedback
        
        % draw fixcross again for feedback
        Screen('DrawLines', window, fixCoords,...
            fixWidth, white, [xCenter yCenter], 2)                          ; 
        
        % drawing the checkerboard stim at the chosen location. The
        % reward_bool tells us win(1) or loss(0) ... we add 1 so we get
        % win=2, loss=1
        Screen('FillRect', window, reward(:,:,reward_bool+1),...
            rect_locs(:,:,picked_loc))                                      ;

        Screen('DrawTextures', window, masktexture, [],...
            mask_locs(:,:,picked_loc))                                      ;            
        Screen('Flip', window)                                              ;
        WaitSecs(2)                                                         ; % show feedback for 2 seconds
            
        

        % display the question
        DrawFormattedText(window, 'Do you want to', ...
            'center', .25*screenYpixels, white)                             ;

        DrawFormattedText(window, 'draw another sample', ...
            'center', 'center', white, [], [], [], [], [], textwin1)        ;

        DrawFormattedText(window, 'make a choice', ...
            'center', 'center', white, [], [], [], [], [], textwin2)        ;

        Screen('Flip', window)                                              ;
        
        WaitSecs(1+rand)                                                    ; % For this, just wait briefly above 1 sec, we have no RT to replay accurately
            
        
        % answer ... depending on "samples" idx whether another sample or
        % choice
        if samples ~= prev_samples(choice_run)
            % if samples idx is not at its max, just sample ...
            DrawFormattedText(window, 'draw another sample', ...
                'center', 'center', white, [], [], [], [], [], textwin1)    ;
            Screen('Flip', window)                                          ;
            WaitSecs(1+rand)                                                ; % For this, just wait briefly above 1 sec 

            % now start from "samples" loop again
            
        else
            % now samples idx is at max, so we make a choice
            DrawFormattedText(window, 'make a choice', ...
                'center', 'center', white, [], [], [], [], [], textwin2)    ;
            Screen('Flip', window)                                          ;
            WaitSecs(1+rand)                                                ; % For this, just wait briefly above 1 sec 
            
            % get the historical values from our data
            picked_loc = aSP_prefLot_mat(1, choice_run)                     ;
            rt = aSP_prefLot_mat(2, choice_run)                             ; % see a few lines below for checking the RT to be reasonable
            reward_bool = aSP_prefLot_mat(3, choice_run)                    ;
            
            
            % Replay decision process originally, as long as it is [1,3]sec
            if rt < 1 ||  rt > 3
                rt = randi(2,1,1)+rand                                      ; % if actual RT differs, create a conforming random RT
            end
     
            
            % "Ask the subject, which lottery she wants to select"
            DrawFormattedText(window, texts('aSP_choice'), 'center', ...
                'center', white)                                            ;
            Screen('Flip', window)                                          ;
            WaitSecs(rt)                                                    ; % For this, use actual rt (see above though) for waiting

            
            % draw fixcross
            Screen('DrawLines', window, fixCoords,...
                fixWidth, white, [xCenter yCenter], 2)                      ; 
            Screen('Flip', window)                                          ;
    
            % drawing the checkerboard stim at the chosen location. The
            % reward_bool tells us win(1) or loss(0) ... we add 1 so we get
            % win=2, loss=1
            Screen('FillRect', window, reward(:,:,reward_bool+1),...
                rect_locs(:,:,picked_loc))                                  ;

            Screen('DrawTextures', window, masktexture, [],...
                mask_locs(:,:,picked_loc))                                  ;            
            Screen('Flip', window)                                          ;
            WaitSecs(2)                                                     ; % show feedback for 2 seconds
            
            % Now shuffle lotteries (i.e., advance in outer loop)
            
        end
   
        
    end
    
    
end

end
function save_data(exp_start, exp_end, total_earnings, subj_id)

% a function that neatly saves all data of the experiment and adds some
% readme information.
%
% Parameters
% ----------
% - exp_start: start of experiment (date time)
% - exp_end: end of experiment (date time)
% - total_earnings: the total amount of points gathered in the experiment
% - subj_id: ID of the subject
%
% Returns
% ----------
% -  None
%


%% Function start


% data 'readme' cells for quick reference in data analysis part

SP_Readme = cell(6,1);
SP_Readme(1,1) = cellstr('row1: which location was picked? 1=left 2=right');
SP_Readme(2,1) = cellstr('row2: how quickly was it picked in ms? (for passive DFE: how long was the jitter)');
SP_Readme(3,1) = cellstr('row3: was it rewarded? 0=no, 1=yes');
SP_Readme(4,1) = cellstr('row4: was the good lottery chosen? 0=no, 1=yes') ;
SP_Readme(5,1) = cellstr('row5: what is the current "run" in SP / counts the samples previous to choice');
SP_Readme(6,1) = cellstr('*Additional INFO*: the "payoff" array describes the four final draws from the reward urn');


% In Bandit, we do not have a feedback for the last 'draw' of indicating
% your preferred lottery. Thus, there are two cells less in the choice
% Bandit (whether feedback was rewarded, and which color it had) compared
% to the sample bandit.
% Furthermore, the Bandit data structure has separate bandit runs encoded
% in the 3rd dimension, whereas the DFE data structure does this in 2D
PFP_Readme = cell(5,1);
PFP_Readme(1,1) = cellstr('row1: which location was picked? 1=left 2=right');
PFP_Readme(2,1) = cellstr('row2: how quickly was it picked in ms? (for passive Bandit: how long was the jitter)');
PFP_Readme(3,1) = cellstr('row3: was the good lottery chosen? 0=no, 1=yes');
PFP_Readme(4,1) = cellstr('row4: *Only for sample*: was it rewarded? 0=no, 1=yes');
PFP_Readme(5,1) = cellstr('*Additional INFO*: separate bandit runs are encoded in the 3rd dimension of the data structure');


% one data structure with every game type as a nested structure, which then
% contains the data

activeSP.sampleData = aSP_mat                                        ;
activeSP.choiceData = aSP_prefLot_mat                            ;
activeSP.payoff = activeDFE_payoff                                         ;
activeSP.readme = SP_Readme                                               ;

passiveSP.sampleData = passiveDFE_mat                                      ;
passiveSP.choiceData = passiveDFE_prefLottery_mat                          ;
passiveSP.payoff = passiveDFE_payoff                                       ;
passiveSP.readme = SP_Readme                                              ;

activePFP.sampleData = aPFP_mat                                  ;
activePFP.choiceData = aPFP_prefLot_mat                      ;
activePFP.readme = PFP_Readme                                         ;

passivePFP.sampleData = passiveBandit_mat                                ;
passivePFP.choiceData = passiveBandit_prefLottery_mat                    ;
passivePFP.readme = PFP_Readme                                        ;

experimentalVars.expStart = exp_start                                ;
experimentalVars.expEnd = exp_end                                    ;
experimentalVars.subj_id = subj_id                                          ;

data.activeSP = activeSP                                                  ;
data.passiveSP = passiveSP                                                ;
data.activePFP = activePFP                                            ;
data.passivePFP = passivePFP                                          ;
data.experimentalVars = experimentalVars                                    ;   


%% Actual Saving Procedure
% Save all the data with an appropriate file name 

cd ..                                                                       ; % data dir is a sibling of the current working dir, not a child

% make sure we get the correct data dir
if exist(fullfile(pwd, 'data'),'dir')==7
    data_dir = fullfile(pwd, 'data')                                        ;
    sprintf('Saving in data dir: %s', data_dir)         
else
    mkdir(data)
    data_dir = fullfile(pwd, 'data')                                        ;  
    sprintf('creating new data dir: %s', data_dir) 
end

% saving it to the data dir
cur_time = datestr(datetime('now','Format','d_MMM_y_HH_mm_ss'))             ; % the current time and date                                          
fname = fullfile(data_dir, strcat('subj_', sprintf('%03d_', subj_id), ...
    cur_time, '.mat'))                                                      ; % fname consists of subj_id and datetime to avoid overwriting files
save(fname, 'data')                                                         ; % save it!

end
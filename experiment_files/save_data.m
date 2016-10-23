function save_data(exp_start, exp_end, total_earnings, subj_id, aPFP_mat, aPFP_prefLot_mat, aSP_mat, aSP_prefLot_mat)

% a function that neatly saves all data of the experiment and adds some
% readme information.
%
% Parameters
% ----------
% - exp_start: start of experiment (date time)
% - exp_end: end of experiment (date time)
% - total_earnings: the total amount of points gathered in the experiment
% - subj_id: ID of the subject
% - aPFP_mat: containing the data from the active Partial feedback Paradigm
% - aPFP_prefLot_mat: containing the "what was the best lottery" data
% - aSP_mat: containing the samples data from the active Sampling Paradigm
% - aSP_prefLot_mat: containing the choice data from the aSP
%
% Returns
% ----------
% -  None
%


%% Function start


% data 'readme' cells for quick reference in data analysis part

% In PFP, we do not have a feedback for the last 'draw' of indicating
% your preferred lottery. Thus, there are two cells less in the choice
% Bandit (whether feedback was rewarded, and which color it had) compared
% to the sample bandit.
% Furthermore, the Bandit data structure has separate bandit runs encoded
% in the 3rd dimension, whereas the DFE data structure does this in 2D
PFPreadme = cell(5,1);
PFPreadme(1,1) = cellstr('row1: which location was picked? 1=left 2=right');
PFPreadme(2,1) = cellstr('row2: how quickly was it picked in ms?');
PFPreadme(3,1) = cellstr('row3: was the good lottery chosen? 0=no, 1=yes');
PFPreadme(4,1) = cellstr('row4: was it rewarded? 0=no, 1=yes');
PFPreadme(5,1) = cellstr('*Additional INFO*: separate PFP runs are encoded in the 3rd dimension of the data structure');



% in Sampling Paradigm
SP_Readme = cell(6,1);
SP_Readme(1,1) = cellstr('row1: which location was picked? 1=left 2=right');
SP_Readme(2,1) = cellstr('row2: how quickly was it picked in ms? (for passive DFE: how long was the jitter)');
SP_Readme(3,1) = cellstr('row3: was it rewarded? 0=no, 1=yes');
SP_Readme(4,1) = cellstr('row4: was the good lottery chosen? 0=no, 1=yes') ;
SP_Readme(5,1) = cellstr('row5: Counts the samples previous to choice');



% one data structure with every game type as a nested structure, which then
% contains the data

% Partial Feedback Paradigm Data
aPFP.sampleData = aPFP_mat                                                  ;
aPFP.prefLotData = aPFP_prefLot_mat                                         ;
aPFP.readme = PFPreadme                                                     ;


% Sampling Paradigm Data
aSP.sampleData = aSP_mat                                                    ;
aSP.choiceData = aSP_prefLot_mat                                            ;
aSP.readme = SP_Readme                                                      ;


% other variables of interest
experimentalVars.expStart = exp_start                                       ;
experimentalVars.expEnd = exp_end                                           ;
experimentalVars.subj_id = subj_id                                          ;
experimentalVars.total_earnings = total_earnings                            ;


% Now the overarching data structure
data.activePartialFeedbackParadigm = aPFP                                   ;
data.activeSamplingParadigm = aSP                                           ;
data.experimentalVars = experimentalVars                                    ;   


%% Saving Procedure
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
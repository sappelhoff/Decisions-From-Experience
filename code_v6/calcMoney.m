function calcMoney(ID)

% Calculates the money that a subject has earned after participating in the
% four paradigms: bandit, banditReplay, sp, spReplay. Assumes that all data
% of the subject are in the working directory.
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
%
% calcMoney(ID)
%
% IN
% - ID: Identification number of the subject, an integer.
%
% OUT 
% - none, but prints out the earned reward and saves it as a file.

%% Function start

% Check that there is only data of current subject in working dir
if length(dir('*.mat')) ~=4
    error(['There are not exactly four data files in the working', ...
        ' directory. There must be the following .mat files:', ...
        ' bandit*.mat, banditReplay*.mat, sp*.mat, and spReplay*.mat'])
end


% Participants get a fixed amount for showing up. Furthermore, they
% can earn a set maximum in each, bandit and sp, depending on their
% performance. For the replays, they can earn a certain maximum depending
% on how well they reacted to distractors.
showUpMoney = 18;
banditMoney = 4;
spMoney     = 4;
rtMoney     = 4;



% Start calculating how much mney was earned
moneyEarned = showUpMoney;


% Rest of earnings is calculated according to performance in bandit
% paradigm and sp (sampling paradigm). First load the data into memory as
% structures. Also make sure, that data fits to ID
banditFile = dir('bandit*.mat');
banditName = char({banditFile.name});
if sscanf(banditName,'bandit_subj_%d') == ID, bandit = load(banditName);
else error('File name does not match up with ID (bandit).'), end

bReplayFile = dir('banditReplay*.mat');
bReplayName = char({bReplayFile.name});
if sscanf(bReplayName,'banditReplay_subj_%d')==ID,bReplay=load(bReplayName);
else error('File name does not match up with ID (bandit replay).'), end

spFile = dir('sp*.mat');
spName = char({spFile.name});
if sscanf(spName,'sp_subj_%d') == ID, sp = load(spName);
else error('File name does not match up with ID (sp).'), end

spReplayFile = dir('spReplay*.mat');
spReplayName = char({spReplayFile.name});
if sscanf(spReplayName,'spReplay_subj_%d')==ID,spReplay=load(spReplayName);
else error('File name does not match up with ID (sp replay).'), end


% Added money from bandit is calculated by taking percentage rewarded
% trials of bandit with the maximum of money that can be earned in the
% bandit.
banditPerc = sum(bandit.choiceMat(4,:))/length(bandit.choiceMat(4,:));
moneyEarned = moneyEarned + banditPerc * banditMoney;


% Added money from sp is calculated by taking the percentage of rewarded
% choices (NOT sampling)
choices = sp.choiceMat(4,:);
choices(isnan(choices)) = [];
spPerc = sum(choices)/length(choices);
moneyEarned = moneyEarned + spPerc * spMoney;

% Added money from replays is calculated by taking percentage of all RTs
% that were below a threshold defined in seconds.
threshRT = 0.4;

allRTs = [bReplay.BdistrMat, spReplay.SPdistrMat];
allRTs(isnan(allRTs)) = [];
rtPerc = sum(allRTs < threshRT)/length(allRTs);
moneyEarned = moneyEarned + rtPerc * rtMoney;

% Lastly, we round up the earned money 
moneyEarned = ceil(moneyEarned);

% Print out, how much money was earned
sprintf('You have earned %d Euro.',moneyEarned)

% Also save the amount of earnings to disk
dataDir = fullfile(pwd);
curTime = datestr(now,'dd_mm_yyyy_HH_MM_SS');
fname   = fullfile(dataDir,strcat('money_subj_', ...
    sprintf('%03d_',ID),curTime));
save(fname, 'moneyEarned', 'hours', 'banditPerc', 'spPerc', 'rtPerc');

end % function end
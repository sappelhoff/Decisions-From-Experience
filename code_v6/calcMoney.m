function calcMoney(hours, ID)

% Calculates the money that a subject has earned after participating in the
% four paradigms: bandit, banditReplay, sp, spReplay. 
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
%
% calcMoney(hours, ID)
%
% IN
% - hours: Number of started hours that the subject was present in the lab.
% - ID: Identification number of the subject, an integer.
%
% OUT 
% - none, but prints out the earned reward and saves it as a file.

%% Function start

% Check that there is only data of current subject in working dir
if length(dir('*.mat')) ~=4
    warning(['There are not exactly four data files in the working', ...
        ' directory. There must be .mat files for one subject only!', ...
        ' bandit*.mat, banditReplay*.mat, sp*.mat, and spReplay*.mat'])
end


% Participants get a fixed amount for each started hour. Furthermore, they
% can earn a set maximum in each, bandit and sp, depending on their
% performance.
hourMoney = 9;
banditMoney = 3.5;
spMoney = 3.5;


% Start calculating how much mney was earned
moneyEarned = hourMoney * hours;


% Rest of earnings is calculated according to performance in bandit
% paradigm and sp (sampling paradigm). First load the data into memory as
% structures. Also make sure, that data fits to ID
banditFile = dir('bandit*.mat');
banditName = char({banditFile.name});
if sscanf(banditName,'bandit_subj_%d') == ID, bandit = load(banditName);
else error('File name does not match up with ID (bandit).'), end

spFile = dir('sp*.mat');
spName = char({spFile.name});
if sscanf(spName,'sp_subj_%d') == ID, sp = load(spName);
else error('File name does not match up with ID (sp).'), end


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

% Lastly, we round up the earned money 
moneyEarned = ceil(moneyEarned);

% Print out, how much money was earned
sprintf('You have earned %d Euro.',moneyEarned)

% Also save the amount of earnings to disk
dataDir = fullfile(pwd);
curTime = datestr(now,'dd_mm_yyyy_HH_MM_SS');
fname   = fullfile(dataDir,strcat('money_subj_', ...
    sprintf('%03d_',ID),curTime));
save(fname, 'moneyEarned', 'hours', 'banditPerc', 'spPerc');

end % function end
function texts = produce_texts

% this is a function which produces all the texts we will display at some
% point during the experiment but not coherently after one another. For
% this, the function puts out a container map, through wich we can access
% the text strings with a specific key.
% 
% see: http://de.mathworks.com/help/matlab/ref/containers.map-class.html

%% Function start

texts = containers.Map;


% General texts
texts('break') = sprintf('Now there will be a short break\n\nbefore we continue with the next task.\n\n\nPress a key if you want to continue.');
texts('end') = sprintf('You are done.\n\nThank you for participating!\n\n\nPress a key to close.');
texts('shuffled') = sprintf('The lotteries have been shuffled.');
texts('payoff') = sprintf('You earned: ');
texts('next_intro') = sprintf('Welcome to the next task.\n\nPlease carefully read the following instructions.');


% Passive conditions texts
texts('replay1') = sprintf('You will now see a replay of\n\nsomeone''s performance on the previous task.\n\nThe same rules as before apply.');
texts('replay2') = sprintf('Please pay close attention\n\nand try to keep track of the reward.\n\nHowever, no physical action is required.');
texts('replay3') = sprintf('At the end, you will be asked, whether\n\nthe reward shown by the computer is correct.');


% Active PFP specific texts
texts('aPFP_PrefLot') = sprintf('Which lottery do you think was more profitable?\nPress [left] or [right].');
texts('aPFP_intro1') = sprintf('Whenever you see the + sign,\n\nuse [left] and [right] to choose a lottery.');
texts('aPFP_intro2') = sprintf('Each "win" outcome will be worth 1.\n\nEach "lose" outcome will be worth 0.');
texts('aPFP_intro3') = sprintf('Try to maximize your "win" outcomes.\n\nYou need to balance exploration\n\nand exploitation of your options.');


% Active SP specific texts
texts('aSPchoice') = sprintf('From which lottery do\nyou want to draw your payoff?\nPress [left] or [right]');

texts('aSP_intro1') = sprintf('Whenever you see the + sign,\n\nuse [left] and [right] to choose a lottery.');
texts('aSP_intro2') = sprintf('However, the outcomes you see\n\n reflect "samples".\n\nYou do not receive\n\npoints for these samples.');
texts('aSP_intro3') = sprintf('Once you have taken enough samples\n\nto know whether a certain lottery is profitable,\n\nyou can stop sampling and choose a lottery');
texts('aSP_intro4') = sprintf('Upon choice, the outcome is added\n\nto your payoff. After that,\n\nyou can continue to sample.\n\nHowever, the lotteries will be shuffled.');
texts('aSP_intro5') = sprintf('A "win" outcome upon choice will be worth 10.\n\nA "lose" outcome upon choice will be worth 0.');
texts('aSP_intro6') = sprintf('Feel free to explore your options through sampling.\n\nThe outcomes will only affect your reward once you finally decide for one option.');

end

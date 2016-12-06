function Stims = ptbStims(window, windowRect, screenNumber)

% Calculates all stimuli and returns them in their final format.
% To choose from *_locs variables, use (:,:,x), where x=1 for left, x=2 for
% right, x=3 for center
%
% Author: Stefan Appelhoff (stefan.appelhoff@gmail.com)
%
% Stims = produce_Stims(window, windowRect, screenNumber)
%
% IN:
% - window: the window opened initially with the PsychImaging command
% - windowRect: the rectangle that is returned together with the window
% - screenNumber: the screen that is being drawn to
%
% OUT:
% - Stims: a structure with the following fields
%       .fixWidth: how fat the fixcross lines should be
%       .fixCoords: the coordinates for the fixation cross
%       .colors1: red for checkerboard
%       .colors2: blue for checkerboard
%       .colors3: green for checkerboard
%       .rectLocs: checkerboard locs to choose from
%       .maskLocs: the locations where a mask will be displayed. 
%       .maskTexture: a texture that makes our square checkerboard circular
%

%% Function start

% Getting the dimensions of the screen in pixels and the center of the
% screen. Also get the color white as an RGB tuple.
[screenXpixels, screenYpixels] = Screen('WindowSize', window); 
[xCenter, yCenter] = RectCenter(windowRect); 
white = WhiteIndex(screenNumber); 

%--------------------------------------------------------------------------
%                      Preparing all Stimuli                              
%--------------------------------------------------------------------------

%% Fixation cross

% how large and fat should the fixcross be
fixCrossDimPix       = 20; 
Stims.fixWidth       = 2; 

% we define coordinates for two lines ...relative to 0 so that it's 
% centered on the screen: These are [x1, x2, y1, y2]
fixXcoords          = [-fixCrossDimPix fixCrossDimPix 0 0]; 
fixYcoords          = [0 0 -fixCrossDimPix fixCrossDimPix];
Stims.fixCoords     = [fixXcoords; fixYcoords];



%% Checkerboard stimuli


% How many squares do we want in our checkerboard stimuli? How large should
% the overall checkerboards be? Note, if you want an even number of
% squares, you have a problem. With this code you will get one square more
% than you wanted, if you type in an even number. E.g., 10-->11
squares             = 30;
stimSize            = 500; 

% Define colors, red=stim1, blue=stim2, green=distractor and
% white=common background
checkerColor1       = [1, 0, 0];
checkerColor2       = [0, 0, 1];
checkerColor3       = [0, 1, 0];
checkerBackground   = [1, 1, 1];

% Make the coordinates for our grid of squares
squares             = floor(squares/2); 
[xPos, yPos]        = meshgrid(-squares:1:squares); 

% Calculate the number of squares and reshape the matrices of coordinates
% into a vector
[s1, s2]            = size(xPos); 
numSquares          = s1 * s2; 
xPos                = reshape(xPos, 1, numSquares); 
yPos                = reshape(yPos, 1, numSquares);

% Determine size of the single rects within checkerboards. the individual
% rectangles making up an overall checkerboard have the dimensions of
% baseRect
dim                 = stimSize/s1; 
baseRect            = [0 0 dim dim];


% Scale the grid spacing to the size of our squares and centre. Place the
% stimuli in the middle between central fixation cross and border of the
% screen. Either on left "middle" or right "middle". Also one central
% checkerboard.
checkerXposLeft     = xPos .* dim + screenXpixels * 0.25; 
checkerYposLeft     = yPos .* dim + yCenter; 
checkerXposRight    = xPos .* dim + screenXpixels * 0.75;
checkerYposRight    = yPos .* dim + yCenter;
checkerXposCenter   = xPos .* dim + xCenter; 
checkerYposCenter   = yPos .* dim + screenYpixels * 0.75;

% Setting colors of the checkerboards - 1 is red, 2 is blue, 3 is green.
% For that, concatenate a vector where stimcolor and stimbackground change
% for each rect in the checkerboard. Lastly, append one more color, because
% our checkerboards have odd numbers of rects
colors1 = repmat([checkerColor1',checkerBackground'],1,numSquares/2-.5);
Stims.colors1 = [colors1, checkerColor1']; 

colors2 = repmat([checkerColor2',checkerBackground'],1,numSquares/2-.5);
Stims.colors2 = [colors2, checkerColor2'];

colors3 = repmat([checkerColor3',checkerBackground'],1,numSquares/2-.5);
Stims.colors3 = [colors3, checkerColor3'];



% Make our rectangle coordinates ... preallocate for speed, each column
% represents 4 'coordinates' of 1 rect
allRectsLeft    = nan(4,numSquares);
allRectsRight   = nan(4,numSquares);
allRectsCenter  = nan(4,numSquares);

% center the individual rects on the grid we created before
for i = 1:numSquares
    allRectsLeft(:, i) = CenterRectOnPointd(baseRect,...                
        checkerXposLeft(i), checkerYposLeft(i)); 
    allRectsRight(:, i) = CenterRectOnPointd(baseRect,...
        checkerXposRight(i), checkerYposRight(i));
    allRectsCenter(:, i) = CenterRectOnPointd(baseRect,...                
        checkerXposCenter(i), checkerYposCenter(i)); 
end

% Put the board locations into a matrix to choose from during the procedure
%  (:,:,1) will be left, (:,:,2) will be right, (:,:,3) for center
Stims.rectLocs = cat(3, allRectsLeft, allRectsRight, allRectsCenter); 



%% Circular apperture to lay over checkerboard


% Respective coordinates for the apperture
maskXleft   = xCenter - screenXpixels * 0.25; 
maskXright  = xCenter + screenXpixels * 0.25;
maskYcenter = yCenter + screenYpixels * 0.25;

% the apperture will be centered within a rect, which is centered on our
% Stims. The rect has to be big enough to cover the checkerboard 
% completely, but not bigger.
maskRect    = [0 0 stimSize stimSize];

rightMask   = CenterRectOnPointd(maskRect, maskXright, yCenter); 
leftMask    = CenterRectOnPointd(maskRect, maskXleft, yCenter);
centerMask  = CenterRectOnPointd(maskRect, xCenter, maskYcenter); 

% put the two locations into one matrix to choose from during the procedure
% (:,:,1) will be left, (:,:,2) will be right, (:,:,3) will be center
Stims.maskLocs = cat(3, leftMask, rightMask, centerMask);

% Our apperture is a texture: basically a circle within a rect, where the
% interior of the circle is 100% transparent and the rest of the rect looks
% like the background of the experimental screen. We proceed as follows:
% 1) Circle(x) creates an x X x logical matrix. x determines the resolution
% 2) We add a third dimension representing alpha levels (transparency)
% 3) We turn interior of circle=0 and exterior=1
% 4) We turn the exterior of the circle to grey ... interior stays 0
% 5) We turn transparency levels for "grey" to 1 again ... 0% transparent
% ... the interior stays 100% transparent

mask        = Circle(100);
mask(:,:,2) = mask; 
mask        = ~mask;
mask        = double(mask) * white/2;
mask(:,:,2) = mask(:,:,2) * 2; 

% PTB call to make our matrix 'mask' a texture on the main window 
Stims.maskTexture = Screen('MakeTexture', window, mask); 



%% Function end
end
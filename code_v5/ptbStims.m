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

[screenXpixels, screenYpixels] = Screen('WindowSize', window)               ; % geting the dimensions of the screen in pixels
[xCenter, yCenter] = RectCenter(windowRect)                                 ; % getting the center of the screen

white = WhiteIndex(screenNumber)                                            ; % This function returns an RGB tuble for 'white' = [1 1 1]


%-------------------------------------------------------------------------%
%                      Preparing all Stimuli                              %
%-------------------------------------------------------------------------%

%% Fixation cross

fixCrossDimPix      = 20                                                    ; % how large should the fixcross be
Stims.fixWidth            = 2                                                     ; % how fat should the fixcross lines be

% we define coordinates for two lines
fixXcoords          = [-fixCrossDimPix fixCrossDimPix 0 0]                  ; % relative to 0 so that it's centered on the screen
fixYcoords          = [0 0 -fixCrossDimPix fixCrossDimPix]                  ;
Stims.fixCoords           = [fixXcoords; fixYcoords]                              ;



%% Checkerboard stimuli
squares             = 10                                                    ; % squares per row in checkerboard: if even, it will later be rounded to next highest odd number
Stimsize            = 200                                                   ; % how large the checkerboard stimuli should be
checkerColor1       = [1, 0, 0]                                             ; % color for stim 1: red
checkerColor2       = [0, 0, 1]                                             ; % color for stim 2: blue
checkerColor3       = [0, 1, 0]                                             ; % color for stim 3: green ... distraction stim
checkerBackground   = [1, 1, 1]                                             ; % background for both Stims: white

% Make the coordinates for our grid of squares
squares             = floor(squares/2)                                      ; % processing step for meshgrid, to go from -squares to +squares and get dim: squares+1
[xPos, yPos]        = meshgrid(-squares:1:squares)                          ; % with this code, we can only display boards with an odd number of single rects as the grid crosses 0

% Calculate the number of squares and reshape the matrices of coordinates
% into a vector
[s1, s2]            = size(xPos)                                            ; % could also take yPos here, they have the same dimensions: it's a square grid after all
numSquares          = s1 * s2                                               ; % calculate overall number of squares
xPos                = reshape(xPos, 1, numSquares)                          ; 
yPos                = reshape(yPos, 1, numSquares)                          ;

% Determine size of the single rects within checkerboards
dim                 = Stimsize/s1                                           ; % divide overall size by number of rects per row in checkerboard
baseRect            = [0 0 dim dim]                                         ; % the individual rectangles making up an overall checkerboard have these dimensions


% Scale the grid spacing to the size of our squares and centre
checkerXposLeft     = xPos .* dim + screenXpixels * 0.25                    ; % vertical: stim centered on middle between screen border and fixation cross
checkerYposLeft     = yPos .* dim + yCenter                                 ; % horizontal: always centered on middle between screen borders
checkerXposRight    = xPos .* dim + screenXpixels * 0.75                    ;
checkerYposRight    = yPos .* dim + yCenter                                 ;
checkerXposCenter   = xPos .* dim + xCenter                                 ; % central checkerboard will be needed for instruction screen
checkerYposCenter   = yPos .* dim + screenYpixels * 0.75                    ;

% Setting colors of the checkerboards - 1 is red, 2 is blue, 3 is green
colors1 = repmat([checkerColor1',checkerBackground'],1,numSquares/2-.5)     ; % concatenate a vector where stimcolor and stimbackground change for each rect in the checkerboard
Stims.colors1 = [colors1, checkerColor1']                                         ; % append one more color, because our checkerboards have odd numbers of rects

colors2 = repmat([checkerColor2',checkerBackground'],1,numSquares/2-.5)     ;
Stims.colors2 = [colors2, checkerColor2']                                         ;

colors3 = repmat([checkerColor3',checkerBackground'],1,numSquares/2-.5)     ;
Stims.colors3 = [colors3, checkerColor3']                                         ;





% Make our rectangle coordinates
allRectsLeft    = nan(4,numSquares)                                         ; % preallocate for speed ... each column represents 4 'coordinates' of 1 rect
allRectsRight   = nan(4,numSquares)                                         ;
allRectsCenter  = nan(4,numSquares)                                         ;

for i = 1:numSquares
    allRectsLeft(:, i) = CenterRectOnPointd(baseRect,...                
        checkerXposLeft(i), checkerYposLeft(i))                             ; % center the individual rects on the grid we created before
    allRectsRight(:, i) = CenterRectOnPointd(baseRect,...
        checkerXposRight(i), checkerYposRight(i))                           ;
    allRectsCenter(:, i) = CenterRectOnPointd(baseRect,...                
        checkerXposCenter(i), checkerYposCenter(i))                         ; 
end

% Put the board locations into a matrix to choose from during the procedure
Stims.rectLocs = cat(3, allRectsLeft, allRectsRight, allRectsCenter)              ; %  (:,:,1) will be left, (:,:,2) will be right, (:,:,3) for center



%% Circular apperture to lay over checkerboard


% Respective coordinates for the apperture
maskXleft   = xCenter - screenXpixels * 0.25                                ; % we are not working with a grid here, so it's just a single coordinate point
maskXright  = xCenter + screenXpixels * 0.25                                ;
maskYcenter = yCenter + screenYpixels * 0.25                                ;

% the apperture will be centered within a rect, which is centered on our
% Stims
maskRect    = [0 0 Stimsize Stimsize]                                       ; % the rect has to be big enough to cover the checkerboard completely, but not bigger

rightMask   = CenterRectOnPointd(maskRect, maskXright, yCenter)             ; % center the 'destination rect' for the mask directly on our checkerboard
leftMask    = CenterRectOnPointd(maskRect, maskXleft, yCenter)              ;
centerMask  = CenterRectOnPointd(maskRect, xCenter, maskYcenter)            ; % we also need to mask the checkerboard shown during instructions

% put the two locations into one matrix to choose from during the procedure
Stims.maskLocs    = cat(3, leftMask, rightMask, centerMask)                       ; % (:,:,1) will be left, (:,:,2) will be right, (:,:,3) will be center

% Our apperture is a texture: basically a circle within a rect, where the
% interior of the circle is 100% transparent and the rest of the rect looks
% like the background of the experimental screen
mask        = Circle(100)                                                   ; % the argument x to Circle(x) determines the 'resolution' of our circle ... if it's too high, it will take too long to compute
mask(:,:,2) = mask                                                          ; % add a 3rd dimension to the texture to represent alpha levels (transparency)
mask        = ~mask                                                         ; % make sure that interior of circle=0, exterior=1
mask        = double(mask) * white/2                                        ; % color the exterior of the circle grey, as the background of experimental screen. interior of the circle i 0, so it is not affected. 
mask(:,:,2) = mask(:,:,2) * 2                                               ; % exterior of 2nd layer(=alpha levels) is now also set to 'grey'=0.5 --> we want the exterior of the circle to be 1(0% transparency) 

Stims.maskTexture = Screen('MakeTexture', window, mask)                           ; % PTB call to make our matrix 'mask' a texture on the main window 



%% Function end
end
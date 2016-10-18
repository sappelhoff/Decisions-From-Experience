function [fixWidth, fixCoords, colors_1, colors_2, rect_locs, mask_locs, masktexture] = produce_stims

% a function to calculate all stimuli and return them in their final
% format.
%
% to choose from *_locs variables, use (:,:,x), where x=1 for left, x=2 for
% right, x=3 for center
%
%
% Parameters
% ----------
% - None
%
% Returns
% ----------
% - fixWidth: how fat the fixcross lines should be
% - fixCoords: the coordinates for the fixation cross
% - colors_1: red for checkerboard
% - colors_2: blue for checkerboard
% - rect_locs: checkerboard locs to choose from
% - mask_locs: the locations where a mask will be displayed. 
% - masktexture: a texture that makes our square checkerboard circular
%


%-------------------------------------------------------------------------%
%                      Preparing all Stimuli                              %
%-------------------------------------------------------------------------%

%% Fixation cross

fixCrossDimPix = 20                                                         ; % how large should the fixcross be
fixWidth = 2                                                            ; % how fat should the fixcross lines be


% we define coordinates for two lines
fix_xCoords = [-fixCrossDimPix fixCrossDimPix 0 0]                          ; % relative to 0 so that it's centered on the screen
fix_yCoords = [0 0 -fixCrossDimPix fixCrossDimPix]                          ;
fixCoords = [fix_xCoords; fix_yCoords]                                      ;


%% Checkerboard stimuli
squares = 10                                                                ; % squares per row in checkerboard: if even, it will later be rounded to next highest odd number
stim_size = 200                                                             ; % how large the checkerboard stimuli should be
checker_color_1 = [1, 0, 0]                                                 ; % color for stim 1: red
checker_color_2 = [0, 0, 1]                                                 ; % color for stim 2: blue
checker_background = [1, 1, 1]                                              ; % background for both stims: white

% Make the coordinates for our grid of squares
squares = floor(squares/2)                                                  ; % processing step for meshgrid, to go from -squares to +squares and get dim: squares+1
[xPos, yPos] = meshgrid(-squares:1:squares)                                 ; % with this code, we can only display boards with an odd number of single rects as the grid crosses 0

% Calculate the number of squares and reshape the matrices of coordinates
% into a vector
[s1, s2] = size(xPos)                                                       ; % could also take yPos here, they have the same dimensions: it's a square grid after all
numSquares = s1 * s2                                                        ; % calculate overall number of squares
xPos = reshape(xPos, 1, numSquares)                                         ; 
yPos = reshape(yPos, 1, numSquares)                                         ;

% Determine size of the single rects within checkerboards
dim = stim_size/s1                                                          ; % divide overall size by number of rects per row in checkerboard
baseRect = [0 0 dim dim]                                                    ; % the individual rectangles making up an overall checkerboard have these dimensions


% Scale the grid spacing to the size of our squares and centre
checker_xPosLeft = xPos .* dim + screenXpixels * 0.25                       ; % vertical: stim centered on middle between screen border and fixation cross
checker_yPosLeft = yPos .* dim + yCenter                                    ; % horizontal: always centered on middle between screen borders
checker_xPosRight = xPos .* dim + screenXpixels * 0.75                      ;
checker_yPosRight = yPos .* dim + yCenter                                   ;
checker_xPosCenter = xPos .* dim + xCenter                                  ; % central checkerboard will be needed for instruction screen
checker_yPosCenter = yPos .* dim + screenYpixels * 0.75                     ;

% Setting colors of the checkerboards - 1 is red, 2 is blue
colors_1 = repmat([checker_color_1',checker_background'],1,numSquares/2-.5) ; % concatenate a vector where stimcolor and stimbackground change for each rect in the checkerboard
colors_1 = [colors_1, checker_color_1']                                     ; % append one more color, because our checkerboards have odd numbers of rects

colors_2 = repmat([checker_color_2',checker_background'],1,numSquares/2-.5) ;
colors_2 = [colors_2, checker_color_2']                                     ;


% Make our rectangle coordinates
allRectsLeft = nan(4, numSquares)                                           ; % preallocate for speed ... each column represents 4 'coordinates' of 1 rect
allRectsRight = nan(4, numSquares)                                          ;
allRectsCenter = nan(4,numSquares)                                          ;

for i = 1:numSquares
    allRectsLeft(:, i) = CenterRectOnPointd(baseRect,...                
        checker_xPosLeft(i), checker_yPosLeft(i))                           ; % center the individual rects on the grid we created before
    allRectsRight(:, i) = CenterRectOnPointd(baseRect,...
        checker_xPosRight(i), checker_yPosRight(i))                         ;
    allRectsCenter(:, i) = CenterRectOnPointd(baseRect,...                
        checker_xPosCenter(i), checker_yPosCenter(i))                       ; 
end

% Put the board locations into a matrix to choose from during the procedure
rect_locs = cat(3, allRectsLeft, allRectsRight)                             ; %  (:,:,1) will be left, (:,:,2) will be right


%% Circular apperture to lay over checkerboard


% Respective coordinates for the apperture
mask_xLeft = xCenter - screenXpixels *0.25                                  ; % we are not working with a grid here, so it's just a single coordinate point
mask_xRight = xCenter + screenXpixels *0.25                                 ;
mask_yCenter = yCenter + screenYpixels * 0.25                               ;

% the apperture will be centered within a rect, which is centered on our
% stims
maskRect = [0 0 stim_size stim_size]                                        ; % the rect has to be big enough to cover the checkerboard completely, but not bigger

right_mask = CenterRectOnPointd(maskRect, mask_xRight, yCenter)             ; % center the 'destination rect' for the mask directly on our checkerboard
left_mask = CenterRectOnPointd(maskRect, mask_xLeft, yCenter)               ;
center_mask = CenterRectOnPointd(maskRect, xCenter, mask_yCenter)           ; % we also need to mask the checkerboard shown during instructions

% put the two locations into one matrix to choose from during the procedure
mask_locs = cat(3, left_mask, right_mask, center_mask)                      ; % (:,:,1) will be left, (:,:,2) will be right, (:,:,3) will be center

% Our apperture is a texture: basically a circle within a rect, where the
% interior of the circle is 100% transparent and the rest of the rect looks
% like the background of the experimental screen
mask = Circle(100)                                                          ; % the argument x to Circle(x) determines the 'resolution' of our circle ... if it's too high, it will take too long to compute
mask(:,:,2) = mask                                                          ; % add a 3rd dimension to the texture to represent alpha levels (transparency)
mask = ~mask                                                                ; % make sure that interior of circle=0, exterior=1
mask = double(mask) * grey                                                  ; % color the exterior of the circle grey, as the background of experimental screen. interior of the circle i 0, so it is not affected. 
mask(:,:,2) = mask(:,:,2) * 2                                               ; % exterior of 2nd layer(=alpha levels) is now also set to 'grey'=0.5 --> we want the exterior of the circle to be 1(0% transparency) 

masktexture = Screen('MakeTexture', window, mask)                           ; % PTB call to make our matrix 'mask' a texture on the main window 




end
function clc(inputState)
% Overloaded clc function to prevent students from 
%   clearing autograder dialog
% Place into Autograder directory
%
% inputState    :   a persistent variable to set clc action
%
% clc(0)        :   deactivates traditional clc
%                     subsequent clc calls clear screen
%
% clc(1)        :   reactivates traditional clc
%                     all subsequent clc calls from within autograder 
%                     base directory don't result in a cleared screen
%
% date: 4/19/12

% loads / keeps clc state
persistent state        

% flow control for clc based on state variable
if nargin == 0 
    if state == 1   %clc active
        builtin('clc');
    end
    
    return;
end

% load state and update; however don't evaluate clc if turning state on
if nargin == 1
    if isa(state, 'double')
        state = inputState;
    end
        
    return;
end


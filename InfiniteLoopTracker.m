% Initialize timer and associated variables to catch infinite loop during 
% the grading process.

% autograderTimer = timer('TasksToExecute', 2, 'ExecutionMode', 'fixedRate', 'BusyMode', 'error');
autograderTimer = timer();

autograderTimer.StartFcn = {@AutoGraderDisplayStartGradingMessage, 'Started grading function [...]'};
autograderTimer.StopFcn = {@AutoGraderDisplayEndGradingMessage, 'Ended grading function[...]'};
autograderTimer.ErrorFcn = {@AutoGraderDisplayErrorMessage, 'Function [...] timed out'};

autograderTimer.TimerFcn = @RunInfiniteLoop;
% autograderTimer.TimerFcn = @(x,y)disp('Hello World!');

%%

start(autograderTimer);

stop(autograderTimer);

delete(autograderTimer);


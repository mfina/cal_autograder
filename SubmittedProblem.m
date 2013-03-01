classdef SubmittedProblem < handle
    properties
        problemDisplayName = 'UNDEFINED';
        problemFileName = 'UNDEFINED';
        problemFunctionHandle;
        isProblemSubmitted;
    end
    
    methods
        function obj = SubmittedProblem(problemDisplayName, problemFileName, problemFunctionHandle, isProblemSubmitted)
            obj.problemDisplayName = problemDisplayName;
            obj.problemFileName = problemFileName;
            obj.problemFunctionHandle = problemFunctionHandle;
            obj.isProblemSubmitted = isProblemSubmitted;            
        end        
    end 
end
        
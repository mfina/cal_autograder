classdef Problem < handle
    properties
        problemDisplayName = '';
        problemFileName = '';
        problemType = '';
        isEffortBased = false;
        problemTestCases = {};
        problemFunction;
    end

    methods
        function obj = Problem(problemDisplayName, problemType, isEffortBased, problemTestCases, loadSolFcn)
            obj.problemDisplayName = problemDisplayName;
            obj.problemType = problemType;
            obj.isEffortBased = isEffortBased;
            obj.problemTestCases = problemTestCases;
            
            % MF - modification to extract problemFileName from within problemDisplayName for problemType "function"
            if strcmpi(problemType, 'function') || strcmpi(problemType, 'script') || strcmpi(problemType, 'plot_visual') || strcmpi(problemType, 'recursive')
                % strip name from within single quotes, e.g. 'Problem4.m'
                commaInd = strfind(obj.problemDisplayName,'''');
                if isempty(commaInd)   %extract problemFileName from within problemDisplayName
                    exception = MException('Problem:InvalidInput', 'problemFileName was not set. Include within single quotes in problemName');
                    throw(exception);
                end
                tempFileName = obj.problemDisplayName(commaInd(1)+1:commaInd(2)-1);
                
                % strip '.m' if remains in filename
                dotMInd = strfind(tempFileName, '.m');
                if ~isempty(dotMInd)
                    tempFileName(dotMInd:dotMInd+1) = [];
                end
                obj.problemFileName = tempFileName;
                obj.problemFunction = loadSolFcn(obj.problemFileName);
            end
            
            if strcmp(problemType, 'visually-inspect-plot') && isEffortBased == true
                exception = MException('Problem:InvalidInput', 'Visual Inspection Problems cannot be effort based.');
                throw(exception);
            end
        end        
                
        function addTestCase(obj, newTestCase)
            obj.problemTestCases{length(obj.problemTestCases) + 1} = newTestCase;
        end
        
        function [totalPoints] = getTotalPoints(obj)
            totalPoints = 0;
            for I = 1:length(obj.problemTestCases)
                totalPoints = totalPoints + obj.problemTestCases{I}.getTotalPoints();
            end
        end
    end
end
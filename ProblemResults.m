classdef ProblemResults < handle
    properties
        problemDisplayName;
        problemFileName;
        problemStatus = ''
        problemTestCaseResults = {};
    end

    methods
        function obj = ProblemResults(problemDisplayName, problemFileName, problemStatus, problemTestCaseResults)
            obj.problemDisplayName = problemDisplayName;
            obj.problemFileName = problemFileName;
            obj.problemStatus = problemStatus;
            obj.problemTestCaseResults = problemTestCaseResults;
        end
                
        function addTestCaseResult(obj, newTestCaseResult)
            obj.problemTestCaseResults{length(obj.problemTestCaseResults) + 1} = newTestCaseResult;
        end
        
        function [totalPoints] = getTotalPoints(obj)
            totalPoints = 0;
            for I = 1:length(obj.problemTestCaseResults)
                totalPoints = totalPoints + obj.problemTestCaseResults{I}.getTotalPoints();
            end
        end
    end
end
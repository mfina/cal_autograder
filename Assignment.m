classdef Assignment < handle
    properties
        assignmentName = {'UNDEFINED'}
        assignmentProblems = {};
    end

    methods
        function obj = Assignment(assignmentName, assignmentProblems)
            obj.assignmentName{1} = assignmentName;
            obj.assignmentProblems = assignmentProblems;
        end
                
        function addProblem(obj, assignmentProblem)
            obj.assignmentProblems{length(obj.assignmentProblems) + 1} = assignmentProblem;
        end
        
        function addProblemArray(obj, assignmentProblemArray)
            for I = 1:length(assignmentProblemArray)
                obj.assignmentProblems{I} = assignmentProblemArray(I);
            end
        end
        
        function [assignmentProblem] = getProblem(obj, problemFileName)
            for I = 1:length(obj.assignmentProblems)
                if strcmp(obj.assignmentProblems{I}.problemFileName, problemFileName)
                    assignmentProblem = obj.assignmentProblems{I};
                    break
                end
            end
        end
        
        function [points] = getTotalAssignmentPoints(obj)
           
            points = 0;
           
            for I = 1:length(obj.assignmentProblems)
                for J = 1:length(obj.assignmentProblems{I}.problemTestCases)
                    points = points + sum(obj.assignmentProblems{I}.problemTestCases{J}.testCasePoints);
               end
            end
        end
    end
end
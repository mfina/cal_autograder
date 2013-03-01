classdef TestCaseResults < handle
    properties
        originalTestCase;
        studentOutput = {};
        correctOutput = {};
        pointsAwarded = [];
    end

    methods
        function obj = TestCaseResults(originalTestCase, studentOutput, correctOutput, pointsAwarded)
            obj.originalTestCase = originalTestCase;
            obj.studentOutput = studentOutput;
            obj.correctOutput = correctOutput;
            obj.pointsAwarded = pointsAwarded;
        end
        
        function [totalPoints] = getTotalPoints(obj)
           totalPoints = sum(obj.pointsAwarded);
        end
    end
end
classdef Student < handle
    properties
        studentFirstName = 'UNDEFINED';
        studentLastName = 'UNDEFINED';
        studentSID = 0;
        studentFolderName = '';
        studentSubmittedProblems = {};
        studentGrade = 0;
        studentGradedProblems = {};
        hasBeenGraded = 0;
    end

    % MODIFY all get*Problem functions to use problemDisplayName property
    %  rather than problemFileName property, which may not be unique
    methods
        function obj = Student(studentFirstName, studentLastName, studentSID, studentFolderName, studentSubmittedProblems, studentGrade)
            obj.studentFirstName = studentFirstName;
            obj.studentLastName = studentLastName;
            obj.studentSID = studentSID;
            obj.studentFolderName = studentFolderName;
            obj.studentSubmittedProblems = studentSubmittedProblems;
            obj.studentGrade = studentGrade;
        end

        function addSubmittedProblem(obj, f)
            obj.studentSubmittedProblems{length(obj.studentSubmittedProblems) + 1} = f;
        end
        
        function [submittedProblem] = getSubmittedProblem(obj, problemFileName)
            submittedProblem = [];       
            for I = 1:length(obj.studentSubmittedProblems)
                if strcmp(obj.studentSubmittedProblems{I}.problemFileName, problemFileName)
                    submittedProblem = obj.studentSubmittedProblems{I};
                    break;
                end
            end
        end
        
        function addGradedProblem(obj, newGradedProblem)
            obj.studentGradedProblems{length(obj.studentGradedProblems) + 1} = newGradedProblem;
        end
        
        function [gradedProblem] = getGradedProblem(obj, problemFileName)
            gradedProblem = [];       
            for I = 1:length(obj.studentGradedProblems)
                if strcmp(obj.studentGradedProblems{I}.problemFileName, problemFileName)
                    gradedProblem = obj.studentGradedProblems{I};
                    break;
                end
            end
        end
        
        % MF - added to tabulate problem score
        function [problemGrade] = getProblemGrade(obj, problemFileName)
            
            % check for problem submission
            [submittedProblem] = obj.getSubmittedProblem(problemFileName);
            if ~submittedProblem.isProblemSubmitted        % -1, problem not submitted
                problemGrade = -1;                      
                return;
            end
            
            % check that problemFileName is recognized
            [gradedProblem] = obj.getGradedProblem(problemFileName);
            if isempty(gradedProblem)       % -2, problemFileName not explicitly found for obj, check problemFileName spelling
                fprintf(['\nWarning: problemFileName ''', problemFileName, ''' was not found\n\n']);
                problemGrade = -2;
                return;
            end
            
            % tabluate total problem score, i.e. sum points for each test case
            problemGrade = 0;
            for I = 1:length(gradedProblem.problemTestCaseResults)
                problemGrade = problemGrade + sum(gradedProblem.problemTestCaseResults{I}.pointsAwarded);
            end 
        end
        
        function [studentGrade] = getStudentGrade(obj)
            
            studentGrade = 0;
            
            for I = 1:length(obj.studentGradedProblems)
               for J = 1:length(obj.studentGradedProblems{I}.problemTestCaseResults)
                   studentGrade = studentGrade + sum(obj.studentGradedProblems{I}.problemTestCaseResults{J}.pointsAwarded);
               end
            end
            
            obj.studentGrade = studentGrade;
        end
    end
end
function [ autosaveStudentArray ] = AutoLoadFunctionPointers( studentPath, assignment, autosaveStudentArray )
%AutoLoadFunctionPointers Reinitialize student function pointers for AutoSave file
%   When saving an array function pointers are lost. This function will
%   reload the student submission function pointers

for I=1:length(autosaveStudentArray)
    
    % Initialize studentSubmittedProblems to an empty cell array
    autosaveStudentArray(I).studentSubmittedProblems = {};
    
    submissionAttachmentsPath = fullfile(studentPath, autosaveStudentArray(I).studentFolderName, 'Submission Attachment(s)');
    
    if isdir(submissionAttachmentsPath)
        assignmentProblems = assignment.assignmentProblems;
        
        for P = 1:length(assignmentProblems)
            
            problemDisplayName = assignmentProblems{P}.problemDisplayName;
            problemFileName = assignmentProblems{P}.problemFileName;
            
            if ~was_submitted(submissionAttachmentsPath, problemFileName)
                
                % TODO: find the function equivalent of nil
                autosaveStudentArray(I).addSubmittedProblem(SubmittedProblem(problemDisplayName, problemFileName, 0, false));
                
            else
                
                warning off; userpath(submissionAttachmentsPath); warning on;   % overloaded clc will produce annoying messages
                problemFunctionHandle = str2func(problemFileName);
                userpath('reset');  

                autosaveStudentArray(I).addSubmittedProblem( ...
                    SubmittedProblem(problemDisplayName, problemFileName, problemFunctionHandle, true));
                
            end
        end
    end
end

    function [out] = was_submitted(path, name)
        % Checks if function is in the path.
        
        % get files in directory
        files = dir(path);
        out = 0;
        
        % Start at 3 to account for '.' and '..'
        
        for i = 3:length(files)
            
            filename = files(i).name;
            
            if strcmpi(filename(end-1:end), '.m')
                
                if strcmpi(filename(1:end-2), name)
                    out = 1;
                    return
                end
                
            end
        end
        
    end

    function [studentFileName] = getStudentFileName(path, name)
        % Gets the exact name that the student named their file because some
        % stuents may have named their files with incorrect case sensitivity.
        
        % get files in directory
        files = dir(path);
        studentFileName = '';
        
        % Start at 3 to account for '.' and '..'
        
        for i = 3:length(files)
            
            filename = files(i).name;
            
            if strcmpi(filename(end-1:end), '.m')
                
                if strcmpi(filename(1:end-2), name)
                    studentFileName = filename(1:end-2);
                    return
                end
                
            end
        end
        
    end

end

classdef StudentOutputFileWriter < handle
    properties
        studentPath = 'UNDEFINED';
        status = false;                         % added MF. To toggle write function
        filename = '';                          % added MF. Set by default to "AutoGraderOutput.txt"
    end
    
    methods
        function obj = StudentOutputFileWriter(studentPath, filename)
            if nargin < 2
                obj.filename = 'AutoGraderOutput.txt';
                obj.status = true;
            elseif ~(strcmpi(filename,'none') || strcmpi(filename,'off'))
                obj.filename = filename;
                obj.status = true;
            end
            obj.studentPath = studentPath;
        end
        
        % TODO: See if it's good to return obj here
        
        function [obj] = generateOutputFile(obj, assignment, student)
            
            if ~obj.status      % returns without writing output
                return;
            end
            
            %Create path to student text file, fNameText
            fNameText = fullfile(obj.studentPath, student.studentFolderName, 'Feedback Attachment(s)', obj.filename);
            fileID = fopen(fNameText, 'w+');
            
            fprintf(fileID, ['AutoGrader Output for student: ' student.studentFirstName ' ' student.studentLastName ' on ' assignment.assignmentName{1} '\n\n']);
            fprintf(fileID, ['Your grade is ' num2str(student.getStudentGrade()) ' out of ' num2str(assignment.getTotalAssignmentPoints()) '\n\n']);
            fprintf(fileID, ['Here is your problem breakdown: \n\n']);
            
            for I = 1:length(assignment.assignmentProblems)
                
                gradedProblem = student.studentGradedProblems{I};
                
                assignmentProblem = assignment.getProblem(gradedProblem.problemFileName);
                
                % fprintf(fileID, ['\tProblem ' num2str(I) ': ' gradedProblem.problemName '\n']);         % Original output
                fprintf(fileID, [' ' gradedProblem.problemDisplayName ':\n\n']);
                
                fprintf(fileID, ['You earned ' num2str(gradedProblem.getTotalPoints()) ' points out of ' num2str(assignmentProblem.getTotalPoints()) ' points' '\n\n\n']);
                
                % The student's function was submitted correctly and
                % graded. The number of points the student earned will be
                % displayed.
                if strcmp(gradedProblem.problemStatus, 'GRADED')
                    
                    for J = 1:length(gradedProblem.problemTestCaseResults)
                        
                        problemTestCaseResult = gradedProblem.problemTestCaseResults{J};
                        fprintf(fileID, ['Test Case: ' problemTestCaseResult.originalTestCase.testCaseName '\n']);
                        fprintf(fileID, ['Test Case Description: ' problemTestCaseResult.originalTestCase.testCaseMessage '\n']);
                        fprintf(fileID, ['You scored: ' '[' num2str(problemTestCaseResult.pointsAwarded) ']' '\n']);
                        fprintf(fileID, ['Total possible points: ' '[' num2str(problemTestCaseResult.originalTestCase.testCasePoints) ']' '\n\n\n']);
                        
                        
                        % cprintf does not automatically transpose;
                        %  some work is required to prevent this from
                        %  crashing program
                        try
                            % Print Student Output:
                            lenStudentOutput = length(problemTestCaseResult.studentOutput);
                            studentOutputCell = {};   %use cellStr since easier to see output errors
                            studentOutputCell = [studentOutputCell; {'Your output was: \n'}];
                            
                            for indOutArg = 1:lenStudentOutput % thru each output arguments
                                if lenStudentOutput > 1
                                    studentOutputCell = [studentOutputCell; {sprintf('\toutput argument %s:\n', num2str(indOutArg))}];
                                end
                                studentOutArgTemp = problemTestCaseResult.studentOutput{indOutArg};
                                
                                if isa(studentOutArgTemp, 'cell') %potentially buried cell (assume only one depth level); extract contents 
                                    for indCell = 1:numel(studentOutArgTemp)
                                        studentOutputCell = [studentOutputCell; {sprintf('\t\tcell #%s:\n', num2str(indCell))}];  
                                        studentOutputTemp = cprintf(studentOutArgTemp{indCell});
                                        sizeStudentTemp = size(studentOutputTemp);
                                        studentOutputTemp = [repmat(sprintf('\t'), sizeStudentTemp(1), 3), ...
                                            studentOutputTemp, repmat(sprintf('\n'), sizeStudentTemp(1), 1)];
                                        studentOutputTemp = mat2cell(studentOutputTemp, ...
                                            ones(sizeStudentTemp(1),1), (sizeStudentTemp(2)+4)*ones(sizeStudentTemp(1),1));
                                        studentOutputCell = [studentOutputCell; studentOutputTemp{:}];
                                    end
                                    
                                elseif isa(studentOutArgTemp, 'double') || isa(studentOutArgTemp, 'char') 
                                    studentOutputTemp = cprintf(studentOutArgTemp);
                                    sizeStudentTemp = size(studentOutputTemp);
                                    studentOutputTemp = [repmat(sprintf('\t'), sizeStudentTemp(1), 2), ...
                                        studentOutputTemp, repmat(sprintf('\n'), sizeStudentTemp(1), 1)];
                                    studentOutputTemp = mat2cell(studentOutputTemp, ...
                                        ones(sizeStudentTemp(1),1), (sizeStudentTemp(2)+3));
                                    studentOutputCell = [studentOutputCell; studentOutputTemp{:}];
                                    
                                elseif isa(studentOutArgTemp, 'struct')
                                    error('Must modify studentOutputFileWriter for struct class');
                                    
                                end
                                
                                studentOutputCell = [studentOutputCell; {sprintf('\n')}];
                            end
                            studentOutputCell = [studentOutputCell; {sprintf('\n')}];
                            

                            % Print GSI Output:
                            lenCorrectOutput = length(problemTestCaseResult.correctOutput);
                            correctOutputCell = {};   %use cellStr since easier to see output errors
                            correctOutputCell = [correctOutputCell; {'GSI output was: \n'}];
                            
                            for indOutArg = 1:lenCorrectOutput % thru each output arguments
                                if lenCorrectOutput > 1
                                    correctOutputCell = [correctOutputCell; {sprintf('\toutput argument %s:\n', num2str(indOutArg))}];
                                end
                                correctOutArgTemp = problemTestCaseResult.correctOutput{indOutArg};
                                
                                if isa(correctOutArgTemp, 'cell') %potentially buried cell (assume only one depth level); extract contents 
                                    for indCell = 1:numel(correctOutArgTemp)
                                        correctOutputCell = [correctOutputCell; {sprintf('\t\tcell #%s:\n', num2str(indCell))}];  
                                        correctOutputTemp = cprintf(correctOutArgTemp{indCell});
                                        sizeCorrectTemp = size(correctOutputTemp);
                                        correctOutputTemp = [repmat(sprintf('\t'), sizeCorrectTemp(1), 3), ...
                                            correctOutputTemp, repmat(sprintf('\n'), sizeCorrectTemp(1), 1)];
                                        correctOutputTemp = mat2cell(correctOutputTemp, ...
                                            ones(sizeCorrectTemp(1),1), (sizeCorrectTemp(2)+4)*ones(sizeCorrectTemp(1),1));
                                        correctOutputCell = [correctOutputCell; correctOutputTemp{:}];
                                    end
                                    
                                elseif isa(correctOutArgTemp, 'double') || isa(correctOutArgTemp, 'char') 
                                    correctOutputTemp = cprintf(correctOutArgTemp);
                                    sizeCorrectTemp = size(correctOutputTemp);
                                    correctOutputTemp = [repmat(sprintf('\t'), sizeCorrectTemp(1), 2), ...
                                        correctOutputTemp, repmat(sprintf('\n'), sizeCorrectTemp(1), 1)];
                                    correctOutputTemp = mat2cell(correctOutputTemp, ...
                                        ones(sizeCorrectTemp(1),1), (sizeCorrectTemp(2)+3));
                                    correctOutputCell = [correctOutputCell; correctOutputTemp{:}];
                                    
                                elseif isa(correctOutArgTemp, 'struct')
                                    fprintf('Must modify StudentOutputFileWriter for struct class... \n');
                                    fprintf('Using default output\n');
                                    pause
                                    error('\n\nGoing to catch statement:');

                                end
                                
                                correctOutputCell = [correctOutputCell; {sprintf('\n')}];
                            end
                            correctOutputCell = [correctOutputCell; {sprintf('\n\n')}];
                            
                            
                            
                            %Loop through each studentOutput, correctOutput & print to txt file
                            if ~strcmpi(assignmentProblem.problemType, 'plot_visual') 
                                fprintf(fileID, [studentOutputCell{:}]);
                                fprintf(fileID, [correctOutputCell{:}]);
                                
                            else
                                fprintf(fileID, '\t');
                                fprintf(fileID, [studentOutputCell{1:2},correctOutputCell{2}]);
                                % fprintf(fileID, studentOutputString);
                                % fprintf(fileID, '\n\n');
                                % fprintf(fileID, correctOutputString);
                            end
                            
                         
                        catch err           %likely incorrectly formatted
                            warning off backtrace
                            warning('fileWriter:cprintfFailed', 'cprintf failed to evaluate output in StudentOutputFileWriter>generateOutputFile.');
                            warning on backtrace
                            try
                                fprintf(fileID, ['Your output was: \n']);
                                for ind1 = 1:length(problemTestCaseResult.studentOutput)
                                    outputLineStudent = problemTestCaseResult.studentOutput{ind1};
                                    tempStudentOut = cprintf(outputLineStudent(:)');
                                    fprintf(fileID, tempStudentOut);
                                    fprintf(fileID, '\n');
                                end
                                
                                fprintf(fileID, ['\nGSI output was: \n']);
                                for ind2 = 1:length(problemTestCaseResult.correctOutput)
                                    outputLineCorrect = problemTestCaseResult.correctOutput{ind2};
                                    tempCorrectOut = cprintf(outputLineCorrect(:)')';
                                    fprintf(fileID, tempCorrectOut);
                                    fprintf(fileID, '\n');
                                end
                                clear ind1 ind2 tempStudentOutput tempCorrectOutput outputLineStudent outputLineCorrect
                                
                            catch err
                                warning off backtrace
                                warning('fileWriter:cprintfFailed', 'cprintf failed to evaluate output in StudentOutputFileWriter>generateOutputFile.');
                                warning on backtrace
                                fprintf(fileID, 'Your output was not able to be displayed.');
                            end
                        end
                        fprintf(fileID, '\n\n');
                    end
                    fprintf(fileID, '\t\t\n');
                    
                    % The student's submitted function has an incorrect number
                    % of input and output arguments.
                elseif strcmp(gradedProblem.problemStatus, 'Error: INCORRECT NUMBER OF INPUT OR OUTPUT PARAMS')
                    
                    fprintf(fileID, ['\t\tError: File ''' gradedProblem.problemFileName '.m'' has the incorrect number of input and output arguments\n']);
                    
                    % The student did not submit the function
                elseif strcmp(gradedProblem.problemStatus, 'NOT SUBMITTED')
                    
                    problemFileName = gradedProblem.problemFileName;
                    fprintf(fileID, ['\t\tYou did not submit: ''' problemFileName '.m''\n']);
                    % fprintf(fileID, ['\t\tYou did not submit: ' gradedProblem.problemName '\n']);   % Original output
                    
                    % There was an error the autograder could not catch and the
                    % students should contact the Head TA
                else
                    
                    fprintf(fileID, ['\t\tError: ' gradedProblem.problemName ' threw an unknown error. Please contact the Head TA.\n']);
                end
                
                fprintf(fileID, '\t\n');
            end
            
            fclose(fileID);
        end
    end
end
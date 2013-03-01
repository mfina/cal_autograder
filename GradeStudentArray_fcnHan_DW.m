function [ArrayStudents] = GradeStudentArray_fcnHan_DW(agconfig, ArrayStudents, assignmentSolution, studentResultsFileWriter)
%
% [ArrayStudents] = GradeStudentArray(agconfig, ArrayStudents, ...
%                       assignmentSolution, studentResultsFileWriter)
%
% Master grading function:
% - Grades problem (function, script, plot) against solution
% - Produces individual student output file: e.g., "AutoGraderOutput.txt"
% - Reads and rewrites "grades.csv" file
% 
% Inputs:
% - agconfig                    :	OS (file seperator is primary purpose)
% - ArrayStudents               :   From Bulk2... Students loaded with
%                                     problems & testCases from Assignment
% - assignmentSolution          :   Assignment & solution functions
% - studentResultsFileWriter    :   Class to control writing "grades.csv" 
%                                     and "XXX.txt" outputs
%
% Output:
% - ArrayStudents               :   Graded array containing results of run
% - "XXX.txt" (file output)     :   In student folder, shows student scoring
% - "grades.csv" (file output)  :   All student scores for test run
%                                    Note: runByStudent updates single student
%
% Date: Continuously updated

% ---------------- %
% Some Suggestions %
% ---------------- %
%
% A barrage of suggestions for future AutoGrader developers (there are numerous):
%
% - Consider reconstructing problem class hierarchy as:
%     Problem > ProblemInput > ProblemTestOutput 
% i.e., allow multiple output comparisons for same input; 
% problemTestCase is actually problemInputCases; allow for multiple 
% problemOutputComparisons for a single input.
%
% - Consider grading problem-by-problem rather than student-by-student
% in essence switching I <=> J loops below
%
% - HERE GRADE correct_output and then use I,J,K below as reference
% to avoid grading the GSI functionS 400+ times
%   GradeGSI
%   loop students
%     GradeStudent
%       compare studentOutput, correctOutput(within GradeGSI)
%
% - RE:above since all objects are created with '< handle', they don't
% inherit the inferior class referencing - subsref (class operators) 
% needs to overwritted individually for each class to allow for simple 
% class traversal, e.g. to evaluate correctOutput from within GradeGSI
%
% - Consider adding functionality to produce a grade sheet that is 
% devided up by problem, testcase, etc. rather than one output score.
% A function can be called to add up score and produce grades.csv for
% bSpace
%
% - Note that by setting flagRunLength in problemDescriptionFile in effect 
% is runByStudent. Should probably create a runByProblem option.
%
% - Infinite for/while loops have not been addressed yet. Consider implementation 
% using a timer object with an event callback calling errorFcn. Admittedly,
% setting this up may prove complicated because Matlab is single-threaded.

% close all open figures, files; retore formatting
Restore_default_state();

% total point count used to output student percentage score
totalGrade = assignmentSolution.getTotalAssignmentPoints;

% % % UPDATE TO GRADE CORRECT SOLUTION FIRST
% % home;
% % fprintf('Grading GSI solution')
% % lenProblems = length(assignmentSolution.assignmentProblems);
% % correct_output = cell(1, lenProblems);
% % for indProblem = 1:lenProblems    
% %     currSolProblem = assignmentSolution.assignmentProblems{indProblem};
% %     lenTestCases = length(currSolProblem.problemTestCases);
% %     correct_problemOutput = cell(1, lenTestCases);
% %     for indProblemTestCase = 1:lenTestCases
% %         currSolTestCase = currSolProblem.problemTestCases{indProblemTestCases};
% %         %
% %         % Requires copying from below, e.g.:
% %         %   correct_outputTemp = get_function_output(problemSolutionFunction,
% %         %                          problemTestCase);
% %         %
% %         correct_problemOutput{indProblemTestCase} = correct_outputTemp;
% %     end
% %     correct_output{indProblem} = correct_problemOutput;
% % end
% % % Suggested update      

% clc.m is overloaded 
warning('off', 'MATLAB:dispatcher:nameConflict'); 

% Loop thru students (generated from sub-folders in ".\LabX" folder)
for I = 1:length(ArrayStudents)         
    % display grading status
    if ArrayStudents(I).hasBeenGraded           
        fprintf(['Student has already been graded: ' [ArrayStudents(I).studentFirstName, ' ', ArrayStudents(I).studentLastName]]);
        continue;
    else
        fprintf(['Grading student (' int2str(I) '/' int2str(length(ArrayStudents)) '):  ' [ArrayStudents(I).studentFirstName ' ' ArrayStudents(I).studentLastName '\n']]);
    end
    
    % get student submitted problems
    studentSubmittedProblems = ArrayStudents(I).studentSubmittedProblems;    
    
    % Loop problems - All problems inserted (Bulk2...) even if empty...ok
    % - however, for consisteny purposes all problems be based on problemSolution
    % and not some combination of studentSubmittedProblems and problemSolution
    for J = 1:length(studentSubmittedProblems)                              
        studentSubmittedProblem = studentSubmittedProblems{J};              % get current student, problem
        
%         
        
        % If the problem was submitted proceed to compare against solution
        if studentSubmittedProblem.isProblemSubmitted
            problemDisplayName = studentSubmittedProblem.problemDisplayName;
            problemFileName = studentSubmittedProblem.problemFileName;
            
            fprintf(['\tgrading function:  ' studentSubmittedProblem.problemDisplayName '\n\n'])
            problemResults = ProblemResults(problemDisplayName, problemFileName, 'UNKNOWN', {});
            
            problemSolution = assignmentSolution.getProblem(studentSubmittedProblem.problemFileName);
            problemSolutionFunction = problemSolution.problemFunction;
            
            %there is an issue that nargin(script) produces error
            % try-catch in isScript, which is handled correctly
            %however, if there is another error such which occurs with
            % nargin(script) - such as nargin(script) -> unbalanced bracket
            % this will be missed altogether... this must be corrected
            % below
            flagFcnRuns = true;
            try
                nargin(studentSubmittedProblem.problemFunctionHandle);
                nargin(problemSolutionFunction);
            catch err
                if ~strcmp(err.identifier, 'MATLAB:nargin:isScript')
                    flagFcnRuns = false;
                    isNarginIncorrect = true;
                end
            end
            % confirmed an uncommon error did not occur
            if flagFcnRuns
                if ~IsScript(studentSubmittedProblem.problemFunctionHandle) && ...
                   ~IsScript(problemSolutionFunction) 
                    try
                        isNarginIncorrect = nargin(studentSubmittedProblem.problemFunctionHandle) ~= nargin(problemSolutionFunction) || ...
                                            nargout(studentSubmittedProblem.problemFunctionHandle) ~= nargout(problemSolutionFunction);
                    catch err
                        isNarginIncorrect = 1;
                    end
                elseif IsScript(studentSubmittedProblem.problemFunctionHandle) && ...
                         IsScript(problemSolutionFunction) 
                    isNarginIncorrect = 0;
                else
                    isNarginIncorrect = 1;
                    if IsScript(studentSubmittedProblem.problemFunctionHandle)
                        fprintf('Student file is a script. \nGSI solution is a function\n');
                    else
                        fprintf('Student file is a function. \nGSI solution is a script\n');
                    end
                end
            end
            
            % Check the number of input and ouput arguments are incorrect 
            % - note for 'plot_visual' problem solution file doesn't need to exist
            if isNarginIncorrect && ~strcmpi(problemSolution.problemType, 'plot_visual') 
                
                % Assign 0 points and put a message in the result
                problemResults.problemStatus = 'INCORRECT NUMBER OF INPUT OR OUTPUT PARAMS';
                fprintf('incompatible number of input or output arguments');
                
                % If the problem was correctly submitted proceed grading with
                % test cases
            else
                problemTestCases = problemSolution.problemTestCases;
                
                for K = 1:length(problemTestCases)
                    
                    % Mark problem as graded and get first test case.
                    problemResults.problemStatus = 'GRADED';
                    problemTestCase = problemTestCases{K};
                    testCaseResults = TestCaseResults(problemTestCase, {}, {}, []);
                    
                    % SUGGESTED UPDATE:
                    % Reduce BELOW statements to a sub-function: 
                    % [outputTemp] = GetOutput(studentSubmittedProblem, problemTestCase)
                    if strcmpi(problemSolution.problemType, 'function')
                        
                        % Initialize the rand seed for student function.
                        rand('twister', 0);
                        student_output = get_function_output(studentSubmittedProblem.problemFunctionHandle, problemTestCase);
                        
                        % Initialize the rand seed for solution function.
                        rand('twister', 0);
                        correct_output = get_function_output(problemSolutionFunction, problemTestCase);
                        
                    elseif strcmpi(problemSolution.problemType, 'script')
                        
                        flagPlotVisual = false;
                        
                        % For plot_visual-like format
                        if flagPlotVisual
                            flagRun = 1 + (I>1) + (I==length(ArrayStudents)); % 1:I=1; 2:I!=1,end; 3:I=end
                            % Initialize the rand seed for student function.
                            rand('twister', 0);
                            close all force;
                            [output] = get_script_output(studentSubmittedProblem.problemFunctionHandle, problemTestCase, flagRun);
                            graderAssignedPoints = output{1};
                            graderComments = output{2};
                            output = output{3}{:};
                        else                   
%                             For function-like format
                            % Initialize the rand seed for student function.
                            
                            rand('twister', 0);
                            student_output = get_script_output(studentSubmittedProblem.problemFunctionHandle, problemTestCase);

                            solutionPath = evalin('base', 'solutionPath');
                            problemSolutionFunction = [solutionPath, '\', studentSubmittedProblem.problemFileName];
                            clear solutionPath

                            % Initialize the rand seed for solution function.
                            rand('twister', 0);
                            correct_output = get_script_output(problemSolutionFunction, problemTestCase);
                        end
                        
                    elseif strcmpi(problemSolution.problemType, 'plot_function')
                        
                        % Initialize the rand seed for student function.
                        rand('twister', 0);
                        close all force;
                        student_output = get_plot_output(studentSubmittedProblem.problemFunctionHandle, problemTestCase);
                        close all force;
                        
                        % Initialize the rand seed for solution function.
                        rand('twister', 0);
                        close all force;
                        correct_output = get_plot_output(problemSolutionFunction, problemTestCase);
                        close all force;
                        
                    elseif strcmpi(problemSolution.problemType, 'plot_visual')
                        
                        flagRun = 1 + (I>1) + (I==length(ArrayStudents)); % 1:I=1; 2:I!=1,end; 3:I=end
                        % Initialize the rand seed for student function.
                        rand('twister', 0);
                        close all force;
                        [graderAssignedPoints, graderComments, output] = ...
                            get_plot_visual_output(studentSubmittedProblem.problemFunctionHandle, problemTestCase, flagRun);
                        
                    end
                    
                    % SUGGESTED UPDATE:
                    % Reduce BELOW statements to a sub-function: 
                    % [testCaseResults] = GradeOutput(student_output, correct_output, problemSolution)
                    %
                    % If the problem was graded visually assign the points
                    % directly
                    if strcmpi(problemSolution.problemType, 'plot_visual') || ...
                        (strcmpi(problemSolution.problemType, 'script') && flagPlotVisual)
                        testCaseResults.studentOutput = {'Visually graded; see output message for scoring'};
                        if ~exist('graderComments', 'var') || isempty(graderComments)
                            testCaseResults.correctOutput = {'No comments.'};
                        else
                            testCaseResults.correctOutput = graderComments;
                        end
                        testCaseResults.pointsAwarded = graderAssignedPoints;
                    else
                        % Legacy option - consider removing - assigns full points for submitting
                        if problemSolution.isEffortBased
                            points = assign_points_effort_based(student_output, correct_output, problemTestCase);
                        else
                            % If problem is not effort based, grade.
                            
                            [student_output, correct_output, points] = ...
                                assign_points_value_based(student_output, correct_output, problemTestCase);
                        end
                            
                        
                        % % Log the results. - typically too verbose for clarity
                        % format compact;
                        % fprintf(['\t\tStudent output:\n']) 
                        % fprintf('\t\t\t'); disp(student_output{:});
                        % fprintf(['\t\tSolution output:\n'])
                        % fprintf('\t\t\t'); disp(correct_output{:});
                        % fprintf(['\tpoints earned: ' num2str(points) '\n\n'])
                        % format;
                        
                        testCaseResults.studentOutput = student_output;
                        testCaseResults.correctOutput = correct_output;
                        testCaseResults.pointsAwarded = points;
                        
                    end
                    
                    %problemResults already wrong?
                    problemResults.addTestCaseResult(testCaseResults);
                    
                end
            end
            % The problem was not submitted, assign 0 points.
        else
            
            % Assign 0 points and put a message in the result
            problemDisplayName = studentSubmittedProblem.problemDisplayName;
            problemFileName = studentSubmittedProblem.problemFileName;
            problemResults = ProblemResults(problemDisplayName, problemFileName, 'UNKNOWN', {});
            problemResults.problemStatus = 'NOT SUBMITTED';
            fprintf(['Problem ''' studentSubmittedProblem.problemFileName '.m'' was not submitted']);
        end
        
        % Add graded problem results to stuent class
        ArrayStudents(I).addGradedProblem(problemResults);
    end
    
    % Create output file for student with all their scores
    
    studentResultsFileWriter.generateOutputFile(assignmentSolution, ArrayStudents(I));  %modify output filename
    
    % Update the gradebook
    [studentGrade] = UpdateGradebook(agconfig, ArrayStudents(I), studentResultsFileWriter, 'grades.csv');
    
    strTemp = sprintf([ '\nCompleted grading student (%i/%i): ', ...
                        '\n\tStudent scored (%i/%i) = %2.0f%% \n\n\n'], ...
                        I, length(ArrayStudents), ...
                        studentGrade, totalGrade, ...
                        studentGrade/totalGrade*100);
	disp(strTemp);          % was not printing correctly using fprintf, possibly b/c '%%'
    
%     pause(1);
    home;
    
    ArrayStudents(I).hasBeenGraded = 1;
    % End Update to ArrayStudents
    
    
    % ****AutoSave feature below****
    flagOriginalSave = 0;
    if flagOriginalSave    
        % Original code - saves .mat after each student is graded
        delete('AutoSave*');
        S = sprintf('AutoSave-%s.mat', assignmentSolution.assignmentName);
        S(S == ' ') = '_';
        S(S == ':') = [];
        save(S, 'ArrayStudents');
    else
        % Modified code - only save ArrayStudents when finished grading or error found
        assignin('caller', 'ArrayStudents', ArrayStudents);
        clc(1);                 % Reactivate clc after failed run, probably not necessary
    end
end

end

function [studentGrade] = UpdateGradebook(agconfig, student, studentResultsFileWriter, filename)

% Put an assertion that the number of students in the gradebook equals the
% number of students in the graded student array.

fid = fopen([studentResultsFileWriter.rootPath agconfig.getDirectorySeparator() filename], 'r');


allLines = {};

while ~feof(fid)
    
    tline = fgetl(fid);
    
    if strfind(tline, num2str(student.studentSID))
        studentGrade = student.getStudentGrade();
        
        [bSpaceID1,bSpaceID2, studentLastName, studentFirstName, discard] = strread(tline, '%d%d%s%s%f', 'delimiter', ',', 'emptyvalue', NaN);
        
        allLines = [allLines; {sprintf('%d,%d,%s,%s,%d', bSpaceID1, bSpaceID2, cell2mat(studentLastName), cell2mat(studentFirstName), ceil(studentGrade))}];
        
    else
        
        allLines = [allLines; {tline}];
        
    end
    
    %allLines{end}
    %pause
    
end

fclose(fid);

% Now open the file to write out the student's grade.

fid = fopen([studentResultsFileWriter.rootPath agconfig.getDirectorySeparator() filename], 'r+');

for i = 1:length(allLines)
    %     [allLines{i},'\n']
    %     pause
    fprintf(fid,[allLines{i},'\n']);
end

fclose(fid);

end

function [student_output, correct_output, points] = assign_points_value_based(student_output, correct_output, testCase)

% NOTE: in future, allow multiple test cases to be produced from single problem run

% Modify Output to evaluate; see sub-function below
if testCase.testCaseFlagOutputConfig
  [student_output, correct_output, testCase] = ...
    ConfigureOutputCompare(student_output, correct_output, testCase);
end

for i = 1:length(student_output)    
    
    tolerance = testCase.testCaseTolerance;
    testCasePoints = testCase.testCasePoints(i);
    
    % Set up params for cell and struct comparison
    params.outfileorfid = 1;
    params.displaycontextprogress = 1;
    params.NumericTolerance = testCase.testCaseTolerance;
    % This parameter ensures strict equality
    params.ignoreunmatchedfieldnames = 0;
    
    % this output is erroneous, then skip it and assign no points
    if isa(student_output{i}, 'char') && size(student_output{i},1)==1
        if ~isempty(strfind(student_output{i}, 'Error')) || ~strcmp(class(student_output{i}), class(correct_output{i}))
            points(i) = 0;
            continue;
        end
    end
    
    % Output common for txt and csv file reads where conversion to double
    %  is not explicitly made
    if isa(correct_output{i}, 'int32')      % consider adding error logical qualifier, e.g. if ~error && isa()
        correct_output{i} = double(correct_output{i});
    end
    if isa(student_output{i}, 'int32')
        student_output{i} = double(student_output{i});
    end
    
    % if classes of output are different, award no points
    if ~strcmp(class(correct_output{i}), class(student_output{i}))
        points(i) = 0;
        fprintf('No points awarded. Output classes do not match.\n\n');
        continue;
    end  
    
    if isa(correct_output{i}, 'double') || isa(correct_output{i}, 'logical') 
        if  doublecmp(double(correct_output{i}), double(student_output{i}), tolerance)
            points(i) = testCasePoints;
        else
            points(i) = 0;
        end
        
    elseif isa(correct_output{i}, 'char')
        if  strcmpi(correct_output{i},student_output{i})
            points(i) = testCasePoints;
        else
            points(i) = 0;
        end
        
    elseif isa(correct_output{i}, 'struct')
        % structcmp can be done with cellcmp
        if cellcmp(correct_output{i}, student_output{i}, [], params)
            points(i) = testCasePoints;
        else
            points(i) = 0;
        end
        
    elseif isa(correct_output{i}, 'cell')
        display('cell cmp')
        if cellcmp(correct_output{i}, student_output{i}, [], params)
            points(i) = testCasePoints;
        else
            points(i) = 0;
        end
        
    elseif isa(correct_output{i}, 'function_handle')
        % To evaluate input for anonymous function handles, must then
        %   evaluate input using now-defined function handle - may be an
        %   issue if there are infinitely-deep fcnHan defined
        
        % set up function_handle input as {[1],[2]} where:
        %  [1] - are inputs to define function handle
        %  [2] - inputs argument to evaluate function handle
        
        display('fcnHan')
        

        testCase.testCaseInput = testCase.testCaseInput{2};  %strip first cell
        
        try
        temp_student_output = get_function_output(student_output{i}, testCase);
        catch err
            temp_student_output = err;
        end
        temp_correct_output = get_function_output(correct_output{i}, testCase);
        [student_output,correct_output,temp_points] = assign_points_value_based({temp_student_output}, {temp_correct_output}, testCase);
        student_output = student_output{1};
        correct_output = correct_output{1};
        points(i) = temp_points;
        
        clear temp_points
        
    else
        error('AutoGrader cannot handle function outputs of class %s', class(correct_output{i}))
    end
    
    % output scoring results
    if all(points(i))
        fprintf('Full points awarded\n\n');
    elseif any(points(i))
        fprintf('Partial points awarded\n\n');
    else
        fprintf('No points awarded\n\n');
    end
end

end

function [student_output, correct_output, testCase] = ...
    ConfigureOutputCompare(student_output, correct_output, testCase)
% Subfunction to "assign_points_value_based" above
%   See TestCase.m, properties: testCaseFlagOutputConfig, testCaseOutputConfig
%
% To allow formatting function outputs for comparison in following cases:
%
% 1. Formats output to support function operation on outputs. 
%      E.g., class(student_output) and class(correct_output)
% 2. Formats output to compare indexes, fields of arrays, structures and cells. 
%      E.g., student_output(10).GSI and correct_output(10).GSI
% 3. Combinations of (1)&(2), using functions and index, field references
%      E.g., [student_output(1:5).GSI] and [correct_output(1:5).GSI]
%
% Supports arrays, cells and structures only. Strings should be handled
%   separately since all evaluation errors produce string outputs
% Only first output variable, cell 1, is compared. Remaining outputs are
%   discarded. Future versions could include a second row of cells to
%   handle multiple outputs separately.
% Function based on subsref, substruct referencing to generalize indexing
%
% Date: 3.15.12
%

% modify first output argument only!
outTemp = cell(1,2);
studentOutTemp = student_output{1};
correctOutTemp = correct_output{1};

% Either/Both studentOutTemp, correctOutTemp may have evluated as an error
%  and thus contain string error messages, check for string
if ~isa(studentOutTemp, 'char'); outTemp{1} = studentOutTemp; end
if ~isa(correctOutTemp, 'char'); outTemp{2} = correctOutTemp; end

% unpack formatting - e.g., {@(x) class(x), {'()',{1},'.','ID'}}
%   determine how to format output - outCase
outFormTemp = testCase.testCaseOutputConfig;
fcnHan = outFormTemp{1};
indStrct = outFormTemp{2};
isMT_fcnHan = isempty(fcnHan);
isMT_indStrct = isempty(indStrct);
if (isMT_fcnHan+isMT_indStrct) == 2             % output not modified; return
    return;
elseif (isMT_fcnHan+isMT_indStrct)==1 && isMT_fcnHan    % evaluate index 
    outCase = 1;                
elseif (isMT_fcnHan+isMT_indStrct) == 1         % evaluate function
    outCase = 2;
else                                            % evaluate function and index
    outCase = 3;                            
end

for ind = 1:2       % thru student_output, correct_output
    % Handles autograder eval errors - do not modify string output
    if isempty(outTemp{ind})
        continue;
    end
    
    substrctTemp = @(x) subsref(x, substruct(indStrct{:}));
    
    try 
        switch outCase 
            % evaluate function and index
            case 3                             
                outTemp{ind} = feval(fcnHan, substrctTemp(outTemp{ind}));
            % evaluate function
            case 2
                outTemp{ind} = feval(fcnHan, outTemp{ind});
            % evaluate index
            case 1
                outTemp{ind} = substrctTemp(outTemp{ind});
            % all cases have been accounted for, no need for otherwise case
        end
    catch err
        outTemp{ind} = err.message;             % output is stored error message
    end
end
clear substrctTemp fcnHan
    
if ~isempty(outTemp{1}); student_output{1} = outTemp{1}; end
if ~isempty(outTemp{2}); correct_output{1} = outTemp{2}; end

student_output = student_output(1);
correct_output = correct_output(1);

cprintf(student_output)
cprintf(correct_output)

end

function [points] = assign_points_effort_based(student_output, correct_output, testCase)
% Class compare correct_output and student_output

for i = 1:length(student_output)
    
    tolerance = testCase.testCaseTolerance;
    testCasePoints = testCase.testCasePoints(i);
    
    % Set up params for cell and struct comparison
    
    params.outfileorfid = 1;
    params.displaycontextprogress = 1;
    params.NumericTolerance = testCase.testCaseTolerance;
    % This parameter ensures strict equality
    params.ignoreunmatchedfieldnames = 0;
    
    % this output is erroneous, then skip it and assign no points
    if isa(student_output{i}, 'char') && size(student_output{i},1)==1
        if ~isempty(strfind(student_output{i}, 'Error')) || ~strcmp(class(student_output{i}), class(correct_output{i}))
            points(i) = 0;
            continue;
        end
    end
    
    if isa(correct_output{i}, 'double') && isa(student_output{i}, 'double')
        points(i) = testCasePoints;
        
    elseif isa(correct_output{i}, 'char') && isa(student_output{i}, 'char')
        points(i) = testCasePoints;
        
    elseif isa(correct_output{i}, 'struct') && isa(student_output{i}, 'struct')
        points(i) = testCasePoints;
        
    elseif isa(correct_output{i}, 'cell') && isa(student_output{i}, 'cell')
        points(i) = testCasePoints;
        
    elseif isa(correct_output{i}, 'function_handle') && isa(student_output{i}, 'function_handle')
        points(i) = testCasePoints;
        
    else
        
        %Assign 0 points since student did not generate an output of the
        %correct type
        points(i) = 0;
        
        %TODO: put an autograder message 'Expected argument of type blah'
    end
    
end

end

function [output] = get_function_output(fun, testCase)

% Evaluate output
[output] = Eval_output(testCase, fun, 'function');

% Removes remaining open figures, files; retores output formatting 
Restore_default_state();  

end

function [output] = get_script_output(fncHan, testCase, flagRun)
% Note: must first run script2function with specified options

% Script functions are typically used early in E7 course
%  often with basic plotting. In the future, script functions
%  should offer compatitibilty for both:
% 1. visual plot comparison
% 2. function output comparison
%
% It should be noted that a simple workaround is to use the current 
%  autograder to generate a common function and then compare using
%  the traditional function approach, for which problemType 'plot_visual'
%  and 'function' already work.

% For plot_visual-like approach
if nargin == 3  %plot visual asserted
    % Initialize layout to visually grade plots
    Init_plot_visual(flagRun);
    
    % Get function handle to student's plotting function
    [fncHan] = script2function(fncHan, testCase);

    % Evaluate output
    [output] = Eval_output(testCase, fncHan, 'script');

    % Restore plot visbility - consider changing later
    set(findobj('type', 'figure'), 'visible', 'on')
    
    % PostPlotVisual
    [graderAssignedPoints, graderComments] = Grade_plot_visual(testCase, flagRun);
    
    output = {graderAssignedPoints, graderComments, output};
else
    evalc('fncHan()');
    
    keyboard
    
    %add writeOptions for script problemType - to define header/footer 
%     [fncHan] = script2function(fncHan, testCase);
    fncHan = insertzeros;

    % Evaluate output
    [output] = Eval_output(testCase, fncHan, 'function');

    % Removes remaining open figures, files; retores output formatting 
    Restore_default_state();  
end

end

function [graderAssignedPoints, graderComments, output] = get_plot_visual_output(fun, testCase, flagRun)
% Function to allow visual grading within autograder
%

% Initialize layout to visually grade plots
Init_plot_visual(flagRun);

% Evaluate output
[output] = Eval_output(testCase, fun, 'plot_visual');

% PostPlotVisual
[graderAssignedPoints, graderComments] = Grade_plot_visual(testCase, flagRun);

end

% function [output] = get_plot_output(fun, testCase)
% 
% % Evaluate output
% [output] = Eval_output(testCase, fun, 'plot');
%
% % Removes remaining open figures, files; retores output formatting 
% Restore_default_state();
% 
% end

function [output] = Eval_output(testCase, fun, problemType)

% Subfunction to concatenate evaluation strings for generating output
%
% problemType:      'function' | 'script' | 'plot' | 'plot_visual'

% Control input to 'fun' - inputTemp 
if testCase.testCaseFlagRunInput && ~strcmpi(problemType, 'script')
    runInput = eval(testCase.testCaseInput{1});
    % below for may only be for loading data - consider rewriting:
    % - out = eval('load(''fName'')'); %returns out.('vars'), where vars are
    %                                  % loaded variables...interpretation below
    fldNames = fieldnames(runInput);                
    for indInput = 1:length(fldNames)
        inputTemp{indInput} = runInput.(fldNames{1}{indInput});
    end
else
    inputTemp = testCase.testCaseInput{1};     %note this overwrite 'input' function
end

% Core concatentation code
%
input_name = 'inputTemp';
output_name = 'output';
func_name = 'fun';

% Control number of inputs, outputs
if strcmpi(problemType, 'script')
    nInputs = 0;        %inputs workspace inputs may be added in header
    nOutputs = 1;       %everything required encapsulated in output{:}
elseif strcmpi('problemType', 'plot')
    nOutputs = 1;       %double-check later; feature not currently available
else
    % never assume that a student's function is error-free!!!
    try    
        % find number of inputs and outputs
        nInputs = nargin(fun);
        nOutputs = nargout(fun);
        nOutputs(nOutputs==-1) = 1;         %anonymous function handles can only output 1 var; overwrite
    catch err
        % nIn, nOut shouldn't matter here students function will generate error 
        %  regardless of input / output parameters, may want to double
        %  check implementation, though
        nInputs = 0;
        nOutputs = 0;
    end
end
    
% example S: '[output1] = fun(inputTemp{1}, inputTemp{2});'
S = '[';
for i = 1:nOutputs
    S = [S, output_name, num2str(i)];
    if i < nOutputs, S = [S, ', ']; end
end
S = [S, ']'];
S = [S, ' = ', func_name, '('];
for i = 1:nInputs
    S = [S, input_name, '{',num2str(i),'}'];
    if i < nInputs, S = [S, ', ']; end
end
S = [S, ');'];

% example SS: 'output = {output1};'
SS = [output_name, ' = {'];
for i = 1:nOutputs
    SS = [SS, output_name, num2str(i)];
    if i < nOutputs, SS = [SS, ', ']; else SS = [SS, '}']; end
end
SS = [SS, ';'];      

% No outputs specified ... may occur for plot_visual with header: [] = fun()
if nOutputs == 0
    S = S( strfind(S, 'fun'):length(S) );   % strip erroneous '[] = ' from '[] = fun(inputs)'
                                            %  ok to keep fun() if nargin == 0
    SS = 'output = {}';                     % SS not properly formatted for nargout == 0  
end




% Main string evaluation
try
    clc(0);                 % deactivate clc for current run
    evalc(S);               % execute function    
    evalc(SS);              % encapulate output; out = {out};
    clc(1);                 % reactivate clc after successful run
catch err
    for i = 1:nOutputs
        output{i} = err.message;
    end
end

% plot visual does not require output to grade
if strcmpi(problemType, 'plot_visual') && nOutputs == 0, output = []; end

end

function [] = Restore_default_state()

% Close objects with global scope - e.g., fID, figure, etc. HERE:
if ~isempty(fopen('all')); fclose('all'); end               %close fid
if ~isempty(findobj('type','figure')); close('all'); end    %close figures
                        
% Restores output formatting in case students have modified it
format short;
format compact; 

end

function [] = Init_plot_visual(flagRun)
% Initialize Matlab window to visually grade plot
%
% flagRun controls initialization/closing of figure window
% - flagRun = 1     :   first occurrence
% - flagRun = 2     :   other occurrence
% - flagRun = 3     :   last occurrence

% Close any open plots
close all force;

% Setup 'Figures' window for grading figures - could also use .xml layout file
desktop = com.mathworks.mde.desk.MLDesktop.getInstance;     %Matlab COM object use java
if flagRun == 1 || ~desktop.isGroupShowing('Figures') || ~desktop.isGroupDocked('Figures')
    desktop.showGroup('Figures',1);
    desktop.setGroupDocked('Figures',1);
    fprintf('\nMove ''Figures'' window to ideal location for grading plots\n');
    fprintf('Press ''Enter'' when complete\n');
    pause
end

% Dock Figures window
set(gcf, 'WindowStyle', 'Docked')

end

function [graderAssignedPoints, graderComments] = Grade_plot_visual(testCase, flagRun)
% Grade Matlab plots; 
% Finalize Matlab layout after running plots
%
% flagRun controls initialization/closing of figure window
% - flagRun = 1     :   first occurrence
% - flagRun = 2     :   other occurrence
% - flagRun = 3     :   last occurrence

% dock undocked figure(s): 
%  students either "close; figure" or "figure"
newFigs = findobj('type', 'figure', 'windowstyle', 'normal');
if ~isempty(newFigs), set(newFigs, 'windowstyle', 'docked'); end

% warn multiple figures present
if length(findobj('type', 'figure')) > 1
    warning off backtrace
    warning('GradePlots:MultipleFiguresPresent','Multiple figures present');
    warning on backtrace
end

% error and plot not generated
if ~exist('err', 'var') && ~isempty(findobj('type', 'axes'))
    % Prompt grader for score, comments
    % ...scoring plot
    gradingComplete = false;
    graderAssignedPoints = 0;
    maxPoints = testCase.testCasePoints;
    while ~gradingComplete
        fprintf(['Enter points to assign (', int2str(maxPoints), ' points max):  '])
        graderAssignedPoints = input('', 's');
        graderAssignedPoints = str2double(graderAssignedPoints);
        if isa(graderAssignedPoints, 'double') && (0 <= graderAssignedPoints && graderAssignedPoints <= maxPoints)
            gradingComplete = true;
            fprintf(['\nYou have assigned ', num2str(graderAssignedPoints), '\n']); 
        else
            fprintf('graderAssignedPoints not accepted.\n\n')
            gradingComplete = false;
        end
        if (imag(graderAssignedPoints) ~= 0)    %accidentally enter 'i' or 'j' produce imaginary numbers
            fprintf('Imaginary grades not accepted.\n\nRe-enter grade');
            gradingComplete = false;
        end
        % % Option to confirm entered score
        % fprintf(['\nYou have assigned ', num2str(graderAssignedPoints), ' points.\n\tIs this correct? Y/N [N]:  ']); 
        % confirmPoints = input('', 's');
        % if strcmpi(confirmPoints, 'Y'), gradingComplete = true; end        
        fprintf('\n');
    end
    % ...commenting plot
    if abs(graderAssignedPoints-maxPoints) < 0.0001
        graderComments = 'Full points awarded';
        graderComments = {graderComments};
        commentingComplete = true;
    else
        commentingComplete = false;
    end
    while ~commentingComplete
        fprintf('Enter comments to include:\n\t\t[;]: Break comment line\n\t[enter]: Finished commenting\n\n');
        graderComments = input('', 's');
        graderComments(graderComments == ';') = char(10);       %insert new line
        fprintf('\n');
        fprintf(['You have included the following comments:\n\n'])
        fprintf(graderComments)
        if isempty(graderComments)               
            fprintf('No Comments.');     
            % fprintf('\n\nAre they correct? Y/N [N]:  ');
            % confirmComments = input('', 's');            
            % if strcmpi(confirmComments, 'Y'), commentingComplete = true; end
            commentingComplete = true;
            fprintf('\n');
        else
            commentingComplete = true;  %assume any input comments were correct
            fprintf('\n');            
            graderComments = {graderComments};
        end
    end 
elseif exist('err', 'var')
    graderAssignedPoints = 0;
    graderComments = {err.message};
    fprintf(['\n', err.message, '\n']);
else
    graderAssignedPoints = 0;
    graderComments = {'No plot was generated.'};
    fprintf('\nNo plot was generated\n');
end

% Removes remaining open figures, files; retores output formatting 
Restore_default_state();

% Restore desktop layout
if flagRun == 3
    desktop = com.mathworks.mde.desk.MLDesktop.getInstance;     %Matlab COM object use java
    desktop.closeGroup('Figures');
    desktop.setDefaultLayout();
end

end

function [fncHan] = script2function(fncHan, testCase)
% Provides AutoGrader support for script files
%   through converting script file to function
%   using read / write operations
%
% Date: 3.29.12

% Option to overwrite existing function
flagRewriteFunction = true;

% SPECIAL FORMATTING REQUIRED FOR problemType 'script':
% - opening code is imported from testCase.testCaseInput{1};
% - closing code is imported from testCase.testCaseInput{2};
% - outputVarName are imported from testCase.testCaseConfigOutput


% CONFIGURE filenames
filenameScript = fncHan;            %Full file path for script
indSlash = find(filenameScript=='\',1,'last');
filenamePath = filenameScript(1:indSlash-1);
shortFilenameScript = filenameScript(indSlash+1:end);     %strip .m
shortFilenameFunction = [shortFilenameScript, '1'];                 
filenameFunction = [filenamePath, '\', shortFilenameFunction, '.m'];

% Control flow if function already exists
if exist(filenameFunction, 'file') 
    if flagRewriteFunction              %function exists, rewrite
        delete(filenameFunction);  
    else                                %function exists, return handle
        return; 
    end
end  

% OPEN FUNCTION FOR WRITING
fidWrt = fopen(filenameFunction, 'wt');    

% CREATE, WRITE HEADER
fcnHeader = ['function [output] = ', shortFilenameFunction, '()'];
fprintf(fidWrt, [fcnHeader,'\n\n']);

% ACCEPT OPENING CODE FROM USER
if ~isempty(testCase.testCaseInput) && ~isempty(testCase.testCaseInput{1})
    fprintf(fidWrt, '%%Opening code:\n');
    if testCase.testCaseFlagRunInput
        eval(testCase.testCaseInput{1});
    else
        fprintf(fidWrt, testCase.testCaseInput{1});
    end
    fprintf(fidWrt, ['\n']);
end

% INSERT SCRIPT TO TEMP
fidRd = fopen([filenamePath, '\', shortFilenameScript, '.m'], 'r');
fprintf(fidWrt, '%%Copied script file:\n');
wrtStr = fread(fidRd,'char')';
wrtStr( wrtStr(1:end-1)==13 & wrtStr(2:end)==10 ) = [];  %remove ascii cr/lf double-spacing
wrtStr = strrep(char(wrtStr), 'clear', '%clear');
wrtStr = strrep(char(wrtStr), 'clc', '%clc');
fprintf(fidWrt, '%s', char(wrtStr));
fclose(fidRd);

% ACCEPT CLOSING CODE FROM USER
if ~isempty(testCase.testCaseInput) && ~isempty(testCase.testCaseInput{2})
    fprintf(fidWrt, ['%%Closing code:\n']);
    fprintf(fidWrt, [testCase.testCaseInput{2}, '\n']);
end

% CONSTRUCT OUTPUT
fprintf(fidWrt, '\n%%Output code:');
output_call = {};                           % for usage with evalc ...
evalOut = 'output = {';
outVarNames = testCase.testCaseOutputConfig;
for ind = 1:length(outVarNames)
  if strcmp(outVarNames{ind}, 'gcf')
    output_call = [output_call, {'\nset(gcf, ''visible'', ''off'');\nfig = get(gcf);'}];
    evalOut = [evalOut, 'fig'];
  elseif strcmp(outVarNames{ind}, 'gca')
    output_call = [output_call, {'\nset(gcf, ''visible'', ''off'');\naxe = get(gca);'}];
    evalOut = [evalOut, 'axe'];
  else                                              % may produce error, tested later
    evalOut = [evalOut, outVarNames{ind}];
  end

  if ind < length(outVarNames)
    evalOut = [evalOut, ', '];
  else                  %can block out this line for issues with 
    evalOut = [evalOut, '}'];   % nOutputs <= 0 gives error, intentional??? 
  end
end
evalOut = [evalOut, ';'];  

% FOOTER including setting up output variables
if ~isempty(output_call), fprintf(fidWrt, [output_call{:}]); end
fprintf(fidWrt, ['\n', evalOut]);
fprintf(fidWrt, '\n\nend');
fclose(fidWrt);

% RETURN FULL FILENAME PATH
filenameFunction = [filenameScript(1:end), '1.m'];

% Get new fncHan to return
tempDir2 = pwd;
cd(filenamePath);
fncHan = str2func(shortFilenameFunction);
cd(tempDir2);
clear tempDir tempDir2

end
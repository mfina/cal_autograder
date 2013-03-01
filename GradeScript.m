function [ArrayStudents] = GradeScript(agconfig, ArrayStudents, assignmentSolution, studentResultsFileWriter)
% 
% ---------------------------- %
% GRADE SINGLE SCRIPT PROBLEM  %
% ---------------------------- %
% MF (8.30.12)
%

% close all open figures, files; retore formatting
Restore_default_state();

% get all outputVars from testCases -- only will work for one problem at a time
%   must then change problem number below:
outVarNames = cellfun(@(x) x.testCaseInput, ...
  assignmentSolution.assignmentProblems{1}.problemTestCases);

% total point count used to output student percentage score
totalGrade = assignmentSolution.getTotalAssignmentPoints;

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
    % - however, for consisteny purposes all problems must be based on problemSolution
    %     and not some combination of studentSubmittedProblems and problemSolution
    for J = 1:length(studentSubmittedProblems)                              
        studentSubmittedProblem = studentSubmittedProblems{J};              % get current student, problem
        
        % If the problem was submitted proceed to compare against solution
        if studentSubmittedProblem.isProblemSubmitted
            problemDisplayName = studentSubmittedProblem.problemDisplayName;
            problemFileName = studentSubmittedProblem.problemFileName;
            
            fprintf(['\tgrading function:  ' studentSubmittedProblem.problemDisplayName '\n\n'])
            problemResults = ProblemResults(problemDisplayName, problemFileName, 'UNKNOWN', {});
            
            problemSolution = assignmentSolution.getProblem(studentSubmittedProblem.problemFileName);
            problemSolutionFunction = problemSolution.problemFunction;
            
            %an issue exists:  nargin(script) produces error
            % try-catch in isScript is handled correctly
            %however, if there is another error such as which occurs with
            % nargin(script) - such as nargin(script) -> unbalanced bracket
            % this will be missed altogether... this must be corrected below
            flagRuns = true;
            try
                nargin(studentSubmittedProblem.problemFunctionHandle);
                nargin(problemSolutionFunction);
            catch err
                if ~strcmp(err.identifier, 'MATLAB:nargin:isScript')
                    flagRuns = false;
                    isNarginIncorrect = true;
                end
            end
            
            % confirm an uncommon error did not occur
            if flagRuns
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

            %Evaluate student, solution script files; generate output
            problemResults.problemStatus = 'GRADED';
            
            % Get student output for script variables matching 'outVarNames'
            rand('twister', 0);
            problem_student_output = get_script_output(studentSubmittedProblem.problemFunctionHandle, outVarNames);            
            
            % Get GSI solution output
            rand('twister', 0);
            problem_correct_output = get_script_output(problemSolutionFunction, outVarNames);
            
            % Thru testCases
            problemTestCases = problemSolution.problemTestCases;
            for K = 1:length(problemTestCases)

                % Get Kth testCase.
                problemTestCase = problemTestCases{K};
                testCaseResults = TestCaseResults(problemTestCase, {}, {}, []);
                
                curr_student_output = problem_student_output(K);
                curr_correct_output = problem_correct_output(K);
                
                % Comparison function  :  
                %  Note! Legacy option "EFFORT BASED" REMOVED
                [student_output, correct_output, points] = ...
                    assign_points_value_based(curr_student_output, curr_correct_output, problemTestCase);
                


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

                problemResults.addTestCaseResult(testCaseResults);
            end

        else   %problem not submitted, assign 0 points, output message
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
    
    pause(1);
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
%
% *** An error will occur here if the "grades.csv" file is open for viewing
%       while the autograder is running!!!
%


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
        if cellcmp(correct_output{i}, student_output{i}, [], params)
            points(i) = testCasePoints;
        else
            points(i) = 0;
        end
        
    elseif isa(correct_output{i}, 'function_handle')
        % To evaluate input for anonymous function handles, must then
        %   evaluate input using now-defined function handle - may be an
        %   issue if there are infinitely-deep fcnHan defined
        temp_student_output = get_function_output(student_output{i}, testCase);    
        temp_correct_output = get_function_output(correct_output{i}, testCase);
        [temp_points] = assign_points_value_based({temp_student_output}, {temp_correct_output}, testCase);
        points(i) = temp_points;
        clear temp_points
        
    else
        error('AutoGrader cannot handle function outputs of class %s', class(correct_output{i}))
    end
    
    % % output scoring results
    % if all(points(i))
    %     fprintf('Full points awarded\n\n');
    % elseif any(points(i))
    %     fprintf('Partial points awarded\n\n');
    % else
    %     fprintf('No points awarded\n\n');
    % end
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

function [output] = get_script_output(fcnHan, outVarNames)

%generate workspace variables
% fcnHan();
% try fcnHan();
% catch err
%   output{1} = [err.message];
%   return;
% end

try 
  evalc('fcnHan()');
  % in case of error, neglect error and proceed normally
end


%get testCase again, may have been deleted
if ~exist('outVarNames')
    outVarNames = evalin('caller', 'outVarNames');
end

%initialize output to size of 'outVarNames'
output = cell(size(outVarNames));

%determine if variables exist in workspace;
%  note: testCaseInput contains varNames -> {'a','b'}
outVarExists = cellfun(@exist, outVarNames); 
output(find(~outVarExists)) = {'Error... Variable not found'};
outputTemp = cellfun(@eval, outVarNames(find(outVarExists)), 'uni', false);
output(find(outVarExists)) = outputTemp;
% output defined

end

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
        inputTemp{indInput} = runInput.(fldNames{indInput});
    end
else
    inputTemp = testCase.testCaseInput;     %note this overwrite 'input' function
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
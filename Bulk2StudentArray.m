function [ArrayStudents] = Bulk2StudentArray(studentPath, assignment, flagRunLength)
%   Previously:
% function [ArrayStudents] = Bulk2StudentArray(homePath, gradingPath,
% assignment, flagRunLength)
%
% gradingPath -> studentPath   (consistency)
%


home;

% clc.m is overloaded 
warning('off', 'MATLAB:dispatcher:nameConflict'); 

% Revised method
folders = dir(studentPath);
folders = folders([folders.isdir]);             %rmv non-directory folders
indRoot = strmatch('.',strvcat(folders.name));  %rmv folders beginning with '.'
folders(indRoot(:)) = [];
clear indRoot

% accept flagRunLength argument
if nargin < 3
    lenFolders = length(folders);
    runFolders = 1:lenFolders;
else
    % sub-function to configure runs based on flagRunLength input
    [lenFolders, runFolders] = Format_flagRunLength(folders, flagRunLength);     
end

for S = 1:lenFolders    %index to runFolders; i.e. tempFolder = runFolders(S)
    
    %Get current student info
    [studentFirstName, studentLastName, studentID] = ParseStudentFolder(folders(runFolders(S)).name);
    
    %Create temporary student for evaluation
    tempStudent = Student(studentFirstName, studentLastName, studentID, folders(runFolders(S)).name, {}, 0);
    
    %Generate student file path
    submissionAttachmentsPath = fullfile(studentPath, folders(runFolders(S)).name, 'Submission Attachment(s)');

    fprintf(['Loading Student (' int2str(S) '/' int2str(lenFolders) '):\n\t' tempStudent.studentFolderName '\n\n']);
    if isdir(submissionAttachmentsPath)
        assignmentProblems = assignment.assignmentProblems;

        for P = 1:length(assignmentProblems)
            problemDisplayName = assignmentProblems{P}.problemDisplayName;
            problemFileName = assignmentProblems{P}.problemFileName;
            problemType = assignmentProblems{P}.problemType;
            [isSubmitted, problemFunctionHandle] = LocateSubmittedFile(submissionAttachmentsPath, problemFileName, problemType);
            
            if isSubmitted
                tempStudent.addSubmittedProblem( ...
                    SubmittedProblem( problemDisplayName, problemFileName, problemFunctionHandle, true)  );
            else                     
                tempStudent.addSubmittedProblem(SubmittedProblem(problemDisplayName, problemFileName, 0, false));
            end
        end
    end

    ArrayStudents(S) = tempStudent;
end 

fprintf('\nLoading student files completed ...\n')
% pause(1)
home;

end

function [lenFolders, runFolders] = Format_flagRunLength(folders, flagRunLength)
% Move above flagRunLength formatting here as subfunction
flagFind_bIDs = false;
if isa(flagRunLength, 'double')     
    numStudents = length(folders);               %Number of student folders 
    flagRunLength = sort(flagRunLength);        %Evaluate folders alphabetically
    
    if (length(flagRunLength) == 1 && flagRunLength < 1000)     %format: [X]
        if flagRunLength > numStudents       %Only ind out of range
            error(['\nflagRunLength tried to grade a single student but the index was out of range ...', ...
                  '\n\ti.e. ind > length(students)']);
        end
        %runFolders are 1:flagRunLength ... interpreted elsewhere
        lenFolders = flagRunLength;
        
    elseif length(flagRunLength) == 2 && all(flagRunLength < 1000) % [X(1) ... X(2)]
        if all(flagRunLength > numStudents)  %Both inds out of range
            error(['\nflagRunLength tried to grade a series of students but both indexes were out of range ...', ...
                  '\n\ti.e. [ind1, ind2] > length(students)']);
        elseif flagRunLength(2) > numStudents    %Set ind2 to end of folders
            fprintf('\nflagRunLength(2) > length(students), set to end of student list');
            runFolders = flagRunLength(1):numStudents;  %set last student to evaluate at length(Students)
            lenFolders = length(runFolders);
        end
        return;
        
    elseif length(flagRunLength) > 2 && all(flagRunLength < 1000) % [X(1), X(2), ..., X(n)]
        logOoBs = (flagRunLength > numStudents); %Out of Bounds logical
        if ~isempty(logOoBs)
            flagRunLength(logOoBs) = [];
            fprintf('\nStudents removed because they were ouf of bounds\n');
        end
        runFolders = flagRunLength;
        lenFolders = length(runFolders);
        
    else                                                        %format: [bIDs]
        flagFind_bIDs = true;
        bIDs = cellfun(@(x) num2str(x), num2cell(flagRunLength), 'uni', false);
    end
elseif isa(flagRunLength, 'cell') 
    if length(flagRunLength) == 1 
        if isa(flagRunLength{1}, 'char')
            flagRunLength = str2double(flagRunLength{1});
        end

        if flagRunLength < 1000
            lenFolders = flagRunLength;
        else
            flagFind_bIDs = true;
            bIDs = {int2str(flagRunLength)};
        end
    else
        flagFind_bIDs = true;
        if isa(flagRunLength{1}, 'double')                      %format: {bIDs}
            bIDs = cellfun(@(x) num2str(x), flagRunLength, 'uni', false);
        else                                                    %format: {'bIDs'}
            bIDs = flagRunLength;
        end
    end  
elseif isa(flagRunLength, 'char')
    if str2double(flagRunLength) < 1000                         %format: 'X'
        lenFolders = str2double(flagRunLength);
    else
        flagFind_bIDs = true;                                   %format: 'bID'
        bIDs = {flagRunLength};
    end 
else
    error('flagRunLength incorrectly defined...check input');
end

runFolders = [];
if ~flagFind_bIDs
    if ~flagRunLength
        lenFolders = length(folders);
    elseif flagRunLength == 1
        lenFolders = 30;
    %else  %no modification required
    %    lenFolders = flagRunLength; 
    end
    runFolders = 1:lenFolders;
else
%format: {'bIDs'}
%search folder for matches in foldernames
    for ind = 1:length(bIDs)
        srch1 = regexp({folders.name}, ['.', bIDs{ind},'.']);
        pad1 = cellfun(@(x) ~isempty(x), srch1, 'uni', false);
        ind_bIDs = find([pad1{:}]);
        if isempty(ind_bIDs)
            warning(['bID: ', bIDs{ind}, ' not found by search'])
        else
            runFolders = [runFolders, ind_bIDs];
        end    
        clear srch1 pad1 ind_bIDs
    end
    lenFolders = length(runFolders);
end

end

function [isSubmitted, problemFunctionHandle] = LocateSubmittedFile(pathTemp, filename, problemType)
% Locates student submitted file by name and returns information stored to
%  SubmittedProblem.problemFunctionHandle
% - Note: for script files return full file path of file


% Revise original method
files = dir(pathTemp);
indRoot = strmatch('.',strvcat(files.name));  %rmv folders beginning with '.'
files(indRoot(:)) = [];
clear indRoot


% get files in directory
isSubmitted = 0;
problemFunctionHandle = [];
studentFilename = '';
for i = 1:length(files)
    fileTemp = files(i).name;

    if strcmpi(fileTemp(end-1:end), '.m') && strcmpi(fileTemp(1:end-2), filename)
        isSubmitted = 1;
        studentFilename = fileTemp(1:end-2);    %strip .m
        break;
    end
end

if isSubmitted
    % MF    : Modification to simplify "script" problemType
    % Date  : 8.30.12
    warning off; userpath(pathTemp); warning on;   % overloaded clc will produce annoying messages
    problemFunctionHandle = str2func(studentFilename);
    userpath('reset');  
  
    % % Previous implementation  : pre-8.30.12
    % %   Also inconsistent with Problem.m (Solution) .problemFunction
    % if ~strcmpi(problemType, 'script')
    %     warning off; userpath(pathTemp); warning on;   % overloaded clc will produce annoying messages
    %     problemFunctionHandle = str2func(studentFilename);
    %     userpath('reset');
    % else            % FOR SCRIPT FILES ONLY - RETURN FULL PATH TO FILE
    %     problemFunctionHandle = [pathTemp, '\', studentFilename];
    % end    
end

end
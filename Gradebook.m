classdef Gradebook < handle
    % Class to control grading file(s):
    % . to produce a problem grades file
    % . to produce master grades.csv file
    %
    % Auxiliary applications:
    % . integration with responseSummary.m -- 
    %     easy visualization of output results
    % . integration with AGSave.m -- 
    %     autosave files contain final data; 
    %     Gradebook can either extract from arrayStudents (real-time) 
    %     or autosave files (post-process)
    %
    %
    % METHODS w headers, descriptions:
    %  %initialize Gradebook object for lab, problem (generate file name)
    %   obj = Gradebook(studentPath, currLab, currProblem)
    %
    %  %create new gradebook, call updateGradebook to add grades for tempStudent
    %   obj = WriteGradebook(tempStudent)
    %
    %  %goes through csv file and adds tempStudent
    %   obj = UpdateGradebook(tempStudent)
    %
    %  %function to run a grades.csv file and return studentCell
    %   [tempStudentInfo] = ReadGradesCSV(fGradebook)
    %
    %  %After all problems are called this will generate "grades.csv"
    %  % to be uploaded to bSpace
    %   [fNameOut,studentInfo] = GenerateLabGradesCSV(cellFileNames)
    %
    %  %Use AutoSave (.mat) file to update / create a usable gradebook
    %   AutoSave2Gradebook(labNumber, problemNumber)
    %
    %
    % Created: 10.19.2012 (MF) 
    
    properties
        type = '';                  %{'lab' | 'problem'} - type of csv file

        %Grade Cell Array - Database
        studentInfo;                %structure with fields for name/id, grade
        headerCell = {};            %csv header
        headerLength = [];          %number of headerCell lines
        studentCell = {};           %studentInfo into cells
        fullGradesCell = {};        %full file to write to csv

        %Lab,Problem info
        currLab = '';
        labName = '';
        labNumber = [];
        currProblem = '';
        problemName = '';
        problemNumber = [];

        %Files / Paths
        studentPath = '';
        shortFileName = '';
        fullFileName = '';
    end
    
    methods
        %initialize Gradebook object for lab, problem (generate file name)
        function obj = Gradebook(studentPath, currLab, currProblem)
            obj.studentPath = studentPath;

            %Resolve Lab information
            %  properties :  currLab, labName, labNumber
            obj.currLab = currLab;
            obj.labName = currLab.name;
            findLabNum = str2double(regexp(obj.labName, '\d+', 'match'));
            if ~isempty(findLabNum)
                obj.labNumber = findLabNum(1);
            else
                error('Lab number not found... Required to setup csv file.\n')
            end

                
            %Construct filename and then find and create it
            if nargin < 3
                obj.type = 'lab';           %grades_LabX.csv
                
                %Create full csv filename
                obj.shortFileName = sprintf('grades_Lab%d.csv', obj.labNumber);
            else
                obj.type = 'problem';         %grades_LabX_ProblemY.csv
                
                %Resolve problem information
                %  properties :  currProblem, problemName, problemNumber
                obj.currProblem = currProblem;  %ProblemY
                obj.problemName = currProblem.name;
                findProbNum = str2double(regexp(obj.problemName, '\d+', 'match'));
                if ~isempty(findProbNum)
                    obj.problemNumber = findProbNum(1);
                else
                    error('Problem number not found... Require to setup csv file.\n')
                end
                
                %Create problem csv filename
                obj.shortFileName = sprintf('grades_Lab%d_Problem%d.csv', ...
                    obj.labNumber, obj.problemNumber);
            end
            obj.fullFileName = fullfile(obj.studentPath, obj.shortFileName);
                            
            %Give chance to reject this grades name
            if ~exist( obj.fullFileName , 'file' )
                val = false;
                while ~val
                    fprintf(['\nCreating new file:  ', obj.shortFileName, '\n']);
                    reader_response = input('\nIs this correct [Y/N]? ', 's');
                    fprintf('\n');
                    switch lower(reader_response)
                        case 'y'
                            val = true;
                        case 'n' 
                            fprintf('You have chosen to select a different csv filename\n');
                            obj.shortFileName = input('Please enter csv filename to create', 's');
                            obj.shortFileName( obj.shortFileName == ' ' ) = '_';
                            obj.fullFileName = fullfile(obj.studentPath, obj.shortFileName);
                    end
                end
            else % filename exists
                fprintf(['\nThe file:  ', obj.shortFileName, ' already exists and will be updated\n']);
            end
        end
        
        %------------------------------------------------------------------
        
        %create new gradebook, call updateGradebook to add grades for tempStudent
        function obj = WriteGradebook(tempStudent)
            
            %load gradebook filename to search 
            fullFileName = obj.fullFileName;
            
            %check for existence of fName - if exists, file already created
            if exists(fullFileName, 'file') 
                UpdateGradebook(tempStudent);
            else
                %In studentPath, get folders 
                folders = dir(obj.studentPath);
                folders = folders([folders.isdir]);             %rmv non-directory folders
                indRoot = strmatch('.',strvcat(folders.name));  %rmv folders beginning with '.'
                folders(indRoot(:)) = [];
                clear indRoot

                %Setup header - verbose to show formatting (four commas per line)
                obj.headerCell = {sprintf('%s student scores,,,,', LabX.name); ...
                                  sprintf('Created:  %s,,,,', datestr(now)); ...
                                  sprintf(',,,,'); ...
                                  sprintf('Display ID,ID,Last Name,First Name,grade') ...
                                 };
                obj.headerLength = length(obj.headerCell);  %later used to know offset to students

                %Setup student info 
                studentLastNames = cell(length(folders),1);
                studentFirstNames = cell(length(folders),1);
                studentIDs = cell(length(folders),1);
                studentGrades = num2cell(repmat(0,length(folders),1));
                for ind = 1:length(folders)
                    tempStudentPath = fullfile(obj.studentPath, folders(ind).name);
                    [tempStudentFirstName, tempStudentLastName, tempStudentID] = ...
                        ParseStudentFolder(tempStudentPath);
                    studentLastNames{ind} = tempStudentLastName;
                    studentFirstNames{ind} = tempStudentFirstName;
                    studentIDs{ind} = tempStudentID;
                end

                %Create studentInfo structure -- 
                %  possibly for database later, to improve functionality
                studentCellArray = [studentLastNames, studentFirstNames, studentIDs, studentGrades];
                studentFields = {'lastName', 'firstName', 'SID', 'grades'};
                obj.studentInfo = cell2struct(studentCellArray, studentFields, 2);

                %Write into csv format -- 
                %  Important note: this initializes all to scores to 0
                studentCell = cell(length(folders),1);
                for ind = 1:length(folders)
                    %below originally cell2mat(studentLastName),
                    %  cell2mat(studentFirstName)
                    studentCell{ind} = sprintf('%d,%d,%s,%s,%d', ...
                        studentIDs{ind}, studentIDs{ind}, ...
                        studentLastNames{ind}, studentFirstNames{ind}, ...
                        studentGrades{ind}); %grades initialized to 0
                end
                obj.studentCell = studentCell;
                fullGradesCell = [headerCell; studentCell];
                obj.fullGradesCell = fullGradesCell;

                %Write new csv file
                fid = fopen(obj.fullFileName, 'w');  %if 'w' generates error, grades already exists!?
                for ind = 1:length(fullGradesCell)
                    fprintf(fid, [fullGradesCell{ind}, '\n']);
                end
                fclose(fid);
                
                %call updateGradebook to add grade for student; previously
                %  initialized to 0 for all students
                UpdateGradebook(tempStudent);
            end
        end
        
        %------------------------------------------------------------------
        
        %goes through csv file and adds tempStudent
        function obj = UpdateGradebook(tempStudent)
            %score to add to student
            updatedStudentGrade = tempStudent.studentGrade;
            
            %unpack studentInfo
            studentInfo = obj.studentInfo;
            studentIDs = [studentInfo.studentIDs];
            studentLastNames = [studentInfo.studentLastNames];
            studentFirstNames = [studentInfo.studentFirstNames];
            studentGrades = [studentInfo.studentGrades];
            studentCell = obj.studentCell;
                
            %search for SID in studentInfo
            tempSID = tempStudent.studentSID;
            allSIDs = obj.studentInfo.studentIDs;
            indStudent = find([allSIDs] == tempSId);  %quick search
            
            %headerLength to determine row of gradebook addition
            headerLength = obj.headerLength;
                
            if ~isempty(indStudent)     %convert to line number in csv file
                
                %update student grade in studentInfo
                studentGrades{indStudent} = updatedStudentGrade;
                studentInfo.studentGrades = studentGrades;
                obj.studentInfo = studentInfo;
                
                %update studentCell
                studentCell{indStudent} = sprintf('%d,%d,%s,%s,%d', ...
                    studentIDs{indStudent}, studentIDs{indStudent}, ...
                    studentLastNames{indStudent}, studentFirstNames{indStudent}, ...
                    updatedStudentGrade);
                obj.studentCell = studentCell;
                
                %use headerCell + studentCell to update fullGradesCell
                headerCell = obj.headerCell;
                fullGradesCell = [headerCell; studentCell];
                obj.fullGradesCell = fullGradesCell;
                
            else                        %student not found, add studentInfo to csv
                tempLineNumber = headerLength + length(studentIDs) + 1;
                
                %update studentInfo
                lenStudents = length(studentGrades);
                studentIDs{lenStudents+1} = tempStudent.studentSID;
                studentLastNames{lenStudents+1} = tempStudent.studentLastName;
                studentFirstNames{lenStudents+1} = tempStudent.studentFirstName;
                studentGrades{lenStudents+1} = updatedStudentGrade;
                studentCellArray = [studentLastNames, studentFirstNames, studentIDs, studentGrades];
                studentFields = {'lastName', 'firstName', 'SID', 'grades'};
                studentInfoTemp = cell2struct(studentCellArray, studentFields, 2);
                
                %cat foldernames and sort folders
                studentFullNames = structfun(@(x) [x.studentLastName, ', ', x.studetnFirstName], studentInfoTemp); 
                [fullNamesSorted,indexNamesSorted] = sortrows(studentFullNames); 
                studentInfo = studentInfoTemp(indexNamesSorted);
                obj.studentInfo = studentInfo;
                
                %update studentCell
                studentCell{lenStudents+1} = sprintf('%d,%d,%s,%s,%d', ...
                    studentIDs{end}, studentIDs{end}, ...
                    studentLastNames{end}, studentFirstNames{end}, ...
                    updatedStudentGrade);
                studentCell = studentCell(indexNamesSorted);
                obj.studentCell = studentCell;
                
                %use headerCell + studentCell to update fullGradesCell
                headerCell = obj.headerCell;
                fullGradesCell = [headerCell; studentCell];
                obj.fullGradesCell = fullGradesCell;
                
            end
                
            %output csv to file, may use 'w+' write permissions
            fullFileName = obj.fullFileName;
            fid = fopen(fullFileName, 'w+');
            for ind = 1:length(fullGradesCell)
                fprintf(fid, [fullGradesCell{ind}, '\n']);
            end
        end
        
        %------------------------------------------------------------------    
        
        %function to run a grades.csv file and return studentCell
        function [tempStudentInfo] = ReadGradesCSV(fGradebook)
            fid = fopen(fGradebook, 'r');
            allLines = {};
            while ~feof(fid)
                allLines = [allLines; {fgetl(fid)}];
            end
            fclose(fid);
            
            indLastHeader = find(cellfun(@(x) ~isempty( ...
                strmatch('Display ID,ID,Last Name,First Name,grade', x)), allLines));
            
            tempStudentCell = allLines(indLastHeader+1:end);
            
            tempStudentIDs = {};
            tempStudentLastNames = {};
            tempStudentFirstNames = {};
            tempStudentGrades = {};
            for ind = 1:length(tempStudentCell)
                [tempID1, tempID2, tempLastName, tempFirstName, tempGrade] = ...
                    strread(tempStudentCell{ind}, '%d%d%s%s%d', 'delimiter', ',', 'emptyvalue', NaN);
                tempStudentIDs{ind} = tempID1;
                tempStudentLastNames{ind} = tempLastName;
                tempStudentFirstNames{ind} = tempFirstName;
                tempStudentGrades{ind} = tempGrade;
            end
            
            studentCellArray = [tempStudentLastNames, tempStudentFirstNames, ...
                                tempStudentIDs, tempStudentGrades];
            studentFields = {'lastName', 'firstName', 'SID', 'grades'};
            tempStudentInfo = cell2struct(studentCellArray, studentFields, 2);
        end
        
        %------------------------------------------------------------------    
        
        %After all problems are called this will generate "grades.csv"
        % to be uploaded to bSpace
        function [fNameOut,studentInfo] = GenerateLabGradesCSV(cellFileNames)
            %collect studentCells from 
            arrayStudentInfo = cell(1, length(cellFileNames));
            for ind = 1:length(cellFileNames)
                arrayStudentInfo{ind} = ReadGradesCSV(cellFileNames{ind});
            end
            
            %create finalStudentInfo below:
            
            %get complete list of SIDs, just in case 
            allIDs = [];
            for ind = 1:length(arrayStudentInfo)
                tempStrct = arrayStudentInfo{ind};
                tempIDs = [tempStrct.SID];
                allIDs = [allIDs, tempIDs(:)'];
            end
            allIDs = sort(unique(allIDs));  %sort by ID?
            
            %deal with possibilty different problem lists have different
            % numbers of students and correct
            flagDifferentLists = (length(allIDs) ~= length(arrayStudentInfo{1}));
            if flagDifferentLists
                tempStudentInfo = arraysStudentInfo{1};
                missingList1IDs = setdiff(allIDs, [tempStudentInfo.SID]);
                missingStudentInfo = cell(5, length(missingList1IDs));
                for ind = 2:length(arrayStudentInfo)
                    
                    for indIDs = 1:length(missingIDs)
                        
                        
                    end
                end
            end
            
            gradesByID = cell(1, length(allIDs));
            for ind = 1:length(allIDs)
                tempGrades = zeros(1, length(cellFileNames));
                for indProb = 1:length(cellFileNames)
                    tempStudentInfo = arrayStudentInfo{ind};
                    indStudent = find(allIDs(ind) == [tempStudentInfo.SID]); 
                    if ~isempty(indStudent)
                        tempGrades(indProb) = tempStudentInfo(indStudent).grades;
                    else
                        tempGrades(indProb) = 0;
                    end
                end
                gradesByID{ind} = tempGrades;
            end
            
            %retain studentInfo 
            
            
            %convert studentInfo into format to write csv file
            % fullGradesCell = fullGradesCell = [headerCell; studentCell];
            
            %write output to file, return fNameOut (fullfile name of
            %grades.csv generated
            
            fNameOut = []; %name of output grades file
            
            
        end
        
        %------------------------------------------------------------------
        
        % Use AutoSave (.mat) file to update / create a usable gradebook
        function AutoSave2Gradebook(labNumber, problemNumber)
            switch nargin
                case 1   %labNumber only ... all problems included
                    
                case 2   %labNumber, problemNumber 
                    
                otherwise
                    error('\nMissing ');
            end
            
            lenStudents = length(ArrayStudents);
            
            csv = cell(dim, numprob*2+1);
            for i = 1:lenStudents
                csv{i,1} = ArrayStudents(1,i).studentFolderName;
                if strcmp(ArrayStudents(1,i).studentGradedProblems{1,1}.problemStatus, 'GRADED') 
                    for k = 1:numprob
                        csv{i,k*2} = ArrayStudents(1,i).studentGradedProblems{1,1}.problemTestCaseResults{1,k}.studentOutput{1,1};
                        csv{i, k*2+1} = ArrayStudents(1,i).studentGradedProblems{1,1}.problemTestCaseResults{1,k}.pointsAwarded;
                    end
                end
            end
        end
    end
end
classdef AGSave
    
    properties
        ArrayStudents = [];
        LabX = [];
        SavePath = []; %Directory where AGSave objects are stored
        CSV_Cell = []; %Cell array containing a summary of points for each problem
    end
    
    methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = AGSave(LabX, ArrayStudents)
            
            if nargin == 2
                obj.ArrayStudents = addStudentArray(obj, ArrayStudents);
                obj.LabX = addLabX(obj, LabX);
            elseif nargin == 1
                obj = addLabX(obj, LabX);
            elseif nargin == 0
                %do nothing
            end
            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = initAGSave(obj, studentPath, agPath, flagRunLength)
            
            %Save LabX to AGSave object
            LabX = obj.LabX;
            labName = LabX.assignmentName{1};
            
            resetDir = pwd;
            cd(studentPath);
            
            cd ..
            
            colonIdx = strfind(labName,':');
            labNum = labName(5:colonIdx-1);
            
            %Set AGSave.SavePath = autoSaveFolder
            autoSaveFolder = ['Lab ' labNum ' AutoSave'];
            obj.SavePath = [pwd filesep autoSaveFolder];
            
            if ~isdir(autoSaveFolder)
                mkdir(autoSaveFolder);
                cd(autoSaveFolder);
            else
                cd(autoSaveFolder);
            end
            
            %
            agSaveMatName = regexprep(labName, '[^\w*]','');
            %             thisAutoSave(thisAutoSave == ' ') = '_';
            %             thisAutoSave(thisAutoSave == ':') = [];
            
            indAS = [];
            allMats = dir('*.mat');
            if ~isempty(allMats)
                indAS = strmatch(agSaveMatName, {allMats.name});
            end
            
            if ~isempty(indAS)
                replyLoadAutoSave = input('Do you want to the last AGSave for this file? Y/N [N]: ', 's');
                if isempty(replyLoadAutoSave)
                    reply = 'N';
                end
                
                if strcmpi(replyLoadAutoSave, 'N')
                    cd(agPath);
                    studentSubmissions = Bulk2StudentArray(studentPath, LabX, flagRunLength);
                else
                    load(allAutoSave(indAS).name);
                    cd(agPath)
                    ArrayStudents = AutoLoadFunctionPointers(studentPath, LabX, ArrayStudents);
                    studentSubmissions = ArrayStudents;
                end
            else
                cd(agPath)
                studentSubmissions = Bulk2StudentArray(studentPath, LabX, flagRunLength);
            end
            
            obj.ArrayStudents = studentSubmissions;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = saveAG(obj,entireLab)
            %saves either entire lab or just single problem
            if nargin == 1
                currDir = pwd;
                
                stuPath = evalin('base', 'studentPath');
                
                cd(stuPath);
                cd ..
                dirs = dir('*AutoSave');
                
                cd(dirs.name)
                
                obj.SavePath = pwd;
                
                agSaveName = ['AGS_' regexprep(obj.LabX.assignmentName{1},'[^\w]','')];
                
                %Generate Name of mat file to be saved
                if length(obj.LabX.assignmentName) == 1
                    
                    %get problem#
                    pbNo = regexp(agSaveName,'em(\d*)', 'match');
                    pbNo = pbNo{1}(3:end);
                    
                    %Get Lab#
                    labNo = regexp(agSaveName,'b(\d*)P', 'match');
                    labNo = labNo{1}(2:end-1);
                    
                    
                    agVarName = ['AGSave_L' labNo 'P' pbNo];
                    
                else %AGSave object has multiple problems in it
                    
                    labNo = regexp(agSaveName,'b(\d*)P', 'match');
                    labNo = labNo{1}(2:end-1);
                    
                    
                    agSaveName = ['Lab' labNo 'Combined'];
                    
                    agVarName = ['AGSave_L' labNo];
                end
                
                
                eval([agVarName '= obj;'])
                
                save(agSaveName, agVarName);
                display([agSaveName ' Saved to ' obj.SavePath])
                cd(currDir);
                
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function obj = AutoSave2Gradebook(obj, labNoStr)
            
            ArrayStudents = obj.ArrayStudents;
            LabX = obj.LabX;
            
            numStudents = length(ArrayStudents);
            numProbs = length(LabX.assignmentProblems);
            
            csv = cell(numStudents + 3, numProbs);
            
            csv(1,1:3) = {['Lab ' labNoStr], 'Points', ['Saved: ' datestr(now)]};
            csv(3,1:4) = {'Display ID', 'ID', 'Last Name', 'First Name'};
            
            for S = 1:numStudents
                
                csv{S+3,1} = ArrayStudents(S).studentSID;
                csv{S+3,2} = ArrayStudents(S).studentSID;
                
                csv{S+3,3} = ArrayStudents(S).studentLastName;
                csv{S+3,4} = ArrayStudents(S).studentFirstName;
                
                for P = 1:numProbs
                    
                    labProb = LabX.assignmentProblems{P};
                    
                    %add lab problem name header
                    if S == 1; csv{3,P+4} = labProb.problemDisplayName; end
                    
                    csv{S+3,P+4} = 0; %default points to 0 if below conditions aren't met
                    
                    for SP = 1:length(ArrayStudents(S).studentGradedProblems)
                        
                        stuProb = ArrayStudents(S).studentGradedProblems{SP};
                        
                        %compare student submitted problem status and
                        %compare student file name against lab display name
                        if (strcmp(stuProb.problemStatus, 'GRADED') & ...
                                strcmp(stuProb.problemDisplayName, labProb.problemDisplayName))
                            
                            csv{S+3,P+4} = ArrayStudents(S).studentGrade(SP);
                            
                        end
                        
                    end
                    
                end
                
                %add up student total points
                stuTotalPts(S) = sum(cell2mat(csv(S+3,5:end)));
                
                csv{S+3,numProbs+5} = stuTotalPts(S);
                
            end
            
            obj.CSV_Cell = csv;
            
            %Produce 3 spreadsheets
            %   1 - Score Summary - Score breakdown for each problem
            %   2 - grades.csv
            %   3 - Response Summary - Student Responses
            
            try
                display(['Saving Score_Summary' date '.xlsx ......'])
                xlswrite([obj.SavePath filesep 'Score_Summary' date '.xlsx'], obj.CSV_Cell);
                display('Score_Summary write complete!')
            catch
                display('Unable to save Score Summary...')
                display('csv property of combined AGSave object contains spreadsheet info that would have been saved')
            end
            
            gradesCSV = csv(:,1:4);
            gradesCSV{3,5} = 'grade';
            
            for S = 1:numStudents
                gradesCSV{S+3,5} = stuTotalPts(S);
            end
            
            display(['Writing grades.csv to ' obj.SavePath ' ...'])
            xlswrite([obj.SavePath filesep 'grades.csv'], gradesCSV)
            display('grades.csv write complete!')
            
            display(['Writing responseSummary to AutoGrader directory...'])
            %Note: will need to fix responseSummary to write the
            %spreadsheet to the obj.SavePath filepath
            responseSummary(ArrayStudents, LabX, labNoStr);
            
            obj = saveAG(obj);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = addStudentArray(obj, ArrayStudents)
            savedAS = obj.ArrayStudents;
            
            if isempty(savedAS)
                
                obj.ArrayStudents = ArrayStudents;
                
            else
                
                savedSIDs = [savedAS.studentSID];
                
                %cycle through each student and append info
                for S = 1:length(ArrayStudents)
                    
                    stuIdx = find(savedSIDs == ArrayStudents(S).studentSID);
                    
                    % if we can't find a match, display a message and
                    % continue. Later on, add in ability to insert student
                    if isempty(stuIdx) %if ArrayStudents(S) isn't in savedAS...
                        display(['Student ' ArrayStudents(S).studentFolderName ' not found'])
                        
                        savedAS(end + 1) = ArrayStudents(S);
                        
                    else %ArrayStudents(S) exists in savedAS(stuIdx), so add them to savedAS
                        
                        savedAS(stuIdx).studentSubmittedProblems{end+1} = ArrayStudents(S).studentSubmittedProblems{1};
                        
                        savedAS(stuIdx).studentGrade(end+1) = ArrayStudents(S).studentGrade;
                        
                        savedAS(stuIdx).studentGradedProblems{end+1} = ArrayStudents(S).studentGradedProblems{1};
                        
                        savedAS(stuIdx).hasBeenGraded(end+1) = ArrayStudents(S).hasBeenGraded;
                        
                    end
                    
                    
                    obj.ArrayStudents = savedAS;
                end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = addLabX(obj, LabX)
            
            if isempty(obj.LabX)
                
                obj.LabX = LabX;
                
            else %append new LabX info to existing structure
                
                for A = 1:length(LabX.assignmentName)
                    obj.LabX.assignmentName(end+1) = LabX.assignmentName(A);
                end
                
                for P = 1:length(LabX.assignmentProblems)
                    obj.LabX.assignmentProblems(end+1) = LabX.assignmentProblems(P);
                end
                
            end
            
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end %methods
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods(Static)
        
        function AGSaveL = genCombinedAGSave(agSavePath, agPath)
            % Combines all mat files begining with AGS in the agSavePath
            % directory into one object "AGSaveL"
            
            % Creates a grade summary csv
            
            currDir = pwd;
            
            files = dir([agSavePath filesep 'AGS*.mat']);
            
            cd(agPath)
            
            for F = 1:length(files)
                
                S = load([agSavePath filesep files(F).name]);
                fn = fieldnames(S);
                fn = fn{1};
                
                if F == 1
                    
                    AGSaveL = S.(fn);
                    
                else %call AGSave methods to append LabX and ArrayStudents structures
                    
                    AGSaveL = addStudentArray(AGSaveL, S.(fn).ArrayStudents);
                    AGSaveL = addLabX(AGSaveL, S.(fn).LabX);
                    
                end
                
            end
            
            %             AGSaveL = AGSaveL.AutoSave2Gradebook(;
            
            AGSaveL = saveAG(AGSaveL);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    end
    
end




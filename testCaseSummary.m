function out = testCaseSummary(ArrayStudents,LabX)
% 1 sheet per problem

%remove special characters in LabX.assignment name
xlsName = [regexprep(LabX.assignmentName,'[^\w]','') , '.xls'];

numStudents = length(ArrayStudents);
numProblems = length(LabX.assignmentProblems);

% 3 columns with { SID | LAST NAME | FIRST NAME }
studentsColumn = {'SID', ArrayStudents.studentSID; 'LAST NAME', ArrayStudents.studentLastName; 'FIRST NAME', ArrayStudents.studentFirstName}';

for P = 1:numProblems
    
    
    numTestCases = length(LabX.assignmentProblems{P}.problemTestCases);
    
    
    for T = 1:numTestCases
        
        %get the number of outputs per test case
        numOutputs{T} = size(LabX.assignmentProblems{P}.problemTestCases{T}.testCasePoints,2);
        
        
        if T == 1
            %Heading (1st row of spreadsheet) with each of the testCase inputs
            sheetHeading{1,T} = LabX.assignmentProblems{P}.problemTestCases{T}.testCaseInput{1};
            colNumb(T) = 1;
        else
            %column number to space out heading column if the testCase
            %input should return multiple outputs
            colNumb(T) = colNumb(T-1) + numOutputs{T-1};
            sheetHeading{1,colNumb(T)} = LabX.assignmentProblems{P}.problemTestCases{T}.testCaseInput{1};
            
        end
    end
    
    
    for S = 1:numStudents
        
        stud = ArrayStudents(S);
        
        if (stud.studentSubmittedProblems{P}.isProblemSubmitted == 1) %if student submitted problem
            
            %get their responses
            for T = 1:numTestCases
                try
                    
                    stuResponse = stud.studentGradedProblems{P}.problemTestCaseResults{T}.studentOutput;
                    
                    for L = 1:length(stuResponse)
                        if size(stuResponse{L},1) == 1
                            allResponses{S,colNumb(T) + L - 1} = stuResponse{L};
                        else
                            allResponses{S,colNumb(T) + L - 1} = 'Student Output Size Mismatch';
                        end
                    end
                    
                catch
                    %Write problem status to spreadsheet if studentOutput
                    %errors out
                    allResponses{S,T} = stud.studentGradedProblems{P}.problemStatus;
                end
            end
            
        else %student didn't submit problem, put '*NS*' in cell
            
            for T = 1:numTestCases
                allResponses{S,T} = '*NS*'; %No Submission
            end
            
        end
        
    end

    %stitch headings and responses together
    compiledCells(1:numStudents+1,1:3) = studentsColumn;
    
    try
        compiledCells(1,4:colNumb(end) + numOutputs{end}) = sheetHeading;
    catch
        display([xlsName ' Heading not properly formatted'])
    end
    
    compiledCells(2:numStudents+1,4:colNumb(end) + numOutputs{end} + 2) = allResponses;
    
    out = xlswrite(xlsName,compiledCells,['Problem ', num2str(P)]);
    
end

end
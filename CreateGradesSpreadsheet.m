agPath = 'C:\Users\Mike\Desktop\Classes\E7\Spring 2012\Autograder';   
writePath = 'C:\Users\Mike\Desktop\Classes\e7\Spring 2012\Labs\Lab2';          
cd(agPath)
clear agPath

% .xls file to create
fName = 'ProblemScores_Lab2_7thru11.xls';

% Load "ArrayStudents" 
load('AutoSave-Lab 2 Data Structures & Functions - Regrade Problems 7-11.mat')

% Names - problem number and function name
problemDisp = {'Problem7','Problem8','Problem9','Problem10','Problem11'};
problemName = {'myTemp', 'mySphere', 'mySplitMatrix', 'myTrip', 'myCosts'};

% Initialize students structure
clear students
students(length(ArrayStudents)).name = [];                  % initialize structure
[students(:).score] = deal(zeros(1,length(problemName)));   % add score field

% Fill students with "names", "score"
for indStudents = 1:length(ArrayStudents)        
    students(indStudents).name = [ArrayStudents(indStudents).studentLastName ', ' ArrayStudents(indStudents).studentFirstName];
    for indProblem = 1:length(problemName)
        students(indStudents).score(indProblem) = ArrayStudents(indStudents).getProblemGrade(problemName{indProblem});         
    end
end

% Convert to list and write to .xls file
listScores = reshape([students(:).score],5,[])';
cd(writePath)
if exist(fName,'file')  % delete existing version of fName
    delete(fName)
end
xlswrite(fName,['Student Names';{students(:).name}'],sprintf('A2:A%i',length(ArrayStudents)+2));
xlswrite(fName,problemDisp, sprintf('B1:%s1', char(double('B')+length(problemName)-1)));
xlswrite(fName,problemName, sprintf('B2:%s2', char(double('B')+length(problemName)-1)));
xlswrite(fName,listScores,sprintf('B3:F%i',length(ArrayStudents)+2));

clear ArrayStudents 

%open created file
dos(fName)




% studentList = {students(([students(:).myTripScore] <= 20)).name};   %creates a cell array of students scoring less than perfect
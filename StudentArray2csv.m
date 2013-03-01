function csv = StudentArray2csv(ArrayStudents)
  dim = size(ArrayStudents, 2);
  numprob = size(ArrayStudents(1,1).studentGradedProblems{1,1}.problemTestCaseResults,2);
  csv = cell(dim, numprob*2+1);
  for i = 1:dim
      csv{i,1} = ArrayStudents(1,i).studentFolderName;
      if strcmp(ArrayStudents(1,i).studentGradedProblems{1,1}.problemStatus, 'GRADED') 
        for k = 1:numprob
          csv{i,k*2} = ArrayStudents(1,i).studentGradedProblems{1,1}.problemTestCaseResults{1,k}.studentOutput{1,1};
          csv{i, k*2+1} = ArrayStudents(1,i).studentGradedProblems{1,1}.problemTestCaseResults{1,k}.pointsAwarded;
        end
      end
  end
end
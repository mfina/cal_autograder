
nStudents = length(studentSubmissions);
nProbs = length(studentSubmissions(1).studentGradedProblems);

%%
for i = 1:nProbs
    
    probs(i).name = studentSubmissions(1).studentGradedProblems{i}.problemName;
    probs(i).testcasePoints = [];
    probs(i).nCases = 0;
    
    for j = 1:nStudents
        
        if length(studentSubmissions(j).studentGradedProblems{i}.problemTestCaseResults) > probs(i).nCases
            probs(i).nCases = length(studentSubmissions(j).studentGradedProblems{i}.problemTestCaseResults);
            
        end
    end
end

%%
for i = 1:nStudents
    for j = 1:nProbs
        
        testcases = zeros(probs(j).nCases,1);
        
        if ~isempty(studentSubmissions(i).studentGradedProblems{j}.problemTestCaseResults);
            for k = 1:probs(j).nCases
                testcases(k) = studentSubmissions(i).studentGradedProblems{j}.problemTestCaseResults{k}.pointsAwarded;
            end
        end
        probs(j).testcasePoints = [probs(j).testcasePoints, testcases];
        
    end
end

%%
figure
for i = 1:nProbs
    subplot(1,nProbs,i)
    hist(probs(i).testcasePoints', 5)
    title(probs(i).name)
    grid on
    L = cell(1,probs(i).nCases);
    for j = 1:probs(i).nCases
        
        L{j} = sprintf('Test Case #%d',j);

    end
    legend(L)
end
function X = randomPopulation(M, N, A)
% https://uk.mathworks.com/matlabcentral/answers/180246-selecting-a-random-number-with-some-probability#comment_1631718
    X = reshape(A(1,sum(A(2,:) < rand(M*N,1)*ones(1,size(A,2)),2)+1),M,N);
end


function [b,P,q,T,R,W] = nipals_pls1(X,y,LV)
% [b,P,q,T,R,W] = nipals_pls1(X,y,LV)
% b = regression coefficients
% P = loadings, X
% q = loadings, y
% T = Scores, X

% Carl Emil Eskildsen, 2017

[n,m] = size(X);        % n samples   
                        % m variables

% Preallocation
T = nan(n,LV);          % scores    (X)
W = nan(m,LV);          % weights   (X)
P = nan(m,LV);          % loadings  (X)
q = nan(LV,1);          % loadings  (y)

for i = 1:LV
    v = X'*y;
    W(:,i) = v/sqrt(v'*v);
    T(:,i) = X*W(:,i);
    tt = T(:,i)'*T(:,i);
    P(:,i) = X'*T(:,i)/tt;
    X = X-T(:,i)*P(:,i)';
    q(i) = T(:,i)'*y/tt;
    b(:,i) = W(:,1:i)*inv(P(:,1:i)'*W(:,1:i))*q(1:i);
    R(:,i) = W(:,1:i)*inv(P(:,1:i)'*W(:,1:i))*q(1:i);
end
end

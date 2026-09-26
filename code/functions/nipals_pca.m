function [T,P,expVar] = nipals_pca(X,LV)
% [T,P,expVar] = nipals_pca(X,LV)

% Carl Emil Eskildsen, 2018
% handles missing values, updated 2024
[I_m,J_m] = find(isnan(X));

I = true(size(X,1),1);
I(unique(I_m)) = false;

J = true(size(X,2),1);
J(unique(J_m)) = false;

M = isnan(X);
X(M) = 0;

SSt = sum(diag(X'*X)); % total sum of squares

[n,m] = size(X);
itmax = 10000;               % max iterations
tol = 1e-4;                 % tolerance

T = zeros(n,LV);            % preallocate matrix for scores
P = zeros(m,LV);            % preallocate matrix for loadings
expVar = zeros(LV,2);       % prealocate vector for explained variance

for i = 1:LV
    it = 0;                 % count iterations
    [~,j] = max(diag(X'*X));
    tit = X(:,j);
    sse = tol+1;
    
    while sse > tol^2
        it = it+1;
        T(:,i) = tit;
        P(:,i) = X(I,:)'*tit(I);
        pp = sqrt(P(J,i)'*P(J,i));
        P(:,i) = P(:,i)/pp;
        tit = X(:,J)*P(J,i);
        sse = (T(:,i)-tit)'*(T(:,i)-tit);
        if itmax < it
            T(:,i) = tit;
            Mdisp('convergence has not been reached')
            break
        end
    end
    
    X = X-T(:,i)*P(:,i)';
    X(M) = 0;

    SSe = sum(diag(X'*X));
    expVar(i,1) = (1-SSe/SSt)*100;
    if i==1
        expVar(i,2) = expVar(i,1);
    else
        expVar(i,2) = expVar(i,1)-expVar(i-1,1);
    end
end

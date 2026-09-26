function M = SavitzkyGolay(X,K,F,Dn)
%% Savitzky-Golay filtering
% M = SavitzkyGolay(spectra, poly.order, window size, derivative order);

[~,g] = sgolaycoef(K,F);
[nrow,ncol] = size(X);
M = zeros(nrow,ncol);
F1 = (F+1)/2;
F2 = -F1+1:F1-1;

for j = F1:ncol-(F-1)/2 % Calculate the n-th derivative of each spectrum
   if Dn == 0
       z = X(:,j + F2)*g(:,1);
   else
       z = X(:,j + F2)*(Dn*g(:,Dn+1));
   end
   M(:,j) = z;
end
end


function [B,G] = sgolaycoef(k,F)
%sgolaycoef         - Computes the Savitsky-Golay coefficients
%function [B,G] = sgolaycoef(k,F)
%where the polynomial order is K and the frame size is F (an odd number)
% Local implementation used by SavitzkyGolay above.

W = eye(F);

s = fliplr(vander(-(F-1)/2:(F-1)/2));

S = s(:,1:k+1);   % Compute the Vandermonde matrix

[~,R] = qr(sqrt(W)*S,0);

G = S/(R)*inv(R)'; % Find the matrix of differentiators

B = G*S'*W; % Compute the projection matrix B
end

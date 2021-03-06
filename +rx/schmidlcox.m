function [ isSynchronized ] = schmidlcox( ra_opp, offset )
%SCHMIDLCOX Implements schmidl-cox iterative time metric calculation
%   Detailed explanation goes here

L = 32; % N_FFT/2

% Remove cyclic prefix and reshape
ra_opp = ra_opp(:,12:75);
ra_opp = reshape(ra_opp.',1,[]);

% imagesc(abs(fft(ra_opp,[],2)))

% Schmidl-cox sliding windows
for ii = 1:length(ra_opp)-2*L
    P(ii) = sqrt(conj(ra_opp(ii:ii-1+L)) * ra_opp(ii+L:ii-1+2*L).');
    R(ii) = ra_opp(ii+L:ii-1+2*L) * ra_opp(ii+L:ii-1+2*L)';
    
    if abs(P(ii))^2 > 10*R(ii) % end of signal
        P(ii) = 0;
        R(ii) = 0;
        break;
    end % endif 
end % endfor

% Timing metric
M = (P .* conj(P) ) ./ (R.^1);

% find peaks
peaks = [];
for jj = 2:length(M)-1
    if ( M(jj) > M(jj-1) ) && ( M(jj) > M(jj+1) )
        peaks = [ peaks; jj M(jj) ];
    end
end

% choose highest n-peaks
n = 24; % <- chosen by trial and error
top_peaks = zeros(n,2);
for kk = 1:n
    [~, idx ] = max( peaks(:,2) );
    top_peaks(kk,:) = peaks(idx,:);
    peaks(idx,:) = [];
end

% order from first to last in time
[~,idx] = sort(top_peaks(:,1));
top_peaks = top_peaks(idx,:);


% now look for two peeks apprx. 1 ofdm symbol apart
for ll = 1:size(top_peaks,1)-1
    tmp = abs(top_peaks(ll+1:end,1) - top_peaks(ll,1) );
    % 2 symbol tolerance
    cmpr = (tmp == 64) | (tmp == 63) | (tmp == 65) | (tmp == 62) | (tmp == 66);
    if sum(cmpr) > 0
        offset_est = top_peaks(ll,1);
        break;
    else
        offset_est = 0;
    end
end

% compare to actual offset with N_CP symbol tolerance
if abs( ((offset+1)*64)+1 - offset_est) < 11
    isSynchronized = true;
else
    isSynchronized = false;
end

% subplot 211
% hold on;
% plot(M);
% plot(top_peaks(:,1),top_peaks(:,2),'go');
% subplot 212
% plot(abs(ra_opp));

end % endfun

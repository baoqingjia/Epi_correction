function [M r offsets] = spin_system3D(L,N,spectrum)
% [M r omega_cs] = SPIN_SYSTEM(L,N,spectrum) creates an array of
% magnetisation vector, an array of coordinates and an array of chemical
% shifts for a given system  size. The dimension of the system can be 1 or 2
% in:
% L: 1 * d array containing the length of the system
% N: 1 * d array containing the number of spins in each dimension
% spectrum: for now, simply an overall offset
% out:
% M: 3 * Ntotal array of magetisation vector initialised to Mz
% r: d * Ntotal array of position
% omega_cs: 1 * Ntotal array of chemical shifts


if any(L) < 0
    error('The length of the system should be positive')
end
if size(L) ~= size(N)
    error('Format: L and N should the same size')
end
if size(L,1) ~= 1
    error('Format: L and N should have a size 1 * d, where d is the dimension')
end
if any(abs(N-floor(N))) > eps
    error('The number of spins should be an integer')
end
if ~isscalar(spectrum)
    error('For now, spectrum should be a scalar')
end


% Calculate the positions of the spins and the total number of spins, for a
% system of dimension 1 or 2
switch size(L,2)
    
    case 1
        
        r = L/N * ((0:N-1) - N/2)';
        nspins = N;
        
    case 2
        
        % Each spin is given a one dimensional index
        % index = indexx + Nx * (indexy-1)
        r = zeros(N(1)*N(2),2);
        for indexx = 1:N(1)
            for indexy = 1:N(2)
                index = indexx + N(1) * (indexy-1);
                r(index,1) = L(1)/N(1) * ((indexx-1) - N(1)/2);
                r(index,2) = L(2)/N(2) * ((indexy-1) - N(2)/2);
            end
        end
        
        nspins = N(1) * N(2);
        
    case 3
        
        % Each spin is given a one dimensional index
        % index = indexx + Nx * (indexy-1)
        r = zeros(N(1)*N(2)*N(3),3);
        for indexx = 1:N(1)
            for indexy = 1:N(2)
                for indexz = 1:N(3)
                    index = indexx + N(1) * (indexy-1) + N(1)*N(2) * (indexz-1);
                    r(index,1) = L(1)/N(1) * ((indexx-1) - N(1)/2);
                    r(index,2) = L(2)/N(2) * ((indexy-1) - N(2)/2);
                    r(index,3) = L(3)/N(3) * ((indexz-1) - N(3)/2);
                end
            end
        end
        
        xtemp=-L(1)/2:L(1)/N(1):-L(1)/2+(N(1)-1)*(L(1)/N(1));
        ytemp=-L(2)/2:L(2)/N(2):-L(2)/2+(N(2)-1)*(L(2)/N(2));
        ztemp=-L(3)/2:L(3)/N(3):-L(3)/2+(N(3)-1)*(L(3)/N(3));
        tempr(:,1)=reshape(repmat(xtemp,1,N(2),N(3)),[],1);
        tempr(:,2)=reshape(repmat(ytemp,N(1),1,N(3)),[],1);
        tempr(:,3)=reshape(repmat(ztemp,N(1),N(2),1),[],1);
        
        nspins = N(1) * N(2) * N(3);
        
    otherwise
        
        error('unsupported dimension')
        
end

% create and initialise the magnetisation vector
M = zeros(nspins,3);
M(:,3) = 1;

% For now, there is a single resonance frequency
offsets = 2 * pi * spectrum * ones(nspins,1);

end
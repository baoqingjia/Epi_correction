function offsets = inhomogeneise3D(offsets,r,N,imap)

a1 = imap.a1;
a2 = imap.a2;
ar = imap.ar;


dimension = size(N,2);

switch dimension
    
    case 1
        
        offsets = offsets + 2*pi*(a1*r + a2*r.^2 + ar*randn(size(r)));
        
    case 2
        
        offsetstemp = reshape(offsets,N(1),N(2));
        rx = reshape(r(:,1),N(1),N(2));
        ry = reshape(r(:,2),N(1),N(2));
        
        offsetstemp = offsetstemp + ...
            2*pi*(a1(1)*rx+a2(1)*rx.^2+a1(2)*ry+a2(2)*ry.^2+...
            ar*randn(size(rx)));
        
        %figure
        %contourf(rx,ry,offsetstemp,'edgecolor','none')
        
        offsets = offsetstemp(:);
        
    case 3
        
        offsetstemp = reshape(offsets,N(1),N(2),N(3));
        rx = reshape(r(:,1),N(1),N(2),N(3));
        ry = reshape(r(:,2),N(1),N(2),N(3));
        rz = reshape(r(:,3),N(1),N(2),N(3));
        offsetstemp = offsetstemp + ...
            2*pi*(a1(1)*rx+a2(1)*rx.^2+a1(2)*ry+a2(2)*ry.^2+ a1(3)*rz+a2(3)*rz.^2+...
            ar*randn(size(rx)));
        
        %figure
        %contourf(rx,ry,offsetstemp,'edgecolor','none')
        
        offsets = offsetstemp(:);
        
    otherwise
        
        error('unknown dimension')
        
end

end
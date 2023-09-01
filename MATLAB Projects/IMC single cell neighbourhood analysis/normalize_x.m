function xNorm = normalize_x(x)
    minX = min(x(:));
    maxX =  max(x(:));
    xNorm = (x)./(maxX-minX);
end
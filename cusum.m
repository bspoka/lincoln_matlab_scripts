function cus = cusum(data)

mn = mean(data);
n = numel(data);
cus = zeros(1, n);
cus(1) = 0;
for a = 2:n    
    cus(a) = cus(a-1)+(data(a)-mn);    
end

end
function normd = norm01(array, mn_range)

mn = mean(array(mn_range));
mx = max(array);

ar_sub = array-mn;
normd = ar_sub./mx;
% 
% sum_ar = sum(abs(array));
% normd = array./sum_ar;

end
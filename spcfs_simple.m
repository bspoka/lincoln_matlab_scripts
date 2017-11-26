function [ft_singl_norm, ft_ens_norm, singl_m_ens_norm, ens_norm, singl_m_ens, ens]...
    = spcfs_simple(all_auto, all_cross, ens_range, singl_range)

    auto_m_cross = (all_auto-all_cross);
    singl = mean(auto_m_cross(:, singl_range), 2);
    ens = mean(auto_m_cross(:, ens_range), 2);

    singl_m_ens = singl-ens;
    singl_m_ens_norm = singl_m_ens./(max(singl_m_ens));
    ens_norm = ens./max(ens);

    ft_singl = abs(fftshift(fft(singl_m_ens_norm)));
    ft_ens = abs(fftshift(fft(ens_norm)));
    ft_singl_norm = ft_singl./max(ft_singl);
    ft_ens_norm = ft_ens./max(ft_ens);


end
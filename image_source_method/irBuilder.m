function h_os = irBuilder(image_sources, L, fs, c, maxTime, absorption_profiles, face_profile_indices, air_absorption)

    % Parameters
    numBands = 6;
    N = round(fs*maxTime);  % Length of IR
    h_os = zeros(N, numBands);   % Multi-band impulse response

    for i = 1:numel(image_sources)
        src = image_sources(i);
        d = norm(src.position - L);
        t = d / c;
        n = round(t * fs) + 1;

        if i == 1
            fprintf('Direct sound arrival time: %.6f seconds (sample %d at fs = %d Hz)\n', t, n, fs);
        end

    
        if n < 1 || n > N
            continue;
        end
    
        % Start with reflection coefficient of 1 (no loss)
        coeff = ones(1, numBands);
    
        % Walk up tree and apply reflection coefficients cumulatively
        current = src;
        while ~isnan(current.parent_index)
            face_id = current.created_by;
            profile_id = face_profile_indices(face_id);
            profile = absorption_profiles(profile_id, :);  % 6-band absorption
            refl = sqrt(1 - profile);                      % reflection coeff
            coeff = coeff .* refl;                         % multiply each band's total
            current = image_sources(current.parent_index);
        end
    
        % --- Apply air absorption PER BAND
        air_loss = (1 - air_absorption).^d;
    
        % --- Distance attenuation (spherical spreading)
        dist_atten = 1 / (4 * pi * d);  % physically more accurate
    
        % --- Final amplitude per band
        amp = coeff .* air_loss * dist_atten;
    
        % --- Add to impulse response
        h_os(n, :) = h_os(n, :) + amp;
    end
end
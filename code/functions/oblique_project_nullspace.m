function t0 = oblique_project_nullspace(t, Q_blank, u_y, mnTblank)
% Oblique projection along the analyte direction onto the blank subspace.
% Solves: (t - mnTblank) = Q_blank*a + u_y*s
% Returns: t0 = mnTblank + Q_blank*a

    B = [Q_blank, u_y];
    cB = cond(B);
    if cB > 1e8
        warning('Oblique projection may be unstable: cond([Q_blank u_y]) = %.2e', cB);
    end

    rhs  = (t - mnTblank)';
    coef = B \ rhs;
    a = coef(1);

    t0 = mnTblank + (Q_blank * a)';
end

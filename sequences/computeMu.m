% mtxMu = computeMu(mtxM, vN)
function mtxMu = computeMu(mtxM, vN)
    % The value $mu_{ij}$ is zero unless both neurons $i$ and $j$ appear in the
    % corresponding sequence $s$. If both $i$ and $j$ appear in the sequence,
    % then $\mu_{ij}(s) = m_{ij}(s) / (n_i n_j) - 1/2$, which is defined since
    % $n_i, n_j \neq 0$.

    % The code below simply computes all mu values according to the above
    % formula. Since the resultant matrix will likely be sparse, we can speed up
    % computation by using sparse matrices.
    mtxDenoms = vN(:) * vN(:)';
    mtxDenomsNonZero = sparse(mtxDenoms ~= 0);
    mtxMu = zeros(size(mtxM));
    mtxMu(mtxDenomsNonZero) = 2 * (mtxM(mtxDenomsNonZero) ./ ...
        mtxDenoms(mtxDenomsNonZero)) - 1;
    mtxMu = mtxMu - diag(diag(mtxMu));
    mtxMu = sparse(mtxMu);
end
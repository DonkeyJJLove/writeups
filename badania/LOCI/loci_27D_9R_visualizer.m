function loci_27D_9R_visualizer(sampleFile)
    clc; close all;

    fprintf('=========================================\n');
    fprintf('LOCI 27D → 9R METASPACE VISUALIZER\n');
    fprintf('=========================================\n');

    % ----------------------------------------
    % 1. LOAD + FEATURE EXTRACTION
    % ----------------------------------------
    data = parse_sample_0001n_fixed(sampleFile);
    T = i_extract_features(data);

    fprintf('Generations: %d\n', height(T));

    % ----------------------------------------
    % 2. NORMALIZACJA → [0,1] (Hypercube)
    % ----------------------------------------
    X = normalize(T{:,:}, 'range');

    % ----------------------------------------
    % 3. MAPOWANIE → 27D
    % (rozszerzenie przestrzeni cech)
    % ----------------------------------------
    X27 = i_expand_to_27D(X);

    % ----------------------------------------
    % 4. PROJEKCJA → 9R (PCA)
    % ----------------------------------------
    [coeff, score] = pca(X27);

    X9 = score(:,1:9);

    % ----------------------------------------
    % 5. TRAJEKTORIA (kolejne generacje)
    % ----------------------------------------
    steps = sqrt(sum(diff(X9).^2,2));
    steps = [0; steps];

    % LOCI (heurystycznie: max gradient kroku)
    [~, onset] = max(movmean(steps,5));

    % ----------------------------------------
    % 6. WIZUALIZACJA
    % ----------------------------------------

    figure('Color','k','Position',[100 100 1400 900]);

    % === (1) TRAJEKTORIA 3D ===
    subplot(2,2,1)
    scatter3(X9(:,1), X9(:,2), X9(:,3), 30, (1:length(X9)),'filled');
    hold on
    plot3(X9(:,1), X9(:,2), X9(:,3), 'w-','LineWidth',1)

    scatter3(X9(onset,1), X9(onset,2), X9(onset,3), ...
        120,'r','filled')

    title('Trajektoria artefaktu (9R)','Color','w')
    xlabel('R1'); ylabel('R2'); zlabel('R3')
    grid on
    set(gca,'Color','k','XColor','w','YColor','w','ZColor','w')

    % === (2) DŁUGOŚĆ KROKU ===
    subplot(2,2,2)
    plot(steps,'c','LineWidth',1.5)
    hold on
    xline(onset,'r--','LineWidth',2)

    title('Dynamika trajektorii','Color','w')
    xlabel('Generacja'); ylabel('||Δx||')
    grid on
    set(gca,'Color','k','XColor','w','YColor','w')

    % === (3) GĘSTOŚĆ (NN distance) ===
    subplot(2,2,3)
    D = pdist2(X9,X9);
    D(D==0)=inf;
    nn = min(D,[],2);

    plot(nn,'y','LineWidth',1.5)
    hold on
    xline(onset,'r--')

    title('Gęstość (Nearest Neighbor)','Color','w')
    xlabel('Generacja'); ylabel('distance')
    grid on
    set(gca,'Color','k','XColor','w','YColor','w')

    % === (4) PROJEKCJA 2D + EWOLUCJA ===
    subplot(2,2,4)
    scatter(X9(:,1), X9(:,2), 40, steps,'filled')
    hold on
    plot(X9(:,1), X9(:,2),'w-')

    scatter(X9(onset,1), X9(onset,2),120,'r','filled')

    title('Projekcja 2D (R1-R2)','Color','w')
    xlabel('R1'); ylabel('R2')
    grid on
    set(gca,'Color','k','XColor','w','YColor','w')

    colormap turbo
    colorbar

    fprintf('\n=== META-WYNIKI ===\n');
    fprintf('Onset (LOCI approx): G%04d\n', onset);
    fprintf('Mean step          : %.4f\n', mean(steps));
    fprintf('Max step           : %.4f\n', max(steps));
    fprintf('Trajectory length  : %.4f\n', sum(steps));

end


% =========================================
% FEATURE EXTRACTION
% =========================================
function T = i_extract_features(data)

    n = length(data.entries);

    len = zeros(n,1);
    tokens = zeros(n,1);
    entropy = zeros(n,1);
    uniq = zeros(n,1);

    for i=1:n
        txt = char(data.entries(i).text);

        len(i) = strlength(txt);

        words = split(txt);
        tokens(i) = length(words);

        uniq(i) = length(unique(words)) / max(1,tokens(i));

        p = histcounts(double(txt),256,'Normalization','probability');
        p(p==0)=[];
        entropy(i) = -sum(p.*log2(p));
    end

    d_len = [0; diff(len)];
    d_tokens = [0; diff(tokens)];

    T = table(len, tokens, uniq, entropy, d_len, d_tokens);

end


% =========================================
% EXPANSJA DO 27D
% =========================================
function X27 = i_expand_to_27D(X)

    % bazowe cechy
    base = X;

    % interakcje (kwadratowe)
    sq = X.^2;

    % interakcje krzyżowe
    cross = [];

    for i=1:size(X,2)
        for j=i+1:size(X,2)
            cross = [cross X(:,i).*X(:,j)];
        end
    end

    % sklejenie
    X27 = [base sq cross];

    % przycięcie / dopasowanie do 27
    if size(X27,2) > 27
        X27 = X27(:,1:27);
    elseif size(X27,2) < 27
        X27 = [X27 zeros(size(X27,1),27-size(X27,2))];
    end

end
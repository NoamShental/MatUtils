function [score, cache] = my_score_dags(data, ns, dags, varargin)
% my_score_dags Compute the score of one or more DAGs
% score = score_dags(data, ns, dags, varargin)
%
% data{i,m} = value of node i in case m (can be a cell array).
% node_sizes(i) is the number of size of node i.
% dags{g} is the g'th dag
% score(g) is the score of the i'th dag
%
% The following optional arguments can be specified in the form of name/value pairs:
% [default value in brackets]
%
% scoring_fn - 'bayesian' or 'bic' [ 'bayesian' ]
%              Currently, only networks with all tabular nodes support Bayesian scoring.
% type       - type{i} is the type of CPD to use for node i, where the type is a string
%              of the form 'tabular', 'noisy_or', 'gaussian', etc. [ all cells contain 'tabular' ]
% params     - params{i} contains optional arguments passed to the CPD constructor for node i,
%              or [] if none.  [ all cells contain {'prior', 1}, meaning use uniform Dirichlet priors ]
% discrete   - the list of discrete nodes [ 1:N ]
% clamped    - clamped(i,m) = 1 if node i is clamped in case m [ zeros(N, ncases) ]
% cache      - data structure used to memorize local score computations (cf. GENER_EMPTY_CACHE function) [ [] ]
%
% e.g., score = score_dags(data, ns, mk_all_dags(n), 'scoring_fn', 'bic', 'params', [],'cache',cache);
%
% (Caching implementation : olivier.francois@insa-rouen.fr, philippe.leray@insa-rouen.fr)

[n ncases] = size(data);

% set default params
type = cell(1,n);
params = cell(1,n);
%cache=[];
for i=1:n
    type{i} = 'tabular';
    params{i} = { 'prior_type', 'dirichlet', 'dirichlet_weight', 1 };
end
scoring_fn = 'bayesian';
discrete = 1:n;
clamped = zeros(n, ncases);

args = varargin;
nargs = length(args);
for i=1:2:nargs
    switch args{i},
        case 'scoring_fn', scoring_fn = args{i+1};
        case 'type',       type = args{i+1};
        case 'discrete',   discrete = args{i+1};
        case 'clamped',    clamped = args{i+1};
        case 'params',     if isempty(args{i+1}), params = cell(1,n); else params = args{i+1};  end
            %   case 'cache',      cache=args{i+1} ;
    end
end

NG = length(dags);
score = zeros(1, NG);

% Go over all the variables
for j=1:n
    % set ps to zeros
    ps = zeros(NG,n);

    for g=1:NG
        % Find the parents
        temp_ps = parents(dags{g}, j);
        ps(g,1:length(temp_ps)) = temp_ps;
    end

    % Do the unique
    psu = unique(ps, 'rows');   
  
    scor = zeros(1, NG);

    
    % Now do the scoring ...
    for g=1:size(psu, 1) 
        u = find(clamped(j,:)==0);
        scor(g)  = score_family(j, psu(g, find(psu(g,:)))   , type{j}, scoring_fn, ns, discrete, data(:,u), params{j});
    end

    for g=1:NG
        gg = 1;
        for gg=1:length(psu)
            if(ps(g,:) == psu(gg,:))
                % Update the score
                score(g) = score(g) + scor(gg);
                break;
            end
        end
    end

end

